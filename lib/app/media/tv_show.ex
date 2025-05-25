defmodule App.Media.TvShow do
  use Ecto.Schema
  import Ecto.Changeset

  alias App.Media.UserTvShow

  schema "tv_shows" do
    field :imdb_id, :string
    field :title, :string
    field :release_year, :string
    field :rating, :float
    field :poster, :string
    field :runtime, :string
    field :genre, :string
    field :favorite, :boolean, default: false

    has_many :user_tv_shows, UserTvShow
    has_many :users, through: [:user_tv_shows, :user]
    has_many :seasons, App.Media.Season
    timestamps()
  end

  @required_fields ~w(imdb_id title)a
  @optional_fields ~w(release_year rating poster runtime genre favorite)a

  @doc false
  def changeset(tv_show, attrs) do
    tv_show
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> unique_constraint(:imdb_id)
  end
end
