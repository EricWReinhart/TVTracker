defmodule AppWeb.Components.Live.RateComponent do
  use AppWeb, :live_component

  def render(assigns) do
    ~H"""
    <div class="p-4 bg-gray-100 rounded-lg shadow-md">
      <h2 class="text-xl font-bold mb-2 text-center"> <%= gettext("Who looks cooler?") %> </h2>
      <div class="flex gap-4 justify-center">
        <%= for image <- @current_images do %>
          <div class="text-center">
            <img src={image} class="cursor-pointer hover:opacity-80 border-4 border-transparent hover:border-blue-500 rounded-lg transition"
                 phx-click="rate" phx-value-image={image} width="200" />
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  def update(assigns, socket) do
    {:ok, assign(socket, current_images: assigns.current_images)}
  end
end
