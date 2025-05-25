defmodule AppWeb.Components.UI.Input do
  use Phoenix.Component

  @doc """
  Renders an Input with label and error messages.

  A `Phoenix.HTML.FormField` may be passed as argument,
  which is used to retrieve the Input name, id, and values.
  Otherwise all attributes may be passed explicitly.

  ## Types

  This function accepts all HTML Input types, considering that:

    * You may also set `type="select"` to render a `<select>` tag

    * `type="checkbox"` is used exclusively to render boolean values

    * For live file uploads, see `Phoenix.Component.live_file_Input/1`

  See https://developer.mozilla.org/en-US/docs/Web/HTML/Element/Input
  for more information. Unsupported types, such as hidden and radio,
  are best written directly in your templates.

  ## Examples

      <.input field={@form[:email]} type="email" />
      <.input name="my-Input" errors={["oh no!"]} />
  """

  attr :id, :any, default: nil
  attr :icon, :string, default: nil
  attr :class, :any, default: nil
  attr :wrapper_class, :any, default: nil
  attr :name, :any
  attr :description, :string, default: nil
  attr :label, :string, default: nil
  attr :value, :any

  attr :type, :string,
    default: "text",
    values:
      ~w(checkbox color date datetime-local email file hidden month number password range search select tel text textarea time url week)

  attr :field, Phoenix.HTML.FormField,
    doc: "a form field struct retrieved from the form, for example: @form[:email]"

  attr :errors, :list, default: []
  attr :checked, :boolean, doc: "the checked flag for checkbox Inputs"
  attr :prompt, :string, default: nil, doc: "the prompt for select Inputs"
  attr :options, :list, doc: "the options to pass to Phoenix.HTML.Form.options_for_select/2"
  attr :multiple, :boolean, default: false, doc: "the multiple flag for select Inputs"

  attr :rest, :global,
    include:
      ~w(accept autocomplete capture cols datepicker disabled form list max maxlength min minlength multiple pattern placeholder readonly required rows size step)

  def input(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    errors = if Phoenix.Component.used_input?(field), do: field.errors, else: []

    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, Enum.map(errors, &translate_error(&1)))
    |> assign_new(:name, fn -> if assigns.multiple, do: field.name <> "[]", else: field.name end)
    |> assign_new(:value, fn -> field.value end)
    |> input()
  end

  def input(%{type: "hidden"} = assigns) do
    assigns =
      assign_new(assigns, :checked, fn ->
        Phoenix.HTML.Form.normalize_value("checkbox", assigns[:value])
      end)

    ~H"""
    <input type="hidden" id={@id} name={@name} value={@value} />
    """
  end

  def input(%{type: "checkbox"} = assigns) do
    assigns =
      assign_new(assigns, :checked, fn ->
        Phoenix.HTML.Form.normalize_value("checkbox", assigns[:value])
      end)

    ~H"""
    <div class={["flex", @wrapper_class]}>
      <div class="flex items-center h-5">
        <input type="hidden" name={@name} value="false" disabled={@rest[:disabled]} />
        <input
          type="checkbox"
          id={@id}
          name={@name}
          value="true"
          checked={@checked}
          class="w-4 h-4 text-blue-600 bg-gray-100 border-gray-300 rounded focus:ring-blue-500 dark:focus:ring-blue-600 dark:ring-offset-gray-800 focus:ring-2 dark:bg-gray-700 dark:border-gray-600"
          {@rest}
        />
      </div>
      <div class="ms-2 text-sm">
        <label for={@id} class="font-medium text-gray-900 dark:text-gray-300">
          {@label}
        </label>
        <p :if={@description} class="text-xs font-normal text-gray-500 dark:text-gray-300">
          {@description}
        </p>
        <.error :for={msg <- @errors}>{msg}</.error>
      </div>
    </div>
    """
  end

  def input(%{type: "select"} = assigns) do
    ~H"""
    <div class={@wrapper_class}>
      <.label :if={@label} for={@id} class="block mb-2">{@label}</.label>
      <select
        id={@id}
        name={@name}
        class={[
          "bg-gray-50 border border-gray-300 text-gray-900 text-sm rounded-lg block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:placeholder-gray-400 dark:text-white phx-no-feedback:focus:ring-blue-500 phx-no-feedback:focus:border-blue-500 phx-no-feedback:dark:focus:ring-blue-500 phx-no-feedback:dark:focus:border-blue-500",
          @errors == [] &&
            "focus:ring-blue-500 focus:border-blue-500 dark:focus:ring-blue-500 dark:focus:border-blue-500",
          @errors != [] &&
            "focus:ring-red-500 focus:border-red-500 dark:focus:ring-red-500 dark:focus:border-red-500"
        ]}
        multiple={@multiple}
        {@rest}
      >
        <option :if={@prompt} value="">{@prompt}</option>
        {Phoenix.HTML.Form.options_for_select(@options, @value)}
      </select>
      <div :if={@description} class="mt-2 text-sm text-gray-500 dark:text-gray-400">
        {@description}
      </div>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  def input(%{type: "textarea"} = assigns) do
    ~H"""
    <div class={@wrapper_class}>
      <.label :if={@label} for={@id} class="block mb-2">{@label}</.label>
      <textarea
        id={@id}
        name={@name}
        class={[
          "bg-gray-50 border border-gray-300 text-gray-900 text-sm rounded-lg block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:placeholder-gray-400 dark:text-white phx-no-feedback:focus:ring-blue-500 phx-no-feedback:focus:border-blue-500 phx-no-feedback:dark:focus:ring-blue-500 phx-no-feedback:dark:focus:border-blue-500 min-h-[6rem]",
          @errors == [] &&
            "focus:ring-blue-500 focus:border-blue-500 dark:focus:ring-blue-500 dark:focus:border-blue-500",
          @errors != [] &&
            "focus:ring-red-500 focus:border-red-500 dark:focus:ring-red-500 dark:focus:border-red-500"
        ]}
        {@rest}
      ><%= Phoenix.HTML.Form.normalize_value("textarea", @value) %></textarea>
      <div :if={@description} class="mt-2 text-sm text-gray-500 dark:text-gray-400">
        {@description}
      </div>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  # All other Inputs text, datetime-local, url, password, etc. are handled here...
  def input(assigns) do
    ~H"""
    <div class={@wrapper_class}>
      <.label :if={@label} for={@id} error={Enum.count(@errors) > 0} class="block mb-2">
        {@label}
      </.label>
      <div class={[@icon && "relative"]}>
        <div
          :if={@icon}
          class="absolute inset-y-0 start-0 flex items-center ps-3.5 pointer-events-none"
        >
          <svg
            :if={@icon == "calendar"}
            class="w-4 h-4 text-gray-500 dark:text-gray-400"
            aria-hidden="true"
            xmlns="http://www.w3.org/2000/svg"
            fill="currentColor"
            viewBox="0 0 20 20"
          >
            <path d="M20 4a2 2 0 0 0-2-2h-2V1a1 1 0 0 0-2 0v1h-3V1a1 1 0 0 0-2 0v1H6V1a1 1 0 0 0-2 0v1H2a2 2 0 0 0-2 2v2h20V4ZM0 18a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2V8H0v10Zm5-8h10a1 1 0 0 1 0 2H5a1 1 0 0 1 0-2Z" />
          </svg>
          <svg
            :if={@icon == "landmark"}
            class="w-4 h-4 text-gray-500 dark:text-gray-400"
            aria-hidden="true"
            xmlns="http://www.w3.org/2000/svg"
            width="24"
            height="24"
            fill="currentColor"
            viewBox="0 0 24 24"
          >
            <path
              fill-rule="evenodd"
              d="M10.915 2.345a2 2 0 0 1 2.17 0l7 4.52A2 2 0 0 1 21 8.544V9.5a1.5 1.5 0 0 1-1.5 1.5H19v6h1a1 1 0 1 1 0 2H4a1 1 0 1 1 0-2h1v-6h-.5A1.5 1.5 0 0 1 3 9.5v-.955a2 2 0 0 1 .915-1.68l7-4.52ZM17 17v-6h-2v6h2Zm-6-6h2v6h-2v-6Zm-2 6v-6H7v6h2Z"
              clip-rule="evenodd"
            />
            <path d="M2 21a1 1 0 0 1 1-1h18a1 1 0 1 1 0 2H3a1 1 0 0 1-1-1Z" />
          </svg>
        </div>
        <input
          type={@type}
          name={@name}
          id={@id}
          value={Phoenix.HTML.Form.normalize_value(@type, @value)}
          class={[
            "bg-gray-50 border phx-no-feedback:border-gray-300 text-gray-900 text-sm rounded-lg block w-full p-2.5 dark:bg-gray-700 phx-no-feedback:dark:border-gray-600 dark:placeholder-gray-400 dark:text-white  disabled:cursor-not-allowed readonly:cursor-not-allowed phx-no-feedback:focus:ring-blue-500 phx-no-feedback:focus:border-blue-500 phx-no-feedback:dark:focus:ring-blue-500 phx-no-feedback:dark:focus:border-blue-500",
            @errors == [] &&
              "border-gray-300 dark:border-gray-600 focus:ring-blue-500 focus:border-blue-500 dark:focus:ring-blue-500 dark:focus:border-blue-500",
            @errors != [] &&
              "border-red-300 dark:border-red-600 focus:ring-red-500 focus:border-red-500 dark:focus:ring-red-500 dark:focus:border-red-500",
            @icon && "ps-10",
            @class
          ]}
          {@rest}
        />
      </div>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  @doc """
  Renders a label.
  """
  attr :class, :string, default: nil
  attr :error, :boolean, default: false
  attr :for, :string, default: nil
  slot :inner_block, required: true

  def label(assigns) do
    ~H"""
    <label
      for={@for}
      class={[
        "text-sm font-medium",
        !@error && "text-gray-900 dark:text-white",
        @error && "text-red-700 dark:text-red-500",
        @class
      ]}
    >
      {render_slot(@inner_block)}
    </label>
    """
  end

  @doc """
  Generates a generic error message.
  """
  slot :inner_block, required: true

  def error(assigns) do
    ~H"""
    <p class="mt-2 text-sm text-red-600 dark:text-red-500">{render_slot(@inner_block)}</p>
    """
  end

  @doc """
  Translates an error message using gettext.
  """
  def translate_error({msg, opts}) do
    # When using gettext, we typically pass the strings we want
    # to translate as a static argument:
    #
    #     # Translate the number of files with plural rules
    #     dngettext("errors", "1 file", "%{count} files", count)
    #
    # However the error messages in our forms and APIs are generated
    # dynamically, so we need to translate them by calling Gettext
    # with our gettext backend as first argument. Translations are
    # available in the errors.po file (as we use the "errors" domain).
    if count = opts[:count] do
      Gettext.dngettext(AppWeb.Gettext, "errors", msg, msg, count, opts)
    else
      Gettext.dgettext(AppWeb.Gettext, "errors", msg, opts)
    end
  end

  @doc """
  Translates the errors for a field from a keyword list of errors.
  """
  def translate_errors(errors, field) when is_list(errors) do
    for {^field, {msg, opts}} <- errors, do: translate_error({msg, opts})
  end
end
