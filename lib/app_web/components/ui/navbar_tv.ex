defmodule AppWeb.Components.UI.NavbarTV do
  use Phoenix.Component
  use Gettext, backend: AppWeb.Gettext

  use Phoenix.VerifiedRoutes,
    endpoint: AppWeb.Endpoint,
    router: AppWeb.Router,
    statics: AppWeb.static_paths()

  @doc """
  Renders a navbar.
  """
  attr :message_changeset, :map, required: true

  def navbar_tv(assigns) do
    ~H"""
    <a href="#main-content"
       class="sr-only focus:not-sr-only focus:absolute focus:top-0 focus:left-0 focus:bg-white focus:text-black focus:p-2 z-50">
      Skip to Content
    </a>

    <nav class="sticky bg-gradient-to-r from-blue-500 to-indigo-600 text-white shadow-md transition-all duration-300 dark:from-gray-800 dark:to-gray-900">
      <div class="w-screen flex items-center justify-between p-4 relative">
        <!-- Navbar items (always visible) -->
        <div class="flex items-center space-x-8 flex-grow justify-start ml-12 rtl:space-x-reverse">
          <.link href={~p"/tvtracker"} class="text-lg font-bold hover:text-yellow-300">
            <%= gettext("TVTracker") %>
          </.link>
          <.link href={~p"/tvtracker/search"} class="text-lg font-bold hover:text-yellow-300">
            <%= gettext("Search") %>
          </.link>
          <.link href={~p"/tvtracker/library"} class="text-lg font-bold hover:text-yellow-300">
            <%= gettext("Library") %>
          </.link>
          <.link href={~p"/tvtracker/stats"} class="text-lg font-bold hover:text-yellow-300">
            <%= gettext("Stats") %>
          </.link>
          <.link href={~p"/about"} class="text-lg font-bold hover:text-yellow-300">
            <%= gettext("About") %>
          </.link>
        </div>

        <!-- Dark mode toggle, etc. -->
        <div class="flex items-center space-x-2 rtl:space-x-reverse px-2">
          <!-- put your dark-mode toggle here if needed -->
        </div>
      </div>
    </nav>
    """
  end
end
