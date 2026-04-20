import { expect, test } from "playwright/test";
import { openPreparedDashboard, openPreparedPage } from "../support/prepared-state";

test("public setup state opens the anonymous home surface", async ({ browser }) => {
  const { context, page } = await openPreparedPage(browser, "public", "/");

  await expect(page.getByTestId("home-hero")).toBeVisible();
  await expect(page.getByRole("navigation", { name: "Public routes" })).toBeVisible();

  await context.close();
});

test("authenticated setup state opens the dashboard shell", async ({ browser }) => {
  const { context, page, preparedState } = await openPreparedDashboard(browser);

  await expect(page).toHaveURL(new URL(preparedState.dashboard_path, preparedState.base_url).toString());
  await expect(page.getByTestId("workspace-shell")).toBeVisible();
  await expect(page.getByRole("region", { name: "Workspace app shell" })).toBeVisible();
  await expect(page.getByTestId("workspace-page-dashboard")).toBeVisible();
  await expect(page.getByTestId("workspace-avatar-menu-trigger")).toBeVisible();

  await context.close();
});
