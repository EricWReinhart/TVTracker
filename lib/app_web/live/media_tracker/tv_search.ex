defmodule AppWeb.TVSearch do
  use AppWeb, :live_view

  alias AppWeb.OMDb
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
     |> assign(current_user: current_user)
     |> assign(query: "", show: nil, error: nil)
     |> assign(open_modal: false, show_to_add: nil, add_status: nil)
     |> assign(suggestions: [])}
  end

  @impl true
  def handle_params(%{"query" => q}, _uri, socket) do
    decoded = URI.decode(q)
    socket = assign(socket, query: decoded, error: nil)
    send(self(), {:run_search, decoded})
    {:noreply, socket}
  end

  @impl true
  def handle_params(_params, _uri, socket) do
    # no query → just render the empty search page
    {:noreply, socket}
  end

  @impl true
  def handle_info({:run_search, q}, socket) do
    case OMDb.fetch_by_title(q) do
      {:ok, show} ->
        {:noreply,
         socket
         |> assign(show: show, suggestions: [], error: nil)}

      {:error, reason} ->
        {:noreply,
         socket
         |> assign(show: nil, suggestions: [], error: reason)}
    end
  end

  @impl true
  def handle_event("search", %{"query" => q}, socket) do
    q = String.trim(q)

    socket = assign(socket, suggestions: [])

    if q == "" do
      {:noreply, assign(socket, error: "Please enter a title", show: nil)}
    else
      case OMDb.fetch_by_title(q) do
        {:ok, show} ->
          {:noreply,
           socket
           |> assign(show: show, error: nil, query: q)
           |> assign(suggestions: [])}

        {:error, msg} ->
          {:noreply,
           socket
           |> assign(error: msg, show: nil, query: q)
           |> assign(suggestions: [])}
      end
    end
  end

  @impl true
  def handle_event("add_to_list", %{"status" => status}, socket) do
    if socket.assigns.current_user do
      {:noreply,
       assign(socket,
         open_modal: true,
         show_to_add: socket.assigns.show,
         add_status: status
       )}
    else
      {:noreply, put_flash(socket, :error, "Please log in to add shows")}
    end
  end

  @impl true
  def handle_event("cancel_add", _params, socket) do
    {:noreply,
     assign(socket,
       open_modal: false,
       show_to_add: nil,
       add_status: nil
     )}
  end

  @impl true
  def handle_event("confirm_add", params, socket) do
    user = socket.assigns.current_user
    show = socket.assigns.show_to_add
    status = socket.assigns.add_status

    wy = Map.get(params, "watch_year", "")
    ur = Map.get(params, "user_rating", "")

    watch_year = if wy != "", do: wy, else: nil
    user_rating =
      case Float.parse(ur) do
        {val, _} -> val
        _ -> nil
      end

    show_attrs = %{
      imdb_id:     show.imdb_id,
      title:       show.title,
      year:        show.year,
      rating:      show.imdb_rating,
      poster:      show.poster,
      runtime:     show.runtime,
      watch_year:  watch_year,
      user_rating: user_rating
    }

    case Media.add_show_to_user(user, show_attrs, String.to_atom(status)) do
      {:ok, _} ->
        friendly =
          status
          |> String.split("_")
          |> Enum.map(&String.capitalize/1)
          |> Enum.join(" ")

        {:noreply,
         socket
         |> put_flash(:info, "#{show.title} added to #{friendly}")
         |> assign(
           open_modal: false,
           show_to_add: nil,
           add_status: nil
         )}

      {:error, changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, "Could not add: #{inspect(changeset.errors)}")
         |> assign(
           open_modal: false,
           show_to_add: nil,
           add_status: nil
         )}
    end
  end

  @impl true
  def handle_event("suggest", %{"query" => q}, socket) do
    q = String.trim(q)
    suggestions =
      if q == "" do
        []
      else
        OMDb.search_shows(q)
      end

    {:noreply, assign(socket, suggestions: suggestions, query: q)}
  end

  @impl true
  def handle_event("select", %{"title" => title}, socket) do
    case OMDb.fetch_by_title(title) do
      {:ok, show} ->
        {:noreply,
         socket
         |> assign(show: show, query: title)
         |> assign(suggestions: [], error: nil)}

      {:error, msg} ->
        {:noreply,
         socket
         |> assign(show: nil, error: msg)
         |> assign(suggestions: [])}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="p-6 max-w-4xl mx-auto space-y-12">
      <!-- Page header -->
      <header class="text-center mb-8">
        <h1 class="text-4xl font-bold text-gray-900 dark:text-gray-100 mb-2">
          TV Show Finder
        </h1>
        <p class="text-lg text-gray-600 dark:text-gray-300 mb-4">
          Search any TV show, preview its details, and add it to your Watchlist, mark it In Progress, or mark as Finished.
        </p>
      </header>


      <!-- Flash messages -->
      <%= if info = @flash[:info] do %>
        <div class="bg-green-100 dark:bg-green-900 text-green-800 dark:text-green-200 p-3 rounded-lg shadow">
          <%= info %>
        </div>
      <% end %>
      <%= if err = @flash[:error] do %>
        <div class="bg-red-100 dark:bg-red-900 text-red-800 dark:text-red-200 p-3 rounded-lg shadow">
          <%= err %>
        </div>
      <% end %>

      <!-- Search Card -->
      <div class="bg-white dark:bg-gray-800 shadow-lg rounded-lg p-4">
        <form phx-submit="search" class="flex items-stretch">
          <div class="relative flex-grow">
            <input
              name="query"
              value={@query}
              placeholder="Search for TV show..."
              phx-change="suggest"
              phx-debounce="300"
              autocomplete="off"
              class="w-full border dark:border-gray-600 dark:bg-gray-700 dark:text-white placeholder-gray-500 dark:placeholder-gray-400 rounded-l px-3 py-2 focus:outline-none focus:ring-2 focus:ring-blue-400"
            />
            <%= if @suggestions != [] do %>
              <ul class="absolute z-20 bg-white dark:bg-gray-700 ring-1 ring-black ring-opacity-5 rounded-b mt-1 w-full max-h-48 overflow-auto">
                <%= for title <- @suggestions do %>
                  <li
                    phx-click="select"
                    phx-value-title={title}
                    class="px-3 py-2 hover:bg-gray-100 dark:hover:bg-gray-600 text-black dark:text-white cursor-pointer"
                  >
                    <%= title %>
                  </li>
                <% end %>
              </ul>
            <% end %>
          </div>
          <button
            type="submit"
            class="px-4 py-2 bg-blue-500 hover:bg-blue-600 focus:outline-none focus:ring-2 focus:ring-blue-400 text-white rounded-r"
          >
            Search
          </button>
        </form>
      </div>

      <!-- Error -->
      <%= if @error do %>
        <div class="text-red-600 dark:text-red-400"><%= @error %></div>
      <% end %>

      <!-- Search result card -->
      <%= if @show do %>
        <div class="bg-white dark:bg-gray-800 shadow-lg rounded-lg overflow-hidden">
          <div class="flex flex-col md:flex-row">
            <img
              src={@show.poster}
              alt="Poster"
              class="w-full md:w-48 object-cover rounded-t-lg md:rounded-l-lg"
            />
            <div class="p-4 flex-1 space-y-2">
              <h2 class="text-2xl font-bold dark:text-white">
                <%= @show.title %> (<%= @show.year %>)
              </h2>

              <div class="text-sm text-gray-600 dark:text-gray-300 space-y-1">
                <p>Seasons: <%= @show.total_seasons || "N/A" %></p>
                <p><%= Enum.join(@show.genres, ", ") %></p>
              </div>

              <p class="text-sm dark:text-gray-200"><%= @show.plot %></p>
              <p class="text-sm font-semibold dark:text-gray-100">
                IMDb Rating: <%= @show.imdb_rating %>
              </p>

              <div class="mt-4 grid grid-cols-1 sm:grid-cols-3 gap-2">
                <button
                  phx-click="add_to_list"
                  phx-value-status="finished"
                  class="px-3 py-2 bg-green-500 hover:bg-green-600 focus:outline-none focus:ring-2 focus:ring-green-400 text-white rounded"
                >
                  Mark as Finished
                </button>
                <button
                  phx-click="add_to_list"
                  phx-value-status="in_progress"
                  class="px-3 py-2 bg-yellow-500 hover:bg-yellow-600 focus:outline-none focus:ring-2 focus:ring-yellow-400 text-white rounded"
                >
                  In Progress
                </button>
                <button
                  phx-click="add_to_list"
                  phx-value-status="watchlist"
                  class="px-3 py-2 bg-blue-500 hover:bg-blue-600 focus:outline-none focus:ring-2 focus:ring-blue-400 text-white rounded"
                >
                  Add to Watchlist
                </button>
              </div>
            </div>
          </div>
        </div>
      <% end %>
      </div>
      
      <!-- Modal with transitions -->
      <.modal
        :if={@open_modal}
        id="add-show-modal"
        show
        heading={"Add \"#{@show_to_add.title}\" to " <>
          (case @add_status do
            "finished"    -> "Finished"
            "in_progress" -> "In Progress"
            "watchlist"   -> "Watchlist"
          end)
        }
        on_cancel={JS.push("cancel_add")}
      >
        <div class="p-6 space-y-4 bg-white dark:bg-gray-800 text-gray-900 dark:text-gray-100">
          <form phx-submit="confirm_add" class="space-y-4">
            <% label_text =
                case @add_status do
                  "finished"    -> "Year Watched (optional)"
                  "in_progress" -> "Year Started (optional)"
                  "watchlist"   -> "Year Planned (optional)"
                end
            %>
            <div>
              <label class="block mb-1 font-medium dark:text-gray-200"><%= label_text %></label>
              <select
                name="watch_year"
                class="w-full border border-gray-300 dark:border-gray-600 rounded px-2 py-1
                      bg-white dark:bg-gray-700 text-gray-900 dark:text-gray-100
                      focus:outline-none focus:ring-2 focus:ring-blue-400"
              >
                <option value="">—</option>
                <%= for year <- 2025..2015//-1 do %>
                  <option value={year}><%= year %></option>
                <% end %>
              </select>
            </div>

            <%= if @add_status in ["finished", "in_progress"] do %>
              <div>
                <label class="block mb-1 font-medium dark:text-gray-200">Your Rating (optional)</label>
                <input
                  name="user_rating"
                  type="number"
                  step="0.1"
                  min="0"
                  max="10"
                  placeholder="e.g. 8.5"
                  class="w-full border border-gray-300 dark:border-gray-600 rounded px-2 py-1
                        bg-white dark:bg-gray-700 text-gray-900 dark:text-gray-100
                        focus:outline-none focus:ring-2 focus:ring-blue-400"
                />
              </div>
            <% end %>

            <div class="mt-6 flex justify-end space-x-2">
              <.button type="button"phx-click="cancel_add">
                Cancel
              </.button>
              <.button type="submit">
                Add
              </.button>
            </div>
          </form>
        </div>
      </.modal>
    """
  end
end
