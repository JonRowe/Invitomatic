import Config

# Configure your database
config :invitomatic, Invitomatic.Repo,
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10,
  url: "postgres://#{System.get_env("DB_USER", "postgres")}@localhost/invitomatic_dev"

cert_file_exists = fn file -> File.exists?(Path.join(Path.expand("priv/cert"), file)) end

maybe_https_config =
  if Enum.all?(["selfsigned_key.pem", "selfsigned.pem"], cert_file_exists) do
    [
      port: 4001,
      cipher_suite: :strong,
      keyfile: "priv/cert/selfsigned_key.pem",
      certfile: "priv/cert/selfsigned.pem"
    ]
  else
    IO.puts("Warning, no HTTPS config, run `mix phx.gen.cert` to test locally.")
  end

config :invitomatic, InvitomaticWeb.Endpoint,
  # Binding to loopback ipv4 address prevents access from other machines.
  # Change to `ip: {0, 0, 0, 0}` to allow access from other machines.
  http: [ip: {127, 0, 0, 1}, port: 4000],
  https: maybe_https_config,
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "TQrsAj2KocR8ixg2cnc1c/9D46Fy+RdN1HYJXlRqWN10HwsrkSKlALuM5Dt3U2kk",
  watchers: [
    esbuild: {Esbuild, :install_and_run, [:default, ~w(--sourcemap=inline --watch)]}
  ]

# Watch static and templates for browser reloading.
config :invitomatic, InvitomaticWeb.Endpoint,
  live_reload: [
    patterns: [
      ~r"priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"priv/gettext/.*(po)$",
      ~r"lib/invitomatic_web/(controllers|live|components)/.*(ex|heex)$"
    ]
  ]

# Enable dev routes for dashboard and mailbox
config :invitomatic, dev_routes: true

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20

# Initialize plugs at runtime for faster development compilation
config :phoenix, :plug_init_mode, :runtime

# Disable swoosh api client as it is only required for production adapters.
config :swoosh, :api_client, false
