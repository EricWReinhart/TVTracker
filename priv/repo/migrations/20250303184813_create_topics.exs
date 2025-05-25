defmodule App.Repo.Migrations.CreateTopics do
  use Ecto.Migration

  def change do
    create table(:topics) do
      add :slug, :string
      add :title, :string
    end

    create unique_index(:topics, [:slug])
  end
end
