import { expect, test } from "playwright/test";

import { openPreparedDashboard } from "../support/prepared-state";

test.describe("workspace sign out", () => {
  test("authenticated shell sign out exits back to the public route family", async ({
    browser,
  }) => {
    const { context, page } = await openPreparedDashboard(browser);

    await expect(page.getByTestId("workspace-avatar-menu-trigger")).toBeVisible();
    await page.getByTestId("workspace-avatar-menu-trigger").click();
    await page.getByTestId("workspace-sign-out").click();

    await expect(page).toHaveURL(/\/$/);
    await expect(page.getByRole("navigation", { name: "Public routes" })).toBeVisible();
    await expect(page.getByRole("contentinfo", { name: "Public shell footer" })).toBeVisible();
    await expect(page.getByTestId("home-hero")).toBeVisible();

    await context.close();
  });
});
