defmodule App.Repo.Migrations.CreateSeasons do
  use Ecto.Migration

  def change do
    create table(:seasons) do
      add :number, :integer
      add :tv_show_id, references(:tv_shows, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:seasons, [:tv_show_id])
  end
end
