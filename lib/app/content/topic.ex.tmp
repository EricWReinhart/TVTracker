defmodule App.Content.Topic do
  use Ecto.Schema
  import Ecto.Changeset

  schema "topics" do
    field :title, :string
    field :slug, :string
    has_many :pages, App.Content.Page
  end

  @doc false
  def changeset(topic, attrs) do
    topic
    |> cast(attrs, [:slug, :title])
    |> validate_required([:slug, :title])
    |> unique_constraint(:slug)
  end
end
