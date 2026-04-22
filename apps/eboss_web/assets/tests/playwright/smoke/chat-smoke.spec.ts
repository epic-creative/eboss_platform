import { expect, test } from "playwright/test";
import type { Page } from "playwright/test";

import {
  loadPreparedState,
  openPreparedDashboard,
  openPreparedPage,
  type PreparedState,
} from "../support/prepared-state";

const chatBaseUrl = (preparedState: PreparedState): string =>
  new URL(`${preparedState.dashboard_path}/apps/chat`, preparedState.base_url).toString();

const chatNewUrl = (preparedState: PreparedState): string =>
  new URL(`${preparedState.dashboard_path}/apps/chat/new`, preparedState.base_url).toString();

const sessionRow = (page: Page, title: string) =>
  page.locator('[data-testid^="chat-session-"]').filter({ hasText: title }).first();

test.describe("Chat smoke", () => {
  test("public users are redirected away from workspace chat routes", async ({ browser }) => {
    const preparedState = loadPreparedState();
    const { context, page } = await openPreparedPage(
      browser,
      "public",
      `${preparedState.dashboard_path}/apps/chat/new`,
    );

    await expect(page).toHaveURL(/\/sign-in(?:\?.*)?$/);
    await expect(page.getByTestId("auth-shell")).toBeVisible();

    await context.close();
  });

  test("authenticated users can create multiple chat sessions and continue an existing one", async ({
    browser,
  }) => {
    const { context, page, preparedState } = await openPreparedDashboard(browser);
    const firstPrompt = `Smoke first prompt ${Date.now()}`;
    const secondPrompt = `Smoke second prompt ${Date.now() + 1}`;
    const followUpPrompt = `Smoke follow up ${Date.now() + 2}`;

    try {
      await page.getByRole("button", { name: "Apps" }).click();
      await page.getByRole("link", { name: "Chat" }).click();

      await expect(page).toHaveURL(chatBaseUrl(preparedState));
      await expect(page.getByRole("region", { name: "Workspace chat page" })).toBeVisible();
      await expect(page.getByRole("region", { name: "Chat sessions" })).toBeVisible();
      await expect(page.getByRole("region", { name: "Chat transcript" })).toBeVisible();
      await page.getByRole("combobox", { name: "Model" }).selectOption("openai_gpt_4o_mini");

      await page.getByTestId("chat-composer").locator("textarea").fill(firstPrompt);
      await page.getByTestId("chat-send-button").click();

      await expect(page.locator('[data-testid^="chat-message-"]').filter({ hasText: firstPrompt }).first()).toBeVisible();
      await expect(page.getByText(`OpenAI mock reply: ${firstPrompt}`)).toBeVisible({ timeout: 15000 });

      const firstSessionUrl = page.url();
      await expect(firstSessionUrl).toContain("/apps/chat/sessions/");
      await expect(sessionRow(page, firstPrompt)).toBeVisible();

      await page.getByRole("button", { name: "New chat" }).click();
      await expect(page).toHaveURL(chatNewUrl(preparedState));

      await page.getByTestId("chat-composer").locator("textarea").fill(secondPrompt);
      await page.getByTestId("chat-send-button").click();

      await expect(page.getByText(`OpenAI mock reply: ${secondPrompt}`)).toBeVisible({ timeout: 15000 });
      await expect(sessionRow(page, secondPrompt)).toBeVisible();
      await expect(sessionRow(page, firstPrompt)).toBeVisible();

      await sessionRow(page, firstPrompt).click();
      await expect(page).toHaveURL(firstSessionUrl);
      await expect(page.getByText(`OpenAI mock reply: ${firstPrompt}`)).toBeVisible();

      await page.getByTestId("chat-composer").locator("textarea").fill(followUpPrompt);
      await page.getByTestId("chat-send-button").click();

      await expect(page.getByText(`OpenAI mock reply: ${followUpPrompt}`)).toBeVisible({ timeout: 15000 });

      await page.reload({ waitUntil: "domcontentloaded" });
      await expect(page).toHaveURL(firstSessionUrl);
      await expect(page.getByText(`OpenAI mock reply: ${followUpPrompt}`)).toBeVisible({ timeout: 15000 });
    } finally {
      await context.close();
    }
  });
});
