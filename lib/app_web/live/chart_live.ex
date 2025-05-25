defmodule AppWeb.ChartLive do
  use AppWeb, :live_view

  @questions [
    %{
      question: "What is your favorite fruit?",
      votes: %{"Strawberries" => 9, "Orange" => 1, "Banana" => 3, "Watermelon" => 4, "Other" => 5}
    },
    %{
      question: "What is your favorite season?",
      votes: %{"Spring" => 6, "Summer" => 4, "Fall" => 10, "Winter" => 2}
    },
    %{
      question: "What color are your eyes?",
      votes: %{"Brown" => 8, "Blue" => 6, "Green" => 2, "Hazel" => 5, "Other" => 1}
    },
    %{
      question: "Are you a morning person?",
      votes: %{"Yes" => 9, "No" => 13}
    },
    %{
      question: "What is your favorite pet?",
      votes: %{"Dog" => 13, "Cat" => 4, "Bird" => 3, "Fish" => 2, "Other" => 0}
    }
  ]

  @impl true
  def render(assigns) do
    ~H"""
    <div class="format dark:format-invert">
      <h2 class="text-xl font-bold mb-4 text-center"><%= @question %></h2>

      <canvas id="survey-chart" phx-hook="Chart" class={if @chart_type == "pie", do: "w-80 mx-auto", else: "w-full"} data-config={Jason.encode!(@config)} />

      <div class="text-center mt-4 space-x-2">
        <button phx-click="set_chart_type" phx-value-type="bar" class="px-4 py-2 bg-blue-500 text-white rounded hover:bg-blue-600 dark:bg-blue-600 dark:hover:bg-blue-500">Show Bar</button>
        <button phx-click="set_chart_type" phx-value-type="pie" class="px-4 py-2 bg-pink-600 text-white rounded hover:bg-pink-700 dark:bg-pink-700 dark:hover:bg-pink-600">Show Pie</button>
        <button phx-click="random_question" class="px-4 py-2 bg-yellow-500 text-white rounded hover:bg-yellow-600 dark:bg-yellow-600 dark:hover:bg-yellow-500">Random Question</button>
      </div>

      <form phx-submit="update_game" class="mt-10 text-center">
        <input type="text" name="game_title" value={@game_title} placeholder="Enter a game title" class="border p-2 rounded-md w-72 dark:bg-gray-800 dark:text-white" />
        <button type="submit" class="ml-2 px-4 py-2 bg-indigo-600 text-white rounded hover:bg-indigo-700 dark:hover:bg-indigo-500">Load Game Deals</button>
      </form>

      <canvas id="chart-deals" phx-hook="ChartDeals" class="w-full mt-8" data-config={Jason.encode!(@line_chart_config)} />
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    index = 0
    question = Enum.at(@questions, index)
    chart_type = "bar"
    default_game_title = "Skyrim"
    line_chart_config = line_chart_config(default_game_title)

    {:ok,
     assign(socket,
       chart_type: chart_type,
       question_index: index,
       question: question.question,
       config: config(chart_type, question.votes),
       game_title: default_game_title,
       line_chart_config: line_chart_config
     )}
  end

  @impl true
  def handle_event("set_chart_type", %{"type" => type}, socket) do
    question = Enum.at(@questions, socket.assigns.question_index)
    new_config = config(type, question.votes)

    {:noreply,
    socket
    |> assign(:chart_type, type)
    |> assign(:config, new_config)}
  end

  @impl true
  def handle_event("random_question", _params, socket) do
    current_index = socket.assigns.question_index
    total_questions = length(@questions)
    available_indexes = Enum.reject(0..(total_questions - 1), fn i -> i == current_index end)
    new_index = Enum.random(available_indexes)
    new_question = Enum.at(@questions, new_index)

    new_config = config(socket.assigns.chart_type, new_question.votes)

    {:noreply,
    socket
    |> assign(:question_index, new_index)
    |> assign(:question, new_question.question)
    |> assign(:config, new_config)}
  end


  @impl true
  def handle_event("update_game", %{"game_title" => title}, socket) do
    {:noreply,
     socket
     |> assign(:game_title, title)
     |> assign(:line_chart_config, line_chart_config(title))}
  end

  defp config(chart_type, votes) do
    color_schemes = [
      %{background: "rgba(255, 99, 132, 0.2)", border: "rgb(255, 99, 132)"},
      %{background: "rgba(255, 159, 64, 0.2)", border: "rgb(255, 159, 64)"},
      %{background: "rgba(255, 205, 86, 0.2)", border: "rgb(255, 205, 86)"},
      %{background: "rgba(75, 192, 192, 0.2)", border: "rgb(75, 192, 192)"},
      %{background: "rgba(54, 162, 235, 0.2)", border: "rgb(54, 162, 235)"}
    ]

    labels = Map.keys(votes)
    data = Map.values(votes)

    color_set = Enum.shuffle(color_schemes)
    extended_colors = Stream.cycle(color_set) |> Enum.take(length(labels))
    background_colors = Enum.map(extended_colors, & &1.background)
    border_colors = Enum.map(extended_colors, & &1.border)

    base = %{
      type: chart_type,
      data: %{
        labels: labels,
        datasets: [
          %{
            label: "Votes",
            data: data,
            backgroundColor: background_colors,
            borderColor: border_colors,
            borderWidth: 1
          }
        ]
      }
    }

    if chart_type == "bar" do
      Map.put(base, :options, %{
        scales: %{
          y: %{
            beginAtZero: true,
            ticks: %{stepSize: 1}
          }
        }
      })
    else
      Map.put(base, :options, %{}) # Pie-specific options can go here
    end
  end

  defp line_chart_config(game_title) do
    deals = fetch_game_prices(game_title)

    {labels, prices} =
      deals
      |> Enum.map(fn %{salePrice: sale_price, storeID: store_id} ->
        case sale_price do
          val when is_float(val) -> {"Store #{store_id}", val}
          val when is_binary(val) ->
            case Float.parse(val) do
              {float, _} -> {"Store #{store_id}", float}
              _ -> nil
            end
          _ -> nil
        end
      end)
      |> Enum.reject(&is_nil/1)
      |> Enum.unzip()

    %{
      type: "line",
      data: %{
        labels: labels,
        datasets: [
          %{
            label: "Sale Prices for #{game_title}",
            data: prices,
            borderColor: "rgb(75, 192, 192)",
            tension: 0.3
          }
        ]
      },
      options: %{
        responsive: true,
        plugins: %{
          legend: %{
            display: true,
            labels: %{
              color: "white"  # Legend label text color
            }
          },
          title: %{
            display: true,
            text: "Game Prices Across Stores",
            color: "white",  # Title color
            font: %{size: 20}
          }
        },
        scales: %{
          x: %{
            title: %{
              display: true,
              text: "Stores",
              color: "white",  # X-axis title
              font: %{size: 16}
            },
            ticks: %{color: "white"}  # X-axis tick labels
          },
          y: %{
            title: %{
              display: true,
              text: "Price (USD)",
              color: "white",  # Y-axis title
              font: %{size: 16}
            },
            ticks: %{color: "white"}  # Y-axis tick labels
          }
        }
      }
    }
  end


  def fetch_game_prices(game_title) do
    url = "https://www.cheapshark.com/api/1.0/deals?title=#{URI.encode(game_title)}"

    case HTTPoison.get(url) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} -> parse_json(body)
      {:error, %HTTPoison.Error{reason: reason}} ->
        IO.puts("Error fetching data: #{inspect(reason)}")
        []
    end
  end

  defp parse_json(body) do
    body
    |> Jason.decode!(keys: :atoms)
    |> Enum.map(&extract_price_data/1)
  end

  defp extract_price_data(deal) do
    %{
      title: deal[:title],
      price: safe_float(deal[:price]),
      salePrice: safe_float(deal[:salePrice]),
      dealID: deal[:dealID],
      storeID: deal[:storeID]
    }
  end

  defp safe_float(nil), do: nil
  defp safe_float(val) do
    case Float.parse(to_string(val)) do
      {float, _} -> float
      _ -> nil
    end
  end
end
