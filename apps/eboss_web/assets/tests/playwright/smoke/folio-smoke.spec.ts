import { expect, test } from "playwright/test"
import type { Browser, Page } from "playwright/test"

import { openPreparedDashboard, loadPreparedState, openPreparedPage, type PreparedState } from "../support/prepared-state"

const folioPath = (preparedState: PreparedState, surface: "tasks" | "projects" | "activity" | "") => {
  return new URL(`${preparedState.dashboard_path}/apps/folio${surface ? `/${surface}` : ""}`, preparedState.base_url)
    .toString()
}

type FolioReadContract = {
  pageRegionLabel: string
  listRegionLabel: string
  loadingStateTestId: string
  errorStateTestId: string
  emptyStateTestId: string
  rowDataTestIdPrefix: string
}

const folioReadSurfaces: Record<"tasks" | "projects" | "activity", FolioReadContract> = {
  tasks: {
    pageRegionLabel: "Folio tasks page",
    listRegionLabel: "Folio tasks list",
    loadingStateTestId: "tasks-state-loading",
    errorStateTestId: "tasks-state-error",
    emptyStateTestId: "tasks-state-empty",
    rowDataTestIdPrefix: "task-row-",
  },
  projects: {
    pageRegionLabel: "Folio projects page",
    listRegionLabel: "Folio projects list",
    loadingStateTestId: "projects-state-loading",
    errorStateTestId: "projects-state-error",
    emptyStateTestId: "projects-state-empty",
    rowDataTestIdPrefix: "project-row-",
  },
  activity: {
    pageRegionLabel: "Folio activity page",
    listRegionLabel: "Folio activity feed",
    loadingStateTestId: "activity-state-loading",
    errorStateTestId: "activity-state-error",
    emptyStateTestId: "activity-state-empty",
    rowDataTestIdPrefix: "activity-row-",
  },
}

async function expectFolioReadSurface(page: Page, contract: FolioReadContract): Promise<void> {
  await expect(page.getByRole("region", { name: contract.pageRegionLabel })).toBeVisible()
  await expect(page.getByRole("region", { name: contract.listRegionLabel })).toBeVisible()
  await expect(page.getByTestId(contract.errorStateTestId)).toBeHidden()
  await expect(page.getByTestId(contract.loadingStateTestId)).toBeHidden({ timeout: 10000 })

  await expect(
    page.locator(`[data-testid="${contract.emptyStateTestId}"], [data-testid^="${contract.rowDataTestIdPrefix}"]`).first(),
  ).toBeVisible()
}

test.describe("Folio smoke", () => {
  test("app-aware workspace shell links enter Folio from workspace navigation", async ({ browser }) => {
    const { context, page, preparedState } = await openPreparedDashboard(browser)

    const dashboardUrl = new URL(preparedState.dashboard_path, preparedState.base_url).toString()
    const folioBaseUrl = folioPath(preparedState, "")

    await expect(page).toHaveURL(dashboardUrl)
    await expect(page.getByRole("region", { name: "Workspace app shell" })).toBeVisible()
    await expect(page.getByRole("navigation", { name: "Workspace navigation" })).toBeVisible()
    await expect(page.getByRole("region", { name: "Workspace apps" })).toBeVisible()
    await expect(page.getByRole("region", { name: "Workspace sidebar" })).toBeVisible()
    await expect(page.getByTestId("workspace-current-app")).not.toBeVisible()

    await page.getByRole("link", { name: "Members" }).click()
    await expect(page).toHaveURL(new URL(`${preparedState.dashboard_path}/members`, preparedState.base_url).toString())

    await page.getByRole("link", { name: "Overview" }).click()
    await expect(page).toHaveURL(dashboardUrl)

    await page.getByRole("button", { name: "Apps" }).click()
    await page.getByRole("link", { name: "Folio" }).click()

    await expect(page).toHaveURL(folioBaseUrl)
    await expect(page.getByRole("status", { name: "Current workspace app" })).toBeVisible()
    await expect(page.getByTestId("workspace-current-app")).toContainText(/Folio/i)

    await context.close()
  })

  test("Folio tasks, projects, and activity read surfaces render after app enter", async ({ browser }) => {
    const preparedState = loadPreparedState()
    const { context, page } = await openPreparedPage(browser, "authenticated", "/")

    for (const [surface, contract] of Object.entries(folioReadSurfaces) as Array<[
      keyof typeof folioReadSurfaces,
      FolioReadContract,
    ]>) {
      await page.goto(folioPath(preparedState, surface))
      await expectFolioReadSurface(page, contract)
      await expect(page).toHaveURL(folioPath(preparedState, surface))
    }

    await context.close()
  })
})
