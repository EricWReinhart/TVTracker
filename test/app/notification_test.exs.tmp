defmodule App.NotificationTest do
  use App.DataCase

  alias App.Notification

  describe "messages" do
    alias App.Notification.Message

    import App.NotificationFixtures

    @invalid_attrs %{message: nil, email: nil, subject: nil}

    test "list_messages/0 returns all messages" do
      message = message_fixture()
      assert Notification.list_messages() == [message]
    end

    test "get_message!/1 returns the message with given id" do
      message = message_fixture()
      assert Notification.get_message!(message.id) == message
    end

    test "create_message/1 with valid data creates a message" do
      valid_attrs = %{message: "some message", email: "some@email", subject: "some subject"}

      assert {:ok, %Message{} = message} = Notification.create_message(valid_attrs)
      assert message.message == "some message"
      assert message.email == "some@email"
      assert message.subject == "some subject"
    end

    test "create_message/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Notification.create_message(@invalid_attrs)
    end

    # test "update_message/2 with valid data updates the message" do
    #   message = message_fixture()
    #   update_attrs = %{message: "some updated message", email: "some updated email", subject: "some updated subject"}

    #   assert {:ok, %Message{} = message} = Notification.update_message(message, update_attrs)
    #   assert message.message == "some updated message"
    #   assert message.email == "some updated email"
    #   assert message.subject == "some updated subject"
    # end

    # test "update_message/2 with invalid data returns error changeset" do
    #   message = message_fixture()
    #   assert {:error, %Ecto.Changeset{}} = Notification.update_message(message, @invalid_attrs)
    #   assert message == Notification.get_message!(message.id)
    # end

    test "delete_message/1 deletes the message" do
      message = message_fixture()
      assert {:ok, %Message{}} = Notification.delete_message(message)
      assert_raise Ecto.NoResultsError, fn -> Notification.get_message!(message.id) end
    end

    test "change_message/1 returns a message changeset" do
      message = message_fixture()
      assert %Ecto.Changeset{} = Notification.change_message(message)
    end
  end
end
