defmodule App.Bucknell.Course do
  use Ecto.Schema
  import Ecto.Changeset

  schema "courses" do
    field :name, :string
    field :semester, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(course, attrs) do
    course
    |> cast(attrs, [:semester, :name])
    |> validate_required([:semester, :name])
  end
end
