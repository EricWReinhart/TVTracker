defmodule App.Repo.Migrations.DropPlanetsTable do
  use Ecto.Migration

  def change do
    drop table(:planets)
  end
end
