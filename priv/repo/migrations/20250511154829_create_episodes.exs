defmodule App.Repo.Migrations.CreateEpisodes do
  use Ecto.Migration

  def change do
    create table(:episodes) do
      add :title, :string
      add :imdb_id, :string
      add :episode_number, :integer
      add :season_id, references(:seasons, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:episodes, [:season_id])
  end
end
