defmodule AppWeb.Components.UI.ButtonTest do
  use AppWeb.ComponentCase

  import AppWeb.Components.UI.Button

  test "default button" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H"""
        <.button class="custom-class" id="ID">Click</.button>
        """
      )

    assert html =~ "id=\"ID"
    assert html =~ "type=\"button"
    assert html =~ "custom-class"
    assert html =~ "text-white bg-blue-700 hover:bg-blue-800"
    assert html =~ "py-2.5 px-5 me-2 mb-2"
    assert html =~ "Click"
    assert html =~ "</button>"
  end

  test "default button with custom classes" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H"""
        <.button color="default" class="custom-class">Click</.button>
        """
      )
    assert html =~ "type=\"button"
    assert html =~ "text-white bg-blue-700 hover:bg-blue-800"
    assert html =~ "Click"
  end

  test "alternative submit button" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H"""
        <.button type="submit" color="alternative">Click</.button>
        """
      )

    assert html =~ "type=\"submit"
    assert html =~ "py-2.5 px-5 me-2 mb-2"
    assert html =~ "text-gray-900 bg-white border border-gray-200"
    assert html =~ "</button>"
  end
end
