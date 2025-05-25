defmodule App.Repo.Migrations.DropAndReaddRatingAsFloat do
  use Ecto.Migration

  def up do
    alter table(:media) do
      remove :rating
      add :rating, :float
    end
  end

  def down do
    alter table(:media) do
      remove :rating
      add :rating, :string
    end
  end
end
