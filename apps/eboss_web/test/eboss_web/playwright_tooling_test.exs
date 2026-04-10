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

    assert get_in(package_json, ["scripts", "playwright:report"]) ==
             "npm exec --yes --package=playwright@1.59.1 playwright show-report test-results/playwright/report"

    assert File.exists?(Path.join(@playwright_dir, "smoke/bootstrap.spec.ts"))
    assert File.exists?(Path.join(@playwright_dir, "regression/.gitkeep"))
    assert File.exists?(Path.join(@playwright_dir, "fixtures/bootstrap.html"))

    assert config =~ ~s(testDir: "./tests/playwright")
    assert config =~ ~s(outputDir: "test-results/playwright/results")
    assert config =~ ~s(screenshot: "only-on-failure")
    assert config =~ ~s(trace: "retain-on-failure")
    assert config =~ ~s(channel: browserChannel)

    assert readme =~ "tests/playwright/smoke"
    assert readme =~ "tests/playwright/regression"
    assert readme =~ "tests/playwright/fixtures"
    assert readme =~ "test-results/playwright"
    assert readme =~ "npm run playwright:smoke"
    assert readme =~ "checked-in HTML fixture"
  end
end
