defmodule App.Repo.Migrations.AddNameToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :name, :string
      add :birthday, :date
    end
  end
end
