defmodule App.ETS do
  use GenServer

  alias App.Games.MineSweeper

  require Logger

  # @name __MODULE__

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @doc """
  Create and populate in-memory data tables.
  """
  def init(_) do
    :ets.new(:minesweepers, [:ordered_set, :named_table, :public, {:read_concurrency, true}])

    # :ets.new(:planets, [:ordered_set, :named_table, :public, {:read_concurrency, true}])
    # Load and populate planets table
    # case YamlElixir.read_from_file(Path.join(:code.priv_dir(:app), "planets.yaml")) do
    #   {:ok, planets_data} ->
    #     planets =
    #       planets_data
    #       |> Enum.map(fn %{"id" => id} = attrs ->
    #         planet = App.Planets.Planet.build!(attrs)
    #         {id, planet}
    #       end)

    #     :ets.insert(:planets, planets)
    #     Logger.info("Planet table created and populated with #{Enum.count(planets)} planets.")

    #   {:error, reason} ->
    #     Logger.error("Failed to read planets.yaml: #{inspect(reason)}")
    # end

    {:ok, %{}}
  end

  def create_game do
    game = MineSweeper.build_game()
    :ets.insert(:minesweepers, {game.id, game})
    game
  end

  def update_game(game, attrs) do
    game = MineSweeper.update_game(game, attrs)
    :ets.insert(:minesweepers, {game.id, game})
    game
  end

  def get_game(id) do
    case :ets.lookup(:minesweepers, id) do
      [{_slug, game}] -> game
      _ -> nil
    end
  end

  # Returns a list of 81 booleans with 9 of them mines at random positions
  def create_random_mines do
    List.duplicate(true, 9) ++ List.duplicate(false, 72)
    |> Enum.shuffle()
  end

  def adjacent_count(game, index) do
    x = rem(index, 9)
    y = div(index, 9)

    for dx <- -1..1, dy <- -1..1, dx != 0 or dy != 0,
        x + dx in 0..8,
        y + dy in 0..8,
        reduce: 0 do
      acc ->
        neighbor_index = get_index(x + dx, y + dy)
        if Enum.at(game.mine_map, neighbor_index), do: acc + 1, else: acc
    end
  end

  defp get_index(x,y), do: y * 9 + x
end
