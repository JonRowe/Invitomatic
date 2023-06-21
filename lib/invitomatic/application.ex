defmodule Invitomatic.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl Application
  def start(_type, _args) do
    :opentelemetry_cowboy.setup()
    OpentelemetryPhoenix.setup(adapter: :cowboy2)
    OpentelemetryEcto.setup([:invitomatic, Invitomatic.Repo])

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    Supervisor.start_link(
      [
        # Start Finch
        {Finch, name: Invitomatic.Finch},
        # Start the PubSub system
        {Phoenix.PubSub, name: Invitomatic.PubSub},
        # Start the Ecto repository
        Invitomatic.Repo,
        # Start the Telemetry supervisor
        InvitomaticWeb.Telemetry,
        # Start the Endpoint (http/https)
        InvitomaticWeb.Endpoint
      ],
      strategy: :one_for_one,
      name: Invitomatic.Supervisor
    )
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    InvitomaticWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
