import { expect, test } from "playwright/test";

import { openPreparedDashboard, openPreparedPage } from "../support/prepared-state";

test.describe("Notifications smoke", () => {
  test("public users are redirected away from the notification center", async ({ browser }) => {
    const { context, page } = await openPreparedPage(browser, "public", "/notifications");

    await expect(page).toHaveURL(/\/sign-in(?:\?.*)?$/);
    await expect(page.getByTestId("auth-shell")).toBeVisible();

    await context.close();
  });

  test("authenticated users can inspect and clear in-app notifications", async ({ browser }) => {
    const { context, page, preparedState } = await openPreparedDashboard(browser);

    try {
      await page.getByLabel("Notifications").click();
      await expect(page.getByText("Playwright notification").first()).toBeVisible();
      await expect(page.getByRole("link", { name: "Open notification center" })).toBeVisible();

      await page.getByRole("link", { name: "Open notification center" }).click();
      await expect(page).toHaveURL(new URL("/notifications", preparedState.base_url).toString());
      await expect(page.getByText("Signals across every workspace")).toBeVisible();
      await expect(page.getByText("Playwright notification").first()).toBeVisible();
      await expect(page.getByText("Configured for future delivery").first()).toBeVisible();

      await page.getByRole("button", { name: "Mark all read" }).click();
      await expect(page.getByText("0 unread notifications")).toBeVisible();
    } finally {
      await context.close();
    }
  });
});
