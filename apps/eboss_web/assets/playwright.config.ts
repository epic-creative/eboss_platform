import { defineConfig } from "playwright/test";

const browserChannel = process.env.PLAYWRIGHT_BROWSER_CHANNEL ?? "chrome";

export default defineConfig({
  testDir: "./tests/playwright",
  fullyParallel: false,
  forbidOnly: Boolean(process.env.CI),
  retries: process.env.CI ? 2 : 0,
  workers: 1,
  reporter: [
    ["list"],
    ["html", { open: "never", outputFolder: "test-results/playwright/report" }],
  ],
  outputDir: "test-results/playwright/results",
  use: {
    channel: browserChannel,
    headless: true,
    screenshot: "only-on-failure",
    trace: "retain-on-failure",
    video: "off",
    testIdAttribute: "data-testid",
  },
});
