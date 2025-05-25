defmodule App.Planets do
  @moduledoc """
  A context to retrieve data of our solar system.

  This works with planets loaded from a YAML file into ETS.
  """

  @table :planets

  # List all planets
  def list_planets do
    if :ets.whereis(@table) == :undefined do
      []
    else
      :ets.tab2list(@table)
      |> Enum.map(fn {_id, planet} -> planet end)
    end
  end

  # List all planets sorted by name
  def list_planets(:sorted_by_name) do
    list_planets()
    |> Enum.sort_by(& &1.name)
  end

  # List all planets sorted by any field and order
  def list_planets({field, :asc}) do
    list_planets()
    |> Enum.sort_by(&Map.get(&1, field))
  end

  def list_planets({field, :desc}) do
    list_planets()
    |> Enum.sort_by(&Map.get(&1, field), :desc)
  end

  # Get planet by ID
  def get_planet(id) do
    case :ets.lookup(@table, id) do
      [{^id, planet}] -> planet
      _ -> nil
    end
  end

  # Get a random planet
  def get_random_planet do
    list_planets()
    |> Enum.random()
  end
end
