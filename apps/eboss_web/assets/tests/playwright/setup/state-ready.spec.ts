import { expect, test } from "playwright/test";
import { openPreparedPage } from "../support/prepared-state";

test("public setup state opens the anonymous home surface", async ({ browser }) => {
  const { context, page } = await openPreparedPage(browser, "public", "/");

  await expect(page.getByTestId("home-hero")).toBeVisible();
  await expect(page.getByRole("navigation", { name: "Public routes" })).toBeVisible();

  await context.close();
});

test("authenticated setup state opens the dashboard shell", async ({ browser }) => {
  const { context, page, preparedState } = await openPreparedPage(
    browser,
    "authenticated",
    "/dashboard",
  );

  await expect(
    page.getByRole("heading", {
      name: new RegExp(`Welcome back, @${preparedState.user.username}\\.`, "i"),
    }),
  ).toBeVisible();
  await expect(page.getByRole("button", { name: "Sign out" })).toBeVisible();

  await context.close();
});
