defmodule EBossAccounts.MixProject do
  use Mix.Project

  def project do
    [
      app: :eboss_accounts,
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
      mod: {EBossAccounts.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:ash, "~> 3.23"},
      {:ash_authentication, "~> 4.3"},
      {:ash_postgres, "~> 2.8"},
      {:bcrypt_elixir, "~> 3.0"},
      {:eboss_data, in_umbrella: true},
      {:jason, "~> 1.2"},
      {:req, "~> 0.5"},
      {:sourceror, "~> 1.8", only: [:dev, :test]},
      {:swoosh, "~> 1.16"}
    ]
  end

  defp aliases do
    [
      setup: ["deps.get"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"]
    ]
  end
end
