defmodule App.Repo.Migrations.CreateUserTvShows do
  use Ecto.Migration

  def change do
    create table(:user_tv_shows) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :tv_show_id, references(:tv_shows, on_delete: :delete_all), null: false
      add :status, :string, null: false  # we'll enforce values in the schema
      timestamps()
    end

    create index(:user_tv_shows, [:user_id])
    create index(:user_tv_shows, [:tv_show_id])
    create unique_index(:user_tv_shows, [:user_id, :tv_show_id], name: :user_show_unique)
  end
end
