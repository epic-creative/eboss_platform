<script setup lang="ts">
import { computed, ref, watch } from "vue"
import { AlertTriangle, CheckCircle2, LoaderCircle, Plus, Search, Star, UserRound } from "lucide-vue-next"

import InspectorField from "../InspectorField.vue"
import InspectorPane from "../InspectorPane.vue"
import InspectorSection from "../InspectorSection.vue"
import WorkspaceEmptyState from "../WorkspaceEmptyState.vue"
import WorkspacePageHeader from "../WorkspacePageHeader.vue"
import WorkspacePanel from "../WorkspacePanel.vue"
import type { Task } from "../types"
import { formatFolioDate, statusLabel, taskStatusClass } from "../presenters"

interface TaskProjectOption {
  id: string
  title: string
}

const props = defineProps<{
  workspaceReference: string
  tasks: Task[]
  selectedTask: Task | null
  loading: boolean
  error: string | null
  canCreateTask: boolean
  creatingTask: boolean
  canTransitionTask: boolean
  transitioningTask: boolean
  canDelegateTask: boolean
  delegatingTask: boolean
  projectOptions: TaskProjectOption[]
  refresh: () => Promise<void>
  createTask: (title: string, projectId: string | null) => Promise<void>
  transitionTask: (taskId: string, status: Task["status"]) => Promise<void>
  delegateTask: (
    taskId: string,
    payload: {
      intent: "delegate"
      contact_name?: string
      contact_id?: string
      delegated_summary: string
      quality_expectations?: string | null
      deadline_expectations_at?: string | null
      follow_up_at?: string | null
    },
  ) => Promise<void>
}>()

const emit = defineEmits<{
  "update:selectedTask": [value: Task | null]
}>()

const statusFilters = [
  "all",
  "inbox",
  "next_action",
  "waiting_for",
  "scheduled",
  "someday_maybe",
  "done",
  "canceled",
  "archived",
] as const
type StatusFilter = (typeof statusFilters)[number]

const selectedTaskFilter = ref<StatusFilter>("all")
const searchQuery = ref("")
const createFormOpen = ref(false)
const createTaskTitle = ref("")
const createTaskProjectId = ref("")
const createTaskError = ref<string | null>(null)
const transitionStatus = ref<Task["status"]>("inbox")
const transitionError = ref<string | null>(null)
const delegationContactName = ref("")
const delegatedSummary = ref("")
const delegationQualityExpectations = ref("")
const delegationFollowUpAt = ref("")
const delegationDeadlineAt = ref("")
const delegationError = ref<string | null>(null)

const activeDelegation = computed(() => props.selectedTask?.activeDelegation ?? null)
const hasActiveDelegation = computed(
  () => activeDelegation.value !== null && activeDelegation.value.status === "active",
)

const taskQuery = computed(() => {
  const search = searchQuery.value.trim().toLowerCase()

  return props.tasks.filter(task => {
    const matchesStatus =
      selectedTaskFilter.value === "all" || task.status === selectedTaskFilter.value

    if (!matchesStatus) return false
    if (!search) return true

    return task.title.toLowerCase().includes(search) || task.projectId?.toLowerCase().includes(search)
  })
})

const selectedTaskBucket = (task: Task) =>
  task.status === "done"
    ? "done"
    : task.status === "archived" || task.status === "canceled"
      ? "closed"
      : "open"

const toggleTask = (task: Task) => {
  emit("update:selectedTask", props.selectedTask?.id === task.id ? null : task)
}

const canInspectTask = computed(
  () =>
    !props.loading &&
    props.error === null &&
    !!props.selectedTask &&
    taskQuery.value.some((task) => task.id === props.selectedTask?.id),
)

const sortTasks = computed(() =>
  [...taskQuery.value].sort((left, right) => {
    const leftStatus = selectedTaskBucket(left)
    const rightStatus = selectedTaskBucket(right)

    if (leftStatus !== rightStatus) {
      return leftStatus.localeCompare(rightStatus)
    }

    const leftDate = left.dueAt ? new Date(left.dueAt).valueOf() : Number.POSITIVE_INFINITY
    const rightDate = right.dueAt ? new Date(right.dueAt).valueOf() : Number.POSITIVE_INFINITY

    if (leftDate !== rightDate) return leftDate - rightDate
    return left.title.localeCompare(right.title)
  }),
)

const openCreateTaskForm = () => {
  if (!props.canCreateTask) return

  createTaskError.value = null
  createFormOpen.value = true
}

const closeCreateTaskForm = () => {
  createTaskTitle.value = ""
  createTaskProjectId.value = ""
  createTaskError.value = null
  createFormOpen.value = false
}

const normalizedProjectId = (): string | null => {
  const projectId = createTaskProjectId.value.trim()
  return projectId === "" ? null : projectId
}

const submitCreateTask = async () => {
  if (!props.canCreateTask || props.creatingTask) return

  const title = createTaskTitle.value.trim()

  if (!title) {
    createTaskError.value = "Task title is required."
    return
  }

  createTaskError.value = null

  try {
    await props.createTask(title, normalizedProjectId())
    closeCreateTaskForm()
  } catch (cause) {
    createTaskError.value = cause instanceof Error ? cause.message : "Task creation failed."
  }
}

watch(
  () => [props.selectedTask?.id, props.selectedTask?.status] as const,
  () => {
    transitionError.value = null
    transitionStatus.value = props.selectedTask?.status ?? "inbox"
    delegationError.value = null
    delegationContactName.value = activeDelegation.value?.contact.name ?? ""
    delegatedSummary.value = activeDelegation.value?.delegatedSummary ?? ""
    delegationQualityExpectations.value = activeDelegation.value?.qualityExpectations ?? ""
    delegationFollowUpAt.value = toDateInputValue(activeDelegation.value?.followUpAt ?? null)
    delegationDeadlineAt.value = toDateInputValue(activeDelegation.value?.deadlineExpectationsAt ?? null)
  },
  { immediate: true },
)

const submitTransitionTask = async () => {
  if (!props.selectedTask || !props.canTransitionTask || props.transitioningTask) return

  transitionError.value = null

  try {
    await props.transitionTask(props.selectedTask.id, transitionStatus.value)
  } catch (cause) {
    transitionError.value = cause instanceof Error ? cause.message : "Task transition failed."
  }
}

function toDateInputValue(value: string | null): string {
  if (!value) return ""

  const prefix = value.match(/^(\d{4}-\d{2}-\d{2})/)
  if (prefix) return prefix[1]

  const parsed = new Date(value)
  return Number.isNaN(parsed.valueOf()) ? "" : parsed.toISOString().slice(0, 10)
}

const optionalText = (value: string): string | null => {
  const trimmed = value.trim()
  return trimmed === "" ? null : trimmed
}

const optionalDate = (value: string): string | null => {
  const trimmed = value.trim()
  return trimmed === "" ? null : trimmed
}

const delegationContactLabel = (task: Task): string | null =>
  task.activeDelegation?.contact.name || task.activeDelegation?.contact.id || null

const submitDelegateTask = async () => {
  if (!props.selectedTask || !props.canDelegateTask || props.delegatingTask) return

  if (hasActiveDelegation.value) {
    delegationError.value = "This task already has an active delegation."
    return
  }

  const contactName = delegationContactName.value.trim()
  const summary = delegatedSummary.value.trim()

  if (!contactName) {
    delegationError.value = "Contact name is required."
    return
  }

  if (!summary) {
    delegationError.value = "Delegated summary is required."
    return
  }

  delegationError.value = null

  try {
    await props.delegateTask(props.selectedTask.id, {
      intent: "delegate",
      contact_name: contactName,
      delegated_summary: summary,
      quality_expectations: optionalText(delegationQualityExpectations.value),
      follow_up_at: optionalDate(delegationFollowUpAt.value),
      deadline_expectations_at: optionalDate(delegationDeadlineAt.value),
    })
  } catch (cause) {
    delegationError.value = cause instanceof Error ? cause.message : "Task delegation failed."
  }
}
</script>

<template>
  <div class="ui-workspace-page" data-testid="workspace-page-tasks">
    <WorkspacePageHeader title="Tasks" :subtitle="workspaceReference">
      <template #actions>
        <button
          v-if="canCreateTask"
          type="button"
          class="so-button-primary"
          data-testid="tasks-create-open"
          @click="openCreateTaskForm"
        >
          <Plus class="h-3 w-3" />
          New task
        </button>
      </template>
    </WorkspacePageHeader>

    <div class="flex items-center gap-2">
      <div class="relative max-w-xs flex-1">
        <Search
          class="pointer-events-none absolute left-2.5 top-1/2 h-3.5 w-3.5 -translate-y-1/2 text-[hsl(var(--so-muted-foreground))]"
        />
        <input
          v-model="searchQuery"
          placeholder="Filter tasks..."
          class="so-input-field pl-8"
          type="text"
        />
      </div>

      <div class="flex items-center gap-1 rounded-md border border-[hsl(var(--so-border))] p-0.5">
        <button
          v-for="filter in statusFilters"
          :key="filter"
          type="button"
          class="rounded px-2.5 py-1 text-xs capitalize transition-colors"
          :class="
            selectedTaskFilter === filter
              ? 'bg-[hsl(var(--so-accent))] font-medium text-[hsl(var(--so-foreground))]'
              : 'text-[hsl(var(--so-muted-foreground))] hover:text-[hsl(var(--so-foreground))]'
          "
          @click="selectedTaskFilter = filter"
        >
          {{ filter }}
        </button>
      </div>
    </div>

    <WorkspacePanel
      v-if="createFormOpen"
      title="Create task"
      subtitle="Capture a standalone task or link it to a project."
      data-testid="tasks-create-form"
    >
      <form class="space-y-3" data-testid="tasks-create-form-element" @submit.prevent="submitCreateTask">
        <div class="space-y-1">
          <label
            for="folio-task-title"
            class="so-font-mono text-[11px] uppercase tracking-[0.06em] text-[hsl(var(--so-muted-foreground))]"
          >
            Task title
          </label>
          <input
            id="folio-task-title"
            v-model="createTaskTitle"
            class="so-input-field"
            type="text"
            autocomplete="off"
            placeholder="Example: Draft rollout notes"
            data-testid="tasks-create-title-input"
            :disabled="creatingTask"
            @input="createTaskError = null"
          />
        </div>

        <div class="space-y-1">
          <label
            for="folio-task-project"
            class="so-font-mono text-[11px] uppercase tracking-[0.06em] text-[hsl(var(--so-muted-foreground))]"
          >
            Project (optional)
          </label>
          <select
            id="folio-task-project"
            v-model="createTaskProjectId"
            class="so-input-field"
            data-testid="tasks-create-project-select"
            :disabled="creatingTask"
            @change="createTaskError = null"
          >
            <option value="">Unassigned</option>
            <option v-for="project in projectOptions" :key="project.id" :value="project.id">
              {{ project.title }}
            </option>
          </select>
        </div>

        <div
          v-if="createTaskError"
          class="so-alert-panel so-alert-panel-error"
          data-testid="tasks-create-error"
        >
          <p class="text-xs text-[hsl(var(--so-destructive))]">{{ createTaskError }}</p>
        </div>

        <div class="flex flex-wrap items-center justify-end gap-2">
          <button
            type="button"
            class="so-button-secondary"
            :disabled="creatingTask"
            data-testid="tasks-create-cancel"
            @click="closeCreateTaskForm"
          >
            Cancel
          </button>

          <button
            type="submit"
            class="so-button-primary"
            :disabled="creatingTask"
            data-testid="tasks-create-submit"
          >
            <LoaderCircle v-if="creatingTask" class="h-3 w-3 animate-spin" />
            <Plus v-else class="h-3 w-3" />
            {{ creatingTask ? "Creating..." : "Create task" }}
          </button>
        </div>
      </form>
    </WorkspacePanel>

    <div class="flex gap-0">
      <div
        class="min-w-0 flex-1 rounded-md border border-[hsl(var(--so-border))] bg-[hsl(var(--so-card))]"
        :class="selectedTask ? 'rounded-r-none border-r-0' : ''"
      >
        <div class="so-font-mono flex items-center gap-4 border-b border-[hsl(var(--so-border))] px-4 py-2 text-[11px] text-[hsl(var(--so-muted-foreground))]">
          <span class="flex-1">Task</span>
          <span class="hidden w-20 text-center sm:block">Status</span>
          <span class="hidden w-28 text-right md:block">Project</span>
          <span class="hidden w-20 text-right lg:block">Due</span>
          <span class="w-16 hidden text-center lg:block">Priority</span>
        </div>

        <WorkspaceEmptyState
          v-if="loading"
          :icon="LoaderCircle"
          title="Loading tasks"
          copy="Updating the task list from Folio."
          data-testid="tasks-state-loading"
        />

        <div
          v-else-if="error"
          class="so-alert-panel so-alert-panel-error m-4"
          data-testid="tasks-state-error"
        >
          <div class="mb-2 flex items-center gap-2">
            <AlertTriangle class="h-4 w-4 text-[hsl(var(--so-destructive))]" />
            <h3 class="text-sm font-medium text-[hsl(var(--so-destructive))]">Unable to load tasks</h3>
          </div>
          <p class="mb-3 text-xs text-[hsl(var(--so-muted-foreground))]">{{ error }}</p>
          <button type="button" class="so-button-secondary text-[hsl(var(--so-destructive))]" @click="refresh">
            Retry
          </button>
        </div>

        <WorkspaceEmptyState
          v-else-if="!tasks.length"
          title="No tasks yet"
          copy="No Folio tasks have been created for this workspace yet."
          data-testid="tasks-state-empty"
        />

        <div
          v-else-if="!sortTasks.length"
          class="so-font-mono px-4 py-8 text-center text-sm text-[hsl(var(--so-muted-foreground))]"
          data-testid="tasks-state-empty-filtered"
        >
          No tasks match this view.
        </div>

        <div v-else class="divide-y divide-[hsl(var(--so-border))]">
          <button
            v-for="task in sortTasks"
            :key="task.id"
            type="button"
            class="flex w-full items-center gap-4 px-4 py-3 text-left transition-colors"
            :class="selectedTask?.id === task.id ? 'so-row-selected' : 'hover:bg-[hsl(var(--so-accent))/0.3]'"
            :data-testid="`task-row-${task.id}`"
            @click="toggleTask(task)"
          >
            <div class="min-w-0 flex-1">
              <div class="flex items-center gap-2">
                <CheckCircle2
                  class="h-3.5 w-3.5 shrink-0"
                  :class="taskStatusClass(task.status)"
                />
                <span class="truncate text-sm font-medium">{{ task.title }}</span>
                <span class="so-font-mono hidden text-[11px] text-[hsl(var(--so-muted-foreground))] sm:inline">
                  {{ task.id }}
                </span>
                <span
                  v-if="task.activeDelegation"
                  class="so-font-mono hidden rounded border border-[hsl(var(--so-warning))/0.4] bg-[hsl(var(--so-warning))/0.1] px-1.5 py-0.5 text-[10px] text-[hsl(var(--so-warning))] lg:inline"
                >
                  Waiting on {{ delegationContactLabel(task) || "Contact" }}
                </span>
              </div>
            </div>

            <span
              class="so-font-mono hidden w-20 text-center text-[11px] sm:block"
              :class="taskStatusClass(task.status)"
            >
              {{ statusLabel(task.status) }}
            </span>

            <span class="so-font-mono hidden w-28 shrink-0 truncate text-right text-[11px] text-[hsl(var(--so-muted-foreground))] md:block">
              {{ task.projectId || "Unassigned" }}
            </span>

            <span class="so-font-mono hidden w-20 shrink-0 text-right text-[11px] text-[hsl(var(--so-muted-foreground))] lg:block">
              {{ formatFolioDate(task.dueAt) }}
            </span>

            <span class="so-font-mono hidden w-16 text-center text-[11px] text-[hsl(var(--so-muted-foreground))] lg:block">
              {{ task.priorityPosition ?? "—" }}
            </span>
          </button>
        </div>

        <div
          v-if="sortTasks.length"
          class="so-font-mono border-t border-[hsl(var(--so-border))] px-4 py-2 text-[11px] text-[hsl(var(--so-muted-foreground))]"
        >
          {{ sortTasks.length }} task<span v-if="sortTasks.length !== 1">s</span>
        </div>
      </div>

      <InspectorPane
        :open="canInspectTask"
        :title="selectedTask?.title || ''"
        :subtitle="selectedTask?.id"
        data-testid="task-inspector"
        @close="emit('update:selectedTask', null)"
      >
        <template #actions>
          <button type="button" class="so-icon-button">
            <Star class="h-3 w-3" />
          </button>
        </template>

        <div v-if="selectedTask" class="space-y-4">
          <InspectorSection title="Status">
            <InspectorField label="Current status" :valueClass="taskStatusClass(selectedTask.status)">
              <span class="flex items-center gap-1.5">
                <span class="h-1.5 w-1.5 rounded-full bg-current" />
                {{ statusLabel(selectedTask.status) }}
              </span>
            </InspectorField>
            <InspectorField label="Task ID" :value="selectedTask.id" mono />

            <div v-if="canTransitionTask" class="space-y-2">
              <label
                for="folio-task-transition-status"
                class="so-font-mono text-[11px] uppercase tracking-[0.06em] text-[hsl(var(--so-muted-foreground))]"
              >
                Move to
              </label>
              <div class="flex items-center gap-2">
                <select
                  id="folio-task-transition-status"
                  v-model="transitionStatus"
                  class="so-input-field h-8"
                  data-testid="tasks-transition-status-select"
                  :disabled="transitioningTask"
                >
                  <option value="inbox">Inbox</option>
                  <option value="next_action">Next Action</option>
                  <option value="waiting_for">Waiting For</option>
                  <option value="scheduled">Scheduled</option>
                  <option value="someday_maybe">Someday Maybe</option>
                  <option value="done">Done</option>
                  <option value="canceled">Canceled</option>
                  <option value="archived">Archived</option>
                </select>
                <button
                  type="button"
                  class="so-button-primary h-8"
                  data-testid="tasks-transition-submit"
                  :disabled="transitioningTask"
                  @click="submitTransitionTask"
                >
                  <LoaderCircle v-if="transitioningTask" class="h-3 w-3 animate-spin" />
                  <span>{{ transitioningTask ? "Updating..." : "Apply" }}</span>
                </button>
              </div>
              <div
                v-if="transitionError"
                class="so-alert-panel so-alert-panel-error"
                data-testid="tasks-transition-error"
              >
                <p class="text-xs text-[hsl(var(--so-destructive))]">{{ transitionError }}</p>
              </div>
            </div>
          </InspectorSection>

          <InspectorSection title="Delegation" with-divider>
            <div v-if="activeDelegation" class="space-y-2">
              <InspectorField
                label="Contact"
                :value="activeDelegation.contact.name || activeDelegation.contact.id"
              />
              <InspectorField label="Delegated work" :value="activeDelegation.delegatedSummary" />
              <InspectorField
                label="Follow up"
                :value="formatFolioDate(activeDelegation.followUpAt)"
                mono
              />
              <InspectorField
                label="Deadline"
                :value="formatFolioDate(activeDelegation.deadlineExpectationsAt)"
                mono
              />
            </div>

            <div v-if="canDelegateTask" class="space-y-2.5">
              <p
                v-if="hasActiveDelegation"
                class="text-xs text-[hsl(var(--so-muted-foreground))]"
              >
                Complete or cancel the active delegation before assigning this task again.
              </p>

              <template v-else>
                <div class="space-y-1">
                  <label
                    for="folio-task-delegate-contact"
                    class="so-font-mono text-[11px] uppercase tracking-[0.06em] text-[hsl(var(--so-muted-foreground))]"
                  >
                    Contact name
                  </label>
                  <input
                    id="folio-task-delegate-contact"
                    v-model="delegationContactName"
                    class="so-input-field h-8"
                    type="text"
                    data-testid="tasks-delegate-contact-input"
                    autocomplete="off"
                    placeholder="Who owns the handoff?"
                    :disabled="delegatingTask"
                    @input="delegationError = null"
                  />
                </div>

                <div class="space-y-1">
                  <label
                    for="folio-task-delegate-summary"
                    class="so-font-mono text-[11px] uppercase tracking-[0.06em] text-[hsl(var(--so-muted-foreground))]"
                  >
                    Delegated summary
                  </label>
                  <input
                    id="folio-task-delegate-summary"
                    v-model="delegatedSummary"
                    class="so-input-field h-8"
                    type="text"
                    data-testid="tasks-delegate-summary-input"
                    autocomplete="off"
                    placeholder="What was delegated?"
                    :disabled="delegatingTask"
                    @input="delegationError = null"
                  />
                </div>

                <div class="space-y-1">
                  <label
                    for="folio-task-delegate-quality"
                    class="so-font-mono text-[11px] uppercase tracking-[0.06em] text-[hsl(var(--so-muted-foreground))]"
                  >
                    Quality expectations
                  </label>
                  <input
                    id="folio-task-delegate-quality"
                    v-model="delegationQualityExpectations"
                    class="so-input-field h-8"
                    type="text"
                    data-testid="tasks-delegate-quality-input"
                    autocomplete="off"
                    placeholder="How should success look?"
                    :disabled="delegatingTask"
                    @input="delegationError = null"
                  />
                </div>

                <div class="grid gap-2 sm:grid-cols-2">
                  <div class="space-y-1">
                    <label
                      for="folio-task-delegate-follow-up-at"
                      class="so-font-mono text-[11px] uppercase tracking-[0.06em] text-[hsl(var(--so-muted-foreground))]"
                    >
                      Follow up date
                    </label>
                    <input
                      id="folio-task-delegate-follow-up-at"
                      v-model="delegationFollowUpAt"
                      class="so-input-field h-8"
                      type="date"
                      data-testid="tasks-delegate-follow-up-input"
                      :disabled="delegatingTask"
                      @input="delegationError = null"
                    />
                  </div>

                  <div class="space-y-1">
                    <label
                      for="folio-task-delegate-deadline-at"
                      class="so-font-mono text-[11px] uppercase tracking-[0.06em] text-[hsl(var(--so-muted-foreground))]"
                    >
                      Deadline date
                    </label>
                    <input
                      id="folio-task-delegate-deadline-at"
                      v-model="delegationDeadlineAt"
                      class="so-input-field h-8"
                      type="date"
                      data-testid="tasks-delegate-deadline-input"
                      :disabled="delegatingTask"
                      @input="delegationError = null"
                    />
                  </div>
                </div>

                <button
                  type="button"
                  class="so-button-primary h-8"
                  data-testid="tasks-delegate-submit"
                  :disabled="delegatingTask"
                  @click="submitDelegateTask"
                >
                  <LoaderCircle v-if="delegatingTask" class="h-3 w-3 animate-spin" />
                  <UserRound v-else class="h-3 w-3" />
                  <span>{{ delegatingTask ? "Delegating..." : "Delegate + wait" }}</span>
                </button>
              </template>

              <div
                v-if="delegationError"
                class="so-alert-panel so-alert-panel-error"
                data-testid="tasks-delegate-error"
              >
                <p class="text-xs text-[hsl(var(--so-destructive))]">{{ delegationError }}</p>
              </div>
            </div>
          </InspectorSection>

          <InspectorSection title="Context" with-divider>
            <InspectorField label="Project" :value="selectedTask.projectId || 'Unassigned'" />
            <InspectorField label="Priority" :value="selectedTask.priorityPosition?.toString() || '—'" mono />
          </InspectorSection>

          <InspectorSection title="Schedule" with-divider>
            <InspectorField label="Due date" :value="formatFolioDate(selectedTask.dueAt)" mono />
            <InspectorField label="Review date" :value="formatFolioDate(selectedTask.reviewAt)" mono />
          </InspectorSection>
        </div>
      </InspectorPane>
    </div>
  </div>
</template>
