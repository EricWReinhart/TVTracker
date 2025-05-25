defmodule App.Repo.Migrations.AddAttributesToItems do
  use Ecto.Migration

  def change do
    alter table(:items) do
      add :attributes, :smallint
    end
  end
end
