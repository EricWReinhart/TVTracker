defmodule AppWeb.Components.UI.Avatar do
  use Phoenix.Component

  use Phoenix.VerifiedRoutes,
    endpoint: AppWeb.Endpoint,
    router: AppWeb.Router,
    statics: AppWeb.static_paths()

  import AppWeb.Components.UI.Icon

  attr :src, :string, required: true
  attr :class, :string, default: nil

  def avatar(assigns) do
    ~H"""
    <img
      :if={@src}
      class={["w-10 h-10 rounded-full", @class]}
      src={~p"/images/avatars/#{@src}"}
      alt="Avatar"
    />

    <.icon
      :if={!@src}
      name="user-circle"
      class={
        Enum.join(
          [
            "w-10 h-10 rounded-full bg-gray-300 dark:bg-gray-800 text-gray-400 dark:text-gray-500",
            @class
          ],
          " "
        )
      }
    />
    """
  end
end
