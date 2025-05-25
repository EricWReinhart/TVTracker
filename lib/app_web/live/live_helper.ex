defmodule AppWeb.LiveHelper do
  use AppWeb, :live_view

  # def handle_info({AppWeb.PageLive.FormComponent, {:saved, %App.Content.Page{} = page}}, socket) do
  #   # Preload any necessary associations if needed
  #   page = App.Repo.preload(page, [:topic, :tags])  # Ensure associations are loaded

  #   # Process the saved page and update the socket accordingly
  #   {:noreply, socket |> stream_insert(:pages, page)}
  # end

  def handle_info(:logout, socket) do
    Phoenix.PubSub.broadcast(App.PubSub, "user:#{socket.assigns.user.id}", :logout)
    {:noreply, push_event(socket, "logout", %{})}
  end

  # The rest of your handle_info functions follow...
  def handle_event("change-message", %{"message" => message_params}, socket) do
    cs = App.Notification.change_message(%App.Notification.Message{}, message_params)
    |> Map.put(:action, :validate)
    {:noreply, assign(socket, :message_changeset, cs)}
  end

  def handle_event("save-message", %{"message" => message_params}, socket) do
    case App.Notification.create_message(message_params) do
      {:ok, _message} ->
        cs = App.Notification.change_message(%App.Notification.Message{}, %{})
        {:noreply,
         socket
         |> put_flash(:info, "Thank you for your feedback.")
         |> assign(:message_changeset, cs)
         |> push_event("phx:close-modal", %{id: "contact-modal"})}

      {:error, cs} ->
        {:noreply,
         socket
         |> put_flash(:error, "Please correct these errors.")
         |> assign(:message_changeset, cs)}
    end
  end

  def handle_event("logout", _params, socket) do
    Phoenix.PubSub.broadcast(App.PubSub, "user:#{socket.assigns.user.id}", :logout)
    {:noreply, socket}
  end

end
