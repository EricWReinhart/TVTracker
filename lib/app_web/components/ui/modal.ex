defmodule AppWeb.Components.UI.Modal do
  use Phoenix.Component

  import AppWeb.CoreComponents, only: [show: 2, hide: 2]
  import AppWeb.Components.UI.Icon

  alias Phoenix.LiveView.JS

  @classes %{
    "placement" => %{
      "top-left" => "justify-start items-start",
      "top-center" => "justify-center items-start",
      "top-right" => "justify-end items-start",
      "center" => "justify-center items-center",
      "center-left" => "justify-start items-center",
      "center-right" => "justify-end items-center",
      "bottom-left" => "justify-start items-end",
      "bottom-center" => "justify-center items-end",
      "bottom-right" => "justify-end items-end"
    },
    "size" => %{
      "sm" => "max-w-md",
      "md" => "max-w-lg",
      "lg" => "max-w-4xl",
      "xl" => "max-w-7xl"
    }
  }

  @doc """
  Renders a Flowbite [Modal](https://flowbite.com/docs/components/modal).

  Expects pushing on open close, such as:
  /path       (modal closed)
  /path/new   (modal open)


  ## Examples

      <.modal id="confirm-modal">
        This is a modal.
      </.modal>

  JS commands may be passed to the `:on_cancel` to configure
  the closing/cancel event, for example:

      <.modal
        :if={@live_action in [:new, :edit]}
        heading={@page_title}
        id="page-form-modal"
        show
        on_cancel={JS.patch(~p"/pages")}
      >
        This is another modal.
      </.modal>

  """
  attr :backdrop, :string,
    default: "dynamic",
    values: ~w(dynamic static),
    doc: "Choose between static or dynamic to prevent closing the modal when clicking outside."

  attr :heading, :string, default: nil
  attr :id, :string, required: true
  attr :show, :boolean, default: false
  attr :on_cancel, JS, default: %JS{}
  attr :placement, :string, default: "center", values: Map.keys(@classes["placement"])
  attr :size, :string, default: "md", values: Map.keys(@classes["size"])
  slot :inner_block, required: true

  def modal(assigns) do
    assigns =
      assigns
      |> assign(:class, [
        "fixed top-0 left-0 right-0 z-50 hidden w-full p-4 overflow-x-hidden overflow-y-auto md:inset-0 h-[calc(100%-1rem)] max-h-full",
        @classes["placement"][assigns.placement]
      ])
      |> assign_new(:size_class, fn -> @classes["size"][assigns.size] end)

    ~H"""
    <%!-- Modal Wrapper --%>
    <div
      aria-hidden="true"
      class={@class}
      data-cancel={JS.exec(@on_cancel, "phx-remove")}
      id={@id}
      phx-mounted={@show && show_modal(@id)}
      phx-remove={hide_modal(@id)}
      tabindex="-1"
    >
      <%!-- Modal Backdrop --%>
      <div
        id={"#{@id}-bg"}
        class="bg-gray-900/50 dark:bg-gray-900/80 fixed inset-0 transition-opacity"
        aria-hidden="true"
      />
      <%!-- Modal --%>
      <div class={"relative p-4 w-full #{@size_class} max-h-full"}>
        <%!-- Modal Content --%>
        <.focus_wrap
          id={"#{@id}-container"}
          phx-window-keydown={JS.exec("data-cancel", to: "##{@id}")}
          phx-key="escape"
          phx-click-away={@backdrop == "dynamic" && JS.exec("data-cancel", to: "##{@id}")}
          class="relative bg-white rounded-lg shadow-sm dark:bg-gray-700"
        >
          <%!-- Heading and Close button --%>
          <div
            :if={@heading}
            class="flex items-center justify-between p-4 md:p-5 border-b rounded-t dark:border-gray-600 border-gray-200"
          >
            <h3 class="text-xl font-semibold text-gray-900 dark:text-white">{@heading}</h3>
            <button
              type="button"
              class="text-gray-400 bg-transparent hover:bg-gray-200 hover:text-gray-900 rounded-lg text-sm w-8 h-8 ms-auto inline-flex justify-center items-center dark:hover:bg-gray-600 dark:hover:text-white"
              phx-click={JS.exec("data-cancel", to: "##{@id}")}
            >
              <.icon name="x" class="w-10 h-10" />
              <span class="sr-only">Close modal</span>
            </button>
          </div>

          <%!-- Close Button without Heading --%>
          <button
            :if={!@heading}
            type="button"
            class="absolute top-3 end-2.5 text-gray-400 bg-transparent hover:bg-gray-200 hover:text-gray-900 rounded-lg text-sm w-8 h-8 ms-auto inline-flex justify-center items-center dark:hover:bg-gray-600 dark:hover:text-white"
            phx-click={JS.exec("data-cancel", to: "##{@id}")}
          >
            <.icon name="x" class="w-10 h-10" />
            <span class="sr-only">Close modal</span>
          </button>
          <div id={"#{@id}-content"}>
              {render_slot(@inner_block)}
          </div>
        </.focus_wrap>
      </div>
    </div>
    """
  end

  def show_modal(js \\ %JS{}, id) when is_binary(id) do
    js
    |> JS.show(to: "##{id}", display: "flex")
    |> JS.show(
      to: "##{id}-bg",
      transition: {"transition-all transform ease-out duration-300", "opacity-0", "opacity-100"}
    )
    |> show("##{id}-container")
    |> JS.add_class("overflow-hidden", to: "body")

    |> JS.remove_attribute("aria-hidden", to: "##{id}")
    |> JS.set_attribute({"aria-modal", "true"}, to: "##{id}")
    |> JS.set_attribute({"role", "dialog"}, to: "##{id}")
    |> JS.focus_first(to: "##{id}-content")
  end

  def hide_modal(js \\ %JS{}, id) do
    js
    |> JS.hide(
      to: "##{id}-bg",
      transition: {"transition-all transform ease-in duration-200", "opacity-100", "opacity-0"}
    )
    |> hide("##{id}-container")
    |> JS.hide(to: "##{id}", transition: {"flex", "flex", "hidden"})
    |> JS.remove_class("overflow-hidden", to: "body")
    |> JS.pop_focus()
    |> JS.remove_attribute("aria-modal", to: "##{id}")
    |> JS.remove_attribute("role", to: "##{id}")
    |> JS.set_attribute({"aria-hidden", "true"}, to: "##{id}")
  end
end
