import { expect, test } from "playwright/test";
import type { Browser } from "playwright/test";

import { openPreparedPage } from "../support/prepared-state";

async function openDashboard(browser: Browser) {
  return openPreparedPage(browser, "authenticated", "/dashboard");
}

test.describe("dashboard smoke", () => {
  test("authenticated state renders the stable dashboard shell surfaces", async ({ browser }) => {
    const { context, page, preparedState } = await openDashboard(browser);

    await expect(page).toHaveURL(/\/dashboard$/);
    await expect(page.getByTestId("dashboard-shell")).toBeVisible();
    await expect(page.getByRole("region", { name: "Dashboard shell" })).toBeVisible();
    await expect(page.getByRole("complementary", { name: "Dashboard sidebar" })).toBeVisible();
    await expect(page.getByRole("navigation", { name: "Dashboard navigation" })).toBeVisible();
    await expect(page.getByRole("region", { name: "Dashboard workspace" })).toBeVisible();
    await expect(page.getByRole("region", { name: "Dashboard command surface" })).toBeVisible();
    await expect(page.getByRole("navigation", { name: "Dashboard quick actions" })).toBeVisible();
    await expect(page.getByRole("region", { name: "Dashboard launch surface" })).toBeVisible();
    await expect(page.getByRole("region", { name: "Dashboard structure surface" })).toBeVisible();
    await expect(page.getByRole("region", { name: "Dashboard state surface" })).toBeVisible();
    await expect(page.getByRole("region", { name: "Dashboard empty state" })).toBeVisible();
    await expect(page.getByRole("region", { name: "Dashboard loading state" })).toBeVisible();
    await expect(page.getByRole("region", { name: "Dashboard error state" })).toBeVisible();
    await expect(
      page.getByRole("heading", {
        name: new RegExp(`Welcome back, @${preparedState.user.username}\\.`, "i"),
      }),
    ).toBeVisible();
    await expect(page.getByRole("button", { name: "Sign out" })).toBeVisible();

    await context.close();
  });

  test("dashboard shell links keep section navigation stable", async ({ browser }) => {
    const { context, page } = await openDashboard(browser);

    const quickActions = page.getByRole("navigation", { name: "Dashboard quick actions" });
    const commandSurface = page.getByRole("region", { name: "Dashboard command surface" });

    await quickActions.getByRole("link", { name: /Audit fallback states/i }).click();
    await expect(page).toHaveURL(/\/dashboard#dashboard-states$/);

    await commandSurface.getByRole("link", { name: /Primary lane/i }).click();
    await expect(page).toHaveURL(/\/dashboard#dashboard-launchpad$/);

    await commandSurface.getByRole("link", { name: /State audit/i }).click();
    await expect(page).toHaveURL(/\/dashboard#dashboard-states$/);

    await expect(page.getByRole("region", { name: "Dashboard state surface" })).toBeVisible();
    await expect(page.getByRole("region", { name: "Dashboard empty state" })).toBeVisible();
    await expect(page.getByRole("region", { name: "Dashboard loading state" })).toBeVisible();
    await expect(page.getByRole("region", { name: "Dashboard error state" })).toBeVisible();

    await context.close();
  });

  test("shell sign out exits back to the public route family", async ({ browser }) => {
    const { context, page } = await openDashboard(browser);

    await page.getByRole("button", { name: "Sign out" }).click();

    await expect(page).toHaveURL(/\/$/);
    await expect(page.getByRole("navigation", { name: "Public routes" })).toBeVisible();
    await expect(page.getByRole("contentinfo", { name: "Public shell footer" })).toBeVisible();
    await expect(page.getByTestId("home-hero")).toBeVisible();

    await context.close();
  });
});
