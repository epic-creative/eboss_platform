defmodule EBossFolio.MixProject do
  use Mix.Project

  def project do
    [
      app: :eboss_folio,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.15",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      test_coverage: [summary: [threshold: 0]],
      aliases: aliases(),
      deps: deps()
    ]
  end

  def application do
    [
      mod: {EBossFolio.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:ash, "~> 3.23"},
      {:ash_postgres, "~> 2.8"},
      {:eboss_accounts, in_umbrella: true},
      {:eboss_data, in_umbrella: true},
      {:eboss_tenancy, in_umbrella: true},
      {:eboss_workspaces, in_umbrella: true},
      {:jason, "~> 1.2"}
    ]
  end

  defp aliases do
    [
      setup: ["deps.get"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"]
    ]
  end
end
