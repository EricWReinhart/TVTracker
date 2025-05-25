defmodule App.Repo.Migrations.CreateMessages do
  use Ecto.Migration

  def change do
    create table(:messages) do
      add :email, :string
      add :subject, :string
      add :message, :string

      timestamps(type: :utc_datetime)
    end
  end
end
