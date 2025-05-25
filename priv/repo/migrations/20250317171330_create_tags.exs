defmodule App.Repo.Migrations.CreateTags do
  use Ecto.Migration

  def up do
    create table(:tags) do
      add :name, :string
    end

    create unique_index(:tags, :name)

    flush()

    ~w(Bucknell Sports Photography Nature)
    |> Enum.each(&App.Content.create_tag(%{name: &1}))
  end

  def down do
    drop unique_index(:tags, :name)
    drop table(:tags)
  end
end
