import fs from "node:fs";
import path from "node:path";

import { expect, test } from "playwright/test";

const preparedStatePath = path.resolve(__dirname, "..", ".auth", "prepared-state.json");

type PreparedState = {
  base_url: string;
  storage_state: {
    public: string;
    authenticated: string;
  };
  user: {
    email: string;
    username: string;
  };
};

function loadPreparedState(): PreparedState {
  if (!fs.existsSync(preparedStatePath)) {
    throw new Error(
      "Prepared Playwright state is missing. Run `npm run playwright:setup` from apps/eboss_web/assets first.",
    );
  }

  return JSON.parse(fs.readFileSync(preparedStatePath, "utf8")) as PreparedState;
}

test("public setup state opens the anonymous home surface", async ({ browser }) => {
  const preparedState = loadPreparedState();
  const context = await browser.newContext({ storageState: preparedState.storage_state.public });
  const page = await context.newPage();

  await page.goto(`${preparedState.base_url}/`);

  await expect(page.getByTestId("home-hero")).toBeVisible();
  await expect(page.getByRole("link", { name: "Create your account" })).toBeVisible();

  await context.close();
});

test("authenticated setup state opens the dashboard shell", async ({ browser }) => {
  const preparedState = loadPreparedState();
  const context = await browser.newContext({
    storageState: preparedState.storage_state.authenticated,
  });
  const page = await context.newPage();

  await page.goto(`${preparedState.base_url}/dashboard`);

  await expect(page.getByText("Authenticated shell")).toBeVisible();
  await expect(page.getByText(`@${preparedState.user.username}`)).toBeVisible();

  await context.close();
});
