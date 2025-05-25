defmodule AppWeb.Components.UI.Badge do
  use Phoenix.Component

  @doc """
  Renders a badge.
  """
  attr :large, :boolean, default: false
  attr :color, :string, default: "default", values: ~w(default dark red green yellow indigo purple pink)
  attr :type, :string, default: "badge"
  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(disabled form name value)

  slot :inner_block, required: true

  def badge(assigns) do
    ~H"""
    <badge
      type={@type}
      class={[
        "text-sm font-medium me-2 px-2.5 py-0.5 rounded-sm",
        @large && "text-sm",
        !@large && "text-xs",
        @color == "default" &&
          "bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-300",
        @color == "dark" &&
          "bg-gray-100 text-gray-800 dark:bg-gray-700 dark:text-gray-300",
        @color == "red" &&
          "bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-300",
        @color == "green" &&
          "bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-300",
        @color == "yellow" &&
          "bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-300",
        @color == "indigo" &&
          "bg-indigo-100 text-indigo-800 dark:bg-indigo-900 dark:text-indigo-300",
        @color == "purple" &&
          "bg-purple-100 text-purple-800 dark:bg-purple-900 dark:text-purple-300",
        @color == "pink" &&
          "bg-pink-100 text-pink-800 dark:bg-pink-900 dark:text-pink-300",
        @class
      ]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </badge>
    """
  end
end
