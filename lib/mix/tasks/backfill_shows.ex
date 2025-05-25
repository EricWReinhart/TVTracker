# lib/mix/tasks/backfill_shows.ex
defmodule Mix.Tasks.BackfillShows do
  use Mix.Task
  import Ecto.Query, warn: false

  alias App.Repo
  alias App.Media.{TvShow, UserTvShow}

  @shortdoc "Backfills OMDb metadata for TvShows referenced by UserTvShow"

  def run(_args) do
    # Start the Repo and your application
    Mix.Task.run("app.start")

    # 1) collect the distinct tv_show IDs that users have added
    tv_ids =
      Repo.all(
        from ut in UserTvShow,
          select: ut.tv_show_id,
          distinct: true
      )

    # 2) load and update only those shows
    TvShow
    |> where([t], t.id in ^tv_ids)
    |> Repo.all()
    |> Enum.each(&update_show/1)

    Mix.shell().info("✅ Backfill complete for #{length(tv_ids)} shows.")
  end

  # Make sure TvShow is aliased above, so this matches correctly
  defp update_show(%TvShow{} = tv) do
    Mix.shell().info("Updating #{tv.title} (#{tv.imdb_id})...")

    case AppWeb.OMDb.fetch_by_title(tv.title) do
      {:ok, details} ->
        # List.wrap/1 will return a list or [] if it's nil/non-list
        genres = List.wrap(details.genres)

        attrs = %{
          genre:        Enum.join(genres, ", "),
          runtime:      details.runtime,
          release_year: details.year
        }

        tv
        |> TvShow.changeset(attrs)
        |> Repo.update!()

        Mix.shell().info("  ✓ done")

      {:error, reason} ->
        Mix.shell().error("  ⚠️ failed: #{inspect(reason)}")
    end
  end
end
