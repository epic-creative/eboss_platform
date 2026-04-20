import { nextTick } from "vue"
import { describe, expect, it } from "vitest"

import { mountComponent } from "@/tests/vue/support/mount"
import type { FolioActivityEvent } from "@/vue/shell/workspace/folio/types"
import ActivityPage from "@/vue/shell/workspace/pages/ActivityPage.vue"
import ProjectsPage from "@/vue/shell/workspace/pages/ProjectsPage.vue"
import TasksPage from "@/vue/shell/workspace/pages/TasksPage.vue"
import { folioActivityRowTestId, folioProjectRowTestId, folioSurfaceTestContracts, folioTaskRowTestId } from "@/vue/shell/workspace/testContracts"
import type { Project, Task } from "@/vue/shell/workspace/types"

const noopAsync = async () => {}

const project = (overrides: Partial<Project> = {}): Project => ({
  id: "project-1",
  name: "Atlas Service",
  description: null,
  status: "active",
  dueAt: null,
  reviewAt: null,
  priorityPosition: 1,
  notes: null,
  metadata: {},
  ...overrides,
})

const task = (overrides: Partial<Task> = {}): Task => ({
  id: "task-1",
  title: "Draft rollout notes",
  status: "inbox",
  projectId: "project-1",
  priorityPosition: 1,
  dueAt: null,
  reviewAt: null,
  activeDelegation: null,
  ...overrides,
})

const activity = (overrides: Partial<FolioActivityEvent> = {}): FolioActivityEvent => ({
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
  ...overrides,
})

describe("Folio read-state behavior", () => {
  it("hides the projects inspector when the selected project no longer matches the active filter", async () => {
    const activeProject = project()
    const completedProject = project({
      id: "project-2",
      name: "Nimbus Engine",
      status: "completed",
    })

    const wrapper = mountComponent(ProjectsPage, {
      props: {
        workspaceReference: "primary-owner/primary-workspace",
        projectFilters: ["all", "active", "completed"],
        projectFilter: "all",
        projects: [activeProject, completedProject],
        selectedProject: activeProject,
        loading: false,
        error: null,
        canCreateProject: false,
        canUpdateProject: false,
        canTransitionProject: false,
        creatingProject: false,
        updatingProject: false,
        transitioningProject: false,
        refresh: noopAsync,
        createProject: noopAsync,
        updateProject: noopAsync,
        transitionProject: noopAsync,
      },
    })

    expect(
      wrapper.find(`[data-testid="${folioSurfaceTestContracts.projects.inspectorTestId}"]`).exists(),
    ).toBe(true)

    await wrapper.get("[data-testid=\"projects-filter-completed\"]").trigger("click")
    expect(wrapper.emitted("update:projectFilter")).toEqual([["completed"]])

    await wrapper.setProps({ projectFilter: "completed" })
    await nextTick()

    expect(
      wrapper.find(`[data-testid="${folioSurfaceTestContracts.projects.inspectorTestId}"]`).exists(),
    ).toBe(false)
    expect(wrapper.find(`[data-testid="${folioProjectRowTestId(completedProject.id)}"]`).exists()).toBe(
      true,
    )
  })

  it("prioritizes the projects loading state over stale inspector selections", async () => {
    const selectedProject = project()
    const wrapper = mountComponent(ProjectsPage, {
      props: {
        workspaceReference: "primary-owner/primary-workspace",
        projectFilters: ["all", "active", "completed"],
        projectFilter: "all",
        projects: [selectedProject],
        selectedProject,
        loading: false,
        error: null,
        canCreateProject: false,
        canUpdateProject: false,
        canTransitionProject: false,
        creatingProject: false,
        updatingProject: false,
        transitioningProject: false,
        refresh: noopAsync,
        createProject: noopAsync,
        updateProject: noopAsync,
        transitionProject: noopAsync,
      },
    })

    await wrapper.setProps({ loading: true })
    await nextTick()

    expect(
      wrapper.find(`[data-testid="${folioSurfaceTestContracts.projects.loadingStateTestId}"]`).exists(),
    ).toBe(true)
    expect(
      wrapper.find(`[data-testid="${folioSurfaceTestContracts.projects.inspectorTestId}"]`).exists(),
    ).toBe(false)
  })

  it("hides the tasks inspector after a refresh removes the selected task", async () => {
    const selectedTask = task()
    const retainedTask = task({
      id: "task-2",
      title: "Collect launch metrics",
      status: "next_action",
    })

    const wrapper = mountComponent(TasksPage, {
      props: {
        workspaceReference: "primary-owner/primary-workspace",
        tasks: [selectedTask, retainedTask],
        selectedTask,
        loading: false,
        error: null,
        canCreateTask: false,
        creatingTask: false,
        canTransitionTask: false,
        transitioningTask: false,
        canDelegateTask: false,
        delegatingTask: false,
        projectOptions: [],
        refresh: noopAsync,
        createTask: noopAsync,
        transitionTask: noopAsync,
        delegateTask: noopAsync,
      },
    })

    expect(
      wrapper.find(`[data-testid="${folioSurfaceTestContracts.tasks.inspectorTestId}"]`).exists(),
    ).toBe(true)

    await wrapper.setProps({ tasks: [retainedTask] })
    await nextTick()

    expect(
      wrapper.find(`[data-testid="${folioSurfaceTestContracts.tasks.inspectorTestId}"]`).exists(),
    ).toBe(false)
    expect(wrapper.find(`[data-testid="${folioTaskRowTestId(retainedTask.id)}"]`).exists()).toBe(true)
  })

  it("hides the activity inspector and shows empty state when the selected event disappears", async () => {
    const selectedEvent = activity()
    const retainedEvent = activity({
      id: "event-002",
      provider_event_id: "evt_002",
      summary: "Task handoff updated",
      action: "updated",
      subject: {
        type: "task",
        id: "task-1",
        label: "Draft rollout notes",
      },
    })

    const wrapper = mountComponent(ActivityPage, {
      props: {
        workspaceReference: "primary-owner/primary-workspace",
        activityEvents: [selectedEvent, retainedEvent],
        selectedActivity: selectedEvent,
        loading: false,
        error: null,
        refresh: noopAsync,
      },
    })

    expect(
      wrapper.find(`[data-testid="${folioSurfaceTestContracts.activity.inspectorTestId}"]`).exists(),
    ).toBe(true)
    expect(wrapper.find(`[data-testid="${folioActivityRowTestId(retainedEvent.id)}"]`).exists()).toBe(
      true,
    )

    await wrapper.setProps({ activityEvents: [] })
    await nextTick()

    expect(
      wrapper.find(`[data-testid="${folioSurfaceTestContracts.activity.inspectorTestId}"]`).exists(),
    ).toBe(false)
    expect(
      wrapper.find(`[data-testid="${folioSurfaceTestContracts.activity.emptyStateTestId}"]`).exists(),
    ).toBe(true)
  })
})
