defmodule App.Repo.Migrations.CreateUserEpisodes do
  use Ecto.Migration

  def change do
    create table(:user_episodes) do
      add :favorite, :boolean, default: false, null: false
      add :rating, :float
      add :notes, :text
      add :user_id, references(:users, on_delete: :nothing)
      add :episode_id, references(:episodes, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:user_episodes, [:user_id])
    create index(:user_episodes, [:episode_id])
    create unique_index(:user_episodes, [:user_id, :episode_id])
  end
end
