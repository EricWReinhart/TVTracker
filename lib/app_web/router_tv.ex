defmodule AppWeb.Router do
  use AppWeb, :router

  import AppWeb.UserAuth
  import AppWeb.LocaleController, only: [put_locale: 2]

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:put_locale)
    plug(:fetch_live_flash)
    plug(:put_root_layout, html: {AppWeb.Layouts, :root})
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
    plug(:fetch_current_user)
    plug(AppWeb.Plugs.CustomPlug)
  end

  pipeline :api do
    plug(:accepts, ["json"])
  end

  scope "/", AppWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]
    get "/auth/:provider", GoogleAuthController, :request
    get "/auth/:provider/callback", GoogleAuthController, :callback
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:app, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through(:browser)

      live_dashboard("/dashboard", metrics: AppWeb.Telemetry)
      forward("/mailbox", Plug.Swoosh.MailboxPreview)
    end
  end

  ## Authentication routes

  scope "/", AppWeb do
    pipe_through([:browser, :redirect_if_user_is_authenticated])

    live_session :redirect_if_user_is_authenticated,
      on_mount: [
        {AppWeb.UserAuth, :redirect_if_user_is_authenticated},
        {AppWeb.UserAuth, :add_message_changeset},
        {AppWeb.UserAuth, :put_locale}
      ] do
      live("/users/register", UserRegistrationLive, :new)
      live("/users/log_in", UserLoginLive, :new)
      live("/users/reset_password", UserForgotPasswordLive, :new)
      live("/users/reset_password/:token", UserResetPasswordLive, :edit)
    end

    post("/users/log_in", UserSessionController, :create)
  end

  scope "/", AppWeb do
    pipe_through([:browser, :require_authenticated_user])

    live_session :require_authenticated_user,
      on_mount: [
        {AppWeb.UserAuth, :mount_current_user},
        {AppWeb.UserAuth, :ensure_authenticated},
        {AppWeb.UserAuth, :add_message_changeset},
        {AppWeb.UserAuth, :put_locale}
      ] do
      live("/users/settings", UserSettingsLive, :edit)
      live("/users/settings/confirm_email/:token", UserSettingsLive, :confirm_email)
      resources("/messages", MessageController, only: [:index, :delete])

      put("/locale/:locale", LocaleController, :update)

      # TVTracker routes
      live "/tvtracker", HomeLive, :index
      live "/tvtracker/search", TVSearch
      live "/tvtracker/stats", TVStats
      live "/tvtracker/library", TVLive, :index
      live "/tvtracker/library/:id", TVInfo, :show
    end
  end

  scope "/", AppWeb do
    pipe_through([:browser])

    live_session :public_live,
      on_mount: [
        {AppWeb.UserAuth, :add_message_changeset},
        {AppWeb.UserAuth, :put_locale}
      ] do

      # Other projects
      live "/", HomeLive, :index
      live "/about", AboutLive
      live "/pokemon", FacemashLive
      live "/minesweeper", MinesweeperLive, :new
      live "/chat", ChatLive, :chat
      live "/chat/join", ChatLive, :join
      live "/charts", ChartLive
      live "/animations", AnimationsLive
      live "/accessibility", AccessibilityLive
    end
  end

  scope "/", AppWeb do
    pipe_through([:browser])

    delete("/users/log_out", UserSessionController, :delete)

    live_session :current_user,
      on_mount: [
        {AppWeb.UserAuth, :mount_current_user},
        {AppWeb.UserAuth, :add_message_changeset},
        {AppWeb.UserAuth, :put_locale}
      ] do
      live("/users/confirm/:token", UserConfirmationLive, :edit)
      live("/users/confirm", UserConfirmationInstructionsLive, :new)
    end
  end
end
