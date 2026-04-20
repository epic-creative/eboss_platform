import { nextTick } from "vue"
import { afterEach, describe, expect, it, vi } from "vitest"

import { mountComponent } from "@/tests/vue/support/mount"
import { members } from "@/vue/shell/workspace/mockData"
import MembersPage from "@/vue/shell/workspace/pages/MembersPage.vue"
import ShellOperatorWorkspaceApp from "@/vue/shell/workspace/ShellOperatorWorkspaceApp.vue"
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
const nextMacrotask = () => new Promise((resolve) => setTimeout(resolve, 0))

describe("ShellOperatorWorkspaceApp", () => {
  afterEach(() => {
    vi.restoreAllMocks()
  })

  it("clears the selected member when the route page changes", async () => {
    const wrapper = mountComponent(ShellOperatorWorkspaceApp, {
      props: {
        currentUser: {
          username: "operator",
          email: "operator@example.com",
        },
        currentScope: scope(),
        currentPage: workspaceRoute("members"),
        currentPath: "/primary-owner/primary-workspace/members",
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

    wrapper.getComponent(MembersPage).vm.$emit("update:selected-member", members[0])
    await nextTick()

    expect(wrapper.getComponent(MembersPage).props("selectedMember")).toMatchObject({
      id: members[0].id,
    })

    await wrapper.setProps({
      currentPage: workspaceRoute("settings"),
      currentPath: "/primary-owner/primary-workspace/settings",
    })
    await nextTick()

    await wrapper.setProps({
      currentPage: workspaceRoute("members"),
      currentPath: "/primary-owner/primary-workspace/members",
    })
    await nextTick()

    expect(wrapper.getComponent(MembersPage).props("selectedMember")).toBeNull()
  })

  it("resets workspace-local state when the mounted workspace changes", async () => {
    const wrapper = mountComponent(ShellOperatorWorkspaceApp, {
      props: {
        currentUser: {
          username: "operator",
          email: "operator@example.com",
        },
        currentScope: scope(),
        currentPage: workspaceRoute("members"),
        currentPath: "/primary-owner/primary-workspace/members",
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

    wrapper.getComponent(MembersPage).vm.$emit("update:selected-member", members[4])
    await nextTick()

    expect(wrapper.getComponent(MembersPage).props("selectedMember")).toMatchObject({
      id: members[4].id,
    })

    await wrapper.setProps({
      currentPage: workspaceRoute("members"),
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
      currentPath: "/secondary-owner/secondary-workspace/members",
    })
    await nextTick()

    expect(wrapper.getComponent(MembersPage).props("selectedMember")).toBeNull()
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

  it("renders real folio projects on folio app routes", async () => {
    vi.spyOn(global, "fetch").mockResolvedValue({
      ok: true,
      status: 200,
      json: async () => ({
        scope: {
          app_key: "folio",
          workspace: {
            id: "workspace-1",
            name: "Primary Workspace",
            slug: "primary-workspace",
            full_path: "/primary-owner/primary-workspace",
            visibility: "private",
            owner_type: "user",
            owner_id: "owner-1",
            owner_slug: "primary-owner",
            owner_display_name: "Primary Owner",
            dashboard_path: "/primary-owner/primary-workspace",
            "current?": true,
          },
          owner: {
            type: "user",
            id: "owner-1",
            slug: "primary-owner",
            display_name: "Primary Owner",
          },
          app: {
            key: "folio",
            label: "Folio",
            default_path: "/primary-owner/primary-workspace/apps/folio",
            enabled: true,
            capabilities: { read: true, manage: true },
          },
          capabilities: { read: true, manage: true },
          workspace_path: "/primary-owner/primary-workspace",
          app_path: "/primary-owner/primary-workspace/apps/folio",
        },
        projects: [
          {
            id: "project-1",
            title: "Atlas Service",
            status: "active",
            priority_position: 1,
            due_at: "2026-04-01T00:00:00Z",
            review_at: "2026-04-02T00:00:00Z",
          },
          {
            id: "project-2",
            title: "Nimbus Engine",
            status: "on_hold",
            priority_position: 2,
            due_at: null,
            review_at: null,
          },
        ],
      }),
    } as Response)

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
        currentPage: appRoute("folio", "projects"),
        currentPath: "/primary-owner/primary-workspace/apps/folio/projects",
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

    await nextTick()
    await nextMacrotask()

    expect(global.fetch).toHaveBeenCalledWith(
      "/api/v1/primary-owner/workspaces/primary-workspace/apps/folio/projects",
      expect.any(Object),
    )
    const projectsView = wrapper.get('[data-testid="workspace-page-projects"]')
    expect(projectsView.text()).toContain("Atlas Service")
    expect(projectsView.text()).toContain("Nimbus Engine")
    expect(projectsView.text().includes("API Gateway")).toBe(false)

    await projectsView.get('[data-testid="project-row-project-1"]').trigger("click")
    await nextTick()

    expect(projectsView.text()).toContain("Status")
    expect(projectsView.text()).toContain("Due date")
    expect(projectsView.text()).toContain("Review date")
    expect(projectsView.text().includes("Environment")).toBe(false)
    expect(projectsView.text().includes("Region")).toBe(false)
    expect(projectsView.text().includes("Members")).toBe(false)
  })

  it("creates a folio project from the projects surface and refreshes the list", async () => {
    const fetchMock = vi
      .spyOn(global, "fetch")
      .mockResolvedValueOnce({
        ok: true,
        status: 200,
        json: async () => ({
          scope: {},
          projects: [
            {
              id: "project-1",
              title: "Atlas Service",
              status: "active",
              priority_position: 1,
              due_at: null,
              review_at: null,
            },
          ],
        }),
      } as Response)
      .mockResolvedValueOnce({
        ok: true,
        status: 201,
        json: async () => ({
          scope: {},
          project: {
            id: "project-2",
            title: "Launch Console",
            status: "active",
            priority_position: null,
            due_at: null,
            review_at: null,
          },
        }),
      } as Response)
      .mockResolvedValueOnce({
        ok: true,
        status: 200,
        json: async () => ({
          scope: {},
          projects: [
            {
              id: "project-1",
              title: "Atlas Service",
              status: "active",
              priority_position: 1,
              due_at: null,
              review_at: null,
            },
            {
              id: "project-2",
              title: "Launch Console",
              status: "active",
              priority_position: null,
              due_at: null,
              review_at: null,
            },
          ],
        }),
      } as Response)

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
        currentPage: appRoute("folio", "projects"),
        currentPath: "/primary-owner/primary-workspace/apps/folio/projects",
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

    await nextTick()
    await nextMacrotask()

    const projectsView = wrapper.get('[data-testid="workspace-page-projects"]')
    await projectsView.get('[data-testid="projects-create-open"]').trigger("click")

    const titleInput = projectsView.get('[data-testid="projects-create-title-input"]')
    await titleInput.setValue("Launch Console")
    await projectsView.get('[data-testid="projects-create-form-element"]').trigger("submit")

    await nextTick()
    await nextMacrotask()
    await nextTick()
    await nextMacrotask()

    expect(fetchMock).toHaveBeenCalledTimes(3)
    expect(fetchMock).toHaveBeenNthCalledWith(
      2,
      "/api/v1/primary-owner/workspaces/primary-workspace/apps/folio/projects",
      expect.objectContaining({
        method: "POST",
        body: JSON.stringify({ title: "Launch Console" }),
        headers: expect.objectContaining({
          "Content-Type": "application/json",
        }),
      }),
    )

    expect(projectsView.text()).toContain("Launch Console")
    expect(projectsView.find('[data-testid="projects-create-form"]').exists()).toBe(false)
  })

  it("updates folio project details from the projects inspector and refreshes the list", async () => {
    const fetchMock = vi
      .spyOn(global, "fetch")
      .mockResolvedValueOnce({
        ok: true,
        status: 200,
        json: async () => ({
          scope: {},
          projects: [
            {
              id: "project-1",
              title: "Atlas Service",
              description: "Initial scope",
              status: "active",
              priority_position: 1,
              due_at: "2026-04-01T00:00:00Z",
              review_at: "2026-04-02T00:00:00Z",
              notes: "Old notes",
              metadata: {
                cadence: "monthly",
              },
            },
          ],
        }),
      } as Response)
      .mockResolvedValueOnce({
        ok: true,
        status: 200,
        json: async () => ({
          scope: {},
          project: {
            id: "project-1",
            title: "Atlas Service Revamp",
            description: "Refined project scope",
            status: "active",
            priority_position: 1,
            due_at: "2026-05-10T00:00:00Z",
            review_at: "2026-05-15T00:00:00Z",
            notes: "Updated notes",
            metadata: {
              cadence: "weekly",
              owner: "ops",
            },
          },
        }),
      } as Response)
      .mockResolvedValueOnce({
        ok: true,
        status: 200,
        json: async () => ({
          scope: {},
          projects: [
            {
              id: "project-1",
              title: "Atlas Service Revamp",
              description: "Refined project scope",
              status: "active",
              priority_position: 1,
              due_at: "2026-05-10T00:00:00Z",
              review_at: "2026-05-15T00:00:00Z",
              notes: "Updated notes",
              metadata: {
                cadence: "weekly",
                owner: "ops",
              },
            },
          ],
        }),
      } as Response)

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
        currentPage: appRoute("folio", "projects"),
        currentPath: "/primary-owner/primary-workspace/apps/folio/projects",
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

    await nextTick()
    await nextMacrotask()

    const projectsView = wrapper.get('[data-testid="workspace-page-projects"]')
    await projectsView.get('[data-testid="project-row-project-1"]').trigger("click")
    await nextTick()

    await projectsView.get('[data-testid="project-edit-open"]').trigger("click")

    await projectsView.get('[data-testid="project-edit-title-input"]').setValue("Atlas Service Revamp")
    await projectsView.get('[data-testid="project-edit-description-input"]').setValue("Refined project scope")
    await projectsView.get('[data-testid="project-edit-due-input"]').setValue("2026-05-10")
    await projectsView.get('[data-testid="project-edit-review-input"]').setValue("2026-05-15")
    await projectsView.get('[data-testid="project-edit-notes-input"]').setValue("Updated notes")
    await projectsView
      .get('[data-testid="project-edit-metadata-input"]')
      .setValue('{"cadence":"weekly","owner":"ops"}')
    await projectsView.get('[data-testid="project-edit-form"]').trigger("submit")

    await nextTick()
    await nextMacrotask()
    await nextTick()
    await nextMacrotask()

    expect(fetchMock).toHaveBeenCalledTimes(3)
    const patchCall = fetchMock.mock.calls[1]

    expect(fetchMock).toHaveBeenNthCalledWith(
      2,
      "/api/v1/primary-owner/workspaces/primary-workspace/apps/folio/projects/project-1",
      expect.objectContaining({
        method: "PATCH",
        headers: expect.objectContaining({
          "Content-Type": "application/json",
        }),
      }),
    )
    expect(JSON.parse(String(patchCall[1]?.body))).toEqual({
      title: "Atlas Service Revamp",
      description: "Refined project scope",
      due_at: "2026-05-10",
      review_at: "2026-05-15",
      notes: "Updated notes",
      metadata: { cadence: "weekly", owner: "ops" },
    })

    expect(projectsView.text()).toContain("Atlas Service Revamp")
    expect(projectsView.get('[data-testid="project-description-value"]').text()).toContain(
      "Refined project scope",
    )
    expect(projectsView.get('[data-testid="project-metadata-value"]').text()).toContain(
      "\"cadence\": \"weekly\"",
    )
  })

  it("hides project creation controls when folio manage access is not granted", async () => {
    vi.spyOn(global, "fetch").mockResolvedValue({
      ok: true,
      status: 200,
      json: async () => ({
        scope: {},
        projects: [],
      }),
    } as Response)

    const wrapper = mountComponent(ShellOperatorWorkspaceApp, {
      props: {
        currentUser: {
          username: "operator",
          email: "operator@example.com",
        },
        currentScope: scope({
          capabilities: {
            readWorkspace: true,
            manageWorkspace: false,
            readFolio: true,
            manageFolio: false,
          },
          apps: {
            folio: {
              key: "folio",
              label: "Folio",
              defaultPath: "/primary-owner/primary-workspace/apps/folio",
              enabled: true,
              capabilities: {
                read: true,
                manage: false,
              },
            },
          },
        }),
        currentPage: appRoute("folio", "projects"),
        currentPath: "/primary-owner/primary-workspace/apps/folio/projects",
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

    await nextTick()
    await nextMacrotask()

    const projectsView = wrapper.get('[data-testid="workspace-page-projects"]')
    expect(projectsView.find('[data-testid="projects-create-open"]').exists()).toBe(false)
    expect(projectsView.find('[data-testid="projects-create-form"]').exists()).toBe(false)
  })

  it("renders real folio task details from task summary fields", async () => {
    vi.spyOn(global, "fetch").mockResolvedValue({
      ok: true,
      status: 200,
      json: async () => ({
        scope: {
          app_key: "folio",
          workspace: {
            id: "workspace-1",
            name: "Primary Workspace",
            slug: "primary-workspace",
            full_path: "/primary-owner/primary-workspace",
            visibility: "private",
            owner_type: "user",
            owner_id: "owner-1",
            owner_slug: "primary-owner",
            owner_display_name: "Primary Owner",
            dashboard_path: "/primary-owner/primary-workspace",
            "current?": true,
          },
          owner: {
            type: "user",
            id: "owner-1",
            slug: "primary-owner",
            display_name: "Primary Owner",
          },
          app: {
            key: "folio",
            label: "Folio",
            default_path: "/primary-owner/primary-workspace/apps/folio",
            enabled: true,
            capabilities: { read: true, manage: true },
          },
          capabilities: { read: true, manage: true },
          workspace_path: "/primary-owner/primary-workspace",
          app_path: "/primary-owner/primary-workspace/apps/folio",
        },
        tasks: [
          {
            id: "task-1",
            title: "Refine queueing",
            status: "scheduled",
            project_id: "project-1",
            priority_position: 7,
            due_at: "2026-05-01T00:00:00Z",
            review_at: null,
          },
          {
            id: "task-2",
            title: "Archive old notes",
            status: "done",
            project_id: null,
            priority_position: null,
            due_at: null,
            review_at: "2026-04-02T00:00:00Z",
          },
        ],
      }),
    } as Response)

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
        currentPage: appRoute("folio", "tasks"),
        currentPath: "/primary-owner/primary-workspace/apps/folio/tasks",
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

    await nextTick()
    await nextMacrotask()

    expect(global.fetch).toHaveBeenCalledWith(
      "/api/v1/primary-owner/workspaces/primary-workspace/apps/folio/tasks",
      expect.any(Object),
    )

    const tasksView = wrapper.get('[data-testid="workspace-page-tasks"]')
    expect(tasksView.text()).toContain("Refine queueing")
    expect(tasksView.text()).toContain("Archive old notes")

    await tasksView.get('[data-testid="task-row-task-1"]').trigger("click")
    await nextTick()

    expect(tasksView.text()).toContain("Current status")
    expect(tasksView.text()).toContain("Due date")
    expect(tasksView.text()).toContain("Task ID")
    expect(tasksView.text()).toContain("Review date")
  })

  it("creates a folio task from the tasks surface and refreshes the list", async () => {
    const fetchMock = vi
      .spyOn(global, "fetch")
      .mockResolvedValueOnce({
        ok: true,
        status: 200,
        json: async () => ({
          scope: {},
          projects: [
            {
              id: "project-1",
              title: "Atlas Service",
              status: "active",
              priority_position: null,
              due_at: null,
              review_at: null,
            },
          ],
        }),
      } as Response)
      .mockResolvedValueOnce({
        ok: true,
        status: 200,
        json: async () => ({
          scope: {},
          tasks: [
            {
              id: "task-1",
              title: "Existing task",
              status: "inbox",
              project_id: null,
              priority_position: null,
              due_at: null,
              review_at: null,
            },
          ],
        }),
      } as Response)
      .mockResolvedValueOnce({
        ok: true,
        status: 201,
        json: async () => ({
          scope: {},
          task: {
            id: "task-2",
            title: "Draft rollout notes",
            status: "inbox",
            project_id: "project-1",
            priority_position: null,
            due_at: null,
            review_at: null,
          },
        }),
      } as Response)
      .mockResolvedValueOnce({
        ok: true,
        status: 200,
        json: async () => ({
          scope: {},
          tasks: [
            {
              id: "task-1",
              title: "Existing task",
              status: "inbox",
              project_id: null,
              priority_position: null,
              due_at: null,
              review_at: null,
            },
            {
              id: "task-2",
              title: "Draft rollout notes",
              status: "inbox",
              project_id: "project-1",
              priority_position: null,
              due_at: null,
              review_at: null,
            },
          ],
        }),
      } as Response)

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
        currentPage: appRoute("folio", "tasks"),
        currentPath: "/primary-owner/primary-workspace/apps/folio/tasks",
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

    await nextTick()
    await nextMacrotask()
    await nextTick()
    await nextMacrotask()

    const tasksView = wrapper.get('[data-testid="workspace-page-tasks"]')
    await tasksView.get('[data-testid="tasks-create-open"]').trigger("click")

    await tasksView.get('[data-testid="tasks-create-title-input"]').setValue("Draft rollout notes")
    await tasksView.get('[data-testid="tasks-create-project-select"]').setValue("project-1")
    await tasksView.get('[data-testid="tasks-create-form-element"]').trigger("submit")

    await nextTick()
    await nextMacrotask()
    await nextTick()
    await nextMacrotask()

    expect(fetchMock).toHaveBeenCalledTimes(4)
    expect(fetchMock).toHaveBeenNthCalledWith(
      3,
      "/api/v1/primary-owner/workspaces/primary-workspace/apps/folio/tasks",
      expect.objectContaining({
        method: "POST",
        body: JSON.stringify({ title: "Draft rollout notes", project_id: "project-1" }),
        headers: expect.objectContaining({
          "Content-Type": "application/json",
        }),
      }),
    )

    expect(tasksView.text()).toContain("Draft rollout notes")
    expect(tasksView.find('[data-testid="tasks-create-form"]').exists()).toBe(false)
  })

  it("transitions a folio task from the tasks inspector and refreshes the list", async () => {
    const fetchMock = vi
      .spyOn(global, "fetch")
      .mockResolvedValueOnce({
        ok: true,
        status: 200,
        json: async () => ({
          scope: {},
          projects: [],
        }),
      } as Response)
      .mockResolvedValueOnce({
        ok: true,
        status: 200,
        json: async () => ({
          scope: {},
          tasks: [
            {
              id: "task-1",
              title: "Review rollout notes",
              status: "inbox",
              project_id: null,
              priority_position: null,
              due_at: null,
              review_at: null,
            },
          ],
        }),
      } as Response)
      .mockResolvedValueOnce({
        ok: true,
        status: 200,
        json: async () => ({
          scope: {},
          task: {
            id: "task-1",
            title: "Review rollout notes",
            status: "done",
            project_id: null,
            priority_position: null,
            due_at: null,
            review_at: null,
          },
        }),
      } as Response)
      .mockResolvedValueOnce({
        ok: true,
        status: 200,
        json: async () => ({
          scope: {},
          tasks: [
            {
              id: "task-1",
              title: "Review rollout notes",
              status: "done",
              project_id: null,
              priority_position: null,
              due_at: null,
              review_at: null,
            },
          ],
        }),
      } as Response)

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
        currentPage: appRoute("folio", "tasks"),
        currentPath: "/primary-owner/primary-workspace/apps/folio/tasks",
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

    await nextTick()
    await nextMacrotask()
    await nextTick()
    await nextMacrotask()

    const tasksView = wrapper.get('[data-testid="workspace-page-tasks"]')
    await tasksView.get('[data-testid="task-row-task-1"]').trigger("click")
    await nextTick()

    await tasksView.get('[data-testid="tasks-transition-status-select"]').setValue("done")
    await tasksView.get('[data-testid="tasks-transition-submit"]').trigger("click")

    await nextTick()
    await nextMacrotask()
    await nextTick()
    await nextMacrotask()

    expect(fetchMock).toHaveBeenCalledTimes(4)
    expect(fetchMock).toHaveBeenNthCalledWith(
      3,
      "/api/v1/primary-owner/workspaces/primary-workspace/apps/folio/tasks/task-1",
      expect.objectContaining({
        method: "PATCH",
        body: JSON.stringify({ status: "done" }),
        headers: expect.objectContaining({
          "Content-Type": "application/json",
        }),
      }),
    )

    expect(tasksView.text()).toContain("Done")
    expect(tasksView.find('[data-testid="tasks-transition-error"]').exists()).toBe(false)
  })

  it("shows transition validation errors from the folio task endpoint", async () => {
    const fetchMock = vi
      .spyOn(global, "fetch")
      .mockResolvedValueOnce({
        ok: true,
        status: 200,
        json: async () => ({
          scope: {},
          projects: [],
        }),
      } as Response)
      .mockResolvedValueOnce({
        ok: true,
        status: 200,
        json: async () => ({
          scope: {},
          tasks: [
            {
              id: "task-1",
              title: "Waiting dependency",
              status: "inbox",
              project_id: null,
              priority_position: null,
              due_at: null,
              review_at: null,
            },
          ],
        }),
      } as Response)
      .mockResolvedValueOnce({
        ok: false,
        status: 400,
        statusText: "Bad Request",
        json: async () => ({
          error: {
            code: "invalid_task_transition",
            message: "waiting_for tasks require notes or an active delegation",
          },
        }),
      } as Response)

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
        currentPage: appRoute("folio", "tasks"),
        currentPath: "/primary-owner/primary-workspace/apps/folio/tasks",
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

    await nextTick()
    await nextMacrotask()
    await nextTick()
    await nextMacrotask()

    const tasksView = wrapper.get('[data-testid="workspace-page-tasks"]')
    await tasksView.get('[data-testid="task-row-task-1"]').trigger("click")
    await nextTick()

    await tasksView.get('[data-testid="tasks-transition-status-select"]').setValue("waiting_for")
    await tasksView.get('[data-testid="tasks-transition-submit"]').trigger("click")

    await nextTick()
    await nextMacrotask()
    await nextTick()

    expect(fetchMock).toHaveBeenCalledTimes(3)
    expect(tasksView.get('[data-testid="tasks-transition-error"]').text()).toContain(
      "waiting_for tasks require notes or an active delegation",
    )
  })

  it("hides task creation controls when folio manage access is not granted", async () => {
    vi.spyOn(global, "fetch").mockResolvedValue({
      ok: true,
      status: 200,
      json: async () => ({
        scope: {},
        tasks: [],
      }),
    } as Response)

    const wrapper = mountComponent(ShellOperatorWorkspaceApp, {
      props: {
        currentUser: {
          username: "operator",
          email: "operator@example.com",
        },
        currentScope: scope({
          capabilities: {
            readWorkspace: true,
            manageWorkspace: false,
            readFolio: true,
            manageFolio: false,
          },
          apps: {
            folio: {
              key: "folio",
              label: "Folio",
              defaultPath: "/primary-owner/primary-workspace/apps/folio",
              enabled: true,
              capabilities: {
                read: true,
                manage: false,
              },
            },
          },
        }),
        currentPage: appRoute("folio", "tasks"),
        currentPath: "/primary-owner/primary-workspace/apps/folio/tasks",
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

    await nextTick()
    await nextMacrotask()

    const tasksView = wrapper.get('[data-testid="workspace-page-tasks"]')
    expect(tasksView.find('[data-testid="tasks-create-open"]').exists()).toBe(false)
    expect(tasksView.find('[data-testid="tasks-create-form"]').exists()).toBe(false)
  })

  it("renders real folio activity on folio activity surface", async () => {
    vi.spyOn(global, "fetch").mockResolvedValue({
      ok: true,
      status: 200,
      json: async () => ({
        scope: {
          app_key: "folio",
          workspace: {
            id: "workspace-1",
            name: "Primary Workspace",
            slug: "primary-workspace",
            full_path: "/primary-owner/primary-workspace",
            visibility: "private",
            owner_type: "user",
            owner_id: "owner-1",
            owner_slug: "primary-owner",
            owner_display_name: "Primary Owner",
            dashboard_path: "/primary-owner/primary-workspace",
            "current?": true,
          },
          owner: {
            type: "user",
            id: "owner-1",
            slug: "primary-owner",
            display_name: "Primary Owner",
          },
          app: {
            key: "folio",
            label: "Folio",
            default_path: "/primary-owner/primary-workspace/apps/folio",
            enabled: true,
            capabilities: { read: true, manage: true },
          },
          capabilities: { read: true, manage: true },
          workspace_path: "/primary-owner/primary-workspace",
          app_path: "/primary-owner/primary-workspace/apps/folio",
        },
        events: [
          {
            id: "event-001",
            app_key: "folio",
            provider_key: "activity",
            provider_event_id: "evt-20260419",
            occurred_at: "2026-04-19T12:00:00Z",
            actor: {
              type: "system",
              id: "system-operator",
              label: "Builder",
            },
            action: "created",
            summary: "Project Atlas was created",
            subject: {
              type: "project",
              id: "project-1",
              label: "Atlas Service",
            },
            details: "A new project has been provisioned.",
            status: "success",
            changes: {
              status: { before: "pending", after: "active" },
            },
            metadata: {
              source: "bootstrap",
            },
            resource_path: "/primary-owner/primary-workspace/projects/project-1",
          },
        ],
      }),
    } as Response)

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
        currentPage: appRoute("folio", "activity"),
        currentPath: "/primary-owner/primary-workspace/apps/folio/activity",
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

    await nextTick()
    await nextMacrotask()

    expect(global.fetch).toHaveBeenCalledWith(
      "/api/v1/primary-owner/workspaces/primary-workspace/apps/folio/activity",
      expect.any(Object),
    )
    expect(wrapper.get('[data-testid="workspace-page-activity"]').text()).toContain("Project Atlas was created")

    await wrapper.get('[data-testid="activity-row-event-001"]').trigger("click")
    await nextTick()

    expect(wrapper.get('[data-testid="workspace-page-activity"]').text()).toContain("Builder")
    expect(wrapper.get('[data-testid="workspace-page-activity"]').text()).toContain("View resource")
  })

  it("shows loading and empty states on folio projects surface", async () => {
    let resolveFetch: (response: Response) => void = () => {}
    vi.spyOn(global, "fetch").mockImplementation(() =>
      new Promise((resolve) => {
        resolveFetch = resolve
      }) as Promise<Response>,
    )

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
        currentPage: appRoute("folio", "projects"),
        currentPath: "/primary-owner/primary-workspace/apps/folio/projects",
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

    await nextTick()
    expect(wrapper.find('[data-testid="projects-state-loading"]').exists()).toBe(true)

    resolveFetch({
      ok: true,
      status: 200,
      json: async () => ({
        scope: {
          app_key: "folio",
          workspace: {
            id: "workspace-1",
            name: "Primary Workspace",
            slug: "primary-workspace",
            full_path: "/primary-owner/primary-workspace",
            visibility: "private",
            owner_type: "user",
            owner_id: "owner-1",
            owner_slug: "primary-owner",
            owner_display_name: "Primary Owner",
            dashboard_path: "/primary-owner/primary-workspace",
            "current?": true,
          },
          owner: {
            type: "user",
            id: "owner-1",
            slug: "primary-owner",
            display_name: "Primary Owner",
          },
          app: {
            key: "folio",
            label: "Folio",
            default_path: "/primary-owner/primary-workspace/apps/folio",
            enabled: true,
            capabilities: { read: true, manage: true },
          },
          capabilities: { read: true, manage: true },
          workspace_path: "/primary-owner/primary-workspace",
          app_path: "/primary-owner/primary-workspace/apps/folio",
        },
        projects: [],
      }),
    } as Response)

    await nextMacrotask()
    await nextTick()

    expect(wrapper.find('[data-testid="projects-state-empty"]').exists()).toBe(true)
    expect(wrapper.get('[data-testid="projects-state-empty"]').text()).toContain("No projects yet")
  })

  it("shows an actionable error state on folio tasks surface", async () => {
    vi.spyOn(global, "fetch").mockResolvedValue({
      ok: false,
      status: 502,
      statusText: "Bad Gateway",
      json: async () => ({
        error: { message: "Unable to load tasks from Folio" },
      }),
    } as Response)

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
        currentPage: appRoute("folio", "tasks"),
        currentPath: "/primary-owner/primary-workspace/apps/folio/tasks",
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

    await nextTick()
    await nextMacrotask()

    const errorState = wrapper.get('[data-testid="tasks-state-error"]')
    expect(errorState.text()).toContain("Unable to load tasks")
    expect(errorState.text()).toContain("Unable to load tasks from Folio")

    await errorState.get("button").trigger("click")

    expect(global.fetch).toHaveBeenCalledTimes(3)
  })

  it("shows an empty state on folio activity surface", async () => {
    vi.spyOn(global, "fetch").mockResolvedValue({
      ok: true,
      status: 200,
      json: async () => ({
        scope: {
          app_key: "folio",
          workspace: {
            id: "workspace-1",
            name: "Primary Workspace",
            slug: "primary-workspace",
            full_path: "/primary-owner/primary-workspace",
            visibility: "private",
            owner_type: "user",
            owner_id: "owner-1",
            owner_slug: "primary-owner",
            owner_display_name: "Primary Owner",
            dashboard_path: "/primary-owner/primary-workspace",
            "current?": true,
          },
          owner: {
            type: "user",
            id: "owner-1",
            slug: "primary-owner",
            display_name: "Primary Owner",
          },
          app: {
            key: "folio",
            label: "Folio",
            default_path: "/primary-owner/primary-workspace/apps/folio",
            enabled: true,
            capabilities: { read: true, manage: true },
          },
          capabilities: { read: true, manage: true },
          workspace_path: "/primary-owner/primary-workspace",
          app_path: "/primary-owner/primary-workspace/apps/folio",
        },
        events: [],
      }),
    } as Response)

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
        currentPage: appRoute("folio", "activity"),
        currentPath: "/primary-owner/primary-workspace/apps/folio/activity",
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

    await nextTick()
    await nextMacrotask()

    expect(wrapper.find('[data-testid="activity-state-empty"]').exists()).toBe(true)
    expect(wrapper.get('[data-testid="activity-state-empty"]').text()).toContain("No activity yet")
  })
})
