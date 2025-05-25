defmodule AppWeb.TVInfo do
  use AppWeb, :live_view

  alias App.{Accounts, Media}
  alias App.Repo
  alias AppWeb.OMDb
  alias App.Media.UserEpisode

  # helper to compute your “quick‐win” stats
  defp compute_stats(show) do
    # flatten all episodes
    all_eps = show.seasons |> Enum.flat_map(& &1.episodes)
    total_episodes = length(all_eps)

    # watched episodes = any user_episodes exist
    watched_count =
      Enum.count(all_eps, fn ep -> ep.user_episodes != [] end)

    # percent complete
    progress_pct =
      if total_episodes > 0 do
        Float.round(watched_count * 100 / total_episodes, 1)
      else
        0.0
      end

    # seasons complete = every episode in that season watched
    total_seasons = length(show.seasons)

    seasons_completed =
      Enum.count(show.seasons, fn season ->
        episodes = season.episodes
        episodes != [] and Enum.all?(episodes, fn ep -> ep.user_episodes != [] end)
      end)

    # average rating across all rated episodes
    ratings =
      all_eps
      |> Enum.flat_map(& &1.user_episodes)
      |> Enum.map(& &1.rating)
      |> Enum.filter(&(!is_nil(&1)))

    average_rating =
      if ratings != [] do
        Float.round(Enum.sum(ratings) / length(ratings), 1)
      else
        nil
      end

    # favorites count
    favorites_count =
      Enum.count(all_eps, fn ep ->
        Enum.any?(ep.user_episodes, & &1.favorite)
      end)

    favorites_pct =
      if total_episodes > 0 do
        Float.round(favorites_count * 100 / total_episodes, 1)
      else
        0.0
      end

    %{
      total_episodes: total_episodes,
      watched_count: watched_count,
      progress_pct: progress_pct,
      total_seasons: total_seasons,
      seasons_completed: seasons_completed,
      average_rating: average_rating,
      favorites_count: favorites_count,
      favorites_pct: favorites_pct
    }
  end


  # helper to compute your “top‐rated” episodes
  defp compute_top_episodes(show) do
    show.seasons
    |> Enum.flat_map(fn season ->
      season.episodes
      |> Enum.map(fn ep ->
        ue = List.first(ep.user_episodes) || %UserEpisode{rating: nil}
        %{
          season:  season.number,
          episode: ep.episode_number,
          title:   ep.title,
          rating:  ue.rating
        }
      end)
    end)
    |> Enum.filter(& &1.rating)                     # drop unrated
    |> Enum.sort_by(& &1.rating, &>=/2)             # highest first
    |> Enum.take(5)                                 # top 5
  end

  @impl true
  def mount(_params, session, socket) do
    current_user =
      case session["user_token"] do
        nil   -> nil
        token -> Accounts.get_user_by_session_token(token)
      end

    {:ok,
     socket
     |> assign(current_user: current_user)
     |> assign(open_seasons: MapSet.new([1]))}
  end

  @impl true
  def handle_params(%{"id" => id}, _uri, socket) do
    # 1) sync seasons/episodes for this show
    show_db = Repo.get!(Media.TvShow, String.to_integer(id))
    :ok = Media.sync_seasons_for_show(show_db)

    # 2) load the show with all user‐specific preloads
    show = Media.get_show!(id, socket.assigns.current_user)

    # 3) fetch the UserTvShow join so we know if it’s “finished”
    {:ok, user_tv} =
      Media.get_user_tv_show(socket.assigns.current_user, show.id)

    # 4) external OMDb details & compute top episodes
    {:ok, details}    = OMDb.fetch_by_title(show.title)
    top_episodes      = compute_top_episodes(show)

    # 5) compute your stats normally
    stats = compute_stats(show)

    # 6) derive watch time (in minutes)
    runtime_min =
      case Regex.run(~r/(\d+)/, details.runtime || "") do
        [_, mins] -> String.to_integer(mins)
        _         -> 0
      end
    total_watch_mins = runtime_min * stats.watched_count

    # 7) build rating distribution
    rating_values =
      show.seasons
      |> Enum.flat_map(& &1.episodes)
      |> Enum.flat_map(& &1.user_episodes)
      |> Enum.map(& &1.rating)
      |> Enum.filter(& &1)

    rating_dist = Enum.frequencies(rating_values)

    # 8) assign everything (including your new `show_status`)
    {:noreply,
    socket
    |> assign(show:             show)
    |> assign(show_status:      user_tv.status)
    |> assign(details:          details)
    |> assign(top_episodes:     top_episodes)
    |> assign(stats)
    |> assign(total_watch_mins: total_watch_mins)
    |> assign(rating_dist:      rating_dist)}
  end



  @impl true
  def handle_event("toggle-fav", %{"episode-id" => eid}, socket) do
    Media.toggle_favorite_episode(eid, socket.assigns.current_user)
    updated = Media.get_show!(socket.assigns.show.id, socket.assigns.current_user)
    top_eps =
      updated.seasons
      |> Enum.flat_map(fn season ->
        season.episodes
        |> Enum.map(fn ep ->
          ue = List.first(ep.user_episodes) || %UserEpisode{rating: nil}
          %{season: season.number, episode: ep.episode_number, title: ep.title, rating: ue.rating}
        end)
      end)
      |> Enum.filter(& &1.rating)
      |> Enum.sort_by(& &1.rating, &>=/2)
      |> Enum.take(5)

    stats = compute_stats(updated)

    {:noreply,
     socket
     |> assign(show: updated)
     |> assign(top_episodes: top_eps)
     |> assign(stats)}
  end

  @impl true
  def handle_event("toggle_season", %{"season" => season_str}, socket) do
    season = String.to_integer(season_str)
    open   = socket.assigns.open_seasons

    open =
      if MapSet.member?(open, season) do
        MapSet.delete(open, season)
      else
        MapSet.put(open, season)
      end

    {:noreply, assign(socket, open_seasons: open)}
  end

  # live-change (slider)—no flash
  @impl true
  def handle_event("save-notes", %{"_target" => ["rating"], "episode-id" => eid, "rating" => rating}, socket) do
    {:ok, _} = Media.update_episode_notes(eid, socket.assigns.current_user, %{rating: rating})
    updated = Media.get_show!(socket.assigns.show.id, socket.assigns.current_user)

    stats = compute_stats(updated)
    top_eps =
      updated.seasons
      |> Enum.flat_map(fn season ->
        season.episodes
        |> Enum.map(fn ep ->
          ue = List.first(ep.user_episodes) || %UserEpisode{rating: nil}
          %{season: season.number, episode: ep.episode_number, title: ep.title, rating: ue.rating}
        end)
      end)
      |> Enum.filter(& &1.rating)
      |> Enum.sort_by(& &1.rating, &>=/2)
      |> Enum.take(5)

    {:noreply,
     socket
     |> assign(show: updated)
     |> assign(top_episodes: top_eps)
     |> assign(stats)}
  end

  # form-submit (Save button)—with flash
  @impl true
  def handle_event("save-notes", %{"episode-id" => eid} = params, socket) do
    attrs =
      %{}
      |> maybe_put(:notes,  Map.get(params, "notes"))
      |> maybe_put(:rating, Map.get(params, "rating"))

    case Media.update_episode_notes(eid, socket.assigns.current_user, attrs) do
      {:ok, _} ->
        updated = Media.get_show!(socket.assigns.show.id, socket.assigns.current_user)
        stats   = compute_stats(updated)

        top_eps =
          updated.seasons
          |> Enum.flat_map(fn season ->
            season.episodes
            |> Enum.map(fn ep ->
              ue = List.first(ep.user_episodes) || %UserEpisode{rating: nil}
              %{season: season.number, episode: ep.episode_number, title: ep.title, rating: ue.rating}
            end)
          end)
          |> Enum.filter(& &1.rating)
          |> Enum.sort_by(& &1.rating, &>=/2)
          |> Enum.take(5)

        {:noreply,
         socket
         |> put_flash(:info, "Your notes and rating have been saved!")
         |> assign(show: updated)
         |> assign(top_episodes: top_eps)
         |> assign(stats)}

      {:error, _} ->
        {:noreply,
         socket
         |> put_flash(:error, "Could not save your notes.")}
    end
  end

  defp maybe_put(map, _key, val) when val in [nil, ""], do: map
  defp maybe_put(map, key, val),                  do: Map.put(map, key, val)

  @impl true
  def render(assigns) do
    ~H"""
    <nav class="text-sm text-gray-600 dark:text-gray-400 mb-4">
      <.link navigate={~p"/tvtracker/library"} class="hover:underline">
        All Shows
      </.link>
      <span class="mx-2">/</span>
      <span class="font-medium"><%= @details.title %></span>
    </nav>

    <div class="flex justify-center">
      <div class="bg-white dark:bg-gray-800 shadow-lg rounded-lg overflow-hidden mb-8 w-full max-w-5xl">
        <div class="flex flex-col md:flex-row">
          <!-- Poster (made a bit larger) -->
          <img
            src={@details.poster}
            alt={"Poster for #{@details.title}"}
            class="w-full md:w-56 object-contain bg-white dark:bg-gray-800 rounded-t-lg md:rounded-l-lg"
          />

          <!-- Info & Stats -->
          <div class="p-6 flex-1 space-y-4">
            <h2 class="text-3xl font-bold dark:text-white">
              <%= @details.title %> (<%= @details.year %>)
            </h2>

            <div class="text-sm text-gray-600 dark:text-gray-300 space-y-1">
              <p>Seasons: <%= @details.total_seasons || "N/A" %></p>
              <p><%= Enum.join(@details.genres || [], ", ") %></p>
            </div>

            <p class="text-base dark:text-gray-200"><%= @details.plot %></p>
            <p class="text-base font-semibold dark:text-gray-100">
              IMDb Rating: <%= @details.imdb_rating %>
            </p>

            <!-- Inline Stats -->
            <div class="mt-6 grid grid-cols-2 sm:grid-cols-4 gap-6">
              <div class="text-center">
                <div class="text-sm text-gray-500 dark:text-gray-400">Progress</div>
                <div class="mt-1 font-bold text-xl text-gray-900 dark:text-gray-100">
                  <%= if @show_status == "finished" do %>
                    <%= @total_episodes %> / <%= @total_episodes %>
                  <% else %>
                    <%= @watched_count %> / <%= @total_episodes %>
                  <% end %>
                </div>
              </div>

              <div class="text-center">
                <div class="text-sm text-gray-500 dark:text-gray-400">Seasons</div>
                <div class="mt-1 font-bold text-xl text-gray-900 dark:text-gray-100">
                  <%= if @show_status == "finished" do %>
                    <%= @total_seasons %> / <%= @total_seasons %>
                  <% else %>
                    <%= @seasons_completed %> / <%= @total_seasons %>
                  <% end %>
                </div>
              </div>

              <div class="text-center">
                <div class="text-sm text-gray-500 dark:text-gray-400">Avg Rating</div>
                <div class="mt-1 font-bold text-xl text-gray-900 dark:text-gray-100">
                  <%= @average_rating || "N/A" %>
                </div>
              </div>

              <div class="text-center">
                <div class="text-sm text-gray-500 dark:text-gray-400">Favorites</div>
                <div class="mt-1 font-bold text-xl text-gray-900 dark:text-gray-100">
                  <%= @favorites_count %>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <%= if @top_episodes != [] do %>
      <section class="mb-8">
        <h2 class="text-2xl font-semibold text-gray-900 dark:text-gray-100 mb-4">Your Top Episodes</h2>
        <div class="grid sm:grid-cols-2 lg:grid-cols-5 gap-4">
          <%= for ep <- @top_episodes do %>
            <div class="bg-white dark:bg-gray-800 p-3 rounded-lg shadow text-gray-900 dark:text-gray-100">
              <div class="font-semibold mb-1">
                S<%= ep.season %>·E<%= ep.episode %>
              </div>
              <div class="text-sm"><%= ep.title %></div>
              <div class="mt-2 text-xs text-gray-500 dark:text-gray-400">
                <%= ep.rating %>/10
              </div>
            </div>
          <% end %>
        </div>
      </section>
    <% end %>

    <section>
      <%= for season <- @show.seasons do %>
        <div class="border rounded overflow-hidden mb-6 border-gray-200 dark:border-gray-700">
          <button
            phx-click="toggle_season"
            phx-value-season={to_string(season.number)}
            class="w-full text-left px-4 py-2 bg-gray-100 dark:bg-gray-700 hover:bg-gray-200 dark:hover:bg-gray-600 flex justify-between items-center text-gray-900 dark:text-gray-100"
          >
            <span class="font-bold">Season <%= season.number %></span>
            <svg
              class={"w-4 h-4 transform transition-transform duration-200 #{if season.number in @open_seasons, do: "rotate-180"}"}
              xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 10 6"
            >
              <path stroke="currentColor" stroke-width="2" d="M9 5 5 1 1 5"/>
            </svg>
          </button>

          <div
            class={
              "overflow-hidden transition-all duration-300 ease-out " <>
              if season.number in @open_seasons,
                do: "max-h-[1000px] opacity-100",
                else: "max-h-0 opacity-0"
            }
          >
            <div class="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-6 p-4">
              <%= for ep <- season.episodes do %>
                <% ue = List.first(ep.user_episodes) || %UserEpisode{} %>
                <% rating = ue.rating || 0 %>
                <% box_color =
                  cond do
                    rating >= 8 ->
                      "bg-green-200 dark:bg-green-800/30 border border-green-400 dark:border-green-600"
                    rating >= 5 ->
                      "bg-yellow-200 dark:bg-yellow-700/30 border border-yellow-400 dark:border-yellow-500"
                    rating > 0 ->
                      "bg-red-200 dark:bg-red-800/30 border border-red-400 dark:border-red-600"
                    true ->
                      "bg-gray-50 dark:bg-gray-700 border border-gray-200 dark:border-gray-600"
                  end
                %>
                <div class={"#{box_color} p-4 rounded-lg shadow space-y-3"}>
                  <div class="flex justify-between items-start">
                    <span class="font-semibold text-gray-900 dark:text-gray-100">
                      <%= ep.episode_number %>. <%= ep.title %>
                    </span>
                    <button
                      phx-click="toggle-fav"
                      phx-value-episode-id={ep.id}
                      class="text-2xl text-yellow-400 dark:text-yellow-300"
                    >
                      <%= if ue.favorite, do: "★", else: "☆" %>
                    </button>
                  </div>
                  <form
                    phx-change="save-notes"
                    phx-submit="save-notes"
                    phx-value-episode-id={ep.id}
                    class="space-y-2"
                  >
                    <div class="flex items-center gap-4">
                      <label class="text-sm font-medium text-gray-900 dark:text-gray-100">
                        Rating: <strong><%= ue.rating || 0 %></strong>
                      </label>
                      <input
                        type="range" name="rating" min="0" max="10" step="0.5"
                        value={ue.rating || 0}
                        class="flex-1 h-2 bg-gray-200 dark:bg-gray-700 rounded-lg cursor-pointer"
                      />
                    </div>
                    <div>
                      <label class="block text-sm font-medium text-gray-900 dark:text-gray-100">Notes</label>
                      <textarea
                        name="notes" rows="2" placeholder="Your notes…"
                        class="w-full border rounded-md py-1 px-2 focus:outline-none focus:border-blue-500 dark:focus:border-blue-400 bg-white dark:bg-gray-900 text-gray-900 dark:text-gray-100"
                      ><%= ue.notes %></textarea>
                    </div>
                    <button
                      type="submit"
                      class="w-full bg-blue-600 hover:bg-blue-700 dark:bg-blue-500 dark:hover:bg-blue-600 text-white rounded-md py-1 text-xs"
                    >
                      Save
                    </button>
                  </form>
                </div>
              <% end %>
            </div>
          </div>
        </div>
      <% end %>
    </section>
    """
  end

end
