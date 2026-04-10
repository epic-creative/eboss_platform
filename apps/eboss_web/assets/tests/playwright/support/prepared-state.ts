import fs from "node:fs";
import path from "node:path";

import type { Browser, BrowserContext, Page } from "playwright/test";

const preparedStatePath = path.resolve(__dirname, "..", ".auth", "prepared-state.json");

export type PreparedState = {
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

type StorageStateKey = keyof PreparedState["storage_state"];

export function loadPreparedState(): PreparedState {
  if (!fs.existsSync(preparedStatePath)) {
    throw new Error(
      "Prepared Playwright state is missing. Run `npm run playwright:setup` from apps/eboss_web/assets first.",
    );
  }

  return JSON.parse(fs.readFileSync(preparedStatePath, "utf8")) as PreparedState;
}

export async function openPreparedPage(
  browser: Browser,
  storageStateKey: StorageStateKey,
  targetPath: string,
): Promise<{ context: BrowserContext; page: Page; preparedState: PreparedState }> {
  const preparedState = loadPreparedState();
  const context = await browser.newContext({
    storageState: preparedState.storage_state[storageStateKey],
  });
  const page = await context.newPage();

  await page.goto(new URL(targetPath, preparedState.base_url).toString(), {
    waitUntil: "domcontentloaded",
  });

  return { context, page, preparedState };
}
