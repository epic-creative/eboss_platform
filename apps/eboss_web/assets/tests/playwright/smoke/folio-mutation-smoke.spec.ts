import { expect, test } from "playwright/test";
import type { Page } from "playwright/test";

import { openPreparedDashboard, type PreparedState } from "../support/prepared-state";

type FolioMutationSurface = "projects" | "tasks";

const folioPath = (preparedState: PreparedState, surface: FolioMutationSurface): string => {
  return new URL(`${preparedState.dashboard_path}/apps/folio/${surface}`, preparedState.base_url).toString();
};

type MutationSurfaceContract = {
  pageRegionLabel: string;
  loadingStateTestId: string;
  errorStateTestId: string;
};

const folioMutationContracts: Record<FolioMutationSurface, MutationSurfaceContract> = {
  projects: {
    pageRegionLabel: "Folio projects page",
    loadingStateTestId: "projects-state-loading",
    errorStateTestId: "projects-state-error",
  },
  tasks: {
    pageRegionLabel: "Folio tasks page",
    loadingStateTestId: "tasks-state-loading",
    errorStateTestId: "tasks-state-error",
  },
};

function uniqueMutationLabel(prefix: string): string {
  return `${prefix}-${Date.now()}-${Math.floor(Math.random() * 10000)}`;
}

function mutationRowLocator(page: Page, rowPrefix: "project-row" | "task-row", title: string) {
  return page.locator(`[data-testid^="${rowPrefix}-"]`).filter({ hasText: title });
}

async function openFolioSurface(
  page: Page,
  preparedState: PreparedState,
  surface: FolioMutationSurface,
): Promise<void> {
  await page.goto(folioPath(preparedState, surface), { waitUntil: "domcontentloaded" });

  const contract = folioMutationContracts[surface];
  await expect(page.getByRole("region", { name: contract.pageRegionLabel })).toBeVisible();
  await expect(page.getByTestId(contract.loadingStateTestId)).toBeHidden({ timeout: 10000 });
  await expect(page.getByTestId(contract.errorStateTestId)).toBeHidden({ timeout: 10000 });
}

test.describe("Folio mutation confidence", () => {
  test("creates and transitions a folio project", async ({ browser }) => {
    const { context, page, preparedState } = await openPreparedDashboard(browser);
    const projectTitle = uniqueMutationLabel("ST-FOL-034 project");

    try {
      await openFolioSurface(page, preparedState, "projects");

      await page.getByTestId("projects-create-open").click();
      await expect(page.getByTestId("projects-create-form")).toBeVisible();

      await page.getByTestId("projects-create-title-input").fill(projectTitle);
      await page.getByTestId("projects-create-submit").click();

      const projectRow = mutationRowLocator(page, "project-row", projectTitle);
      await expect(projectRow).toBeVisible({ timeout: 15000 });

      await expect(page.getByTestId("project-inspector")).toBeVisible();

      await page.getByTestId("projects-transition-status-select").selectOption("completed");
      await page.getByTestId("projects-transition-submit").click();

      await expect(page.getByTestId("projects-transition-error")).toBeHidden({ timeout: 10000 });
      await expect(page.getByTestId("project-inspector")).toContainText("Completed");
    } finally {
      await context.close();
    }
  });

  test("creates, delegates, completes, and audits a folio task", async ({ browser }) => {
    const { context, page, preparedState } = await openPreparedDashboard(browser);
    const taskTitle = uniqueMutationLabel("ST-FOL-034 task");
    const delegationContact = "Playwright Delegate";

    try {
      await openFolioSurface(page, preparedState, "tasks");

      await page.getByTestId("tasks-create-open").click();
      await expect(page.getByTestId("tasks-create-form")).toBeVisible();

      await page.getByTestId("tasks-create-title-input").fill(taskTitle);
      await page.getByTestId("tasks-create-submit").click();

      const taskRow = mutationRowLocator(page, "task-row", taskTitle);
      await expect(taskRow).toBeVisible({ timeout: 15000 });

      await expect(page.getByTestId("task-inspector")).toBeVisible();

      await page.getByTestId("tasks-delegate-contact-input").fill(delegationContact);
      await page.getByTestId("tasks-delegate-summary-input").fill("Draft an execution plan for this task.");
      await page.getByTestId("tasks-delegate-quality-input").fill("Clear and complete");
      await page.getByTestId("tasks-delegate-submit").click();

      await expect(page.getByTestId("tasks-delegate-error")).toBeHidden({ timeout: 10000 });
      await expect(page.getByTestId("task-active-delegation")).toBeVisible();
      await expect(page.getByTestId("task-delegation-locked")).toBeVisible();
      await expect(page.getByTestId("task-inspector")).toContainText("Waiting For");
      await expect(page.getByTestId("task-inspector")).toContainText(delegationContact);
      await expect(taskRow).toContainText("Waiting on");

      await page.getByTestId("tasks-transition-status-select").selectOption("done");
      await page.getByTestId("tasks-transition-submit").click();

      await expect(page.getByTestId("tasks-transition-error")).toBeHidden({ timeout: 10000 });
      await expect(page.getByTestId("task-inspector")).toContainText("Done");
      await expect(page.getByTestId("task-active-delegation")).toHaveCount(0);
      await expect(page.getByTestId("task-delegation-locked")).toHaveCount(0);
      await expect(page.getByTestId("tasks-delegate-contact-input")).toBeVisible();
      await expect(taskRow).not.toContainText("Waiting on");

      await page.goto(new URL(`${preparedState.dashboard_path}/apps/folio/activity`, preparedState.base_url).toString(), {
        waitUntil: "domcontentloaded",
      });

      await expect(page.getByRole("region", { name: "Folio activity page" })).toBeVisible();
      await expect(page.getByTestId("activity-state-error")).toBeHidden({ timeout: 10000 });

      const firstActivityRow = page.locator('[data-testid^="activity-row-"]').first();
      await expect(firstActivityRow).toBeVisible();
      await firstActivityRow.click();
      await expect(page.getByTestId("activity-inspector")).toBeVisible();
    } finally {
      await context.close();
    }
  });
});
