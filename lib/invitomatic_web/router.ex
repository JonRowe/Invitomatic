defmodule InvitomaticWeb.Router do
  use InvitomaticWeb, :router

  import InvitomaticWeb.GuestAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {InvitomaticWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_guest
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", InvitomaticWeb do
    pipe_through :browser

    get "/", PageController, :home
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:invitomatic, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: InvitomaticWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", InvitomaticWeb do
    pipe_through [:browser, :redirect_if_guest_is_authenticated]

    live_session :redirect_if_guest_is_authenticated,
      on_mount: [{InvitomaticWeb.GuestAuth, :redirect_if_guest_is_authenticated}] do
      live "/guest/log_in", Live.GuestLogin, :new
    end

    post "/guest/log_in", GuestSessionController, :create
  end

  scope "/", InvitomaticWeb do
    pipe_through [:browser, :require_authenticated_guest]

    live_session :require_authenticated_guest,
      on_mount: [{InvitomaticWeb.GuestAuth, :ensure_authenticated}] do
      live "/guest/settings", Live.GuestSettings, :edit
      live "/guest/settings/confirm_email/:token", Live.GuestSettings, :confirm_email
    end
  end

  scope "/", InvitomaticWeb do
    pipe_through [:browser]

    delete "/guest/log_out", GuestSessionController, :delete
  end
end
