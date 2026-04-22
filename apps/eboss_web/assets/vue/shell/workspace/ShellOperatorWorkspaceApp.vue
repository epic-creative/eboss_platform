<script setup lang="ts">
import { computed, ref, watch } from "vue"
import { Link, useEventReply, useLiveConnection } from "live_vue"
import { Menu, Search } from "lucide-vue-next"

import ThemeToggleButton from "../shared/ThemeToggleButton.vue"
import NotificationBell from "../notifications/NotificationBell.vue"
import WorkspaceSidebar from "./WorkspaceSidebar.vue"
import {
  accessAudit,
  apiKeys,
  overviewEvents,
  members,
  roles,
  postureItems,
} from "./mockData"
import AccessPage from "./pages/AccessPage.vue"
import DashboardPage from "./pages/DashboardPage.vue"
import EmptyWorkspacePage from "./pages/EmptyWorkspacePage.vue"
import MembersPage from "./pages/MembersPage.vue"
import ActivityPage from "./pages/ActivityPage.vue"
import ProjectsPage from "./pages/ProjectsPage.vue"
import TasksPage from "./pages/TasksPage.vue"
import SettingsPage from "./pages/SettingsPage.vue"
import ChatPage from "./ChatPage.vue"
import { workspaceAppTestContracts } from "./testContracts"
import type {
  FolioActivityEvent,
  FolioProjectStatus,
  FolioProjectSummary,
  FolioTaskDelegatePayload,
  FolioProjectUpdatePayload,
  FolioTaskStatus,
  FolioTaskSummary,
} from "./folio/types"
import type {
  AccessAuditRecord,
  AccessTab,
  ApiKeyRecord,
  Project,
  Task,
  ProjectFilter,
  CurrentUser,
  Member,
  RoleRecord,
  SettingsTab,
  WorkspaceApp,
  WorkspaceSurface,
  WorkspaceNavigationContext,
  AppNavigation,
  WorkspaceScope,
} from "./types"
import type { NotificationBootstrap } from "../notifications"
import type { ChatLiveState } from "./chat"

interface FolioLiveState {
  surface: string | null
  projects: FolioProjectSummary[]
  tasks: FolioTaskSummary[]
  events: FolioActivityEvent[]
  projectsLoading: boolean
  tasksLoading: boolean
  activityLoading: boolean
  projectsError: string | null
  tasksError: string | null
  activityError: string | null
}

const props = defineProps<{
  currentUser: CurrentUser
  currentScope: WorkspaceScope
  currentPage: WorkspaceNavigationContext
  currentPath: string
  notificationBootstrap?: NotificationBootstrap
  folioState?: FolioLiveState
  chatState?: ChatLiveState
  signOutPath: string
  csrfToken: string
}>()

const { connectionState, isConnected } = useLiveConnection()

const emptyNotificationBootstrap: NotificationBootstrap = {
  unread_count: 0,
  recent: [],
  preferences: [],
  channels: [],
  supported_channels: ["in_app", "email", "sms", "telegram", "webhook", "push"],
  inactive_external_channels: ["email", "sms", "telegram", "webhook", "push"],
}

const mobileNavOpen = ref(false)
const activeAccessTab = ref<AccessTab>("roles")
const activeSettingsTab = ref<SettingsTab>("general")
const selectedMember = ref<Member | null>(null)
const selectedRole = ref<RoleRecord | null>(null)
const selectedKey = ref<ApiKeyRecord | null>(null)
const selectedAccessAudit = ref<AccessAuditRecord | null>(null)
const selectedProject = ref<Project | null>(null)
const selectedTask = ref<Task | null>(null)
const selectedActivity = ref<FolioActivityEvent | null>(null)
const selectedProjectFilter = ref<ProjectFilter>("all")
const creatingProject = ref(false)
const updatingProject = ref(false)
const transitioningProject = ref(false)
const creatingTask = ref(false)
const transitioningTask = ref(false)
const delegatingTask = ref(false)
const liveFolioState = ref<FolioLiveState>(props.folioState ?? emptyFolioState())
const refreshFolioEvent = useEventReply<FolioLiveReply, Record<string, never>>("folio:refresh")
const createProjectEvent = useEventReply<FolioProjectLiveReply, { title: string }>("folio:create_project")
const updateProjectEvent = useEventReply<FolioProjectLiveReply, FolioProjectUpdatePayload & { project_id: string }>("folio:update_project")
const transitionProjectEvent = useEventReply<FolioProjectLiveReply, { project_id: string; status: FolioProjectStatus }>("folio:transition_project")
const createTaskEvent = useEventReply<FolioTaskLiveReply, { title: string; project_id: string | null }>("folio:create_task")
const transitionTaskEvent = useEventReply<FolioTaskLiveReply, { task_id: string; status: FolioTaskStatus }>("folio:transition_task")
const delegateTaskEvent = useEventReply<FolioTaskLiveReply, FolioTaskDelegatePayload & { task_id: string }>("folio:delegate_task")
const projectFilters = ["all", "active", "on_hold", "completed", "canceled", "archived"] satisfies ProjectFilter[]
const isWorkspaceRoute = computed(() => props.currentPage.type === "workspace")
const isAppRoute = computed(() => props.currentPage.type === "app")

interface FolioProjectLiveReply {
  ok: boolean
  project?: FolioProjectSummary
  folio_state?: FolioLiveState
  error?: string
}

interface FolioTaskLiveReply {
  ok: boolean
  task?: FolioTaskSummary
  folio_state?: FolioLiveState
  error?: string
}

interface FolioLiveReply {
  ok: boolean
  folio_state?: FolioLiveState
  error?: string
}

function emptyFolioState(surface: string | null = null): FolioLiveState {
  return {
    surface,
    projects: [],
    tasks: [],
    events: [],
    projectsLoading: false,
    tasksLoading: false,
    activityLoading: false,
    projectsError: null,
    tasksError: null,
    activityError: null,
  }
}

const applyFolioStateReply = (reply: FolioLiveReply) => {
  if (reply.ok && reply.folio_state) {
    liveFolioState.value = reply.folio_state
  }
}

const upsertFolioProject = (project: FolioProjectSummary) => {
  const projects = liveFolioState.value.projects
  const index = projects.findIndex((candidate) => candidate.id === project.id)

  liveFolioState.value = {
    ...liveFolioState.value,
    projects: index === -1
      ? [...projects, project]
      : projects.map((candidate) => candidate.id === project.id ? project : candidate),
  }
}

const upsertFolioTask = (task: FolioTaskSummary) => {
  const tasks = liveFolioState.value.tasks
  const index = tasks.findIndex((candidate) => candidate.id === task.id)

  liveFolioState.value = {
    ...liveFolioState.value,
    tasks: index === -1
      ? [...tasks, task]
      : tasks.map((candidate) => candidate.id === task.id ? task : candidate),
  }
}

const requireFolioProjectReply = (
  reply: FolioProjectLiveReply,
  fallback: string,
): FolioProjectSummary => {
  applyFolioStateReply(reply)
  if (reply.ok && reply.project) return reply.project

  throw new Error(reply.error || fallback)
}

const requireFolioTaskReply = (
  reply: FolioTaskLiveReply,
  fallback: string,
): FolioTaskSummary => {
  applyFolioStateReply(reply)
  if (reply.ok && reply.task) return reply.task

  throw new Error(reply.error || fallback)
}

const refreshFolioState = async () => {
  applyFolioStateReply(await refreshFolioEvent.execute({}))
}

const mapFolioProjectStatus = (status: string): Project["status"] => {
  if (
    status === "active" ||
    status === "on_hold" ||
    status === "completed" ||
    status === "canceled" ||
    status === "archived"
  ) return status

  return "active"
}

const mapFolioProject = (project: FolioProjectSummary): Project => ({
  id: project.id,
  name: project.title,
  description: project.description,
  status: mapFolioProjectStatus(project.status),
  dueAt: project.due_at,
  reviewAt: project.review_at,
  priorityPosition: project.priority_position,
  notes: project.notes,
  metadata: project.metadata,
})

const currentWorkspace = computed(() => props.currentScope.currentWorkspace)
const workspaceReference = computed(() =>
  currentWorkspace.value ? `${currentWorkspace.value.ownerSlug}/${currentWorkspace.value.slug}` : "No workspace",
)
const currentWorkspaceKey = computed(() =>
  currentWorkspace.value ? `${currentWorkspace.value.ownerSlug}/${currentWorkspace.value.slug}` : "empty",
)
const basePath = computed(() => props.currentScope.dashboardPath || props.currentPath)
const dashboardHref = computed(() => props.currentScope.dashboardPath || "/dashboard")
const avatarInitials = computed(() => props.currentUser.username.slice(0, 2).toUpperCase())
const resolvedNotificationBootstrap = computed(() => props.notificationBootstrap ?? emptyNotificationBootstrap)
const connectionLabel = computed(() => (isConnected.value ? "Live" : connectionState.value))
const isAppNavigation = (page: WorkspaceNavigationContext): page is AppNavigation =>
  page.type === "app"
const currentAppPage = computed<AppNavigation | null>(() =>
  isAppNavigation(props.currentPage) ? props.currentPage : null,
)
const isFolioAppRoute = computed(() => isAppRoute.value && currentAppPage.value?.app_key === "folio")
const isFolioProjectsSurface = computed(
  () => isFolioAppRoute.value && currentAppPage.value?.app_surface === "projects",
)
const isFolioTasksSurface = computed(
  () =>
    isFolioAppRoute.value &&
    (currentAppPage.value?.app_surface === "tasks" || !currentAppPage.value?.app_surface),
)
const isFolioActivitySurface = computed(
  () => isFolioAppRoute.value && currentAppPage.value?.app_surface === "activity",
)
const isChatAppRoute = computed(() => isAppRoute.value && currentAppPage.value?.app_key === "chat")
const shouldLoadFolioProjects = computed(
  () =>
    isFolioProjectsSurface.value ||
    (isFolioTasksSurface.value && props.currentScope.capabilities.manageFolio),
)
const folioProjects = computed(() =>
  shouldLoadFolioProjects.value ? liveFolioState.value.projects.map(mapFolioProject) : [],
)
const taskProjectOptions = computed(() =>
  folioProjects.value.map((project) => ({ id: project.id, title: project.name })),
)

const createWorkspaceProject = async (title: string): Promise<void> => {
  if (!props.currentScope.capabilities.manageFolio) {
    throw new Error("You do not have permission to create projects in this workspace.")
  }

  if (creatingProject.value) return

  creatingProject.value = true

  try {
    const project = requireFolioProjectReply(
      await createProjectEvent.execute({ title }),
      "Project creation failed.",
    )

    selectedProjectFilter.value = "all"
    upsertFolioProject(project)
    selectedProject.value = mapFolioProject(project)
  } finally {
    creatingProject.value = false
  }
}

const updateWorkspaceProject = async (
  projectId: string,
  payload: FolioProjectUpdatePayload,
): Promise<void> => {
  if (!props.currentScope.capabilities.manageFolio) {
    throw new Error("You do not have permission to edit projects in this workspace.")
  }

  if (updatingProject.value) return

  updatingProject.value = true

  try {
    const project = requireFolioProjectReply(
      await updateProjectEvent.execute({ project_id: projectId, ...payload }),
      "Project details could not be saved.",
    )

    selectedProjectFilter.value = "all"
    upsertFolioProject(project)
    selectedProject.value = mapFolioProject(project)
  } finally {
    updatingProject.value = false
  }
}

const transitionWorkspaceProject = async (
  projectId: string,
  status: FolioProjectStatus,
): Promise<void> => {
  if (!props.currentScope.capabilities.manageFolio) {
    throw new Error("You do not have permission to transition projects in this workspace.")
  }

  if (transitioningProject.value) return

  transitioningProject.value = true

  try {
    const project = requireFolioProjectReply(
      await transitionProjectEvent.execute({ project_id: projectId, status }),
      "Project transition failed.",
    )

    upsertFolioProject(project)
    selectedProject.value = mapFolioProject(project)
  } finally {
    transitioningProject.value = false
  }
}

const mapFolioTaskDelegation = (
  delegation: FolioTaskSummary["active_delegation"],
): Task["activeDelegation"] => {
  if (!delegation) return null

  return {
    id: delegation.id,
    status: delegation.status,
    delegatedAt: delegation.delegated_at,
    delegatedSummary: delegation.delegated_summary,
    qualityExpectations: delegation.quality_expectations,
    deadlineExpectationsAt: delegation.deadline_expectations_at,
    followUpAt: delegation.follow_up_at,
    contact: {
      id: delegation.contact.id,
      name: delegation.contact.name,
      email: delegation.contact.email,
    },
  }
}

const mapFolioTask = (task: FolioTaskSummary): Task => ({
  id: task.id,
  title: task.title,
  status: task.status,
  projectId: task.project_id,
  priorityPosition: task.priority_position,
  dueAt: task.due_at,
  reviewAt: task.review_at,
  activeDelegation: mapFolioTaskDelegation(task.active_delegation),
})
const folioTasks = computed(() =>
  isFolioTasksSurface.value ? liveFolioState.value.tasks.map(mapFolioTask) : [],
)
const createWorkspaceTask = async (title: string, projectId: string | null): Promise<void> => {
  if (!props.currentScope.capabilities.manageFolio) {
    throw new Error("You do not have permission to create tasks in this workspace.")
  }

  if (creatingTask.value) return

  creatingTask.value = true

  try {
    const task = requireFolioTaskReply(
      await createTaskEvent.execute({
        title,
        project_id: projectId,
      }),
      "Task creation failed.",
    )

    upsertFolioTask(task)
    selectedTask.value = mapFolioTask(task)
  } finally {
    creatingTask.value = false
  }
}

const transitionWorkspaceTask = async (taskId: string, status: FolioTaskStatus): Promise<void> => {
  if (!props.currentScope.capabilities.manageFolio) {
    throw new Error("You do not have permission to transition tasks in this workspace.")
  }

  if (transitioningTask.value) return

  transitioningTask.value = true

  try {
    const task = requireFolioTaskReply(
      await transitionTaskEvent.execute({ task_id: taskId, status }),
      "Task transition failed.",
    )

    upsertFolioTask(task)
    selectedTask.value = mapFolioTask(task)
  } finally {
    transitioningTask.value = false
  }
}

const delegateWorkspaceTask = async (
  taskId: string,
  payload: FolioTaskDelegatePayload,
): Promise<void> => {
  if (!props.currentScope.capabilities.manageFolio) {
    throw new Error("You do not have permission to delegate tasks in this workspace.")
  }

  if (delegatingTask.value) return

  delegatingTask.value = true

  try {
    const task = requireFolioTaskReply(
      await delegateTaskEvent.execute({ task_id: taskId, ...payload }),
      "Task delegation failed.",
    )

    upsertFolioTask(task)
    selectedTask.value = mapFolioTask(task)
  } finally {
    delegatingTask.value = false
  }
}

const folioActivities = computed(() =>
  isFolioActivitySurface.value ? liveFolioState.value.events : [],
)
const activeWorkspaceSurface = computed(() =>
  isWorkspaceRoute.value && props.currentPage.type === "workspace" ? props.currentPage.surface : "dashboard"
)
const currentWorkspaceApp = computed<WorkspaceApp | null>(() => {
  if (!currentAppPage.value) {
    return null
  }

  return props.currentScope.apps?.[currentAppPage.value.app_key] || null
})
const appSurfaceLabel = computed(() =>
  currentAppPage.value && currentAppPage.value.app_surface
    ? currentAppPage.value.app_surface
    : "tasks",
)
const appSurfaceTitle = computed(() =>
  appSurfaceLabel.value
    .split("-")
    .map((segment: string) => `${segment[0].toUpperCase()}${segment.slice(1)}`)
    .join(" "),
)

const isWorkspacePage = (surface: WorkspaceSurface) =>
  isWorkspaceRoute.value && activeWorkspaceSurface.value === surface

const clearInspectors = () => {
  selectedMember.value = null
  selectedRole.value = null
  selectedKey.value = null
  selectedAccessAudit.value = null
  selectedProject.value = null
  selectedTask.value = null
  selectedActivity.value = null
}

const resetWorkspaceState = () => {
  clearInspectors()
  activeAccessTab.value = "roles"
  activeSettingsTab.value = "general"
  selectedProjectFilter.value = "all"
}

watch(() => props.currentPage, () => {
  mobileNavOpen.value = false
  clearInspectors()
})

watch(currentWorkspaceKey, () => {
  mobileNavOpen.value = false
  resetWorkspaceState()
})

watch(() => props.folioState, (nextState) => {
  liveFolioState.value = nextState ?? emptyFolioState()
}, { deep: true })

</script>

<template>
  <div
    class="so-theme flex min-h-screen bg-[hsl(var(--so-background))] text-[hsl(var(--so-foreground))]"
    role="region"
    :aria-label="workspaceAppTestContracts.shellRegionLabel"
    :data-testid="workspaceAppTestContracts.shellTestId"
  >
    <aside
      class="hidden h-screen w-[208px] shrink-0 overflow-y-auto border-r border-[hsl(var(--so-border))] bg-[hsl(var(--so-surface-1))] md:flex md:sticky md:top-0"
    >
      <WorkspaceSidebar
        :current-user="currentUser"
        :current-scope="currentScope"
        :current-page="currentPage"
        :base-path="basePath"
      />
    </aside>

    <div class="flex h-screen min-w-0 flex-1 flex-col">
      <header class="shrink-0 border-b border-[hsl(var(--so-border))] bg-[hsl(var(--so-surface-1))]">
        <div class="flex h-11 items-center gap-3 px-3">
          <div class="md:hidden">
            <button type="button" class="so-icon-button" @click="mobileNavOpen = !mobileNavOpen">
              <Menu class="h-4 w-4" />
            </button>
          </div>

          <a href="/" class="flex shrink-0 items-center gap-2 md:hidden">
            <div class="flex h-6 w-6 items-center justify-center rounded bg-[hsl(var(--so-foreground))]">
              <span class="so-font-mono text-[10px] font-bold text-[hsl(var(--so-background))]">E</span>
            </div>
          </a>

        <div class="max-w-md flex-1">
          <div class="relative">
              <Search
                class="pointer-events-none absolute left-2.5 top-1/2 h-3.5 w-3.5 -translate-y-1/2 text-[hsl(var(--so-muted-foreground))]"
              />
              <input placeholder="Search or jump to..." class="so-input-field h-7 pl-8 pr-10 text-xs" />
              <kbd
                class="so-font-mono absolute right-2 top-1/2 -translate-y-1/2 rounded border border-[hsl(var(--so-border))] px-1 text-[10px] text-[hsl(var(--so-muted-foreground))]"
              >
                ⌘K
              </kbd>
            </div>
          </div>

        <div class="ml-auto flex items-center gap-1">
          <span
            v-if="isAppRoute"
            class="hidden items-center gap-2 rounded-md border border-[hsl(var(--so-border))] px-2 py-1 text-xs text-[hsl(var(--so-muted-foreground))] sm:flex"
            role="status"
            :aria-label="workspaceAppTestContracts.currentAppStatusLabel"
            :data-testid="workspaceAppTestContracts.currentAppTestId"
          >
            <span class="so-font-mono">App</span>
            <span class="font-medium text-[hsl(var(--so-foreground))]">
              {{ currentWorkspaceApp?.label ?? currentAppPage?.app_key }}
            </span>
            <span class="hidden text-[hsl(var(--so-muted-foreground))] lg:inline">
              · {{ appSurfaceTitle }}
            </span>
          </span>

          <span
            class="hidden items-center gap-1.5 rounded-md border border-[hsl(var(--so-border))] px-2 py-1 text-xs text-[hsl(var(--so-muted-foreground))] lg:flex"
            role="status"
            aria-label="LiveView connection status"
          >
            <span
              class="h-1.5 w-1.5 rounded-full"
              :class="isConnected ? 'bg-[hsl(var(--so-success))]' : 'bg-[hsl(var(--so-warning))]'"
            />
            <span class="so-font-mono">{{ connectionLabel }}</span>
          </span>

          <ThemeToggleButton />

            <NotificationBell :bootstrap="resolvedNotificationBootstrap" />

            <details class="so-avatar-menu relative">
              <summary
                class="flex h-7 w-7 cursor-pointer items-center justify-center rounded-full border border-[hsl(var(--so-border))] bg-[hsl(var(--so-surface-2))] text-[10px] font-medium"
                aria-label="Account menu"
                data-testid="workspace-avatar-menu-trigger"
              >
                {{ avatarInitials }}
              </summary>

              <div
                class="so-fade-in absolute right-0 top-[calc(100%+0.5rem)] z-30 w-56 rounded-md border border-[hsl(var(--so-border))] bg-[hsl(var(--so-card))] p-2 shadow-lg"
              >
                <div class="border-b border-[hsl(var(--so-border))] px-2 pb-2">
                  <p class="text-sm font-medium">{{ currentUser.username }}</p>
                  <p class="text-xs text-[hsl(var(--so-muted-foreground))]">{{ currentUser.email }}</p>
                </div>

                <div class="space-y-1 px-1 py-2">
                  <Link
                    :patch="dashboardHref"
                    data-testid="workspace-avatar-dashboard-link"
                    class="block rounded-md px-2 py-1.5 text-sm text-[hsl(var(--so-muted-foreground))] transition-colors hover:bg-[hsl(var(--so-accent))/0.5] hover:text-[hsl(var(--so-foreground))]"
                  >
                    Dashboard
                  </Link>
                </div>

                <form :action="signOutPath" method="post" class="border-t border-[hsl(var(--so-border))] pt-2">
                  <input type="hidden" name="_method" value="delete" />
                  <input type="hidden" name="_csrf_token" :value="csrfToken" />
                  <button
                    type="submit"
                    class="so-button-secondary w-full justify-start"
                    data-testid="workspace-sign-out"
                  >
                    Sign out
                  </button>
                </form>
              </div>
            </details>
          </div>
        </div>
      </header>

      <main class="flex-1 overflow-y-auto">
        <div class="max-w-[1400px] p-5 lg:p-6">
          <div v-if="currentWorkspace" class="so-fade-in">
            <DashboardPage
              v-if="isWorkspacePage('dashboard')"
              :workspace-reference="workspaceReference"
              :posture-items="postureItems"
              :overview-events="overviewEvents"
            />

            <MembersPage
              v-else-if="isWorkspacePage('members')"
              :workspace-reference="workspaceReference"
              :members="members"
              :selected-member="selectedMember"
              @update:selected-member="selectedMember = $event"
            />

            <AccessPage
              v-else-if="isWorkspacePage('access')"
              :workspace-reference="workspaceReference"
              :active-access-tab="activeAccessTab"
              :roles="roles"
              :selected-role="selectedRole"
              :api-keys="apiKeys"
              :selected-key="selectedKey"
              :access-audit="accessAudit"
              :selected-access-audit="selectedAccessAudit"
              @update:active-access-tab="activeAccessTab = $event"
              @update:selected-role="selectedRole = $event"
              @update:selected-key="selectedKey = $event"
              @update:selected-access-audit="selectedAccessAudit = $event"
            />

            <SettingsPage
              v-else-if="isWorkspacePage('settings')"
              :workspace-reference="workspaceReference"
              :active-settings-tab="activeSettingsTab"
              :current-workspace="currentWorkspace"
              @update:active-settings-tab="activeSettingsTab = $event"
            />

            <ProjectsPage
              v-else-if="isFolioProjectsSurface"
              :workspace-reference="workspaceReference"
              :project-filters="projectFilters"
              :project-filter="selectedProjectFilter"
              :projects="folioProjects"
              :selected-project="selectedProject"
              :loading="liveFolioState.projectsLoading"
              :error="liveFolioState.projectsError"
              :can-create-project="currentScope.capabilities.manageFolio"
              :can-update-project="currentScope.capabilities.manageFolio"
              :creating-project="creatingProject"
              :updating-project="updatingProject"
              :can-transition-project="currentScope.capabilities.manageFolio"
              :transitioning-project="transitioningProject"
              :refresh="refreshFolioState"
              :create-project="createWorkspaceProject"
              :update-project="updateWorkspaceProject"
              :transition-project="transitionWorkspaceProject"
              @update:project-filter="selectedProjectFilter = $event"
              @update:selected-project="selectedProject = $event"
            />
            <TasksPage
              v-else-if="isFolioTasksSurface"
              :workspace-reference="workspaceReference"
              :tasks="folioTasks"
              :selected-task="selectedTask"
              :loading="liveFolioState.tasksLoading"
              :error="liveFolioState.tasksError"
              :can-create-task="currentScope.capabilities.manageFolio"
              :creating-task="creatingTask"
              :can-transition-task="currentScope.capabilities.manageFolio"
              :transitioning-task="transitioningTask"
              :can-delegate-task="currentScope.capabilities.manageFolio"
              :delegating-task="delegatingTask"
              :project-options="taskProjectOptions"
              :refresh="refreshFolioState"
              :create-task="createWorkspaceTask"
              :transition-task="transitionWorkspaceTask"
              :delegate-task="delegateWorkspaceTask"
              @update:selected-task="selectedTask = $event"
            />
            <ActivityPage
              v-else-if="isFolioActivitySurface"
              :workspace-reference="workspaceReference"
              :activity-events="folioActivities"
              :selected-activity="selectedActivity"
              :loading="liveFolioState.activityLoading"
              :error="liveFolioState.activityError"
              :refresh="refreshFolioState"
              @update:selected-activity="selectedActivity = $event"
            />
            <ChatPage
              v-else-if="isChatAppRoute && currentAppPage"
              :current-scope="currentScope"
              :current-page="currentAppPage"
              :chat-state="chatState"
            />

            <div
              v-else-if="isAppRoute"
              class="rounded-md border border-[hsl(var(--so-border))] bg-[hsl(var(--so-surface-2))] p-4"
            >
              <p class="so-font-mono text-[11px] uppercase tracking-wider text-[hsl(var(--so-muted-foreground))]">
                App surface
              </p>
              <p class="mt-1 text-sm font-medium">
                {{ currentWorkspaceApp?.label ?? currentAppPage?.app_key }}
              </p>
              <p class="mt-2 text-sm text-[hsl(var(--so-muted-foreground))]">
                Surface: {{ appSurfaceTitle }}
              </p>
            </div>
          </div>

          <EmptyWorkspacePage
            v-else
            :dashboard-path="currentScope.dashboardPath || '/dashboard'"
          />
        </div>
      </main>
    </div>

    <template v-if="mobileNavOpen">
      <div class="fixed inset-0 z-40 bg-black/30 backdrop-blur-sm md:hidden" @click="mobileNavOpen = false" />
      <div
        class="so-fade-in fixed inset-y-0 left-0 z-50 flex w-[280px] flex-col overflow-y-auto border-r border-[hsl(var(--so-border))] bg-[hsl(var(--so-surface-1))] md:hidden"
      >
        <div class="flex items-center justify-between border-b border-[hsl(var(--so-border))] px-3 py-2.5">
          <a href="/" class="flex items-center gap-2">
            <div class="flex h-6 w-6 items-center justify-center rounded bg-[hsl(var(--so-foreground))]">
              <span class="so-font-mono text-[10px] font-bold text-[hsl(var(--so-background))]">E</span>
            </div>
            <span class="text-sm font-semibold">EBoss</span>
          </a>
          <button type="button" class="so-icon-button" @click="mobileNavOpen = false">×</button>
        </div>

        <WorkspaceSidebar
          :current-user="currentUser"
          :current-scope="currentScope"
          :current-page="currentPage"
          :base-path="basePath"
          @navigate="mobileNavOpen = false"
        />
      </div>
    </template>
  </div>
</template>
