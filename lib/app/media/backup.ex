# lib/app/media/backup.ex
defmodule App.Media.Backup do
  @moduledoc """
  Export and import a user's TV-show lists as JSON.
  """

  alias App.Media
  alias App.Repo
  alias Ecto.Multi

  @doc """
  Export a user's three lists as a JSON string.
  """
  def export_user_lists(user) do
    lists = %{
      finished: lists_for(user, :finished),
      in_progress: lists_for(user, :in_progress),
      watchlist: lists_for(user, :watchlist)
    }

    Jason.encode(lists)
  end

  @doc """
  Save the JSON export to disk at the given path.
  """
  def export_to_file(user, path) do
    case export_user_lists(user) do
      {:ok, json} ->
        File.write!(path, json)
        {:ok, path}

      error ->
        error
    end
  end

  @doc """
  Given a JSON string produced by `export_user_lists/1`, upsert all entries
  back into the user's lists. Returns `{:ok, results}` or `{:error, reason}`.
  """
  def import_user_lists(user, json_string) when is_binary(json_string) do
    with {:ok, %{"finished" => f, "in_progress" => ip, "watchlist" => w}} <-
           Jason.decode(json_string) do
      Multi.new()
      |> Multi.run(:finished, fn repo, _ ->
        upsert_entries(repo, user.id, "finished", f)
      end)
      |> Multi.run(:in_progress, fn repo, _ ->
        upsert_entries(repo, user.id, "in_progress", ip)
      end)
      |> Multi.run(:watchlist, fn repo, _ ->
        upsert_entries(repo, user.id, "watchlist", w)
      end)
      |> Repo.transaction()
    end
  end

  # Helpers

  defp lists_for(user, status) do
    # returns a list of maps; adjust fields as you need
    Media.list_user_shows(user, status)
    |> Enum.map(fn ut ->
      %{
        "tv_show_id" => ut.tv_show_id,
        "imdb_id" => ut.tv_show.imdb_id,
        "title" => ut.tv_show.title,
        "release_year" => ut.tv_show.release_year,
        "poster" => ut.tv_show.poster,
        "runtime" => ut.tv_show.runtime,
        "genre" => ut.tv_show.genre,
        "favorite" => ut.tv_show.favorite,
        "watch_year" => ut.watch_year,
        "user_rating" => ut.user_rating
      }
    end)
  end

  # Upsert each entry: returns {:ok, structs} or {:error, entries_with_errors}
  defp upsert_entries(_repo, user_id, status, entries) when is_list(entries) do
    # 1) transform each entry into either {:ok, struct} or {:error, changeset}
    results =
      for entry <- entries do
        attrs =
          entry
          |> Map.put("user_id", user_id)
          |> Map.put("status", status)

        case Media.create_or_update_user_tv_show(attrs) do
          {:ok, struct} -> {:ok, struct}
          {:error, changeset} -> {:error, changeset}
        end
      end

    # 2) if all are ok, return {:ok, [structs]}, else {:error, results}
    if Enum.all?(results, &match?({:ok, _}, &1)) do
      {:ok, Enum.map(results, fn {:ok, struct} -> struct end)}
    else
      {:error, results}
    end
  end
end
