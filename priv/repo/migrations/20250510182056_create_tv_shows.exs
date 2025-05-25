defmodule App.Repo.Migrations.CreateTvShows do
  use Ecto.Migration

  def change do
    create table(:tv_shows) do
      add :imdb_id, :string, null: false
      add :title, :string,   null: false
      add :release_year, :string
      add :rating, :float
      add :poster, :string
      add :runtime, :string
      add :genre, :string
      add :watch_year, :string
      add :user_rating, :float
      add :favorite, :boolean, default: false, null: false
      timestamps()
    end

    create unique_index(:tv_shows, [:imdb_id])
  end
end
