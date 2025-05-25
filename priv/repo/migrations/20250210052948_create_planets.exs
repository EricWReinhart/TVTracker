defmodule App.Repo.Migrations.CreatePlanets do
  use Ecto.Migration

  def change do
    create table(:planets) do
      add :name, :string
      add :distance, :float
      add :orbital_period, :float
    end
  end
end
