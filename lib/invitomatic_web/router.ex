defmodule InvitomaticWeb.Router do
  use InvitomaticWeb, :router

  import InvitomaticWeb.Auth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {InvitomaticWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_login
  end

  pipeline :api do
    plug :accepts, ["json"]
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
    pipe_through [:browser, :redirect_if_authenticated]

    live_session :redirect_if_authenticated,
      on_mount: [
        {InvitomaticWeb.Auth, :redirect_if_authenticated}
      ] do
      live "/log_in", Live.Login, :new
    end

    post "/log_in", SessionController, :create
    get "/log_in/:token", SessionController, :create
  end

  scope "/", InvitomaticWeb do
    pipe_through [:browser, :require_authenticated]

    live_session :require_authenticated,
      on_mount: [
        {InvitomaticWeb.Auth, :ensure_authenticated}
      ] do
      live "/", Live.Invitation, :index
      live "/settings", Live.Settings, :edit
      live "/settings/confirm_email/:token", Live.Settings, :confirm_email
    end
  end

  scope "/manage", InvitomaticWeb do
    pipe_through [:browser, :require_authenticated, :require_admin]

    live_session :require_admin,
      on_mount: [
        {InvitomaticWeb.Auth, :ensure_authenticated_admin}
      ] do
      live "/", Live.InvitationManager, :index
      live "/content", Live.ContentManager, :index
      live "/content/new", Live.ContentManager, :new
      live "/content/:id/edit", Live.ContentManager, :edit
      live "/invites/new", Live.InvitationManager, :new
      live "/invites/:id", Live.InvitationManager, :show
      live "/invites/:id/edit", Live.InvitationManager, :edit
      live "/menu", Live.MenuManager, :index
      live "/menu/new", Live.MenuManager, :new
      live "/menu/:id", Live.MenuManager, :show
      live "/menu/:id/edit", Live.MenuManager, :edit
    end
  end

  scope "/", InvitomaticWeb do
    pipe_through [:browser]

    delete "/log_out", SessionController, :delete
  end
end
