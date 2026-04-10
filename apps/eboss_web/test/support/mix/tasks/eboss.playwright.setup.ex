defmodule Mix.Tasks.Eboss.Playwright.Setup do
  @moduledoc false
  use Mix.Task

  @shortdoc "Prepare deterministic browser-test users and session state for Playwright"

  @impl Mix.Task
  def run(_args) do
    Mix.Task.run("ecto.create", ["--quiet"])
    Mix.Task.run("ecto.migrate", ["--quiet"])
    Mix.Task.run("app.start")

    summary = EBossWeb.PlaywrightSetup.prepare!()

    Mix.shell().info("Prepared deterministic Playwright browser state.")
    Mix.shell().info("  Base URL: #{summary.base_url}")
    Mix.shell().info("  User: #{summary.credentials.email} / #{summary.credentials.username}")
    Mix.shell().info("  Public storage state: #{summary.public_storage_state_path}")
    Mix.shell().info("  Authenticated storage state: #{summary.authenticated_storage_state_path}")
    Mix.shell().info("  Metadata: #{summary.metadata_path}")
  end
end
