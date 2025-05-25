defmodule AppWeb.TVStats do
  use AppWeb, :live_view

  alias App.Accounts
  alias App.Media

  @impl true
  def mount(_params, session, socket) do
    current_user =
      case session["user_token"] do
        nil -> nil
        token -> Accounts.get_user_by_session_token(token)
      end

    # fetch only finished joins, with tv_show preloaded
    finished_joins = Media.list_user_shows(current_user, :finished)

    # === Chart 1: User Ratings per Show ===
    votes =
      finished_joins
      |> Enum.map(fn %App.Media.UserTvShow{tv_show: tv, user_rating: r} ->
        {tv.title, r || 0}
      end)
      |> Map.new()

    config_ratings = build_rating_config(votes)

    # === Chart 2: Count of Shows by Year ===
    counts_by_year =
      finished_joins
      |> Enum.group_by(&(&1.watch_year || "Unknown"))
      |> Enum.map(fn {year, joins} -> {year, length(joins)} end)
      |> Enum.sort_by(&elem(&1, 0))

    labels_year = Enum.map(counts_by_year, &elem(&1, 0))
    data_year   = Enum.map(counts_by_year, &elem(&1, 1))

    config_years = build_year_config(labels_year, data_year)

    {:ok,
     socket
     |> assign(current_user: current_user)
     |> assign(
          config_ratings: config_ratings,
          config_years:  config_years
        )}
  end

  # ----------------------------------------------------------------------------
  # helper: Chart.js config for user-rating bars
  defp build_rating_config(votes) do
    sorted = votes
      |> Enum.to_list()
      |> Enum.sort_by(fn {_t, r} -> -r end)
      |> Enum.take(10)

    labels =
      sorted
      |> Enum.map(fn {t, _} -> String.split(t, ~r/\s+/) end)
    data   = Enum.map(sorted, fn {_t, r} -> r end)

    palette = [
      %{bg: "rgba(54, 162, 235, 0.4)", border: "rgba(54, 162, 235, 1)"},
      %{bg: "rgba(255, 99, 132, 0.4)", border: "rgba(255, 99, 132, 1)"},
      %{bg: "rgba(255, 206, 86, 0.4)", border: "rgba(255, 206, 86, 1)"},
      %{bg: "rgba(75, 192, 192, 0.4)", border: "rgba(75, 192, 192, 1)"},
      %{bg: "rgba(153, 102, 255, 0.4)", border: "rgba(153, 102, 255, 1)"},
      %{bg: "rgba(255, 159, 64, 0.4)", border: "rgba(255, 159, 64, 1)"}
    ]

    chosen = Stream.cycle(palette) |> Enum.take(length(labels))

    %{
      type: "bar",
      data: %{
        labels: labels,
        datasets: [
          %{
            label: "User Rating",
            data: data,
            backgroundColor: Enum.map(chosen, & &1.bg),
            borderColor:     Enum.map(chosen, & &1.border),
            borderWidth: 1
          }
        ]
      },
      options: %{
        plugins: %{legend: %{display: false}},
        scales: %{
          x: %{ticks: %{autoSkip: false, maxRotation: 0, minRotation: 0}},
          y: %{beginAtZero: true, ticks: %{stepSize: 1}}
        }
      }
    }
  end

  defp build_year_config(labels, data) do
    palette = [
      %{bg: "rgba(255, 159, 64, 0.4)",  border: "rgba(255, 159, 64, 1)"},
      %{bg: "rgba(54, 162, 235, 0.4)",  border: "rgba(54, 162, 235, 1)"},
      %{bg: "rgba(153, 102, 255, 0.4)", border: "rgba(153, 102, 255, 1)"},
      %{bg: "rgba(75, 192, 192, 0.4)",  border: "rgba(75, 192, 192, 1)"},
      %{bg: "rgba(255, 99, 132, 0.4)",  border: "rgba(255, 99, 132, 1)"}
    ]

    chosen = Stream.cycle(palette) |> Enum.take(length(labels))

    %{
      type: "bar",
      data: %{
        labels: labels,
        datasets: [
          %{
            label: "Shows Finished",
            data: data,
            backgroundColor: Enum.map(chosen, & &1.bg),
            borderColor:     Enum.map(chosen, & &1.border),
            borderWidth: 1
          }
        ]
      },
      options: %{
        plugins: %{legend: %{display: false}},
        scales: %{
          x: %{title: %{display: true, text: "Year Finished"}, ticks: %{autoSkip: false, maxRotation: 0, minRotation: 0}},
          y: %{title: %{display: true, text: "Number of Shows"}, beginAtZero: true, ticks: %{stepSize: 1}}
        }
      }
    }
  end


  @impl true
  def render(assigns) do
    ~H"""
    <div class="p-6 max-w-4xl mx-auto space-y-12">
      <!-- Page header -->
      <header class="text-center mb-8">
        <h1 class="text-4xl font-bold text-gray-900 dark:text-gray-100 mb-2">
          Your TV Stats Dashboard
        </h1>
        <p class="text-lg text-gray-600 dark:text-gray-300 mb-4">
          See at a glance which shows you rated highest and how many you’ve completed each year.
        </p>
      </header>


      <!-- Chart 1: Ratings -->
      <div class="w-full max-w-4xl mx-auto">
        <h2 class="text-center text-xl font-bold mb-4 text-gray-800 dark:text-white">
          Top 10 Finished Shows (User Ratings)
        </h2>
        <canvas
          id="rating-chart"
          phx-hook="Chart"
          class="w-full h-80"
          data-config={Jason.encode!(@config_ratings)}
        />
      </div>

      <!-- Chart 2: by Year -->
      <div class="w-full max-w-4xl mx-auto">
        <h2 class="text-center text-xl font-bold mb-4 text-gray-800 dark:text-white">
          Finished Shows by Year
        </h2>
        <canvas
          id="year-chart"
          phx-hook="Chart"
          class="w-full h-80"
          data-config={Jason.encode!(@config_years)}
        />
      </div>
    </div>
    """
  end
end
