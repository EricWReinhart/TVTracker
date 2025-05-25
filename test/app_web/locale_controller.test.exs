defmodule AppWeb.LocaleControllerTest do
  use AppWeb.ConnCase, async: true

  @locale_cookie "_app_web_locale"

  describe "PUT locale" do
    test "assigns locale from session when present", %{conn: conn} do
      # Simulate a connection with a locale in the session
      conn = get(conn, "/")

      # Check that the default locale from session is assigned
      assert get_session(conn, :locale) == "en"
      assert conn.assigns[:locale] == "en"

      # Check that the locale is also stored in the cookie
      assert conn.resp_cookies[@locale_cookie].value == "en"
    end

    test "assigns locale from cookie when present", %{conn: conn} do
      # Simulate a connection with a locale in the cookie
      conn =
        conn
        |> put_resp_cookie(@locale_cookie, "de")
        |> get("/")

      # Check that the locale from cookie is assigned
      assert get_session(conn, :locale) == "de"
      assert conn.assigns[:locale] == "de"
    end

    test "assigns locale from accept-language header", %{conn: conn} do
      # Simulate a connection with an Accept-Language header
      conn =
        conn
        |> put_req_header("accept-language", "de,en;q=0.8")
        |> get("/")

      # Check that the locale from the header is assigned
      assert get_session(conn, :locale) == "de"
      assert conn.assigns[:locale] == "de"
    end

    test "assigns default locale when none provided", %{conn: conn} do
      # Simulate a connection with no locale set in session, cookie, or header
      conn = get(conn, "/")

      # Check that the default locale is assigned
      assert get_session(conn, :locale) == "en"
      assert conn.assigns[:locale] == "en"
    end

    test "assigns locale from header but defaults to 'en' if unsupported", %{conn: conn} do
      # Simulate a connection with an unsupported language in the Accept-Language header
      conn =
        conn
        |> put_req_header("accept-language", "fr,es;q=0.8")
        |> get("/")

      # Check that it defaults to 'en'
      assert get_session(conn, :locale) == "en"
      assert conn.assigns[:locale] == "en"
    end
  end

  describe "update/2" do
    setup %{conn: conn} do
      # Set up the conn with a referer and a default locale (e.g., "en")
      conn =
        conn
        |> put_req_header("referer", "http://example.com")
        |> assign(:locale, "en")

      {:ok, conn: conn}
    end

    test "toggles locale from 'en' to 'de' and redirects to referer", %{conn: conn} do
      conn = put(conn, ~p"/locale/de")

      assert get_session(conn, :locale) == "de"
      assert fetch_cookies(conn).cookies[@locale_cookie] == "de"
      assert conn.assigns.locale == "de"
      assert redirected_to(conn) == "http://example.com"
    end

    test "toggles locale from 'de' to 'en' and redirects to referer", %{conn: conn} do
      # Setting initial locale to "de"
      conn = assign(conn, :locale, "de")
      conn = put(conn, ~p"/locale/en")

      assert get_session(conn, :locale) == "en"
      assert fetch_cookies(conn).cookies[@locale_cookie] == "en"
      assert conn.assigns.locale == "en"
      assert redirected_to(conn) == "http://example.com"
    end
  end
end
