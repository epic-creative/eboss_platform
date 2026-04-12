import { defineConfig } from "playwright/test";

const browserChannel = process.env.PLAYWRIGHT_BROWSER_CHANNEL ?? "chromium";
const baseUrl = process.env.PLAYWRIGHT_BASE_URL ?? "http://localhost:4002";

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
    baseURL: baseUrl,
    channel: browserChannel,
    headless: true,
    screenshot: "only-on-failure",
    trace: "retain-on-failure",
    video: "off",
    testIdAttribute: "data-testid",
  },
  webServer: {
    command: "npm run playwright:server:test",
    reuseExistingServer: !process.env.CI,
    stderr: "pipe",
    stdout: "pipe",
    timeout: 120_000,
    url: baseUrl,
  },
});
