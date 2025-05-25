defmodule App.Repo.Migrations.CreatePagesTags do
  use Ecto.Migration

  def change do
    create table("pages_tags") do
      add(:page_id, references(:pages, on_delete: :delete_all), null: false)
      add(:tag_id, references(:tags, on_delete: :delete_all), null: false)
    end

    create(unique_index(:pages_tags, [:page_id, :tag_id]))
  end
end
