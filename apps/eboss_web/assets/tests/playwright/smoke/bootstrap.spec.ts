import path from "node:path";
import { pathToFileURL } from "node:url";

import { expect, test } from "playwright/test";

const bootstrapFixture = path.resolve(__dirname, "..", "fixtures", "bootstrap.html");

test("bootstrap smoke runs against the checked-in browser fixture", async ({ page }) => {
  await page.goto(pathToFileURL(bootstrapFixture).href);

  await expect(page.getByTestId("playwright-bootstrap-shell")).toBeVisible();
  await expect(page.getByRole("heading", { name: "Playwright bootstrap ready" })).toBeVisible();
  await expect(page.getByRole("listitem")).toHaveCount(3);
});
