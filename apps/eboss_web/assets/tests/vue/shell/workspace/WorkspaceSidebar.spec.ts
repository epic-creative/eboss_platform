import { describe, expect, it } from "vitest"

import { mountComponent } from "@/tests/vue/support/mount"
import WorkspaceSidebar from "@/vue/shell/workspace/WorkspaceSidebar.vue"
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
  },
  accessibleWorkspaces: [],
})

describe("WorkspaceSidebar", () => {
  const workspaceRoute = { type: "workspace", surface: "dashboard" }
  const appRoute = (appKey: string) => ({ type: "app", app_key: appKey, app_surface: null })

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

    expect(wrapper.get('[data-testid="workspace-sidebar"]').text()).toContain("No workspace")
    expect(wrapper.text()).toContain("No workspace selected")
    expect(wrapper.text()).toContain("No workspaces available yet.")
    expect(wrapper.text().includes("undefined/undefined")).toBe(false)
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
  })
})
