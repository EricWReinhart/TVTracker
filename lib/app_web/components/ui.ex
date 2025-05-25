defmodule AppWeb.Components.UI do
  @moduledoc """
  Provides resuable UI components.

  Basic UI components are derived from [Flowbite](https://flowbite.com/).
  Icons are provided by [Flowbite](https://flowbite.com/icons/). See `icon/1` for usage.
  """

  defmacro __using__(_) do
    quote do
      import AppWeb.Components.UI.{
        Button,
        Badge,
        Pill,
        # Navbar,
        NavbarTV,
        Icon,
        Modal,
        Avatar,
        Input,
        Dropdown,
        Toggle,
        Rating,
        Footer,
        Timeline,
        Carousel
      }
    end
  end
end
