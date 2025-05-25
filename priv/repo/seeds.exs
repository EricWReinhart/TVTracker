# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     App.Repo.insert!(%App.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.


# [
#   %{name: "Mercury", distance: 0.39, orbital_period: 0.24},
#   %{name: "Venus", distance: 0.72, orbital_period: 0.61},
#   %{name: "Earth", distance: 1.0, orbital_period: 1.0},
#   %{name: "Mars", distance: 1.52, orbital_period: 1.88},
#   %{name: "Jupiter", distance: 5.02, orbital_period: 11.86},
#   %{name: "Saturn", distance: 9.54, orbital_period: 29.46},
#   %{name: "Uranus", distance: 19.18, orbital_period: 84.01},
#   %{name: "Neptune", distance: 30.06, orbital_period: 164.8}
# ]
# |> Enum.each(& App.Planets.create_planet(&1))


