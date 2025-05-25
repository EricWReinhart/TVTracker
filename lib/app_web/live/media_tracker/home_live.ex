defmodule AppWeb.HomeLive do
  use AppWeb, :live_view

  alias App.Accounts
  alias App.Media
  alias URI

  @impl true
  def mount(_params, session, socket) do
    current_user =
      case session["user_token"] do
        nil -> nil
        token -> Accounts.get_user_by_session_token(token)
      end

    {stats, recent, all_ids} =
      if current_user do
        finished    = Media.list_user_shows(current_user, :finished)
        in_progress = Media.list_user_shows(current_user, :in_progress)
        watchlist   = Media.list_user_shows(current_user, :watchlist)
        all         = finished ++ in_progress ++ watchlist

        stats = %{
          total_shows: length(all),
          watched:     length(finished),
          favorites:   Enum.count(all, & &1.tv_show.favorite)
        }

        recent =
          all
          |> Enum.sort_by(& &1.inserted_at, &>=/2)
          |> Enum.map(& &1.tv_show)
          |> Enum.uniq_by(& &1.id)
          |> Enum.take(5)

        ids = Enum.map(all, & &1.tv_show.id)
        {stats, recent, ids}
      else
        {%{total_shows: 0, watched: 0, favorites: 0}, [], []}
      end

    socket
    |> assign(current_user: current_user)
    |> assign(stats:        stats)
    |> assign(recent:       recent)
    |> assign(all_ids:      all_ids)
    |> then(&{:ok, &1})
  end

  @impl true
  def handle_event("surprise", _params, socket) do
    case Media.get_random_show() do
      nil ->
        {:noreply,
         socket
         |> put_flash(:error, "No shows in the database yet!")}

      show ->
        {:noreply,
         push_navigate(socket,
           to: ~p"/tvtracker/search?query=#{show.title}"
         )}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="py-6 px-6 max-w-5xl mx-auto">
      <!-- Hero Section -->
      <div class="text-center mb-8">
        <h1 class="text-4xl font-bold text-gray-900 dark:text-gray-100 mb-2">
          Welcome to TVTracker
        </h1>
        <p class="text-lg text-gray-600 dark:text-gray-300 mb-4">
          Track and explore your favorite TV shows: search, save, rate, and analyze all in one place.
        </p>
      </div>


      <!-- Features Grid -->
      <div class="grid grid-cols-1 md:grid-cols-2 gap-8 mb-12">
        <!-- Search Feature -->
        <div class="flex items-start space-x-4">
          <div class="flex-shrink-0">
            <div class="h-12 w-12 rounded-full bg-blue-500 text-white flex items-center justify-center text-xl font-bold">
              1
            </div>
          </div>
          <div>
            <h2 class="text-xl font-semibold text-gray-800 dark:text-white mb-2">
              Search for Shows
            </h2>
            <p class="text-gray-600 dark:text-gray-300 mb-2">
              Discover TV shows by title, view key details, and find your next binge.
            </p>
            <.link navigate={~p"/tvtracker/search"} class="text-blue-600 hover:underline">
              Go to Search →
            </.link>
          </div>
        </div>

        <!-- Library Feature -->
        <div class="flex items-start space-x-4">
          <div class="flex-shrink-0">
            <div class="h-12 w-12 rounded-full bg-green-500 text-white flex items-center justify-center text-xl font-bold">
              2
            </div>
          </div>
          <div>
            <h2 class="text-xl font-semibold text-gray-800 dark:text-white mb-2">
              Your Library
            </h2>
            <p class="text-gray-600 dark:text-gray-300 mb-2">
              Organize shows into Finished, In Progress, or Watchlist lists and manage them effortlessly.
            </p>
            <.link navigate={~p"/tvtracker/library"} class="text-blue-600 hover:underline">
              View My Library →
            </.link>
          </div>
        </div>

        <!-- Statistics Feature -->
        <div class="flex items-start space-x-4">
          <div class="flex-shrink-0">
            <div class="h-12 w-12 rounded-full bg-yellow-500 text-white flex items-center justify-center text-xl font-bold">
              3
            </div>
          </div>
          <div>
            <h2 class="text-xl font-semibold text-gray-800 dark:text-white mb-2">
              View Statistics
            </h2>
            <p class="text-gray-600 dark:text-gray-300 mb-2">
              Generate charts for your top-rated shows and see trends over time.
            </p>
            <.link navigate={~p"/tvtracker/stats"} class="text-blue-600 hover:underline">
              See Stats →
            </.link>
          </div>
        </div>

        <!-- Data Management Feature -->
        <div class="flex items-start space-x-4">
          <div class="flex-shrink-0">
            <div class="h-12 w-12 rounded-full bg-indigo-500 text-white flex items-center justify-center text-xl font-bold">
              4
            </div>
          </div>
          <div>
            <h2 class="text-xl font-semibold text-gray-800 dark:text-white mb-2">
              Import & Export
            </h2>
            <p class="text-gray-600 dark:text-gray-300 mb-2">
              Backup your data or restore from a JSON file. Keep your tracking safe and portable.
            </p>
            <.link navigate={~p"/tvtracker/library"} class="text-blue-600 hover:underline">
              Manage Data →
            </.link>
          </div>
        </div>
      </div>

      <%= if @current_user do %>
        <!-- Fun Features Section -->
        <div class="space-y-8">
          <!-- Quick Stats Preview -->
          <div class="space-y-2">
            <div class="flex justify-center items-center space-x-4 text-sm text-gray-700 dark:text-gray-400">
              <span>Shows <strong><%= @stats.total_shows %></strong></span>
              <span>Watched <strong><%= @stats.watched %></strong></span>
              <span>Favorites <strong><%= @stats.favorites %></strong></span>
            </div>
            <div class="w-full bg-gray-200 rounded-full h-2 overflow-hidden max-w-md mx-auto">
              <div class="w-full bg-gray-400 border border-gray-500 rounded-full h-2 overflow-hidden max-w-md mx-auto">
                <% pct = if @stats.total_shows > 0, do: round(@stats.watched / @stats.total_shows * 100), else: 0 %>
                <div
                  class="bg-green-500 h-2 transition-all duration-300"
                  style={"width: #{pct}%"}
                ></div>
              </div>

            </div>
          </div>

          <!-- Surprise Me Button -->
          <div class="text-center">
            <button
              phx-click="surprise"
              class="px-4 py-2 bg-purple-600 text-white rounded hover:bg-purple-700"
            >
              Surprise Me!
            </button>
          </div>

          <!-- Recently Added Grid -->
          <%= if @recent != [] do %>
            <div>
              <h2 class="text-xl font-semibold text-gray-800 dark:text-white mb-4 text-center">
                Recently Added Shows
              </h2>
              <div class="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-5 gap-4 mb-12">
                <%= for show <- @recent do %>
                  <% title = show.title %>
                  <.link navigate={~p"/tvtracker/library/#{show.id}"} class="block w-full">
                    <img
                      src={show.poster}
                      alt={show.title}
                      class="w-full h-48 object-contain rounded"
                    />
                    <p class="mt-2 text-center text-sm text-gray-700 dark:text-gray-300">
                      <%= if String.length(title) > 20, do: String.slice(title, 0, 12) <> "...", else: title %>
                    </p>
                  </.link>
                <% end %>
              </div>
            </div>
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end
end
