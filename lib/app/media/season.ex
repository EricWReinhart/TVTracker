defmodule App.Media.Season do
  use Ecto.Schema
  import Ecto.Changeset

  schema "seasons" do
    field :number, :integer
    belongs_to :tv_show, App.Media.TvShow
    has_many   :episodes, App.Media.Episode
    timestamps()
  end

  def changeset(season, attrs) do
    season
    |> cast(attrs, [:number, :tv_show_id])
    |> validate_required([:number, :tv_show_id])
  end
end
