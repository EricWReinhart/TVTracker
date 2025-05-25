defmodule AppWeb.Components.UI.Pill do
  use Phoenix.Component

  @doc """
  Renders a pill.

  ## Examples

      <.pill>Active</.pill>
      <.pill class="ml-2">Inactive</.pill>
  """
  attr :large, :boolean, default: false
  attr :color, :string, default: "default", values: ~w(default red green yellow indigo purple pink dark blue cyan lime amber orange violet fuchsia sky teal)
  attr :type, :string, default: "pill"
  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(disabled form name value)

  slot :inner_block, required: true

  def pill(assigns) do
    ~H"""
    <span
      class={[
        "py-2.5 px-5 me-2 mb-2 font-medium text-sm rounded-full inline-flex items-center focus:outline-none",
        @large && "text-sm",
        !@large && "text-xs",
        @color == "default" && "bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-300",
        @color == "red" && "bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-300",
        @color == "green" && "bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-300",
        @color == "yellow" && "bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-300",
        @color == "indigo" && "bg-indigo-100 text-indigo-800 dark:bg-indigo-900 dark:text-indigo-300",
        @color == "purple" && "bg-purple-100 text-purple-800 dark:bg-purple-900 dark:text-purple-300",
        @color == "pink" && "bg-pink-100 text-pink-800 dark:bg-pink-900 dark:text-pink-300",
        @color == "dark" && "bg-gray-100 text-gray-800 dark:bg-gray-900 dark:text-gray-300",
        @color == "blue" && "bg-blue-500 text-white dark:bg-blue-700 dark:text-gray-300",
        @color == "cyan" && "bg-cyan-500 text-white dark:bg-cyan-700 dark:text-gray-300",
        @color == "lime" && "bg-lime-500 text-white dark:bg-lime-700 dark:text-gray-300",
        @color == "amber" && "bg-amber-500 text-white dark:bg-amber-700 dark:text-gray-300",
        @color == "orange" && "bg-orange-500 text-white dark:bg-orange-700 dark:text-gray-300",
        @color == "violet" && "bg-violet-500 text-white dark:bg-violet-700 dark:text-gray-300",
        @color == "fuchsia" && "bg-fuchsia-500 text-white dark:bg-fuchsia-700 dark:text-gray-300",
        @color == "sky" && "bg-sky-500 text-white dark:bg-sky-700 dark:text-gray-300",
        @color == "teal" && "bg-teal-500 text-white dark:bg-teal-700 dark:text-gray-300",
        @class
      ]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </span>
    """
  end
end
