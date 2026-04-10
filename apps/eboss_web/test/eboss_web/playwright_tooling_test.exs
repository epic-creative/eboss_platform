defmodule EBossWeb.PlaywrightToolingTest do
  use ExUnit.Case, async: true

  @app_dir Path.expand("../..", __DIR__)
  @assets_dir Path.join(@app_dir, "assets")
  @playwright_dir Path.join(@assets_dir, "tests/playwright")

  test "playwright tooling defines smoke commands and artifact layout" do
    package_json =
      @assets_dir
      |> Path.join("package.json")
      |> File.read!()
      |> Jason.decode!()

    config = File.read!(Path.join(@assets_dir, "playwright.config.ts"))
    readme = File.read!(Path.join(@playwright_dir, "README.md"))

    assert get_in(package_json, ["scripts", "playwright:test"]) ==
             "npm exec --yes --package=playwright@1.59.1 playwright test"

    assert get_in(package_json, ["scripts", "playwright:smoke"]) ==
             "npm exec --yes --package=playwright@1.59.1 playwright test tests/playwright/smoke"

    assert get_in(package_json, ["scripts", "playwright:smoke:dashboard"]) ==
             "npm exec --yes --package=playwright@1.59.1 playwright test tests/playwright/smoke/dashboard-shell.spec.ts"

    assert get_in(package_json, ["scripts", "playwright:report"]) ==
             "npm exec --yes --package=playwright@1.59.1 playwright show-report test-results/playwright/report"

    assert get_in(package_json, ["scripts", "playwright:server:test"]) ==
             "cd .. && EBOSS_ENV=test PHX_HOST=localhost MIX_ENV=test mix phx.server"

    assert get_in(package_json, ["scripts", "playwright:setup"]) ==
             "cd .. && EBOSS_ENV=test PHX_HOST=localhost MIX_ENV=test mix eboss.playwright.setup"

    assert File.exists?(Path.join(@playwright_dir, "smoke/auth-public.spec.ts"))
    assert File.exists?(Path.join(@playwright_dir, "smoke/bootstrap.spec.ts"))
    assert File.exists?(Path.join(@playwright_dir, "smoke/dashboard-shell.spec.ts"))
    assert File.exists?(Path.join(@playwright_dir, "regression/.gitkeep"))
    assert File.exists?(Path.join(@playwright_dir, "fixtures/bootstrap.html"))
    assert File.exists?(Path.join(@playwright_dir, "setup/state-ready.spec.ts"))
    assert File.exists?(Path.join(@playwright_dir, "support/prepared-state.ts"))
    assert File.exists?(Path.join(@playwright_dir, ".auth/.gitignore"))

    assert get_in(package_json, ["scripts", "playwright:verify-setup"]) ==
             "npm exec --yes --package=playwright@1.59.1 playwright test tests/playwright/setup"

    assert config =~ ~s(testDir: "./tests/playwright")
    assert config =~ ~s(outputDir: "test-results/playwright/results")
    assert config =~ ~s(baseURL: baseUrl)
    assert config =~ ~s(screenshot: "only-on-failure")
    assert config =~ ~s(trace: "retain-on-failure")
    assert config =~ ~s(channel: browserChannel)
    assert config =~ ~s(command: "npm run playwright:server:test")
    assert config =~ ~s(url: baseUrl)

    assert readme =~ "tests/playwright/smoke"
    assert readme =~ "tests/playwright/setup"
    assert readme =~ "tests/playwright/regression"
    assert readme =~ "tests/playwright/fixtures"
    assert readme =~ "tests/playwright/.auth"
    assert readme =~ "test-results/playwright"
    assert readme =~ "npm run playwright:smoke"
    assert readme =~ "npm run playwright:smoke:dashboard"
    assert readme =~ "npm run playwright:setup"
    assert readme =~ "npm run playwright:verify-setup"
    assert readme =~ "checked-in HTML fixture"
    assert readme =~ "auth boundary"
    assert readme =~ "dashboard handoff"
    assert readme =~ "dashboard shell smoke"
  end
end
