defmodule EBossWeb.FrontendGateTest do
  use ExUnit.Case, async: true

  @root_dir Path.expand("../../../..", __DIR__)
  @workflow_path Path.join(@root_dir, ".github/workflows/frontend-confidence.yml")
  @readme_path Path.join(@root_dir, "README.md")
  @playwright_readme_path Path.join(@root_dir, "apps/eboss_web/assets/tests/playwright/README.md")
  @vue_readme_path Path.join(@root_dir, "apps/eboss_web/assets/tests/vue/README.md")
  @mix_exs_path Path.join(@root_dir, "mix.exs")

  test "frontend gate automation stays pinned to the lean Vitest and Playwright lanes" do
    mix_exs = File.read!(@mix_exs_path)
    workflow = File.read!(@workflow_path)
    readme = File.read!(@readme_path)
    playwright_readme = File.read!(@playwright_readme_path)
    vue_readme = File.read!(@vue_readme_path)

    assert mix_exs =~ ~s("frontend.gate")
    assert mix_exs =~ ~s(run_frontend_gate_vitest)
    assert mix_exs =~ ~s(run_frontend_gate_playwright_setup)
    assert mix_exs =~ ~s(run_frontend_gate_playwright_smoke)
    assert mix_exs =~ ~s|run_frontend_npm(["run", "vue:test"])|
    assert mix_exs =~ ~s|run_frontend_npm(["run", "playwright:setup"])|
    assert mix_exs =~ ~s|run_frontend_npm(["run", "playwright:smoke"])|
    assert mix_exs =~ ~s|Path.expand("apps/eboss_web/assets", __DIR__)|

    assert workflow =~ "name: Frontend Confidence"
    assert workflow =~ "pull_request:"
    assert workflow =~ "push:"
    assert workflow =~ "PLAYWRIGHT_BROWSER_CHANNEL: chromium"
    assert workflow =~ "npm ci"

    assert workflow =~ "npx playwright install --with-deps chromium"

    assert workflow =~ "mix frontend.gate"

    assert readme =~ "## Automated Frontend Gate"
    assert readme =~ "mix frontend.gate"
    assert readme =~ "`Frontend Confidence` workflow"
    assert readme =~ "`npm run vue:test`"
    assert readme =~ "`npm run playwright:setup`"
    assert readme =~ "`npm run playwright:smoke`"
    assert readme =~ "pushes and pull requests"

    assert playwright_readme =~ "mix frontend.gate"
    assert playwright_readme =~ "Frontend Confidence"
    assert playwright_readme =~ "pushes and pull requests"
    assert playwright_readme =~ "`npm run playwright:smoke`"

    assert vue_readme =~ "mix frontend.gate"
    assert vue_readme =~ "Frontend Confidence"
    assert vue_readme =~ "pushes and pull requests"
    assert vue_readme =~ "`npm run vue:test`"
  end
end
