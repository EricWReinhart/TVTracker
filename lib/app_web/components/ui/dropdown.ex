defmodule AppWeb.Components.UI.Dropdown do
  use Phoenix.Component

  alias Phoenix.LiveView.JS

  @doc """
  Renders a dropdown menu.

  ## Examples

      <.dropdown id="user-dropdown" wrapper_classes="">
        <:button class=""></:button>
        <:item patch={~p"/settings"}><%= gettext("Settings") %></:item>
        <:item method="DELETE" href={~p"/logout"}>
          <%= gettext("Sign out") %>
        </:item>
      </.dropdown>
  """
  attr :align, :string, default: "right", values: ~w(left right)
  attr :id, :string, required: true
  attr :wrapper_classes, :any, default: nil, doc: "Affect the div in which button and menu are."

  slot :button, required: true do
    attr :class, :string
  end

  slot :header

  slot :item do
    # live attrs
    attr :navigate, :string, doc: "Set to a valid path if this is a liveview patch"
    attr :patch, :string, doc: "Set to a valid path if this is a liveview patch"
    attr :push, :string, doc: "Set to a valid patch event name if this is a liveview push"
    # href attrs
    attr :href, :string, doc: "Set to a valid URL if this is a href"
    attr :method, :string, values: ~w(GET POST PUT PATCH DELETE), doc: "can be provided with href"
    attr :target, :string
  end

  def dropdown(assigns) do
    ~H"""
    <div class={["relative", @wrapper_classes]}>
      <button
        aria-expanded="false"
        aria-haspopup="true"
        id={"#{@id}-button"}
        class={@button |> List.first() |> Map.get(:class)}
        phx-click={show_dropdown(@id)}
        phx-keyup="open-dropdown"
        phx-value-id={@id}
      >
        {render_slot(@button)}
      </button>

      <.focus_wrap
        id={"#{@id}-menu"}
        class={
          [
            # Anchor positioning
            "absolute z-10 mt-2 ",
            # positioning
            @align == "left" && "left-0 origin-top-left",
            @align == "right" && "right-0 origin-top-right"
          ]
        }
        data-open={show_dropdown(@id)}
        role="menu"
        style="display:none;"
        phx-click-away={hide_dropdown(@id)}
        phx-key="escape"
        phx-window-keydown={hide_dropdown(@id)}
      >
        <div class="bg-white rounded-lg shadow w-44 dark:bg-gray-700 divide-y divide-gray-100 dark:divide-gray-600">
          {render_slot(@header)}
          <ul
            class="py-2 text-sm text-gray-700 dark:text-gray-200"
            aria-orientation="vertical"
            aria-labelledby={"#{@id}-button"}
          >
            <%= for item <- @item do %>
              <li>
                <.link
                  :if={Map.get(item, :href)}
                  class="block font-normal text-left w-full px-4 py-2 hover:bg-gray-100 dark:hover:bg-gray-600 dark:hover:text-white"
                  href={Map.get(item, :href)}
                  method={Map.get(item, :method)}
                  phx-click={hide_dropdown(@id)}
                  role="menuitem"
                  target={Map.get(item, :target, "_self")}
                >
                  {render_slot(item)}
                </.link>
                <button
                  :if={Map.get(item, :push) || Map.get(item, :patch) || Map.get(item, :navigate)}
                  type="button"
                  class="block font-normal text-left w-full px-4 py-2 hover:bg-gray-100 dark:hover:bg-gray-600 dark:hover:text-white"
                  role="menuitem"
                  phx-click={button_action(@id, item)}
                >
                  {render_slot(item)}
                </button>
              </li>
            <% end %>
          </ul>
        </div>
      </.focus_wrap>
    </div>
    """
  end

  defp button_action(id, item) do
    {push, patch, navigate} =
      {Map.get(item, :push), Map.get(item, :patch), Map.get(item, :navigate)}

    cond do
      push -> hide_dropdown(id) |> JS.push(push)
      patch -> hide_dropdown(id) |> JS.patch(patch)
      navigate -> hide_dropdown(id) |> JS.navigate(navigate)
    end
  end

  @doc """
  Call this to open a dropdown menu.

    ## Examples

      <.button phx-click={show_dropdown("user-dropdown")}></.button>
  """
  def show_dropdown(id) when is_binary(id) do
    %JS{}
    |> JS.set_attribute({"area-expanded", "true"}, to: "##{id}-button")
    |> JS.show(
      to: "##{id}-menu",
      transition: {
        "transition ease-out duration-100",
        "transform opacity-0 scale-95",
        "transform opacity-100 scale-100"
      }
    )
  end

  @doc """
  Call this to close a dropdown menu.

    ## Examples

      <.button phx-click={hide_dropdown("user-dropdown") |> JS.patch(~p"/")}></.button>
  """
  def hide_dropdown(js \\ %JS{}, id) when is_binary(id) do
    js
    |> JS.set_attribute({"area-expanded", "false"}, to: "##{id}-button")
    |> JS.hide(
      to: "##{id}-menu",
      transition: {
        "transition ease-in duration-75",
        "transform opacity-100 scale-100",
        "transform opacity-0 scale-95"
      }
    )
  end
end
