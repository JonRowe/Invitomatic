import Config

# Only in tests, remove the complexity from the password hashing algorithm
config :bcrypt_elixir, :log_rounds, 1

config :invitomatic, :emails, sender: {"Invitomatic", "contact@example.com"}

config :invitomatic, Invitomatic.Repo,
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10,
  url: "postgres://#{System.get_env("DB_USER", "postgres")}@localhost/invitomatic_test"

# Configures the endpoint
config :invitomatic, InvitomaticWeb.Endpoint,
  secret_key_base: "IG1ZBxexgwIZtuxz9TCq30CVCpxngoDrTHkPICCFs2nXerQR6UvfHNb63AFyz+P4"

# In test we don't send emails.
config :invitomatic, Invitomatic.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters.
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
