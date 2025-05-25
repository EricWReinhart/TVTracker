defmodule AppWeb.ChatLive do
  use AppWeb, :live_view

  # will render chat, bottom message form and the modal (if liveaction == :join)
  @impl true
  def render(assigns) do
    ~H"""
    <ul id="messages" phx-update="stream" class="space-y-4 pb-20" phx-hook="AutoScroll">
      <%= for {dom_id, message} <- @streams.messages do %>
        <li id={dom_id} phx-mounted={JS.push_focus(to: "#chat_message")}>
          <%= case message do %>
            <% %{type: :user_joined, username: username} -> %>
              <div class="text-sm">
                <span class="font-semibold text-gray-900 dark:text-white"><%= username %></span>
                <span class="text-gray-500 dark:text-gray-400">{gettext("joined the chat")}</span>
              </div>

            <% %{type: :message, username: username, message: text} -> %>
              <div class="flex items-start gap-2.5 mt-4">
                <div class="flex flex-col w-full max-w-[320px] leading-1.5 p-4 border-gray-200 bg-gray-100 rounded-e-xl rounded-es-xl dark:bg-gray-700">
                  <div class="flex items-center space-x-2 rtl:space-x-reverse">
                    <span class="text-sm font-semibold text-gray-900 dark:text-white"><%= username %></span>
                  </div>
                  <p class="text-sm font-normal py-2.5 text-gray-900 dark:text-white break-words"><%= text %></p>
                </div>
              </div>

            <% %{type: :user_left, username: username} -> %>
              <div class="text-sm">
                <span class="font-semibold text-gray-900 dark:text-white"><%= username %></span>
                <span class="text-gray-500 dark:text-gray-400">{gettext("joined the chat")}</span>
              </div>
          <% end %>
        </li>
      <% end %>
    </ul>


    <div class="fixed bottom-0 left-0 right-0 bg-gray-100 h-auto justify-center dark:bg-gray-800 flex">
      <.button :if={!@username} patch={~p"/chat/join"}>
         <span>{gettext("Join Chat")}</span>
      </.button>
      <.form
        :if={@username}
        class="p-6 sm:flex gap-4 w-full items-end"
        for={@form}
        phx-change="change-message"
        phx-submit="send-message"
      >
        <.button phx-click="leave-chat">
          <span>{gettext("Leave Chat")}</span>
        </.button>

        <div class="sm:flex-1">
          <.input field={@form[:message]} id="chat_message" placeholder={gettext("Type Message")} wrapper_class="sm:flex-1" />
        </div>

        <.button type="submit">
          <span>{gettext("Send Message")}</span>
        </.button>

      </.form>
    </div>

    <.modal
      :if={@live_action == :join}
      id="join-modal"
      show
      heading={gettext("Join Chat")}
      backdrop="static"
      on_cancel={JS.patch(~p"/chat")}
    >
      <div class="p-6">
        <.form
          for={@username_form}
          phx-change="change-username"
          phx-submit="join-chat"
        >
          <.input field={@username_form[:username]} placeholder={gettext("Enter your username")}/>
          <div class="mt-6 flex justify-center">
            <.button type="submit" class="w-full">
              <span>{gettext("Join")}</span>
            </.button>
          </div>
        </.form>
        </div>
    </.modal>
    """
  end

  # will set up some basic assigns and our message stream
  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(App.PubSub, "chat")
    end

    {:ok,
     socket
     |> stream(:messages, [])
     |> assign(:form, to_form(change_message(%{}), as: :chat))
     |> assign(:username, nil)}
  end

  # will clean up/provide :username_form depending on whether we are on join page or not
  @impl true
  def handle_params(_unsigned_params, _uri, socket) do
    case socket.assigns.live_action do
      :chat ->
        {:noreply, assign(socket, :username_form, nil)}

      :join ->
        {:noreply, assign(socket, :username_form, to_form(change_username(%{}), as: :user))}
    end
  end

  # triggered when changing the message
  @impl true
  def handle_event(
        "change-message",
        %{"chat" => params},
        socket
      ) do
    changeset = change_message(params)

    {:noreply, assign(socket, :form, to_form(changeset, as: :chat))}
  end

  # triggered when submitting the message
  def handle_event(
        "send-message",
        %{"chat" => params},
        %{assigns: %{username: username}} = socket
      )
      when not is_nil(username) do
    changeset = change_message(params)

    if changeset.valid? do
      message = %{
        id: Ecto.UUID.generate(),
        username: socket.assigns.username,
        message: Ecto.Changeset.get_change(changeset, :message),
        type: :message
      }

      Phoenix.PubSub.broadcast(App.PubSub, "chat", message)

      {:noreply, assign(socket, :form, to_form(change_message(%{}), as: :chat))}
    else
      {:noreply, assign(socket, :form, to_form(changeset, as: :chat))}
    end
  end

  # triggered when changing the username
  def handle_event("change-username", %{"user" => params}, socket) do
    changeset = params |> change_username() |> Map.put(:action, :validate)
    {:noreply, assign(socket, :username_form, to_form(changeset, as: :user))}
  end

  # triggered when submitting the username / joining the chat
  def handle_event("join-chat", %{"user" => params}, socket) do
    changeset = change_username(params)

    if changeset.valid? do
      username = Ecto.Changeset.get_change(changeset, :username)

      message = %{
        id: Ecto.UUID.generate(),
        username: username,
        type: :user_joined
      }

      Phoenix.PubSub.broadcast(App.PubSub, "chat", message)

      {:noreply,
       socket
       |> assign(:username, username)
       |> push_patch(to: ~p"/chat")}
    else
      {:noreply, assign(socket, :username_form, to_form(changeset, as: :user))}
    end
  end

  # triggered when leaving the chat
  def handle_event("leave-chat", _params, socket) do
    if username = socket.assigns[:username] do
      message = %{
        id: Ecto.UUID.generate(),
        username: username,
        type: :user_left
      }

      Phoenix.PubSub.broadcast(App.PubSub, "chat", message)
    end

    {:noreply, assign(socket, :username, nil)}
  end

  # will add the message to the stream
  # triggered at all sockets by a broadcast from any socket.
  @impl true
  def handle_info(message, socket) do
    IO.inspect(message, label: "Received message")
    {:noreply, stream(socket, :messages, [message])}
  end

  # some helper functions to create inline ecto changesets without schema
  @types %{username: :string}
  defp change_username(params) do
    {%{}, @types}
    |> Ecto.Changeset.cast(params, Map.keys(@types))
    |> Ecto.Changeset.validate_required(:username)
    |> Ecto.Changeset.validate_length(:username, max: 16)
  end

  @types %{username: :string, message: :string}
  defp change_message(params) do
    {%{}, @types}
    |> Ecto.Changeset.cast(params, Map.keys(@types))
    |> Ecto.Changeset.validate_required(:message)
    |> Ecto.Changeset.validate_length(:message, max: 255)
  end
end
