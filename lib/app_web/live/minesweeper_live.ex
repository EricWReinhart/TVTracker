defmodule AppWeb.MinesweeperLive do
  use AppWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-col items-center justify-center">
      <h1 class="text-3xl font-bold mb-6 text-black dark:text-white">Minesweeper</h1>

      <div class="text-lg font-semibold mb-3 text-black dark:text-white">
        💣 Mines Remaining: <%= @remaining_bombs %>
      </div>

      <div class="grid grid-cols-9 border border-black">
        <%= for {cell, index} <- Enum.with_index(@game.open_map) do %>
          <%= if cell do %>
            <%= if Enum.at(@game.mine_map, index) do %>
              <!-- Revealed bomb -->
              <div class="w-8 h-8 flex items-center justify-center bg-red-400 border border-black text-sm font-bold text-white">
                💣
              </div>
            <% else %>
              <!-- Revealed number -->
              <div class="w-8 h-8 flex items-center justify-center bg-gray-300 border border-black text-sm font-bold">
                <%= App.ETS.adjacent_count(@game, index) %>
              </div>
            <% end %>
          <% else %>
            <!-- Unrevealed tile: dark gray, lighter on hover -->
            <button
              phx-click="open"
              phx-value-index={index}
              class={
                [
                  "w-8 h-8 bg-gray-400 hover:bg-gray-300 border border-black",
                  @game.finished && "cursor-not-allowed opacity-70"
                ]
              }>
            </button>
          <% end %>
        <% end %>
      </div>

      <%= if @game.finished do %>
        <div class="mt-4 text-xl font-bold">
          <%= if Enum.any?(@game.mine_map, fn mine -> mine and Enum.at(@game.open_map, Enum.find_index(@game.mine_map, &(&1 == mine))) end) do %>
            <div class="text-red-600 dark:text-red-400">💥 Game Over!</div>
          <% else %>
            <div class="text-green-600 dark:text-green-400">🎉 You Win!</div>
          <% end %>
        </div>
        <button phx-click="restart" class="mt-3 px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-500">
          Play Again
        </button>
      <% end %>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    game = App.ETS.create_game()
    {:ok, assign(socket, game: game, remaining_bombs: count_remaining_bombs(game))}
  end

  @impl true
  def handle_event("open", %{"index" => index_str}, socket) do
    index = String.to_integer(index_str)
    game = socket.assigns.game

    if game.finished do
      {:noreply, socket}
    else
      is_mine = Enum.at(game.mine_map, index)

      updated_open_map =
        if is_mine do
          # Reveal all mines if player clicks a bomb
          Enum.with_index(game.mine_map)
          |> Enum.map(fn {has_mine, i} -> has_mine or Enum.at(game.open_map, i) end)
        else
          List.replace_at(game.open_map, index, true)
        end

      # Win detection: if all non-mine tiles are revealed
      total_tiles = length(game.mine_map)
      mine_count = Enum.count(game.mine_map, & &1)
      non_mine_count = total_tiles - mine_count
      opened_tiles = Enum.count(updated_open_map, & &1)
      won = opened_tiles == non_mine_count

      finished = is_mine or won

      updated_game = App.ETS.update_game(game, %{
        open_map: updated_open_map,
        last_opened: index,
        finished: finished
      })

      {:noreply, assign(socket, game: updated_game, remaining_bombs: count_remaining_bombs(updated_game))}
    end
  end


  @impl true
  def handle_event("restart", _params, socket) do
    game = App.ETS.create_game()
    {:noreply, assign(socket, game: game, remaining_bombs: count_remaining_bombs(game))}
  end

  defp count_remaining_bombs(game) do
    total_mines = Enum.count(game.mine_map, & &1)
    opened_mines =
      Enum.zip(game.mine_map, game.open_map)
      |> Enum.count(fn {mine, open} -> mine and open end)

    total_mines - opened_mines
  end
end
