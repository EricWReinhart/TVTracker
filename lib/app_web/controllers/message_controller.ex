defmodule AppWeb.MessageController do
  use AppWeb, :controller

  alias App.Notification
  alias App.Notification.Message

  def index(conn, _params) do
    messages = Notification.list_messages()
    render(conn, :index, messages: messages)
  end

  def new(conn, _params) do
    changeset = Notification.change_message(%Message{})
    render(conn, :new, message_changeset: changeset)
  end

  def create(conn, %{"message" => message_params}) do
    case Notification.create_message(message_params) do
      {:ok, message} ->
        conn
        |> put_flash(:info, "Message created successfully.")
        |> redirect(to: ~p"/messages/#{message}")

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_flash(:error, "Error with your submission")
        |> render(:new, message_changeset: changeset)
        # render(conn, :new, message_changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    message = Notification.get_message!(id)
    render(conn, :show, message: message)
  end

  # def edit(conn, %{"id" => id}) do
  #   message = Notification.get_message!(id)
  #   changeset = Notification.change_message(message)
  #   render(conn, :edit, message: message, changeset: changeset)
  # end

  # def update(conn, %{"id" => id, "message" => message_params}) do
  #   message = Notification.get_message!(id)

  #   case Notification.update_message(message, message_params) do
  #     {:ok, message} ->
  #       conn
  #       |> put_flash(:info, "Message updated successfully.")
  #       |> redirect(to: ~p"/messages/#{message}")

  #     {:error, %Ecto.Changeset{} = changeset} ->
  #       render(conn, :edit, message: message, changeset: changeset)
  #   end
  # end

  def delete(conn, %{"id" => id}) do
    message = Notification.get_message!(id)
    {:ok, _message} = Notification.delete_message(message)

    conn
    |> put_flash(:info, "Message deleted successfully.")
    |> redirect(to: ~p"/messages")
  end
end
