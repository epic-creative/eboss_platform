<script setup lang="ts">
import { computed, ref } from "vue"
import { CheckCircle2, Search, Star } from "lucide-vue-next"

import InspectorPane from "../InspectorPane.vue"
import WorkspacePageHeader from "../WorkspacePageHeader.vue"
import type { Task } from "../types"

const props = defineProps<{
  workspaceReference: string
  tasks: Task[]
  selectedTask: Task | null
}>()

const emit = defineEmits<{
  "update:selectedTask": [value: Task | null]
}>()

const statusFilters = ["all", "inbox", "next_action", "waiting_for", "scheduled", "someday_maybe", "done", "canceled", "archived"] as const
type StatusFilter = (typeof statusFilters)[number]

const selectedTaskFilter = ref<StatusFilter>("all")
const searchQuery = ref("")

const normalizeStatus = (status: string): string =>
  status.replace(/_/g, " ").replace(/\b\w/g, char => char.toUpperCase())

const statusClass = (status: string): string =>
  status === "done"
    ? "text-[hsl(var(--so-success))]"
    : status === "archived" || status === "canceled"
      ? "text-[hsl(var(--so-destructive))]"
      : status === "scheduling"
        ? "text-[hsl(var(--so-warning))]"
        : "text-[hsl(var(--so-primary))]"

const formatDate = (value: string | null): string => {
  if (!value) return "—"

  const parsed = new Date(value)
  return Number.isNaN(parsed.valueOf()) ? value : parsed.toLocaleDateString()
}

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

const selectedTaskStatus = (task: Task) =>
  task.status === "done"
    ? "done"
    : task.status === "archived" || task.status === "canceled"
      ? "closed"
      : "open"

const toggleTask = (task: Task) => {
  emit("update:selectedTask", props.selectedTask?.id === task.id ? null : task)
}

const sortTasks = computed(() =>
  [...taskQuery.value].sort((left, right) => {
    const leftStatus = selectedTaskStatus(left)
    const rightStatus = selectedTaskStatus(right)

    if (leftStatus !== rightStatus) {
      return leftStatus.localeCompare(rightStatus)
    }

    const leftDate = left.dueAt ? new Date(left.dueAt).valueOf() : Number.POSITIVE_INFINITY
    const rightDate = right.dueAt ? new Date(right.dueAt).valueOf() : Number.POSITIVE_INFINITY

    if (leftDate !== rightDate) return leftDate - rightDate
    return left.title.localeCompare(right.title)
  }),
)
</script>

<template>
  <div class="ui-workspace-page" data-testid="workspace-page-tasks">
    <WorkspacePageHeader title="Tasks" :subtitle="workspaceReference" />

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

        <div v-if="sortTasks.length" class="divide-y divide-[hsl(var(--so-border))]">
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
                  :class="statusClass(task.status)"
                />
                <span class="truncate text-sm font-medium">{{ task.title }}</span>
                <span class="so-font-mono hidden text-[11px] text-[hsl(var(--so-muted-foreground))] sm:inline">
                  {{ task.id }}
                </span>
              </div>
            </div>

            <span
              class="so-font-mono hidden w-20 text-center text-[11px] sm:block"
              :class="statusClass(task.status)"
            >
              {{ normalizeStatus(task.status) }}
            </span>

            <span class="so-font-mono hidden w-28 shrink-0 truncate text-right text-[11px] text-[hsl(var(--so-muted-foreground))] md:block">
              {{ task.projectId || "Unassigned" }}
            </span>

            <span class="so-font-mono hidden w-20 shrink-0 text-right text-[11px] text-[hsl(var(--so-muted-foreground))] lg:block">
              {{ formatDate(task.dueAt) }}
            </span>

            <span class="so-font-mono hidden w-16 text-center text-[11px] text-[hsl(var(--so-muted-foreground))] lg:block">
              {{ task.priorityPosition ?? "—" }}
            </span>
          </button>
        </div>

        <div
          v-else
          class="so-font-mono px-4 py-8 text-center text-sm text-[hsl(var(--so-muted-foreground))]"
        >
          No tasks match this view.
        </div>

        <div class="so-font-mono border-t border-[hsl(var(--so-border))] px-4 py-2 text-[11px] text-[hsl(var(--so-muted-foreground))]">
          {{ sortTasks.length }} task<span v-if="sortTasks.length !== 1">s</span>
        </div>
      </div>

      <InspectorPane
        :open="!!selectedTask"
        :title="selectedTask?.title || ''"
        :subtitle="selectedTask?.id"
        @close="emit('update:selectedTask', null)"
      >
        <template #actions>
          <button type="button" class="so-icon-button">
            <Star class="h-3 w-3" />
          </button>
        </template>

        <div v-if="selectedTask" class="space-y-4">
          <p class="text-xs text-[hsl(var(--so-muted-foreground))]">
            Task details for the selected item in the current workspace.
          </p>

          <div class="space-y-2.5 border-t border-[hsl(var(--so-border))] pt-3">
            <div class="flex items-center justify-between">
              <span class="so-font-mono text-[11px] text-[hsl(var(--so-muted-foreground))]">Status</span>
              <span
                class="flex items-center gap-1.5 capitalize"
                :class="statusClass(selectedTask.status)"
              >
                <span class="h-1.5 w-1.5 rounded-full bg-current" />
                {{ normalizeStatus(selectedTask.status) }}
              </span>
            </div>

            <div class="flex items-center justify-between">
              <span class="so-font-mono text-[11px] text-[hsl(var(--so-muted-foreground))]">Project</span>
              <span class="text-xs">{{ selectedTask.projectId || "Unassigned" }}</span>
            </div>

            <div class="flex items-center justify-between">
              <span class="so-font-mono text-[11px] text-[hsl(var(--so-muted-foreground))]">Due date</span>
              <span class="so-font-mono text-xs">{{ formatDate(selectedTask.dueAt) }}</span>
            </div>

            <div class="flex items-center justify-between">
              <span class="so-font-mono text-[11px] text-[hsl(var(--so-muted-foreground))]">Review date</span>
              <span class="so-font-mono text-xs">{{ formatDate(selectedTask.reviewAt) }}</span>
            </div>

            <div class="flex items-center justify-between">
              <span class="so-font-mono text-[11px] text-[hsl(var(--so-muted-foreground))]">Priority</span>
              <span class="so-font-mono text-xs">{{ selectedTask.priorityPosition ?? "—" }}</span>
            </div>
          </div>
        </div>
      </InspectorPane>
    </div>
  </div>
</template>
