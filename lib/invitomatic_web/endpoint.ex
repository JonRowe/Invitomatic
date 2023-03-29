defmodule InvitomaticWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :invitomatic

  # The session will be stored in the cookie, signed and encrypted.
  #
  # Read from the compile env to avoid storing secrets in source as this
  # is intended to be public.
  @session_options [
    store: :cookie,
    key: "_invitomatic_key",
    encryption_salt: Application.compile_env(:invitomatic, [__MODULE__, :session, :encryption_salt]),
    signing_salt: Application.compile_env(:invitomatic, [__MODULE__, :session, :signing_salt]),
    same_site: "Lax"
  ]

  socket "/live", Phoenix.LiveView.Socket, websocket: [connect_info: [session: @session_options]]

  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phx.digest
  # when deploying your static files in production.
  plug Plug.Static,
    at: "/",
    from: :invitomatic,
    gzip: false,
    only: InvitomaticWeb.static_paths()

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
    plug Phoenix.LiveReloader
    plug Phoenix.CodeReloader
    plug Phoenix.Ecto.CheckRepoStatus, otp_app: :invitomatic
  end

  plug Phoenix.LiveDashboard.RequestLogger,
    param_key: "request_logger",
    cookie_key: "request_logger"

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head
  plug Plug.Session, @session_options
  plug InvitomaticWeb.Router
end
