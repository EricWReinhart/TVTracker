defmodule App.Repo.Migrations.CreatePages do
  use Ecto.Migration

  def change do
    create table(:pages) do
      add :content, :text
      # add :topic_id, references(:topics, on_delete: :nothing)
      add :topic_id, references(:topics, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:pages, [:topic_id])
  end
end
