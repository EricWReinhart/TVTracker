defmodule AppWeb.FacemashLive do
  use AppWeb, :live_view

  alias AppWeb.Components.Live.{RateComponent, PollComponent}

  def render(assigns) do
    ~H"""
    <.live_component module={RateComponent} id="rate-component" current_images={@current_images} />
    <.live_component module={PollComponent} id="poll-component" images={@images}  />
    """
  end

  def mount(_params, _session, socket) do
    # images = Enum.map([3, 6, 9, 243, 350, 373, 376, 466, 553, 637], &AppWeb.Endpoint.static_path("/images/facemash/pokemon/#{&1}.png")) # favorites
    # images = Enum.map([155, 158, 252, 255, 258, 495, 501], &AppWeb.Endpoint.static_path("/images/facemash/pokemon/#{&1}.png")) # starters
    images = Enum.map(Enum.take_random(1.. 648, 8), &AppWeb.Endpoint.static_path("/images/facemash/pokemon/#{&1}.png")) # random

    # images = Enum.map(Enum.take_random(1.. 3, 3), &AppWeb.Endpoint.static_path("/images/facemash/dogs/#{&1}.png")) # random

    initial_votes = List.duplicate(0, length(images))

    # Select 2 random images to display initially
    current_images = Enum.take_random(images, 2)

    {:ok, assign(socket, images: images, current_images: current_images, votes: initial_votes, total_votes: 0)}
  end

  def handle_event("rate", %{"image" => image_url}, socket) do
    case Enum.find_index(socket.assigns.images, fn img -> img == image_url end) do
      nil -> {:noreply, socket} # Ignore if image not found (shouldn't happen)

      index ->
        votes = List.update_at(socket.assigns.votes, index, &(&1 + 1))
        total_votes = socket.assigns.total_votes + 1

        # Pick 2 new random images
        new_images = Enum.take_random(socket.assigns.images, 2)

        # Send update to PollComponent to refresh the poll
        send_update(AppWeb.Components.Live.PollComponent,
          id: "poll-component",
          votes: votes,
          total_votes: total_votes
        )

        {:noreply, assign(socket, votes: votes, total_votes: total_votes, current_images: new_images)}
    end
  end

  # def handle_event(event, unsigned_params, socket) do
  #   AppWeb.LiveHelper.handle_event(event, unsigned_params, socket)
  # end

  # All other events will be redirected and resolved by the LiveHelper
  def handle_event(event, params, socket) do
    AppWeb.LiveHelper.handle_event(event, params, socket)
  end

  # All other info handlers will be redirected and resolved by the LiveHelper
  def handle_info(message, socket) do
    AppWeb.LiveHelper.handle_info(message, socket)
  end

end
