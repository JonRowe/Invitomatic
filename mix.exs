defmodule Invitomatic.MixProject do
  use Mix.Project

  def project do
    [
      app: :invitomatic,
      version: "0.1.0",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      elixirc_options: [warnings_as_errors: true],
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      releases: releases()
    ]
  end

  def application do
    [
      mod: {Invitomatic.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:bcrypt_elixir, "~> 3.0"},
      {:ecto_sql, "~> 3.6"},
      {:earmark_parser, "~> 1.4"},
      {:esbuild, "~> 0.7", runtime: Mix.env() == :dev},
      {:finch, "~> 0.13"},
      {:floki, ">= 0.30.0", only: :test},
      {:gen_smtp, "~> 1.3.0"},
      {:jason, "~> 1.2"},
      {:opentelemetry, "~> 1.3"},
      {:opentelemetry_api, "~> 1.2"},
      {:opentelemetry_ecto, "~> 1.1"},
      {:opentelemetry_exporter, "~> 1.4"},
      {:opentelemetry_phoenix, "~> 2.0"},
      {:opentelemetry_cowboy, "~> 1.0"},
      {:plug_cowboy, "~> 2.5"},
      {:phoenix, "~> 1.7.2"},
      {:phoenix_ecto, "~> 4.4"},
      {:phoenix_html, "~> 4.2"},
      {:phoenix_live_dashboard, "~> 0.8.0"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 1.0.4"},
      {:postgrex, ">= 0.0.0"},
      {:swoosh, "~> 1.3"},
      {:telemetry_metrics, "~> 1.1"},
      {:telemetry_poller, "~> 1.0"}
    ]
  end

  defp aliases do
    [
      setup: ["deps.get", "ecto.setup", "assets.setup", "assets.build"],
      "ecto.setup": ["ecto.create", "ecto.load", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: [
        "ecto.create --quiet",
        "ecto.load --quiet --skip-if-loaded",
        "ecto.migrate --quiet",
        "test --warnings-as-errors"
      ],
      "assets.setup": ["esbuild.install --if-missing"],
      "assets.build": ["esbuild default"],
      "assets.deploy": ["esbuild default --minify", "phx.digest"]
    ]
  end

  defp releases do
    [
      invitomatic: [
        applications: [
          invitomatic: :permanent,
          opentelemetry_exporter: :permanent,
          opentelemetry: :temporary
        ],
        include_executables_for: [:unix]
      ]
    ]
  end
end
