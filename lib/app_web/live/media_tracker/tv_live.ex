defmodule AppWeb.TVLive do
  use AppWeb, :live_view

  alias App.Media
  alias App.Accounts
  alias App.Media.Backup


  @impl true
  def mount(_params, session, socket) do
    current_user =
      case session["user_token"] do
        nil   -> nil
        token -> Accounts.get_user_by_session_token(token)
      end

    socket =
      socket
      |> assign(
        current_user:   current_user,
        edit_mode:      false,
        open_edit:      false,
        edit_show:      nil,
        open_delete:    false,
        delete_show:    nil,
        open_sections:  MapSet.new([:finished, :in_progress, :watchlist]),
        import_modal:   false
      )
      |> load_lists()
      |> allow_upload(:import,
          accept: ~w(.json),
          max_entries: 1,
          max_file_size: 2_000_000
      )

    {:ok, socket}
  end

  defp load_lists(socket) do
    user = socket.assigns.current_user

    socket
    |> assign(
      finished:    Media.list_user_shows(user, :finished),
      in_progress: Media.list_user_shows(user, :in_progress),
      watchlist:   Media.list_user_shows(user, :watchlist)
    )
  end

  @impl true
  def handle_event("toggle_section", %{"section" => section}, socket) do
    sect = String.to_existing_atom(section)
    open = socket.assigns.open_sections

    open =
      if MapSet.member?(open, sect) do
        MapSet.delete(open, sect)
      else
        MapSet.put(open, sect)
      end

    {:noreply, assign(socket, open_sections: open)}
  end

  @impl true
  def handle_event("toggle_edit", _params, socket) do
    {:noreply, assign(socket, edit_mode: !socket.assigns.edit_mode)}
  end

  @impl true
  def handle_event("cancel_edit", _params, socket) do
    {:noreply, assign(socket, open_edit: false, edit_show: nil)}
  end

  @impl true
  def handle_event("toggle_favorite", %{"id" => id}, socket) do
    user = socket.assigns.current_user
    tv_id = String.to_integer(id)

    case Media.toggle_favorite(user, tv_id) do
      {:ok, _} -> {:noreply, load_lists(socket)}
      {:error, _} -> {:noreply, socket |> put_flash(:error, "Could not update favorite")}
    end
  end

  @impl true
  def handle_event("prompt_delete", %{"id" => id}, socket) do
    user = socket.assigns.current_user
    tv_id = String.to_integer(id)

    case Media.get_user_tv_show(user, tv_id) do
      {:ok, join} ->
        {:noreply,
         socket
         |> assign(open_delete: true)
         |> assign(delete_show: join)}

      _ ->
        {:noreply, socket |> put_flash(:error, "Could not find show to delete")}
    end
  end

  @impl true
  def handle_event("cancel_delete", _params, socket) do
    {:noreply,
     socket
     |> assign(open_delete: false)
     |> assign(delete_show: nil)}
  end

  @impl true
  def handle_event("confirm_delete", _params, socket) do
    user = socket.assigns.current_user
    %App.Media.UserTvShow{tv_show_id: tv_id} = socket.assigns.delete_show

    case Media.delete_user_show(user, tv_id) do
      :ok ->
        {:noreply,
         socket
         |> assign(open_delete: false, delete_show: nil)
         |> load_lists()}

      {:error, _} ->
        {:noreply,
         socket
         |> put_flash(:error, "Could not delete show")
         |> assign(open_delete: false, delete_show: nil)}
    end
  end

  @impl true
  def handle_event("edit_show", %{"id" => id}, socket) do
    user = socket.assigns.current_user
    tv_id = String.to_integer(id)

    case Media.get_user_tv_show(user, tv_id) do
      {:ok, join} ->
        {:noreply,
         socket
         |> assign(open_edit: true)
         |> assign(edit_show: join)}

      _ ->
        {:noreply, socket |> put_flash(:error, "Could not load show for editing")}
    end
  end

  @impl true
  def handle_event("confirm_edit", params, socket) do
    %App.Media.UserTvShow{id: join_id, status: status} = socket.assigns.edit_show

    # pull out the year (or nil)
    watch_year =
      case params["watch_year"] do
        "" -> nil
        wy -> wy
      end

    # pull out the rating (or nil even if the key is absent)
    user_rating =
      case Map.get(params, "user_rating", "") do
        ur when ur != "" ->
          case Float.parse(ur) do
            {val, _} -> val
            _        -> nil
          end

        _ -> nil
      end

    case Media.update_user_show(join_id, %{watch_year: watch_year, user_rating: user_rating}) do
      {:ok, updated_join} ->
        list_key = String.to_existing_atom(status)
        old_list = Map.fetch!(socket.assigns, list_key)

        new_list =
          Enum.map(old_list, fn
            %App.Media.UserTvShow{id: ^join_id} -> updated_join
            other -> other
          end)

        {:noreply,
        socket
        |> put_flash(:info, "Your changes have been saved!")
        |> assign(open_edit: false, edit_show: nil)
        |> assign(list_key, new_list)}

      {:error, _} ->
        {:noreply, socket |> put_flash(:error, "Could not save changes")}
    end
  end


  @impl true
  def handle_event("export_json", _params, socket) do
    {:ok, json} = Backup.export_user_lists(socket.assigns.current_user)

    socket =
      push_event(socket, "download_media_backup", %{
        filename: "media_backup.json",
        content: json
      })

    {:noreply, socket}
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
     |> put_flash(:info, msg)
     |> assign(import_modal: false)
     |> load_lists()}
  end

  @impl true
  def handle_event("open_import", _params, socket) do
    {:noreply, assign(socket, import_modal: true)}
  end

  @impl true
  def handle_event("close_import", _params, socket) do
    {:noreply, assign(socket, import_modal: false)}
  end

  defp upsert_from_json(user, status, %{"imdb_id" => id, "user_rating" => r, "watch_year" => y}) do
    attrs = %{imdb_id: id, user_rating: r, watch_year: y}
    Media.add_show_to_user(user, attrs, status)
  end


  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen p-6 bg-white dark:bg-gray-900 dark:text-gray-100">
    <!-- Header (centered) -->
    <div class="text-center mb-8">
      <h1 class="text-4xl font-bold text-gray-900 dark:text-gray-100 mb-2">
        Your TV Show Library
      </h1>
      <p class="text-lg text-gray-600 dark:text-gray-300 mb-4">
        Keep track of your favorite shows, view details, and manage your watchlist seamlessly.
      </p>
      <p class="text-sm text-gray-500 dark:text-gray-400">
        💡 Tip: click on any show title to view its details & episode stats.
      </p>
    </div>

      <!-- Import / Export controls -->
      <div class="flex flex-col sm:flex-row justify-center items-center gap-3 mb-6">
        <button
          phx-click="open_import"
          class="flex items-center space-x-2 px-4 py-3 bg-emerald-600 hover:bg-emerald-700 dark:bg-emerald-500 dark:hover:bg-emerald-600 text-white rounded-full shadow"
        >
          <!-- import icon -->
          <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none"
              viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                  d="M4 16v4h16v-4M12 12v8M8 12l4-4 4 4"/>
          </svg>
          <span>Import TV Data</span>
        </button>

        <.modal
          :if={@import_modal}
          id="import-json-modal"
          show
          heading="Import TVTracker JSON"
          on_cancel={JS.push("close_import")}
        >
          <div class="p-6 space-y-4 bg-white dark:bg-gray-800 text-gray-900 dark:text-gray-100">
            <form phx-submit="import_json" phx-change="validate_import" class="space-y-4">
              <.live_file_input
                upload={@uploads.import}
                class="block w-full bg-gray-50 dark:bg-gray-700 text-gray-900 dark:text-gray-200
                      border border-gray-300 dark:border-gray-600 rounded p-2"
              />

              <.button
                type="submit"
                class="w-full"
                disabled={@uploads.import.entries == []}
              >
                Upload &amp; Import
              </.button>

              <%= for err <- upload_errors(@uploads.import) do %>
                <p class="text-sm text-red-600 dark:text-red-400">
                  <%= case err do
                        :too_large    -> "That file is too large."
                        :not_accepted -> "Please select a .json file."
                        _             -> "Upload error: #{inspect(err)}"
                      end %>
                </p>
              <% end %>
            </form>
          </div>
        </.modal>

        <div id="media-export" phx-hook="Downloader">
          <button
            phx-click="export_json"
            class="flex items-center space-x-2 px-4 py-3 bg-indigo-600 hover:bg-indigo-700 dark:bg-indigo-500 dark:hover:bg-indigo-600 text-white rounded-full shadow"
          >
            <!-- download icon -->
            <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none"
                viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                    d="M4 16v2a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2v-2 M7 10l5 5 5-5 M12 15V4"/>
            </svg>
            <span>Download Backup</span>
          </button>
        </div>

        <button
          phx-click="toggle_edit"
          class="flex items-center space-x-2 px-4 py-3 bg-blue-500 text-white hover:bg-blue-600 dark:bg-blue-400 dark:hover:bg-blue-500 rounded-full shadow"
        >
          <span><%= if @edit_mode, do: "Done Editing", else: "Edit List" %></span>
        </button>
      </div>


      <!-- Delete Confirmation Modal -->
      <%= if @open_delete do %>
        <div class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div class="bg-white dark:bg-gray-800 p-6 rounded-lg shadow-lg w-full max-w-sm">
            <p class="mb-4 text-center text-gray-900 dark:text-gray-100">
              Are you sure you want to delete "<%= @delete_show.tv_show.title %>"?
            </p>
            <div class="flex justify-end space-x-2">
              <button phx-click="cancel_delete"
                      class="px-4 py-2 bg-gray-300 hover:bg-gray-400 dark:bg-gray-600 dark:hover:bg-gray-500 rounded">
                Cancel
              </button>
              <button phx-click="confirm_delete"
                      class="px-4 py-2 bg-red-500 hover:bg-red-600 dark:bg-red-400 dark:hover:bg-red-500 text-white rounded">
                Delete
              </button>
            </div>
          </div>
        </div>
      <% end %>

      <!-- Dropdown Sections -->
      <div class="space-y-6">
        <%= for {key, list} <- [
              {"finished",    Enum.sort_by(@finished,    &(&1.user_rating || 0), :desc)},
              {"in_progress", Enum.sort_by(@in_progress, &(&1.user_rating || 0), :desc)},
              {"watchlist",   Enum.sort_by(@watchlist,   &(&1.user_rating || 0), :desc)}
            ] do %>

          <div class="border border-gray-200 dark:border-gray-700 rounded">
            <button
              phx-click="toggle_section"
              phx-value-section={key}
              class="w-full px-4 py-2 text-left bg-gray-100 hover:bg-gray-200 dark:bg-gray-700 dark:hover:bg-gray-600 flex justify-between items-center"
            >
              <span class="font-medium text-gray-900 dark:text-gray-100">
                <%= key
                    |> String.split("_")
                    |> Enum.map(&String.capitalize/1)
                    |> Enum.join(" ") %>
              </span>
              <svg
                class={"w-4 h-4 transform transition-transform duration-200 #{if String.to_existing_atom(key) in @open_sections, do: "rotate-180"}"}
                xmlns="http://www.w3.org/2000/svg"
                fill="none"
                viewBox="0 0 10 6"
              >
                <path stroke="currentColor" stroke-width="2" d="M9 5 5 1 1 5"/>
              </svg>
            </button>

            <div
              class={
                "overflow-hidden transition-all duration-300 ease-out " <>
                if String.to_existing_atom(key) in @open_sections,
                  do: "max-h-[1000px] opacity-100",
                  else: "max-h-0 opacity-0"
              }
            >
              <div class="flex flex-wrap gap-4 p-4">
                <%= if list == [] do %>
                  <p class="italic text-gray-500 dark:text-gray-400">No shows yet.</p>
                <% else %>
                  <%= for uts <- list do %>
                    <% show = uts.tv_show %>

                    <div class="flex-none w-48 bg-white dark:bg-gray-800 shadow rounded overflow-hidden relative">
                      <!-- Favorite star -->
                      <span
                        phx-click="toggle_favorite"
                        phx-value-id={show.id}
                        class="absolute top-2 right-2 text-yellow-400 text-xl cursor-pointer"
                      >
                        <%= if show.favorite, do: "★", else: "☆" %>
                      </span>

                      <!-- Edit/Delete icons in edit_mode -->
                      <%= if @edit_mode do %>
                        <span
                          phx-click="edit_show"
                          phx-value-id={show.id}
                          class="absolute top-2 right-8 text-xl leading-none text-gray-600 dark:text-gray-300 cursor-pointer"
                        >
                          ✏️
                        </span>
                        <span
                          phx-click="prompt_delete"
                          phx-value-id={show.id}
                          class="absolute top-2 right-14 text-xl leading-none text-red-500 dark:text-red-500 hover:text-red-700 cursor-pointer"
                        >
                          &times;
                        </span>
                      <% end %>

                      <div class="px-2 py-1 flex flex-col justify-start h-16 space-y-1">
                        <h4 class="font-bold text-sm leading-tight text-gray-900 dark:text-gray-100">
                          <.link
                            navigate={~p"/tvtracker/library/#{show.id}"}
                            class="inline-flex items-center text-blue-600 dark:text-blue-400 hover:underline hover:text-blue-800 dark:hover:text-blue-300 cursor-pointer"
                          >
                            <span><%= show.title %></span>
                            <svg xmlns="http://www.w3.org/2000/svg"
                                class="h-4 w-4 ml-1"
                                fill="none" viewBox="0 0 24 24"
                                stroke="currentColor">
                              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                                    d="M9 5l7 7-7 7"/>
                            </svg>
                          </.link>
                        </h4>
                        <p class="text-xs text-gray-500 dark:text-gray-400">
                          <%= cond do
                            uts.watch_year && uts.status == "in_progress" -> "Started: #{uts.watch_year}"
                            uts.watch_year && uts.status == "watchlist"   -> "Planned: #{uts.watch_year}"
                            uts.watch_year                                  -> "Watched: #{uts.watch_year}"
                            true                                            -> ""
                          end %>
                        </p>
                        <p class="text-xs text-gray-500 dark:text-gray-400">
                          <%= if uts.user_rating, do: "Your Rating: #{uts.user_rating}", else: "\u00A0" %>
                        </p>
                      </div>

                      <div class="w-full h-64 bg-gray-100 dark:bg-gray-700">
                        <img
                          src={show.poster}
                          alt={show.title}
                          class="w-full h-full object-contain"
                        />
                      </div>
                    </div>
                  <% end %>
                <% end %>
              </div>
            </div>
          </div>
        <% end %>
      </div>


      <!-- Edit Modal -->
      <.modal
        :if={@open_edit}
        id="edit-show-modal"
        show
        heading={"Edit \"#{@edit_show.tv_show.title}\""}
        on_cancel={JS.push("cancel_edit")}
      >
        <div class="p-6 space-y-4 bg-white dark:bg-gray-800 text-gray-900 dark:text-gray-100">
          <form phx-submit="confirm_edit" class="space-y-4">
            <% label_year =
                if @edit_show.status == "in_progress",
                  do: "Year Started (optional)",
                  else: "Year Watched (optional)"
            %>
            <div>
              <label class="block mb-1 font-medium dark:text-gray-200"><%= label_year %></label>
              <select
                name="watch_year"
                class="w-full border border-gray-300 dark:border-gray-600 rounded px-2 py-1
                      bg-white dark:bg-gray-700 text-gray-900 dark:text-gray-100
                      focus:outline-none focus:ring-2 focus:ring-blue-400"
              >
                <option value="" selected={is_nil(@edit_show.watch_year)}>—</option>
                <%= for year <- 2025..2015//-1 do %>
                  <option
                    value={to_string(year)}
                    selected={to_string(year) == @edit_show.watch_year}
                  ><%= year %></option>
                <% end %>
              </select>
            </div>

            <%= if @edit_show.status != "watchlist" do %>
              <div>
                <label class="block mb-1 font-medium dark:text-gray-200">Your Rating (optional)</label>
                <input
                  name="user_rating"
                  type="number"
                  step="0.1"
                  min="0"
                  max="10"
                  value={@edit_show.user_rating}
                  class="w-full border border-gray-300 dark:border-gray-600 rounded px-2 py-1
                        bg-white dark:bg-gray-700 text-gray-900 dark:text-gray-100
                        focus:outline-none focus:ring-2 focus:ring-blue-400"
                />
              </div>
            <% end %>

            <div class="flex justify-end space-x-2">
              <.button type="button" phx-click="cancel_edit">
                Cancel
              </.button>
              <.button type="submit">
                Save
              </.button>
            </div>
          </form>
        </div>
      </.modal>
    </div>
    """
  end
end
