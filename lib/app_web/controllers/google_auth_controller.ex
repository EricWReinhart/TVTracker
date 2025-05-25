defmodule AppWeb.GoogleAuthController do
  use AppWeb, :controller
  plug Ueberauth

  alias App.Accounts
  alias Ueberauth.Failure

  # successful callback
  def callback(%{assigns: %{ueberauth_auth: auth}} = conn, _params) do
    case Accounts.get_or_create_user_from_auth(auth) do
      {:ok, user} ->
        token = Accounts.generate_user_session_token(user)

        conn
        |> configure_session(renew: true)
        |> put_session(:user_token, token)
        |> assign(:current_user, user)
        |> put_flash(:info, "Welcome back, #{user.name}!")
        |> redirect(to: "/csci379-25s-h")

      {:error, reason} ->
        conn
        |> put_flash(:error, "Could not log in: #{inspect(reason)}")
        |> redirect(to: ~p"/users/log_in")
    end
  end

  def callback(%{assigns: %{ueberauth_failure: %Failure{}}} = conn, _params) do
    conn
    |> put_flash(:error, "Authentication failed, please try again.")
    |> redirect(to: ~p"/users/log_in")
  end
end
