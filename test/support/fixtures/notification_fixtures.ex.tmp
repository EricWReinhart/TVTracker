defmodule App.NotificationFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `App.Notification` context.
  """

  @doc """
  Generate a message.
  """
  def message_fixture(attrs \\ %{}) do
    {:ok, message} =
      attrs
      |> Enum.into(%{
        email: "some@email",
        message: "some message",
        subject: "some subject"
      })
      |> App.Notification.create_message()

    message
  end
end
