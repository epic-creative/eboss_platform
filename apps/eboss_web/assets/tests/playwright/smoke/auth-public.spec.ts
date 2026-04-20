import { expect, test } from "playwright/test";

import { openPreparedDashboard, openPreparedPage } from "../support/prepared-state";

test.describe("auth and public smoke", () => {
  test("anonymous public state renders the shared home shell", async ({ browser }) => {
    const { context, page } = await openPreparedPage(browser, "public", "/");

    await expect(page.getByRole("navigation", { name: "Public routes" })).toBeVisible();
    await expect(page.getByRole("contentinfo", { name: "Public shell footer" })).toBeVisible();
    await expect(page.getByTestId("public-shell-context-action")).toBeVisible();
    await expect(page.getByTestId("home-hero")).toBeVisible();
    await expect(
      page.getByRole("heading", {
        name: "Infrastructure for teams that ship with precision",
      }),
    ).toBeVisible();

    await context.close();
  });

  test("anonymous public state is redirected to sign-in for dashboard access", async ({
    browser,
  }) => {
    const { context, page } = await openPreparedPage(browser, "public", "/dashboard");

    await expect(page).toHaveURL(/\/sign-in(?:\?.*)?$/);
    await expect(page.getByTestId("auth-shell")).toBeVisible();
    await expect(page.getByRole("navigation", { name: "Authentication routes" })).toBeVisible();
    await expect(page.getByRole("form", { name: "Password sign-in" })).toBeVisible();
    await expect(page.getByRole("button", { name: "Magic link" })).toBeVisible();

    await context.close();
  });

  test("authenticated state lands on the dashboard shell", async ({ browser }) => {
    const { context, page, preparedState } = await openPreparedDashboard(browser);

    await expect(page).toHaveURL(
      new URL(preparedState.dashboard_path, preparedState.base_url).toString(),
    );
    await expect(page.getByTestId("workspace-shell")).toBeVisible();
    await expect(page.getByRole("region", { name: "Workspace app shell" })).toBeVisible();
    await expect(page.getByRole("navigation", { name: "Workspace navigation" })).toBeVisible();
    await expect(page.getByTestId("workspace-page-dashboard")).toBeVisible();
    await expect(
      page
        .getByTestId("workspace-page-dashboard")
        .getByText(`${preparedState.user.username}/${preparedState.workspace.slug}`, {
          exact: true,
        }),
    ).toBeVisible();

    await context.close();
  });
});
