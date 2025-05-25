defmodule App.Repo.Migrations.AddWatchedToUserEpisodes do
  use Ecto.Migration

  def change do
    alter table(:user_episodes) do
      add :watched, :boolean, default: false, null: false
    end
  end
end
