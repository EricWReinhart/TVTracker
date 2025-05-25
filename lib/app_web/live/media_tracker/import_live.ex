defmodule AppWeb.ImportLive do
  use AppWeb, :live_view

  alias App.Media
  alias App.Accounts

  @impl true
  def mount(_params, session, socket) do
    current_user =
      case session["user_token"] do
        nil -> nil
        token -> Accounts.get_user_by_session_token(token)
      end

    {:ok,
     socket
     |> assign(:current_user, current_user)
     |> allow_upload(:import,
          accept: ~w(.json),
          max_entries: 1,
          max_file_size: 2_000_000
        )}
  end

  @impl true
  def handle_event("validate_import", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("import_json", _params, socket) do
    user = socket.assigns.current_user

    results =
      consume_uploaded_entries(socket, :import, fn %{path: path}, _entry ->
        contents = File.read!(path)

        case Jason.decode(contents) do
          {:ok, %{"finished" => f, "in_progress" => i, "watchlist" => w}} ->
            # Use existing Media.add_show_to_user/3 API
            Enum.each(f, fn item -> upsert_from_json(user, :finished, item) end)
            Enum.each(i, fn item -> upsert_from_json(user, :in_progress, item) end)
            Enum.each(w, fn item -> upsert_from_json(user, :watchlist, item) end)
            {:ok, :imported}

          _ ->
            {:error, :bad_json}
        end
      end)

    msg =
      if Enum.any?(results, fn result -> match?({:error, _}, result) end) do
        "Import failed: invalid JSON format"
      else
        "Import successful"
      end

    {:noreply,
     socket
     |> put_flash(:info, msg)}
  end

  defp upsert_from_json(user, status, %{"imdb_id" => id, "user_rating" => r, "watch_year" => y}) do
    # Delegate to existing Media context API
    attrs = %{imdb_id: id, user_rating: r, watch_year: y}
    Media.add_show_to_user(user, attrs, status)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="container mx-auto px-4 py-8 space-y-4">
      <h2 class="text-xl font-semibold">Import MediaTracker JSON</h2>
      <form
        id="json-import-form"
        phx-submit="import_json"
        phx-change="validate_import"
        class="mb-6"
      >
        <.live_file_input upload={@uploads.import} class="block mb-2" />

        <button
          type="submit"
          class="px-4 py-2 bg-green-600 text-white rounded"
          disabled={@uploads.import.entries == []}
        >
          Upload & Import
        </button>

        <p :for={err <- upload_errors(@uploads.import)} class="mt-2 text-sm text-red-600">
          <%= case err do
              :too_large -> "That file is too large."
              :not_accepted -> "Please select a .json file."
              _ -> "Upload error: #{inspect(err)}"
            end %>
        </p>
      </form>
    </div>
    """
  end
end
