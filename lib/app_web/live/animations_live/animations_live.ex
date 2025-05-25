defmodule AppWeb.AnimationsLive do
  use AppWeb, :live_view

  alias Phoenix.LiveView.JS

  def show_custom_modal(id) do
    %JS{}
    |> JS.show(to: "##{id}-wrapper")
    |> JS.show(
      to: "##{id}-backdrop",
      transition: {"ease-out duration-300", "opacity-0", "opacity-100"}
    )
    |> JS.show(
        to: "##{id}",
        transition:
          {"ease-out duration-300", "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95",
           "opacity-100 translate-y-0 sm:scale-100"}
    )
  end

  def hide_custom_modal(id) do
    %JS{}
    |> JS.hide(
      to: "##{id}-wrapper",
      transition: {"duration-200", "", ""}
    )
    |> JS.hide(
      to: "##{id}-backdrop",
      transition: {"ease-in duration-200", "opacity-100", "opacity-0"}
    )
    |> JS.hide(
      to: "##{id}",
      transition:
        {"ease-in duration-200", "opacity-100 translate-y-0 sm:scale-100",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"}
    )
  end
end
