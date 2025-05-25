defmodule App.Repo.Migrations.CreateMedia do
  use Ecto.Migration

  def change do
    create table(:media) do
      add :title, :string
      add :type, :string
      add :year, :string
      add :poster_url, :string
      add :rating, :float
      add :favorite, :boolean, default: false, null: false

      timestamps(type: :utc_datetime)
    end
  end
end
