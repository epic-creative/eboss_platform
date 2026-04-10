import { expect, test, type Locator } from "playwright/test";

import { openPreparedPage } from "../support/prepared-state";

async function typeIntoField(field: Locator, value: string) {
  await field.click();
  await field.pressSequentially(value);
  await expect(field).toHaveValue(value);
}

test.describe("sign-in field retention regression", () => {
  test("password credentials survive magic-link typing", async ({ browser }) => {
    const { context, page } = await openPreparedPage(browser, "public", "/sign-in");

    try {
      await expect(page.getByTestId("auth-shell")).toBeVisible();

      const passwordForm = page.getByRole("form", { name: "Password sign-in" });
      const magicLinkForm = page.getByRole("form", { name: "Magic-link request" });

      const passwordEmail = passwordForm.getByLabel("Email");
      const passwordField = passwordForm.getByLabel("Password");
      const magicLinkEmail = magicLinkForm.getByLabel("Email");

      await typeIntoField(passwordEmail, "retained-password@example.com");
      await typeIntoField(passwordField, "supersecret123");
      await typeIntoField(magicLinkEmail, "retained-magic@example.com");

      await expect(passwordEmail).toHaveValue("retained-password@example.com");
      await expect(passwordField).toHaveValue("supersecret123");
      await expect(magicLinkEmail).toHaveValue("retained-magic@example.com");
    } finally {
      await context.close();
    }
  });

  test("magic-link email survives password typing", async ({ browser }) => {
    const { context, page } = await openPreparedPage(browser, "public", "/sign-in");

    try {
      await expect(page.getByTestId("auth-shell")).toBeVisible();

      const passwordForm = page.getByRole("form", { name: "Password sign-in" });
      const magicLinkForm = page.getByRole("form", { name: "Magic-link request" });

      const passwordEmail = passwordForm.getByLabel("Email");
      const passwordField = passwordForm.getByLabel("Password");
      const magicLinkEmail = magicLinkForm.getByLabel("Email");

      await typeIntoField(magicLinkEmail, "retained-magic@example.com");
      await typeIntoField(passwordEmail, "retained-password@example.com");
      await typeIntoField(passwordField, "supersecret123");

      await expect(magicLinkEmail).toHaveValue("retained-magic@example.com");
      await expect(passwordEmail).toHaveValue("retained-password@example.com");
      await expect(passwordField).toHaveValue("supersecret123");
    } finally {
      await context.close();
    }
  });
});
