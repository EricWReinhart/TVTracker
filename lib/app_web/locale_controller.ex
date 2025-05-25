defmodule AppWeb.LocaleController do
  use AppWeb, :controller
  use Gettext, backend: AppWeb.Gettext

  import Plug.Conn

  # Make the locale cookie valid for 60 days.
  @max_age 60 * 60 * 24 * 60
  @locale_cookie "_dsa_web_locale"
  @locale_options [max_age: @max_age, same_site: "Lax"]

  @doc """
  Plug to automatically set the locale based on (in this priority):
    1. Session Data
    2. Cookie Data
    3. Preferred language from header
    4. English

  Will also keep the preference alive, as long as the visitor visits within the 60 day duration.
  """
  def put_locale(conn, _opts) do
    locale =
      Map.get(conn.assigns, :locale) ||
        get_session(conn, :locale) ||
        fetch_cookies(conn).cookies[@locale_cookie] ||
        parse_accept_language_from_headers(conn)

    Gettext.put_locale(locale)

    conn
    |> assign(:locale, locale)
    |> put_session(:locale, locale)
    |> put_resp_cookie(@locale_cookie, locale, @locale_options)
  end

  # Helper to parse the Accept-Language header and extract the preferred language, defaults to en
  defp parse_accept_language_from_headers(conn) do
    case Enum.find(conn.req_headers, fn {k, _v} -> k == "accept-language" end) do
      {_, locale} ->
        locale =
          locale
          # Split on commas for multiple languages
          |> String.split(",")
          # Trim spaces
          |> Enum.map(&String.trim/1)
          # Get the first preferred language
          |> List.first()
          # Split language region (e.g., "en-US")
          |> String.split("-")
          # Extract the language (e.g., "en")
          |> List.first()

        cond do
          String.starts_with?(locale, "de-") || locale == "de" -> "de"
          true -> "en"
        end

      nil ->
        "en"
    end
  end

  @doc """
  Action that allows toggling between locales.
  It will update session, set the cookie, and redirect to the same url that refered it.
  """
  def update(conn, %{"locale" => locale}) when locale in ["de", "en"] do
    referer =
      Enum.find(conn.req_headers, fn {k, _v} -> k == "referer" end)
      |> case do
        {_, referer} -> referer
        nil -> "/"
      end

    conn
    |> put_session(:locale, locale)
    |> put_resp_cookie(@locale_cookie, locale, @locale_options)
    |> assign(:locale, locale)
    |> redirect(external: referer)
  end

  
end
