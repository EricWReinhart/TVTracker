defmodule App.Media.Post do
  use Ecto.Schema
  import Ecto.Changeset

  schema "posts" do
    field :title, :string
    field :body, :string

    embeds_many :pictures, App.Media.Upload, on_replace: :delete

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(post, attrs) do
    post
    |> cast(attrs, [:title, :body])
    # |> cast_embed(:pictures, sort_param: :pictures_sort, drop_param: :pictures_drop)
    |> validate_required([:title, :body])
  end
end
