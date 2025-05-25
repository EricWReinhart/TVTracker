defmodule App.Repo.Migrations.RemoveUserFieldsFromTvShows do
  use Ecto.Migration

  def change do
    alter table(:tv_shows) do
      remove :watch_year
      remove :user_rating
    end
  end
end
