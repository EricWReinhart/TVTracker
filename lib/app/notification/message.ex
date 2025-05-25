defmodule App.Notification.Message do
  use Ecto.Schema
  import Ecto.Changeset

  schema "messages" do
    field :message, :string
    field :email, :string
    field :subject, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(message, attrs) do
    message
    |> cast(attrs, [:email, :subject, :message])
    |> validate_required([:email, :message])  # subject is optional
    |> validate_format(:email, ~r/@/, message: "Must contain @")
    |> validate_length(:subject, max: 30, message: "Must have at most 30 characters")
    |> validate_length(:message, min: 5, max: 255, message: "Must have between 5 and 255 characters")
  end
end
