defmodule App.Repo.Migrations.AddUserFieldsToUserTvShows do
  use Ecto.Migration

  def change do
    alter table(:user_tv_shows) do
      add :watch_year, :string
      add :user_rating, :float
    end
  end
end
