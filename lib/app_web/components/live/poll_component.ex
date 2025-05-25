defmodule AppWeb.Components.Live.PollComponent do
  use AppWeb, :live_component

  def render(assigns) do
    ~H"""
    <div class="p-4 bg-white rounded-lg shadow-md mt-4">
      <!-- Total Votes and Show/Hide Button -->
      <div class="flex justify-between items-center">
        <div class="text-xl font-bold mb-2 mt-4">
        <span><%= gettext("Total Votes:") %></span> <%= @total_votes %>
        </div>
        <button class="px-4 py-2 bg-blue-600 text-white rounded-md"
          phx-click="toggle_results" phx-target={@myself}>
          <%= if @show_results, do: gettext("Hide Results"), else: gettext("Show Results") %>
        </button>
      </div>

      <!-- Show results only if total_votes > 0 -->
      <%= if @show_results and @total_votes > 0 do %>
        <h2 class="text-xl font-bold mb-2 mt-4"><span><%= gettext("Poll Results") %></span></h2>

        <ul class="mt-4 space-y-2">
          <%= for {image, index} <- Enum.with_index(@images) do %>
            <li class="flex items-center gap-2">
              <img src={image} width="50" class="rounded-md cursor-pointer" phx-value-index={index} />
              <div class="w-full bg-gray-200 rounded-full h-2.5">
                <div class="bg-blue-600 h-2.5 rounded-full" style={
                  "width: #{if @total_votes > 0, do: (Enum.at(@votes, index, 0) * 100) / @total_votes, else: 0}%"
                }></div>
              </div>
              <span class="text-sm font-semibold"><%= Enum.at(@votes, index, 0) %> <span><%= gettext("votes") %></span></span>
            </li>
          <% end %>
        </ul>
      <% end %>
    </div>
    """
  end

  def mount(socket) do
    {:ok, assign(socket, votes: [], total_votes: 0, show_results: false)}
  end

  def update(%{images: images}, socket) do
    {:ok, assign(socket, images: images, votes: List.duplicate(0, length(images)), total_votes: 0)}
  end

  # This update function is triggered from the parent when vote count changes
  def update(%{votes: votes, total_votes: total_votes}, socket) do
    {:ok, assign(socket, votes: votes, total_votes: total_votes)}
  end

  # Toggle showing or hiding results
  def handle_event("toggle_results", _params, socket) do
    {:noreply, update(socket, :show_results, fn show -> !show end)}
  end
end
