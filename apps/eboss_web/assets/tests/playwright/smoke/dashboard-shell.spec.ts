import { expect, test } from "playwright/test";
import type { Browser } from "playwright/test";

import { openPreparedDashboard } from "../support/prepared-state";

async function openDashboard(browser: Browser) {
  return openPreparedDashboard(browser);
}

test.describe("dashboard smoke", () => {
  test("authenticated state renders the stable workspace shell surfaces", async ({ browser }) => {
    const { context, page, preparedState } = await openDashboard(browser);

    await expect(page).toHaveURL(
      new URL(preparedState.dashboard_path, preparedState.base_url).toString(),
    );
    await expect(page.getByTestId("workspace-shell")).toBeVisible();
    await expect(page.getByRole("region", { name: "Workspace app shell" })).toBeVisible();
    await expect(page.getByTestId("workspace-sidebar")).toBeVisible();
    await expect(page.getByRole("navigation", { name: "Workspace navigation" })).toBeVisible();
    await expect(page.getByRole("region", { name: "Workspace apps" })).toBeVisible();
    await expect(page.getByTestId("workspace-page-dashboard")).toBeVisible();
    await expect(page.getByRole("heading", { name: "Overview" })).toBeVisible();
    await expect(
      page
        .getByTestId("workspace-page-dashboard")
        .getByText(`${preparedState.user.username}/${preparedState.workspace.slug}`, {
          exact: true,
        }),
    ).toBeVisible();
    await expect(page.getByTestId("workspace-avatar-menu-trigger")).toBeVisible();

    await context.close();
  });

  test("workspace shell links keep section navigation stable", async ({ browser }) => {
    const { context, page, preparedState } = await openDashboard(browser);

    await page.getByRole("link", { name: "Members" }).click();
    await expect(page).toHaveURL(
      new URL(`${preparedState.dashboard_path}/members`, preparedState.base_url).toString(),
    );
    await expect(page.getByRole("heading", { name: "Members" })).toBeVisible();

    await page.getByRole("link", { name: "Access" }).click();
    await expect(page).toHaveURL(
      new URL(`${preparedState.dashboard_path}/access`, preparedState.base_url).toString(),
    );
    await expect(page.getByRole("heading", { name: "Access Control" })).toBeVisible();

    await page.getByRole("link", { name: "Settings" }).click();
    await expect(page).toHaveURL(
      new URL(`${preparedState.dashboard_path}/settings`, preparedState.base_url).toString(),
    );
    await expect(page.getByRole("heading", { name: "Settings" })).toBeVisible();

    await context.close();
  });
});
