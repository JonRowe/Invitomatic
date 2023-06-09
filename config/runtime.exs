import Config

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in here, as it won't be applied.
# The block below contains prod specific runtime configuration.

# ## Using releases
#
# If you use `mix release`, you need to explicitly enable the server
# by passing the PHX_SERVER=true when you start it:
#
#     PHX_SERVER=true bin/invitomatic start
#
# Alternatively, you can use `mix phx.gen.release` to generate a `bin/server`
# script that automatically sets the env var above.
if config_env() != :test do
  sender_name =
    System.get_env("EMAIL_SENDER_NAME") ||
      raise("environment variable EMAIL_SENDER_NAME is missing, e.g. \"Invitomatic\"")

  sender_email =
    System.get_env("EMAIL_SENDER_EMAIL") ||
      raise("environment variable EMAIL_SENDER_EMAIL is missing, e.g. \"contact@example.com\"")

  config :invitomatic, :emails, sender: {sender_name, sender_email}
end

if config_env() == :prod do
  config :invitomatic, InvitomaticWeb.Endpoint, server: true, force_ssl: [hsts: true]

  database_url =
    System.get_env("DATABASE_URL") ||
      raise """
      environment variable DATABASE_URL is missing.
      For example: ecto://USER:PASS@HOST/DATABASE
      """

  socket_options =
    if System.get_env("DATABASE_IPV6", "FALSE") == "TRUE" do
      [:inet6]
    else
      [:inet]
    end

  config :invitomatic, Invitomatic.Repo,
    ssl: System.get_env("DATABASE_SSL", "TRUE") =~ ~r/true/i,
    ssl_opts: [verify: :verify_none],
    url: database_url,
    pool_size: String.to_integer(System.get_env("DATABASE_POOL_SIZE") || "10"),
    socket_options: socket_options

  # The secret key base is used to sign/encrypt cookies and other secrets.
  # A default value is used in config/dev.exs and config/test.exs but you
  # want to use a different value for prod and you most likely don't want
  # to check this value into version control, so we use an environment
  # variable instead.
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  host = System.get_env("PHX_HOST") || "example.com"
  port = String.to_integer(System.get_env("PORT") || "4000")

  config :invitomatic, InvitomaticWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [
      # Enable IPv6 and bind on all interfaces.
      # Set it to  {0, 0, 0, 0, 0, 0, 0, 1} for local network only access.
      # See the documentation on https://hexdocs.pm/plug_cowboy/Plug.Cowboy.html
      # for details about using IPv6 vs IPv4 and loopback vs public addresses.
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: port
    ],
    secret_key_base: secret_key_base

  config :invitomatic, Invitomatic.Mailer,
    adapter: Swoosh.Adapters.AmazonSES,
    region: "us-east-1",
    access_key: System.get_env("SES_ACCESS_KEY"),
    secret: System.get_env("SES_SECRET_KEY")

  config :opentelemetry,
    span_processor: :batch,
    traces_exporter: :otlp

  config :opentelemetry_exporter,
    otlp_protocol: :http_protobuf,
    otlp_headers: [{"x-honeycomb-team", System.get_env("OTLP_API_KEY")}],
    otlp_endpoint: System.get_env("OTLP_ENDPOINT")
end
