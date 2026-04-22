import { describe, expect, it } from "vitest"

import { mountComponent } from "@/tests/vue/support/mount"
import WorkspaceSidebar from "@/vue/shell/workspace/WorkspaceSidebar.vue"
import { workspaceAppTestContracts } from "@/vue/shell/workspace/testContracts"
import type { WorkspaceScope } from "@/vue/shell/workspace/types"

const emptyScope = (): WorkspaceScope => ({
  empty: true,
  dashboardPath: "/dashboard",
  currentWorkspace: null,
  owner: null,
  capabilities: {
    readWorkspace: false,
    manageWorkspace: false,
    readFolio: false,
    manageFolio: false,
    readChat: false,
    manageChat: false,
  },
  accessibleWorkspaces: [],
})

describe("WorkspaceSidebar", () => {
  const workspaceRoute = { type: "workspace", surface: "dashboard" }
  const appRoute = (appKey: string) => ({ type: "app", app_key: appKey, app_surface: null, app_path: [] })

  it("renders a stable empty-state summary when no workspace is selected", () => {
    const wrapper = mountComponent(WorkspaceSidebar, {
      props: {
        currentUser: {
          username: "operator",
          email: "operator@example.com",
        },
        currentScope: emptyScope(),
        currentPage: workspaceRoute,
        basePath: "/dashboard",
      },
    })

    expect(
      wrapper.get(`[data-testid="${workspaceAppTestContracts.sidebarTestId}"]`).text(),
    ).toContain("No workspace")
    expect(wrapper.text()).toContain("No workspace selected")
    expect(wrapper.text()).toContain("No workspaces available yet.")
    expect(wrapper.text().includes("undefined/undefined")).toBe(false)
    expect(
      wrapper.find(`nav[aria-label="${workspaceAppTestContracts.sidebarNavigationLabel}"]`).exists(),
    ).toBe(true)
  })

  it("renders app navigation when apps are available", async () => {
    const wrapper = mountComponent(WorkspaceSidebar, {
      props: {
        currentUser: {
          username: "operator",
          email: "operator@example.com",
        },
        currentScope: {
          empty: false,
          dashboardPath: "/primary-owner/primary-workspace",
          currentWorkspace: {
            id: "workspace-1",
            name: "Primary Workspace",
            slug: "primary-workspace",
            fullPath: "/primary-owner/primary-workspace",
            visibility: "private",
            ownerType: "user",
            ownerSlug: "primary-owner",
            ownerDisplayName: "Primary Owner",
            dashboardPath: "/primary-owner/primary-workspace",
            current: true,
          },
          owner: {
            type: "user",
            slug: "primary-owner",
            displayName: "Primary Owner",
          },
          capabilities: {
            readWorkspace: true,
            manageWorkspace: true,
            readFolio: true,
            manageFolio: true,
            readChat: true,
            manageChat: true,
          },
          apps: {
            folio: {
              key: "folio",
              label: "Folio",
              defaultPath: "/primary-owner/primary-workspace/apps/folio",
              enabled: true,
              capabilities: {
                read: true,
                manage: true,
              },
            },
          },
          accessibleWorkspaces: [],
        },
        currentPage: appRoute("folio"),
        basePath: "/primary-owner/primary-workspace",
      },
    })

    expect(wrapper.text()).toContain("Apps")

    const appsToggle = wrapper.findAll("button").find(button => button.text().includes("Apps"))
    expect(appsToggle).toBeDefined()
    expect(appsToggle?.exists()).toBe(true)

    await appsToggle!.trigger("click")
    const folioLink = wrapper.get('a[href="/primary-owner/primary-workspace/apps/folio"]')
    expect(folioLink.text()).toContain("Folio")
    expect(folioLink.classes()).toContain("bg-[hsl(var(--so-accent))]")
    expect(
      wrapper.find(
        `[role="region"][aria-label="${workspaceAppTestContracts.sidebarAppsRegionLabel}"]`,
      ).exists(),
    ).toBe(true)

    expect(wrapper.find('a[href="/primary-owner/primary-workspace/projects"]').exists()).toBe(false)
    expect(wrapper.find('a[href="/primary-owner/primary-workspace/activity"]').exists()).toBe(false)
  })

  it("uses app-aware fallback links and hides disabled apps in the sidebar", async () => {
    const wrapper = mountComponent(WorkspaceSidebar, {
      props: {
        currentUser: {
          username: "operator",
          email: "operator@example.com",
        },
        currentScope: {
          empty: false,
          dashboardPath: "/primary-owner/primary-workspace",
          currentWorkspace: {
            id: "workspace-1",
            name: "Primary Workspace",
            slug: "primary-workspace",
            fullPath: "/primary-owner/primary-workspace",
            visibility: "private",
            ownerType: "user",
            ownerSlug: "primary-owner",
            ownerDisplayName: "Primary Owner",
            dashboardPath: "/primary-owner/primary-workspace",
            current: true,
          },
          owner: {
            type: "user",
            slug: "primary-owner",
            displayName: "Primary Owner",
          },
          capabilities: {
            readWorkspace: true,
            manageWorkspace: true,
            readFolio: true,
            manageFolio: true,
            readChat: true,
            manageChat: true,
          },
          apps: {
            folio: {
              key: "folio",
              label: "Folio",
              defaultPath: "",
              enabled: true,
              capabilities: {
                read: true,
                manage: true,
              },
            },
            reports: {
              key: "reports",
              label: "Reports",
              defaultPath: "/primary-owner/primary-workspace/apps/reports",
              enabled: false,
              capabilities: {
                read: true,
                manage: false,
              },
            },
          },
          accessibleWorkspaces: [],
        },
        currentPage: appRoute("folio"),
        basePath: "/primary-owner/primary-workspace",
      },
    })

    const appsToggle = wrapper.findAll("button").find((button) => button.text().includes("Apps"))
    expect(appsToggle).toBeDefined()

    await appsToggle!.trigger("click")

    expect(wrapper.find('a[href="/primary-owner/primary-workspace/apps/folio"]').exists()).toBe(true)
    expect(wrapper.find('a[href="/primary-owner/primary-workspace/apps/reports"]').exists()).toBe(
      false,
    )
  })
})
