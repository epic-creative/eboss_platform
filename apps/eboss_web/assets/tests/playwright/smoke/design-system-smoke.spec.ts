import { expect, test } from "playwright/test";

import { openPreparedPage } from "../support/prepared-state";

test.describe("design system smoke", () => {
  test("canonical design-system page renders runtime pattern sections", async ({ browser }) => {
    const { context, page } = await openPreparedPage(browser, "public", "/dev/design-system");

    await expect(page.getByRole("heading", { name: "EBoss design system" })).toBeVisible();
    await expect(page.locator("#contract")).toBeVisible();
    await expect(page.locator("#vue-contract")).toBeVisible();
    await expect(page.locator("#livevue-runtime")).toBeVisible();
    await expect(page.locator("#forms")).toBeVisible();
    await expect(page.getByText("Use Link and useLiveNavigation() instead of manual history state.")).toBeVisible();
    await expect(page.getByText("Keep REST and SSE as external contracts, not default browser UI plumbing.")).toBeVisible();

    await context.close();
  });
});
