defmodule AppWeb.UserLoginLive do
  use AppWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-sm">
      <.header class="text-center">
      <div class = "dark:text-white"> Log in to account </div>
        <:subtitle>
          <div class = "dark:text-white">
          Don't have an account?
          <.link navigate={~p"/users/register"} class="font-semibold text-brand hover:underline">
            Sign up
          </.link>
          for an account now.
          </div>
        </:subtitle>
      </.header>

      <.simple_form for={@form} id="login_form" action={~p"/users/log_in"} phx-update="ignore">
        <.input field={@form[:email]} type="email" label="Email" required />
        <.input field={@form[:password]} type="password" label="Password" required />

        <:actions>
          <.input field={@form[:remember_me]} type="checkbox" label="Keep me logged in" />
          <.link href={~p"/users/reset_password"} class="text-sm font-semibold dark:text-white">
            Forgot your password?
          </.link>
        </:actions>
        <:actions>
          <.button type="submit" phx-disable-with="Logging in..." class="w-full">
            Log in <span aria-hidden="true">→</span>
          </.button>
        </:actions>
        
        <:actions>
          <div class="mt-4 flex justify-center w-full">
            <.link
              href={~p"/auth/google"}
              class="inline-flex items-center justify-center
                    px-4 py-2 border border-gray-300 dark:border-gray-600
                    rounded-md shadow-sm text-sm font-medium
                    text-gray-700 dark:text-gray-200
                    bg-white dark:bg-gray-800
                    hover:bg-gray-50 dark:hover:bg-gray-700
                    focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
            >
              <svg
                class="w-5 h-5 mr-2"
                viewBox="0 0 24 24"
                fill="currentColor"
                aria-hidden="true"
              >
                <path d="M12.545,10.239v3.821h5.445c-0.712,2.315-2.647,3.972-5.445,3.972c-3.332,0-6.033-2.701-6.033-6.032s2.701-6.032,6.033-6.032c1.498,0,2.866,0.549,3.921,1.453l2.814-2.814C17.503,2.988,15.139,2,12.545,2C7.021,2,2.543,6.477,2.543,12s4.478,10,10.002,10c8.396,0,10.249-7.85,9.426-11.748L12.545,10.239z"/>
              </svg>
              Sign in with Google
            </.link>
          </div>
        </:actions>
      </.simple_form>


    </div>
    """
  end

  def mount(_params, _session, socket) do
    email = Phoenix.Flash.get(socket.assigns.flash, :email)
    form = to_form(%{"email" => email}, as: "user")
    {:ok, assign(socket, form: form), temporary_assigns: [form: form]}
  end

  # handle event functions that are specific to this live view


  # forward all other events to the liveview helper
  def handle_event(event, unsigned_params, socket) do
    AppWeb.LiveHelper.handle_event(event, unsigned_params, socket)
  end


end
