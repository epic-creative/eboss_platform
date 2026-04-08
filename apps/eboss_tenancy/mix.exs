defmodule EBossTenancy.MixProject do
  use Mix.Project

  def project do
    [
      app: :eboss_tenancy,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.15",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  def application do
    [
      mod: {EBossTenancy.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:ash, "~> 3.23"},
      {:ash_archival, "~> 2.0"},
      {:ash_cloak, "~> 0.2.0"},
      {:ash_postgres, "~> 2.8"},
      {:ash_slug, "~> 0.2.1"},
      {:eboss_accounts, in_umbrella: true},
      {:eboss_data, in_umbrella: true},
      {:jason, "~> 1.2"},
      {:picosat_elixir, "~> 0.2"},
      {:phoenix_pubsub, "~> 2.1"}
    ]
  end

  defp aliases do
    [
      setup: ["deps.get"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"]
    ]
  end
end
