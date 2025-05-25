defmodule App.Media.UserTvShow do
  use Ecto.Schema
  import Ecto.Changeset

  @statuses ["finished", "in_progress", "watchlist"]

  schema "user_tv_shows" do
    field :status, :string
    field :watch_year, :string
    field :user_rating, :float

    belongs_to :user,    App.Accounts.User
    belongs_to :tv_show, App.Media.TvShow

    timestamps()
  end

  @doc false
  def changeset(user_tv_show, attrs) do
    user_tv_show
    |> cast(attrs, [:user_id, :tv_show_id, :status, :watch_year, :user_rating])
    |> validate_required([:user_id, :tv_show_id, :status])
    |> validate_inclusion(:status, @statuses)
    |> unique_constraint([:user_id, :tv_show_id], name: :user_show_unique)
  end
end
