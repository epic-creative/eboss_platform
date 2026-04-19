import { nextTick } from "vue"
import { describe, expect, it } from "vitest"

import { mountComponent } from "@/tests/vue/support/mount"
import { projects } from "@/vue/shell/workspace/mockData"
import ShellOperatorWorkspaceApp from "@/vue/shell/workspace/ShellOperatorWorkspaceApp.vue"
import ProjectsPage from "@/vue/shell/workspace/pages/ProjectsPage.vue"
import type { WorkspaceScope, WorkspaceSurface, WorkspaceSummary } from "@/vue/shell/workspace/types"

const workspace = (overrides: Partial<WorkspaceSummary> = {}): WorkspaceSummary => ({
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
  ...overrides,
})

const scope = (overrides: Partial<WorkspaceScope> = {}): WorkspaceScope => ({
  empty: false,
  dashboardPath: "/primary-owner/primary-workspace",
  currentWorkspace: workspace(),
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
  accessibleWorkspaces: [workspace()],
  ...overrides,
})

const workspaceRoute = (surface: WorkspaceSurface) => ({ type: "workspace", surface })
const appRoute = (appKey: string, appSurface: string | null = null) => ({
  type: "app",
  app_key: appKey,
  app_surface: appSurface,
})

describe("ShellOperatorWorkspaceApp", () => {
  it("clears the selected project when the route page changes", async () => {
    const wrapper = mountComponent(ShellOperatorWorkspaceApp, {
      props: {
        currentUser: {
          username: "operator",
          email: "operator@example.com",
        },
        currentScope: scope(),
        currentPage: workspaceRoute("projects"),
        currentPath: "/primary-owner/primary-workspace/projects",
        signOutPath: "/sign-out",
        csrfToken: "csrf-token",
      },
      global: {
        stubs: {
          ThemeToggleButton: {
            template: "<button data-testid=\"theme-toggle-stub\" />",
          },
        },
      },
    })

    wrapper.getComponent(ProjectsPage).vm.$emit("update:selectedProject", projects[0])
    await nextTick()

    expect(wrapper.getComponent(ProjectsPage).props("selectedProject")).toMatchObject({
      id: projects[0].id,
    })

    await wrapper.setProps({
      currentPage: workspaceRoute("members"),
      currentPath: "/primary-owner/primary-workspace/members",
    })
    await nextTick()

    await wrapper.setProps({
      currentPage: workspaceRoute("projects"),
      currentPath: "/primary-owner/primary-workspace/projects",
    })
    await nextTick()

    expect(wrapper.getComponent(ProjectsPage).props("selectedProject")).toBeNull()
  })

  it("resets workspace-local state when the mounted workspace changes", async () => {
    const wrapper = mountComponent(ShellOperatorWorkspaceApp, {
      props: {
        currentUser: {
          username: "operator",
          email: "operator@example.com",
        },
        currentScope: scope(),
        currentPage: workspaceRoute("projects"),
        currentPath: "/primary-owner/primary-workspace/projects",
        signOutPath: "/sign-out",
        csrfToken: "csrf-token",
      },
      global: {
        stubs: {
          ThemeToggleButton: {
            template: "<button data-testid=\"theme-toggle-stub\" />",
          },
        },
      },
    })

    wrapper.getComponent(ProjectsPage).vm.$emit("update:projectFilter", "archived")
    wrapper.getComponent(ProjectsPage).vm.$emit("update:selectedProject", projects[4])
    await nextTick()

    expect(wrapper.getComponent(ProjectsPage).props("projectFilter")).toBe("archived")
    expect(wrapper.getComponent(ProjectsPage).props("selectedProject")).toMatchObject({
      id: projects[4].id,
    })

    await wrapper.setProps({
      currentPage: workspaceRoute("projects"),
      currentScope: scope({
        dashboardPath: "/secondary-owner/secondary-workspace",
        currentWorkspace: workspace({
          id: "workspace-2",
          name: "Secondary Workspace",
          slug: "secondary-workspace",
          ownerSlug: "secondary-owner",
          ownerDisplayName: "Secondary Owner",
          dashboardPath: "/secondary-owner/secondary-workspace",
        }),
        owner: {
          type: "user",
          slug: "secondary-owner",
          displayName: "Secondary Owner",
        },
        accessibleWorkspaces: [
          workspace({
            id: "workspace-2",
            name: "Secondary Workspace",
            slug: "secondary-workspace",
            ownerSlug: "secondary-owner",
            ownerDisplayName: "Secondary Owner",
            dashboardPath: "/secondary-owner/secondary-workspace",
          }),
        ],
      }),
      currentPath: "/secondary-owner/secondary-workspace/projects",
    })
    await nextTick()

    expect(wrapper.getComponent(ProjectsPage).props("projectFilter")).toBe("all")
    expect(wrapper.getComponent(ProjectsPage).props("selectedProject")).toBeNull()
  })

  it("renders app chrome when on an app route", () => {
    const wrapper = mountComponent(ShellOperatorWorkspaceApp, {
      props: {
        currentUser: {
          username: "operator",
          email: "operator@example.com",
        },
        currentScope: scope({
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
        }),
        currentPage: appRoute("folio", "files"),
        currentPath: "/primary-owner/primary-workspace/apps/folio/files",
        signOutPath: "/sign-out",
        csrfToken: "csrf-token",
      },
      global: {
        stubs: {
          ThemeToggleButton: {
            template: "<button data-testid=\"theme-toggle-stub\" />",
          },
        },
      },
    })

    const currentAppChip = wrapper.find('[data-testid="workspace-current-app"]')
    expect(currentAppChip.exists()).toBe(true)
    expect(currentAppChip.text()).toContain("App")
    expect(currentAppChip.text()).toContain("Folio")
    expect(currentAppChip.text()).toContain("Files")
  })
})
