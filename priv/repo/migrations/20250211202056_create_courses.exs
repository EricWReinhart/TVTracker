defmodule App.Repo.Migrations.CreateCourses do
  use Ecto.Migration

  def change do
    create table(:courses) do
      add :semester, :string
      add :name, :string

      timestamps(type: :utc_datetime)
    end
  end
end
