defmodule App.Media.UserEpisode do
  use Ecto.Schema
  import Ecto.Changeset

  schema "user_episodes" do
    field :favorite, :boolean, default: false
    field :rating,   :float
    field :notes,    :string
    field :watched, :boolean, default: false
    belongs_to :user,    App.Accounts.User
    belongs_to :episode, App.Media.Episode
    timestamps()
  end

  @required_fields ~w(user_id episode_id)a
  @optional_fields ~w(favorite rating notes watched)a

  def changeset(user_episode, attrs) do
    user_episode
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> unique_constraint(:episode_id,
         name: :user_episodes_user_id_episode_id_index,
         message: "you can only have one record per user & episode"
       )
    |> validate_number(:rating,
         greater_than_or_equal_to: 0,
         less_than_or_equal_to: 10
       )
  end

end
