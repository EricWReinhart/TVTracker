defmodule AppWeb.Plugs.CustomPlug do
  import Plug.Conn

  alias App.Notification
  alias App.Notification.Message

  def init(default), do: default

  def call(conn, _opts) do
    changeset = Notification.change_message(%Message{})
    assign(conn, :message_changeset, changeset)
  end
end
