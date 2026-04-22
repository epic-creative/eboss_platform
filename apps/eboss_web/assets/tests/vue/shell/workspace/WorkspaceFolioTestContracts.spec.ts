import { describe, expect, it } from "vitest"

import { mountComponent } from "@/tests/vue/support/mount"
import ShellOperatorWorkspaceApp from "@/vue/shell/workspace/ShellOperatorWorkspaceApp.vue"
import ActivityPage from "@/vue/shell/workspace/pages/ActivityPage.vue"
import ProjectsPage from "@/vue/shell/workspace/pages/ProjectsPage.vue"
import TasksPage from "@/vue/shell/workspace/pages/TasksPage.vue"
import {
  folioActivityRowTestId,
  folioProjectRowTestId,
  folioSurfaceTestContracts,
  folioTaskRowTestId,
  workspaceAppTestContracts,
} from "@/vue/shell/workspace/testContracts"

describe("workspace and folio test contracts", () => {
  it("exposes stable app-aware shell landmarks", () => {
    const wrapper = mountComponent(ShellOperatorWorkspaceApp, {
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
        currentPage: {
          type: "app",
          app_key: "folio",
          app_surface: "files",
          app_path: ["files"],
        },
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

    const shellSelector = `[role="region"][aria-label="${workspaceAppTestContracts.shellRegionLabel}"]`
    const shell = wrapper.get(shellSelector)
    expect(shell.attributes("data-testid")).toBe(workspaceAppTestContracts.shellTestId)
    expect(
      wrapper.find(`nav[aria-label="${workspaceAppTestContracts.sidebarNavigationLabel}"]`).exists(),
    ).toBe(true)
    expect(
      wrapper.find(
        `[role="region"][aria-label="${workspaceAppTestContracts.sidebarAppsRegionLabel}"]`,
      ).exists(),
    ).toBe(true)
    expect(
      wrapper.find(
        `[role="status"][aria-label="${workspaceAppTestContracts.currentAppStatusLabel}"]`,
      ).exists(),
    ).toBe(true)
  })

  it("exposes stable folio projects page and read-state selectors", () => {
    const wrapper = mountComponent(ProjectsPage, {
      props: {
        workspaceReference: "primary-owner/primary-workspace",
        projectFilters: ["all", "active", "completed"],
        projectFilter: "all",
        projects: [
          {
            id: "project-1",
            name: "Atlas Service",
            description: null,
            status: "active",
            dueAt: null,
            reviewAt: null,
            priorityPosition: 1,
            notes: null,
            metadata: {},
          },
        ],
        selectedProject: null,
        loading: false,
        error: null,
        canCreateProject: false,
        canUpdateProject: false,
        canTransitionProject: false,
        creatingProject: false,
        updatingProject: false,
        transitioningProject: false,
        refresh: async () => {},
        createProject: async () => {},
        updateProject: async () => {},
        transitionProject: async () => {},
      },
    })

    const pageSelector =
      `[role="region"][aria-label="${folioSurfaceTestContracts.projects.pageRegionLabel}"]`
    const page = wrapper.get(pageSelector)
    expect(page.attributes("data-testid")).toBe(folioSurfaceTestContracts.projects.pageTestId)
    expect(
      wrapper.find(
        `[role="region"][aria-label="${folioSurfaceTestContracts.projects.listRegionLabel}"]`,
      ).exists(),
    ).toBe(true)
    expect(wrapper.find(`[data-testid="${folioProjectRowTestId("project-1")}"]`).exists()).toBe(true)

    const loadingWrapper = mountComponent(ProjectsPage, {
      props: {
        workspaceReference: "primary-owner/primary-workspace",
        projectFilters: ["all", "active"],
        projectFilter: "all",
        projects: [],
        selectedProject: null,
        loading: true,
        error: null,
        canCreateProject: false,
        canUpdateProject: false,
        canTransitionProject: false,
        creatingProject: false,
        updatingProject: false,
        transitioningProject: false,
        refresh: async () => {},
        createProject: async () => {},
        updateProject: async () => {},
        transitionProject: async () => {},
      },
    })

    expect(
      loadingWrapper.find(
        `[data-testid="${folioSurfaceTestContracts.projects.loadingStateTestId}"]`,
      ).exists(),
    ).toBe(true)
  })

  it("exposes stable folio tasks page and read-state selectors", () => {
    const wrapper = mountComponent(TasksPage, {
      props: {
        workspaceReference: "primary-owner/primary-workspace",
        tasks: [
          {
            id: "task-1",
            title: "Draft rollout notes",
            status: "inbox",
            projectId: "project-1",
            priorityPosition: 1,
            dueAt: null,
            reviewAt: null,
            activeDelegation: null,
          },
        ],
        selectedTask: null,
        loading: false,
        error: null,
        canCreateTask: false,
        creatingTask: false,
        canTransitionTask: false,
        transitioningTask: false,
        canDelegateTask: false,
        delegatingTask: false,
        projectOptions: [],
        refresh: async () => {},
        createTask: async () => {},
        transitionTask: async () => {},
        delegateTask: async () => {},
      },
    })

    const pageSelector = `[role="region"][aria-label="${folioSurfaceTestContracts.tasks.pageRegionLabel}"]`
    const page = wrapper.get(pageSelector)
    expect(page.attributes("data-testid")).toBe(folioSurfaceTestContracts.tasks.pageTestId)
    expect(
      wrapper.find(
        `[role="region"][aria-label="${folioSurfaceTestContracts.tasks.listRegionLabel}"]`,
      ).exists(),
    ).toBe(true)
    expect(wrapper.find(`[data-testid="${folioTaskRowTestId("task-1")}"]`).exists()).toBe(true)

    const loadingWrapper = mountComponent(TasksPage, {
      props: {
        workspaceReference: "primary-owner/primary-workspace",
        tasks: [],
        selectedTask: null,
        loading: true,
        error: null,
        canCreateTask: false,
        creatingTask: false,
        canTransitionTask: false,
        transitioningTask: false,
        canDelegateTask: false,
        delegatingTask: false,
        projectOptions: [],
        refresh: async () => {},
        createTask: async () => {},
        transitionTask: async () => {},
        delegateTask: async () => {},
      },
    })

    expect(
      loadingWrapper.find(`[data-testid="${folioSurfaceTestContracts.tasks.loadingStateTestId}"]`)
        .exists(),
    ).toBe(true)
  })

  it("exposes stable folio activity page and read-state selectors", () => {
    const wrapper = mountComponent(ActivityPage, {
      props: {
        workspaceReference: "primary-owner/primary-workspace",
        activityEvents: [
          {
            id: "event-001",
            app_key: "folio",
            provider_key: "folio",
            provider_event_id: "evt_001",
            occurred_at: "2026-04-01T15:00:00Z",
            actor: {
              type: "user",
              id: "user-1",
              label: "Builder",
            },
            action: "created",
            summary: "Project Atlas was created",
            subject: {
              type: "project",
              id: "project-1",
              label: "Project Atlas",
            },
            details: "Initial project creation",
            status: "success",
            changes: null,
            metadata: {},
            resource_path: "/primary-owner/primary-workspace/apps/folio/projects/project-1",
          },
        ],
        selectedActivity: null,
        loading: false,
        error: null,
        refresh: async () => {},
      },
    })

    const pageSelector =
      `[role="region"][aria-label="${folioSurfaceTestContracts.activity.pageRegionLabel}"]`
    const page = wrapper.get(pageSelector)
    expect(page.attributes("data-testid")).toBe(folioSurfaceTestContracts.activity.pageTestId)
    expect(
      wrapper.find(`[role="feed"][aria-label="${folioSurfaceTestContracts.activity.feedRegionLabel}"]`)
        .exists(),
    ).toBe(true)
    expect(wrapper.find(`[data-testid="${folioActivityRowTestId("event-001")}"]`).exists()).toBe(true)

    const loadingWrapper = mountComponent(ActivityPage, {
      props: {
        workspaceReference: "primary-owner/primary-workspace",
        activityEvents: [],
        selectedActivity: null,
        loading: true,
        error: null,
        refresh: async () => {},
      },
    })

    expect(
      loadingWrapper.find(
        `[data-testid="${folioSurfaceTestContracts.activity.loadingStateTestId}"]`,
      ).exists(),
    ).toBe(true)
  })
})
