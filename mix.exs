defmodule EBoss.Umbrella.MixProject do
  use Mix.Project

  def project do
    [
      apps_path: "apps",
      version: "0.1.0",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      listeners: [Phoenix.CodeReloader],
      usage_rules: usage_rules()
    ]
  end

  def cli do
    [
      preferred_envs: [precommit: :test]
    ]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options.
  #
  # Dependencies listed here are available only for this project
  # and cannot be accessed from applications inside the apps/ folder.
  defp usage_rules do
    [
      file: "AGENTS.md",
      usage_rules: [
        :ash,
        "ash:all",
        ~r/^ash_/,
        "phoenix:all"
      ]
    ]
  end

  defp deps do
    [
      {:igniter, "~> 0.6", only: [:dev, :test]},
      {:usage_rules, "~> 1.1", only: :dev},
      {:dotenvy, "~> 1.1"},
      {:sourceror, "~> 1.8", only: [:dev, :test]},
      # Required to run "mix format" on ~H/.heex files from the umbrella root
      {:phoenix_live_view, ">= 0.0.0"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  #
  # Aliases listed here are available only for this project
  # and cannot be accessed from applications inside the apps/ folder.
  defp aliases do
    [
      # run `mix setup` in all child apps
      setup: ["cmd mix setup"],
      seed: ["run apps/eboss_data/priv/repo/seeds.exs"],
      "frontend.gate": [
        &run_frontend_gate_vitest/1,
        &run_frontend_gate_playwright_setup/1,
        &run_frontend_gate_playwright_smoke/1
      ],
      precommit: [
        "cmd env MIX_ENV=test mix compile --warnings-as-errors",
        &unlock_unused_dev/1,
        &format_dev/1,
        "cmd env MIX_ENV=test mix test"
      ]
    ]
  end

  defp unlock_unused_dev(_args) do
    run_root_mix("dev", ["deps.unlock", "--unused"])
  end

  defp format_dev(_args) do
    run_root_mix("dev", ["format"])
  end

  defp run_frontend_gate_vitest(_args) do
    run_frontend_npm(["run", "vue:test"])
  end

  defp run_frontend_gate_playwright_setup(_args) do
    run_frontend_npm(["run", "playwright:setup"])
  end

  defp run_frontend_gate_playwright_smoke(_args) do
    run_frontend_npm(["run", "playwright:smoke"])
  end

  defp run_root_mix(env, args) do
    mix = System.find_executable("mix") || Mix.raise("Unable to locate the mix executable")

    {_, status} =
      System.cmd(mix, args,
        env: [{"MIX_ENV", env}],
        into: IO.stream(:stdio, :line),
        stderr_to_stdout: true
      )

    if status != 0 do
      Mix.raise("Command failed: MIX_ENV=#{env} mix #{Enum.join(args, " ")}")
    end
  end

  defp run_frontend_npm(args) do
    npm = System.find_executable("npm") || Mix.raise("Unable to locate the npm executable")

    {_, status} =
      System.cmd(npm, args,
        cd: frontend_assets_dir(),
        into: IO.stream(:stdio, :line),
        stderr_to_stdout: true
      )

    if status != 0 do
      Mix.raise("Command failed: (cd apps/eboss_web/assets && npm #{Enum.join(args, " ")})")
    end
  end

  defp frontend_assets_dir do
    Path.expand("apps/eboss_web/assets", __DIR__)
  end
end
