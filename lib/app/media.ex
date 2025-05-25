defmodule App.Media do
  import Ecto.Query, warn: false
  alias App.Repo
  alias App.Accounts.User
  alias App.Media.{TvShow, UserTvShow, Season, Episode, UserEpisode}
  alias AppWeb.OMDb

   @doc """
  Find or insert the global TV show record by IMDb ID;
  pulls fresh data from OMDb and parses out only the fields we care about.
  """
  def get_or_create_show(imdb_id) when is_binary(imdb_id) do
    case Repo.get_by(TvShow, imdb_id: imdb_id) do
      nil ->
        # use the new ID lookup
        {:ok, data} = AppWeb.OMDb.fetch_by_id(imdb_id)

        attrs = %{
          imdb_id:      data.imdb_id,
          title:        data.title,
          release_year: data.year,
          poster:       data.poster,
          runtime:      sanitize_na(data.runtime),
          genre:        sanitize_na(Enum.join(data.genres, ", ")),
          rating:       parse_rating(data.imdb_rating)
        }

        %TvShow{}
        |> TvShow.changeset(attrs)
        |> Repo.insert!()

      show ->
        show
    end
  end


  # Turn "N/A" (or nil) into nil; leave any real string intact
  defp sanitize_na(nil),   do: nil
  defp sanitize_na("N/A"), do: nil
  defp sanitize_na(other),  do: other

  # Parse a float, or return nil on "N/A"/non-numeric
  defp parse_rating(nil),        do: nil
  defp parse_rating("N/A"),      do: nil
  defp parse_rating(str) when is_binary(str) do
    case Float.parse(str) do
      {f, _} -> f
      :error -> nil
    end
  end
  defp parse_rating(f) when is_float(f), do: f

    @doc """
  Adds or updates a TV show entry for the given user and status.
  """
  def add_show_to_user(user, %{watch_year: wy, user_rating: ur} = show_attrs, status) do
    # Pull IMDb ID from either :imdb_id or "imdb_id" in the map
    imdb_id =
      show_attrs
      |> Map.get(:imdb_id)
      |> case do
        nil -> Map.get(show_attrs, "imdb_id")
        id  -> id
      end

    show = get_or_create_show(imdb_id)

    attrs = %{
      user_id:     user.id,
      tv_show_id:  show.id,
      status:      Atom.to_string(status),
      watch_year:  wy,
      user_rating: ur
    }

    %UserTvShow{}
    |> UserTvShow.changeset(attrs)
    |> Repo.insert(
      on_conflict: {:replace_all_except, [:id, :user_id, :tv_show_id, :inserted_at]},
      conflict_target: [:user_id, :tv_show_id]
    )
  end

  @doc """
  Returns a list of `%UserTvShow{}` joins (with `:tv_show` preloaded) for the given user and status.
  If `user` is `nil`, returns an empty list.
  """
  def list_user_shows(nil, _status), do: []

  def list_user_shows(user, status) do
    from(uts in UserTvShow,
      where: uts.user_id == ^user.id and uts.status == ^Atom.to_string(status),
      preload: [:tv_show]
    )
    |> Repo.all()
  end

  @doc """
  Toggle the `favorite` flag on a TV show (global record).
  """
  def toggle_favorite(_user, tv_show_id) do
    case Repo.get(TvShow, tv_show_id) do
      nil ->
        {:error, :not_found}

      %TvShow{} = show ->
        show
        |> TvShow.changeset(%{favorite: !show.favorite})
        |> Repo.update()
    end
  end

  @doc """
  Remove a show from a user’s list (delete the join record).
  """
  def delete_user_show(user, tv_show_id) do
    case Repo.get_by(UserTvShow, user_id: user.id, tv_show_id: tv_show_id) do
      nil ->
        {:error, :not_found}

      %UserTvShow{} = join ->
        join |> Repo.delete() |> case do
          {:ok, _} -> :ok
          err -> err
        end
    end
  end

  @doc """
  Fetch the `%UserTvShow{}` for a user and TV show, with `:tv_show` preloaded.
  Returns `{:ok, join}` or `{:error, :not_found}`.
  """
  def get_user_tv_show(user, tv_show_id) do
    from(uts in UserTvShow,
      where: uts.user_id == ^user.id and uts.tv_show_id == ^tv_show_id,
      preload: [:tv_show]
    )
    |> Repo.one()
    |> case do
      nil -> {:error, :not_found}
      join -> {:ok, join}
    end
  end

  @doc """
  Update the per-user join record (e.g. watch_year, user_rating).
  """
  def update_user_show(join_id, attrs) do
    case Repo.get(UserTvShow, join_id) do
      nil ->
        {:error, :not_found}

      %UserTvShow{} = join ->
        join
        |> UserTvShow.changeset(attrs)
        |> Repo.update()
        |> case do
          {:ok, updated_join} ->
            {:ok, Repo.preload(updated_join, :tv_show)}

          error ->
            error
        end
    end
  end


  @doc """
  Fetches a TV show with seasons and episodes preloaded, including per-user metadata (favorites, ratings, notes).
  """
  def get_show!(show_id, %User{id: user_id}) do
    episodes_query =
      from(e in Episode,
        order_by: e.episode_number,
        preload: [user_episodes: ^from(ue in UserEpisode, where: ue.user_id == ^user_id)]
      )

    seasons_query =
      from(s in Season,
        order_by: s.number,
        preload: [episodes: ^episodes_query]
      )

    Repo.get!(TvShow, show_id)
    |> Repo.preload(seasons: seasons_query)
  end

  @doc """
  Toggle the favorite flag for an episode for the given user.
  """
  def toggle_favorite_episode(episode_id, %User{id: user_id}) do
    case Repo.get_by(UserEpisode, episode_id: episode_id, user_id: user_id) do
      nil ->
        %UserEpisode{}
        |> UserEpisode.changeset(%{episode_id: episode_id, user_id: user_id, favorite: true})
        |> Repo.insert()

      %UserEpisode{} = ue ->
        ue
        |> UserEpisode.changeset(%{favorite: !ue.favorite})
        |> Repo.update()
    end
  end

  @doc """
  Create or update user rating and notes for an episode for the given user.
  """
  def update_episode_notes(episode_id, %User{id: user_id}, attrs) do
    case Repo.get_by(UserEpisode, episode_id: episode_id, user_id: user_id) do
      nil ->
        %UserEpisode{}
        |> UserEpisode.changeset(Map.merge(%{episode_id: episode_id, user_id: user_id}, attrs))
        |> Repo.insert()

      %UserEpisode{} = ue ->
        ue
        |> UserEpisode.changeset(attrs)
        |> Repo.update()
    end
  end

  @doc """
  Fetches all seasons & episodes for the given show title via OMDb,
  inserts any missing Season and Episode rows, and returns :ok.
  """
  def sync_seasons_for_show(%TvShow{id: show_id, title: title}) do
    # OMDb.fetch_all_seasons(title) returns a list of maps
    for season_map <- OMDb.fetch_all_seasons(title) do
      # 1) upsert the season record
      season_number = String.to_integer(season_map["Season"])
      season =
        Repo.get_by(Season, tv_show_id: show_id, number: season_number) ||
          %Season{}
          |> Season.changeset(%{tv_show_id: show_id, number: season_number})
          |> Repo.insert!()

      # 2) upsert each episode in that season
      for ep_map <- season_map["Episodes"] do
        ep_number = String.to_integer(ep_map["Episode"])

        Repo.get_by(Episode, season_id: season.id, episode_number: ep_number) ||
          %Episode{}
          |> Episode.changeset(%{
              season_id:      season.id,
              episode_number: ep_number,
              title:          ep_map["Title"],
              imdb_id:        ep_map["imdbID"]
            })
          |> Repo.insert!()
      end
    end

    :ok
  end

  @doc """
  Create a new user–tv_show join.
  """
  def create_user_tv_show(attrs) do
    %UserTvShow{}
    |> UserTvShow.changeset(attrs)
    |> Repo.insert()
  end

  # call this when you want to mark a show finished for a given user
  def mark_show_finished(user, tv_show_id) do
    # 1. upsert the join record as before
    user_tv =
      case get_user_tv_show(user, tv_show_id) do
        {:ok, join} ->
          {:ok, join} = update_user_show(join.id, %{status: "finished"})
          join

        {:error, _} ->
          {:ok, new_join} = create_user_tv_show(%{
            user_id:    user.id,
            tv_show_id: tv_show_id,
            status:     "finished"
          })
          new_join
      end

    # 2. load all episode IDs in one go
    episode_ids =
      Repo.get!(TvShow, tv_show_id)
      |> Repo.preload(seasons: :episodes)
      |> Map.get(:seasons)
      |> Enum.flat_map(& &1.episodes)
      |> Enum.map(& &1.id)

    # 3. build upsert values
    rows = for eid <- episode_ids do
      %{
        user_id:    user.id,
        episode_id: eid,
        watched:    true,
        inserted_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
        updated_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
      }
    end

    # 4. one SQL upsert: insert all, and on conflict update watched & updated_at
    Repo.insert_all(
      UserEpisode,
      rows,
      on_conflict: {:replace, [:watched, :updated_at]},
      conflict_target: [:user_id, :episode_id]
    )

    {:ok, user_tv}
  end


    @doc """
    Creates a new UserTvShow or updates the existing one (by user_id + tv_show_id)
    with the given attrs map.

    Expects attrs to include at least:
      - "user_id"
      - "tv_show_id"
      - "status"
    and any other fields you want to update (e.g. "watch_year", "user_rating").
    """
    def create_or_update_user_tv_show(attrs) when is_map(attrs) do
      query =
        from ut in UserTvShow,
          where:
            ut.user_id == ^attrs["user_id"] and
              ut.tv_show_id == ^attrs["tv_show_id"]

      case Repo.one(query) do
        nil ->
          # not found → insert new join
          %UserTvShow{}
          |> UserTvShow.changeset(attrs)
          |> Repo.insert()

        %UserTvShow{} = existing ->
          # found → update only changed fields
          existing
          |> UserTvShow.changeset(attrs)
          |> Repo.update()
      end
    end

  @doc """
  Returns a random TvShow from the database (or `nil` if none exist).
  """
  def get_random_show do
    TvShow
    |> order_by(fragment("RANDOM()"))
    |> limit(1)
    |> Repo.one()
  end

end
