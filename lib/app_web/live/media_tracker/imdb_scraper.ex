defmodule AppWeb.OMDb do
  @moduledoc """
  Fetches media data from the OMDb API, including seasons and full details for TV shows or movies.

  Available fields from OMDb:
    - Title
    - Year
    - Rated
    - Released
    - Runtime
    - Genre
    - Director
    - Writer
    - Actors
    - Plot
    - Language
    - Country
    - Awards
    - Poster
    - Ratings (list of %{source, value})
    - Metascore
    - imdbRating
    - imdbVotes
    - imdbID
    - Type (movie, series, episode)
    - totalSeasons (series only)
    - DVD
    - BoxOffice
    - Production
    - Website
  """

  @base_url "http://www.omdbapi.com/"

  @doc "Fetches the API key from runtime configuration"
  def api_key do
    Application.fetch_env!(:app, AppWeb.OMDb)[:api_key]
  end

  @doc "Fetch detailed info for a series by title"
  def fetch_by_title(title, opts \\ []) do
    plot_opt = opts[:plot] || "full"
    type_opt = opts[:type] || "series"
    key = api_key()

    url =
      "#{@base_url}?apikey=#{key}" <>
      "&t=#{URI.encode(title)}" <>
      "&type=#{type_opt}" <>
      "&plot=#{plot_opt}" <>
      "&r=json"

    case HTTPoison.get(url) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        with {:ok, %{"Response" => "True"} = data} <- Jason.decode(body) do
          {:ok, %{
            title:         data["Title"],
            year:          data["Year"],
            rated:         data["Rated"],
            released:      data["Released"],
            runtime:       data["Runtime"],
            genres:        String.split(data["Genre"] || "", ", "),
            director:      data["Director"],
            writer:        data["Writer"],
            actors:        String.split(data["Actors"] || "", ", "),
            plot:          data["Plot"],
            language:      String.split(data["Language"] || "", ", "),
            country:       String.split(data["Country"] || "", ", "),
            awards:        data["Awards"],
            poster:        data["Poster"],
            ratings:       Enum.map(data["Ratings"] || [], fn %{"Source" => src, "Value" => val} -> %{source: src, value: val} end),
            metascore:     data["Metascore"],
            imdb_rating:   data["imdbRating"],
            imdb_votes:    data["imdbVotes"],
            imdb_id:       data["imdbID"],
            type:          data["Type"],
            total_seasons: case data["totalSeasons"] do
                              s when is_binary(s) -> String.to_integer(s)
                              _ -> nil
                            end,
            dvd:           data["DVD"],
            box_office:    data["BoxOffice"],
            production:    data["Production"],
            website:       data["Website"]
          }}
        else
          {:ok, %{"Response" => "False", "Error" => err}} ->
            {:error, err}
          error ->
            {:error, error}
        end

      {:ok, %HTTPoison.Response{status_code: code}} ->
        {:error, "HTTP error #{code}"}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc "Fetch detailed info for a series or movie by IMDb ID"
  def fetch_by_id(imdb_id, opts \\ []) when is_binary(imdb_id) do
    plot_opt = opts[:plot] || "full"
    key = api_key()

    url =
      "#{@base_url}?apikey=#{key}" <>
      "&i=#{URI.encode(imdb_id)}" <>
      "&plot=#{plot_opt}" <>
      "&r=json"

    case HTTPoison.get(url) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        with {:ok, %{"Response" => "True"} = data} <- Jason.decode(body) do
          {:ok, %{
            title:         data["Title"],
            year:          data["Year"],
            rated:         data["Rated"],
            released:      data["Released"],
            runtime:       data["Runtime"],
            genres:        String.split(data["Genre"] || "", ", "),
            director:      data["Director"],
            writer:        data["Writer"],
            actors:        String.split(data["Actors"] || "", ", "),
            plot:          data["Plot"],
            language:      String.split(data["Language"] || "", ", "),
            country:       String.split(data["Country"] || "", ", "),
            awards:        data["Awards"],
            poster:        data["Poster"],
            ratings:       Enum.map(data["Ratings"] || [], fn %{"Source" => src, "Value" => val} -> %{source: src, value: val} end),
            metascore:     data["Metascore"],
            imdb_rating:   data["imdbRating"],
            imdb_votes:    data["imdbVotes"],
            imdb_id:       data["imdbID"],
            type:          data["Type"],
            total_seasons: case data["totalSeasons"] do
                              s when is_binary(s) -> String.to_integer(s)
                              _ -> nil
                            end,
            dvd:           data["DVD"],
            box_office:    data["BoxOffice"],
            production:    data["Production"],
            website:       data["Website"]
          }}
        else
          {:ok, %{"Response" => "False", "Error" => err}} ->
            {:error, err}
          error ->
            {:error, error}
        end

      {:ok, %HTTPoison.Response{status_code: code, body: body}} ->
        {:error, "HTTP error #{code}: #{body}"}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc "Fetches data for a single season of a TV series"
  def fetch_season(show_title, season_num) do
    key = api_key()
    url = URI.encode("#{@base_url}?apikey=#{key}&t=#{show_title}&Season=#{season_num}&r=json")

    case HTTPoison.get(url) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        Jason.decode(body)
      error ->
        error
    end
  end

  @doc "Fetches all seasons for a series, including a poster for each season"
  def fetch_all_seasons(show_title) do
    with {:ok, %{"totalSeasons" => ts}} <- fetch_season(show_title, 1) do
      1..String.to_integer(ts)
      |> Enum.map(fn season_num ->
        case fetch_season(show_title, season_num) do
          {:ok, season_data} ->
            poster = fetch_season_poster(show_title, season_num)
            Map.put(season_data, "Poster", poster)
          _ ->
            nil
        end
      end)
      |> Enum.reject(&is_nil/1)
    end
  end

  @doc "Fetches the poster for the first episode of a given season, or returns a placeholder"
  def fetch_season_poster(show_title, season_num) do
    key = api_key()
    url = URI.encode("#{@base_url}?apikey=#{key}&t=#{show_title}&Season=#{season_num}&Episode=1&r=json")

    with {:ok, %HTTPoison.Response{status_code: 200, body: body}} <- HTTPoison.get(url),
         {:ok, data} <- Jason.decode(body),
         poster when is_binary(poster) <- data["Poster"],
         true <- poster != "N/A" do
      poster
    else
      _ -> "https://via.placeholder.com/300x450?text=Season+#{season_num}"
    end
  end

  @doc "Search shows by query, returning unique titles"
  def search_shows(query) do
    key = api_key()
    url = URI.encode("#{@base_url}?apikey=#{key}&s=#{query}&type=series&r=json")

    case HTTPoison.get(url) do
      {:ok, %HTTPoison.Response{body: body}} ->
        with {:ok, %{"Search" => results}} <- Jason.decode(body) do
          results |> Enum.map(& &1["Title"]) |> Enum.uniq()
        else
          _ -> []
        end

      _ -> []
    end
  end
end
