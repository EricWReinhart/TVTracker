defmodule App.Media.Episode do
  use Ecto.Schema
  import Ecto.Changeset

  schema "episodes" do
    field :title,          :string
    field :imdb_id,        :string
    field :episode_number, :integer
    belongs_to :season,    App.Media.Season
    has_many   :user_episodes, App.Media.UserEpisode
    has_many   :users, through: [:user_episodes, :user]
    timestamps()
  end

  def changeset(episode, attrs) do
    episode
    |> cast(attrs, [:title, :imdb_id, :episode_number, :season_id])
    |> validate_required([:title, :episode_number, :season_id])
  end
end
