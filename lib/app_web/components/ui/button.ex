defmodule AppWeb.Components.UI.Button do
  @moduledoc """
  Flowbite Button
  based on: https://flowbite.com/docs/components/buttons/

  Currently only supports
  - default button style (rounded corners)
  - colors [default, alternative]
  - sizes
  - leading icons
  """
  use Phoenix.Component

  import AppWeb.Components.UI.Icon

  use Phoenix.VerifiedRoutes,
    endpoint: AppWeb.Endpoint,
    router: AppWeb.Router,
    statics: AppWeb.static_paths()


  @doc """
  Renders a styled button.

  ## Examples

      <.button color="alternative" size="xl">Test</.button>
      <.button icon="plus">Test</.button>
  """
  attr :class, :string, default: nil
  attr :color, :string, default: "default", values: ~w(default alternative menu)
  attr :icon, :string, default: nil, doc: "Use at least md size."
  attr :trailing, :boolean, default: false, doc: "Is the icon trailing (true), or leading (false)"
  attr :size, :string, default: "md", values: ~w(xs sm md lg xl)
  attr :style, :string, default: "normal", values: ~w(normal menu)
  attr :patch, :string, default: nil
  attr :navigate, :string, default: nil
  attr :href, :string, default: nil
  attr :method, :string, default: nil

  attr :type, :string, default: "button", values: ["button", "submit"]
  attr :rest, :global, default: %{}, include: ~w(disabled name value)

  slot :inner_block

  def button(%{style: "menu"} = assigns) do
    ~H"""
    <%= if @patch || @navigate || @href do %>
      <.link
        patch={@patch}
        navigate={@navigate}
        href={@href}
        method={@method}
        class={[
          "flex items-center justify-between w-full py-2 px-3 text-gray-900 hover:bg-gray-100 md:hover:bg-transparent md:border-0 md:hover:text-blue-700 md:p-0 md:w-auto dark:text-white md:dark:hover:text-blue-500 dark:focus:text-white dark:hover:bg-gray-700 md:dark:hover:bg-transparent",
          @class
        ]}
        {@rest}
      >
        {render_slot(@inner_block)}
      </.link>
    <% else %>
      <button
        type={@type}
        class={[
          "flex items-center justify-between w-full py-2 px-3 text-gray-900 hover:bg-gray-100 md:hover:bg-transparent md:border-0 md:hover:text-blue-700 md:p-0 md:w-auto dark:text-white md:dark:hover:text-blue-500 dark:focus:text-white dark:hover:bg-gray-700 md:dark:hover:bg-transparent",
          @class
        ]}
        {@rest}
      >
        {render_slot(@inner_block)}
      </button>
    <% end %>
    """
  end

  def button(%{style: "normal"} = assigns) do
    ~H"""
    <%= if @patch || @navigate || @href do %>
      <.link
        patch={@patch}
        navigate={@navigate}
        href={@href}
        method={@method}
        class={[
          "font-medium focus:outline-none focus:ring-4 rounded-lg disabled:cursor-not-allowed",
          color_classes(@color),
          size_classes(@size),
          @icon && "inline-flex items-center justify-center group",
          @class
        ]}
        {@rest}
      >
        <.icon
          :if={@icon}
          name={@icon}
          class={Enum.join(["mr-2", icon_size_classes(@size), icon_color_classes(@color)], " ")}
        />
        {render_slot(@inner_block)}
      </.link>
    <% else %>
      <button
        type={@type}
        class={[
          "font-medium focus:outline-none focus:ring-4 rounded-lg disabled:cursor-not-allowed",
          color_classes(@color),
          size_classes(@size),
          @icon && "inline-flex items-center justify-center group",
          @class
        ]}
        {@rest}
      >
        <.icon
          :if={@icon}
          name={@icon}
          class={Enum.join(["mr-2", icon_size_classes(@size), icon_color_classes(@color)], " ")}
        />
        {render_slot(@inner_block)}
      </button>
    <% end %>
    """
  end

  def button(%{style: "user-menu"} = assigns) do
    ~H"""
    <button
      type="button"
      class={[
        "rounded-full focus:ring-4 focus:ring-gray-300 dark:focus:ring-gray-600",
        @class
      ]}
      {@rest}
    >
      <span class="sr-only">Open user menu</span>
      {render_slot(@inner_block)}
    </button>
    """
  end

  defp size_classes("xs"), do: "px-3 py-2 text-xs"
  defp size_classes("sm"), do: "px-3 py-2 text-sm"
  defp size_classes("md"), do: "px-5 py-2.5 text-sm"
  defp size_classes("lg"), do: "px-5 py-3 text-base"
  defp size_classes("xl"), do: "px-6 py-3.5 text-base"

  defp icon_size_classes("xs"), do: "w-3 h-3"
  defp icon_size_classes("sm"), do: "w-3.5 h-3.5"
  defp icon_size_classes("md"), do: "w-3.5 h-3.5"
  defp icon_size_classes("lg"), do: "w-4 h-4"
  defp icon_size_classes("xl"), do: "w-4 h-4"

  defp color_classes("default") do
    "text-white bg-blue-700 hover:bg-blue-800 focus:ring-blue-300 dark:bg-blue-600 dark:hover:bg-blue-700 dark:focus:ring-blue-800"
  end

  defp color_classes("alternative") do
    "text-gray-900 bg-white border border-gray-200 hover:bg-gray-100 hover:text-blue-700 focus:ring-gray-100 dark:focus:ring-gray-700 dark:bg-gray-800 dark:text-gray-400 dark:border-gray-600 dark:hover:text-white dark:hover:bg-gray-700 disabled:hover:bg-white dark:disabled:hover:bg-gray-800 disabled:hover:text-gray-900 dark:disabled:hover:text-gray-400 disabled:opacity-50"
  end

  defp icon_color_classes("default"), do: "text-white"

  defp icon_color_classes("alternative") do
    "text-gray-900 dark:text-gray-400 group-hover:text-blue-700 dark:group-hover:text-white"
  end

  @doc """
  Creates a button to switch between locales.

    ## Examples
      <.language_toggle locale={@locale} />
  """
  attr :locale, :string, required: true, values: ~w(de en)

  def language_toggle(assigns) do
    ~H"""
    <.link
      :if={@locale == "en"}
      type="button"
      class="rounded-full size-6 block"
      href={~p"/locale/de"}
      method="PUT"
    >
      <span class="sr-only">Deutsch</span>
      <svg
        aria-hidden="true"
        class="size-6 rounded-full"
        xmlns:xlink="http://www.w3.org/1999/xlink"
        viewBox="0 0 3900 3900"
      >
        <path fill="#b22234" d="M0 0h7410v3900H0z" />
        <path
          d="M0 450h7410m0 600H0m0 600h7410m0 600H0m0 600h7410m0 600H0"
          stroke="#fff"
          stroke-width="300"
        />
        <path fill="#3c3b6e" d="M0 0h2964v2100H0z" />
        <g fill="#fff">
          <g id="d">
            <g id="c">
              <g id="e">
                <g id="b">
                  <path id="a" d="M247 90l70.534 217.082-184.66-134.164h228.253L176.466 307.082z" />
                  <use xlink:href="#a" y="420" />
                  <use xlink:href="#a" y="840" />
                  <use xlink:href="#a" y="1260" />
                </g>
                <use xlink:href="#a" y="1680" />
              </g>
              <use xlink:href="#b" x="247" y="210" />
            </g>
            <use xlink:href="#c" x="494" />
          </g>
          <use xlink:href="#d" x="988" />
          <use xlink:href="#c" x="1976" />
          <use xlink:href="#e" x="2470" />
        </g>
      </svg>
    </.link>

    <.link
      :if={@locale == "de"}
      class="rounded-full size-6 block"
      type="button"
      href={~p"/locale/en"}
      method="PUT"
    >
      <span class="sr-only">English (US)</span>
      <svg aria-hidden="true" class="size-6 rounded-full" viewBox="0 0 512 512">
        <path fill="#ffce00" d="M0 341.3h512V512H0z" />
        <path d="M0 0h512v170.7H0z" />
        <path fill="#d00" d="M0 170.7h512v170.6H0z" />
      </svg>
    </.link>
    """
  end
end
