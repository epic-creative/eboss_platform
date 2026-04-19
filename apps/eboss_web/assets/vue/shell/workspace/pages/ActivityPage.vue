<script setup lang="ts">
import { computed } from "vue"
import {
  AlertTriangle,
  ArrowUpRight,
  CheckCircle2,
  Clock,
  LoaderCircle,
  Search,
} from "lucide-vue-next"

import InspectorPane from "../InspectorPane.vue"
import WorkspaceEmptyState from "../WorkspaceEmptyState.vue"
import WorkspacePageHeader from "../WorkspacePageHeader.vue"
import type { FolioActivityEvent } from "../folio/types"

interface ActivityChangeEntry {
  field: string
  from: string
  to: string
}

const props = defineProps<{
  workspaceReference: string
  activityEvents: FolioActivityEvent[]
  selectedActivity: FolioActivityEvent | null
  loading: boolean
  error: string | null
  refresh: () => Promise<void>
}>()

const emit = defineEmits<{
  "update:selectedActivity": [value: FolioActivityEvent | null]
}>()

const toggleActivity = (event: FolioActivityEvent) => {
  emit("update:selectedActivity", props.selectedActivity?.id === event.id ? null : event)
}

const canInspectActivity = computed(
  () =>
    !props.loading &&
    props.error === null &&
    !!props.selectedActivity &&
    props.activityEvents.some((event) => event.id === props.selectedActivity?.id),
)

const actorLabel = (activity: FolioActivityEvent) =>
  activity.actor.label ?? activity.actor.id ?? activity.actor.type ?? "system"

const subjectLabel = (activity: FolioActivityEvent) =>
  activity.subject.label ?? activity.subject.id ?? activity.subject.type

const statusClass = (status: string | null | undefined) =>
  status === "success"
    ? "text-[hsl(var(--so-success))]"
    : status === "warning"
      ? "text-[hsl(var(--so-warning))]"
      : status === "pending"
        ? "text-[hsl(var(--so-warning))]"
        : status === "info"
          ? "text-[hsl(var(--so-primary))]"
          : "text-[hsl(var(--so-muted-foreground))]"

const statusIconClass = (status: string | null | undefined) =>
  status === "success"
    ? "text-[hsl(var(--so-success))]"
    : status === "info" || status === "pending"
      ? "text-[hsl(var(--so-primary))]"
      : "text-[hsl(var(--so-warning))]"

const statusIcon = (status: string | null | undefined) => {
  if (status === "success") {
    return CheckCircle2
  }

  if (status === "warning" || status === "error") {
    return AlertTriangle
  }

  return Clock
}

const formatValue = (value: unknown): string => {
  if (value === null || value === undefined) return "—"
  if (typeof value === "string" || typeof value === "number" || typeof value === "boolean") return String(value)
  return JSON.stringify(value)
}

const formatDateTime = (value: string): string => {
  const parsed = new Date(value)
  return Number.isNaN(parsed.valueOf())
    ? value
    : `${parsed.toLocaleDateString()} ${parsed.toLocaleTimeString()}`
}

const changesFor = (activity: FolioActivityEvent | null): ActivityChangeEntry[] => {
  if (!activity?.changes || typeof activity.changes !== "object") return []

  return Object.entries(activity.changes)
    .filter(([, change]) => change !== null && change !== undefined)
    .map(([field, change]) => {
      const value = change as Record<string, unknown>
      if (
        value &&
        typeof value === "object" &&
        !Array.isArray(value) &&
        (Object.prototype.hasOwnProperty.call(value, "before") ||
          Object.prototype.hasOwnProperty.call(value, "after"))
      ) {
        return {
          field,
          from: formatValue(value.before),
          to: formatValue(value.after),
        }
      }

      return {
        field,
        from: "—",
        to: formatValue(change),
      }
    })
}

const selectedActivityChanges = computed(() => changesFor(props.selectedActivity))
</script>

<template>
  <div class="ui-workspace-page" data-testid="workspace-page-activity">
    <WorkspacePageHeader title="Activity" :subtitle="workspaceReference" />

    <div class="relative max-w-xs flex-1">
      <Search class="pointer-events-none absolute left-2.5 top-1/2 h-3.5 w-3.5 -translate-y-1/2 text-[hsl(var(--so-muted-foreground))]" />
      <input placeholder="Filter activity..." class="so-input-field pl-8" />
    </div>

    <div class="flex gap-0">
      <div
        class="min-w-0 flex-1 rounded-md border border-[hsl(var(--so-border))] bg-[hsl(var(--so-card))]"
        :class="selectedActivity ? 'rounded-r-none border-r-0' : ''"
      >
        <div class="so-font-mono flex items-center gap-4 border-b border-[hsl(var(--so-border))] px-4 py-2 text-[11px] text-[hsl(var(--so-muted-foreground))]">
          <span class="w-20">Hash</span>
          <span class="flex-1">Event</span>
          <span class="hidden w-16 text-center sm:block">Type</span>
          <span class="w-24 text-right">Time</span>
        </div>

        <WorkspaceEmptyState
          v-if="loading"
          :icon="LoaderCircle"
          title="Loading activity"
          copy="Updating the activity feed from Folio."
          data-testid="activity-state-loading"
        />

        <div
          v-else-if="error"
          class="so-alert-panel so-alert-panel-error m-4"
          data-testid="activity-state-error"
        >
          <div class="mb-2 flex items-center gap-2">
            <AlertTriangle class="h-4 w-4 text-[hsl(var(--so-destructive))]" />
            <h3 class="text-sm font-medium text-[hsl(var(--so-destructive))]">Unable to load activity</h3>
          </div>
          <p class="mb-3 text-xs text-[hsl(var(--so-muted-foreground))]">{{ error }}</p>
          <button type="button" class="so-button-secondary text-[hsl(var(--so-destructive))]" @click="refresh">
            Retry
          </button>
        </div>

        <WorkspaceEmptyState
          v-else-if="!activityEvents.length"
          title="No activity yet"
          copy="No Folio activity has been recorded for this workspace yet."
          data-testid="activity-state-empty"
        />

        <div
          v-else
          class="divide-y divide-[hsl(var(--so-border))]"
        >
          <button
            v-for="event in activityEvents"
            :key="event.id"
            type="button"
            class="flex w-full items-start gap-4 px-4 py-3 text-left transition-colors"
            :class="selectedActivity?.id === event.id ? 'so-row-selected' : 'hover:bg-[hsl(var(--so-accent))/0.3]'"
            :data-testid="`activity-row-${event.id}`"
            @click="toggleActivity(event)"
          >
            <span class="so-font-mono w-20 shrink-0 pt-0.5 text-[11px] text-[hsl(var(--so-primary))]">{{ event.provider_event_id }}</span>

            <div class="min-w-0 flex-1">
              <p class="text-sm">{{ event.summary }}</p>
              <p class="mt-0.5 text-[11px] text-[hsl(var(--so-muted-foreground))]">
                by <span class="so-font-mono">{{ actorLabel(event) }}</span>
                <component
                  :is="statusIcon(event.status)"
                  class="ml-1.5 inline h-3 w-3"
                  :class="statusIconClass(event.status)"
                />
              </p>
            </div>

            <span class="hidden w-16 text-center sm:block">
              <span class="so-font-mono rounded border border-[hsl(var(--so-border))] px-1.5 py-0.5 text-[10px] text-[hsl(var(--so-muted-foreground))]">
                {{ event.subject.type }}
              </span>
            </span>

            <span class="so-font-mono w-24 shrink-0 text-right text-[11px] text-[hsl(var(--so-muted-foreground))]">
              {{ formatDateTime(event.occurred_at) }}
            </span>
          </button>
        </div>
      </div>

      <InspectorPane
        :open="canInspectActivity"
        :title="selectedActivity?.summary || ''"
        :subtitle="selectedActivity?.provider_event_id"
        @close="emit('update:selectedActivity', null)"
      >
        <template #actions>
          <button type="button" class="so-icon-button">
            <ArrowUpRight class="h-3 w-3" />
          </button>
        </template>

        <div v-if="selectedActivity" class="space-y-4">
          <div class="space-y-2.5 border-t border-[hsl(var(--so-border))] pt-3 first:border-t-0 first:pt-0">
            <div class="flex items-center justify-between">
              <span class="so-font-mono text-[11px] text-[hsl(var(--so-muted-foreground))]">Actor</span>
              <span class="text-xs text-[hsl(var(--so-primary))]">{{ actorLabel(selectedActivity) }}</span>
            </div>

            <div class="flex items-center justify-between">
              <span class="so-font-mono text-[11px] text-[hsl(var(--so-muted-foreground))]">Resource</span>
              <span class="text-xs">{{ subjectLabel(selectedActivity) }}</span>
            </div>

            <div class="flex items-center justify-between">
              <span class="so-font-mono text-[11px] text-[hsl(var(--so-muted-foreground))]">Type</span>
              <span class="text-xs capitalize">{{ selectedActivity.subject.type }}</span>
            </div>

            <div class="flex items-center justify-between">
              <span class="so-font-mono text-[11px] text-[hsl(var(--so-muted-foreground))]">Status</span>
              <span class="flex items-center gap-1.5 capitalize" :class="statusClass(selectedActivity.status)">
                <span class="h-1.5 w-1.5 rounded-full bg-current" />
                {{ selectedActivity.status }}
              </span>
            </div>

            <div class="flex items-center justify-between">
              <span class="so-font-mono text-[11px] text-[hsl(var(--so-muted-foreground))]">Time</span>
              <span class="so-font-mono text-xs">{{ formatDateTime(selectedActivity.occurred_at) }}</span>
            </div>

            <div class="flex items-center justify-between">
              <span class="so-font-mono text-[11px] text-[hsl(var(--so-muted-foreground))]">Source</span>
              <span class="so-font-mono text-xs">{{ selectedActivity.metadata.source || "—" }}</span>
            </div>
          </div>

          <div class="space-y-2.5 border-t border-[hsl(var(--so-border))] pt-3">
            <h4 class="so-font-mono mb-1 text-[11px] text-[hsl(var(--so-muted-foreground))]">Details</h4>
            <p class="text-xs text-[hsl(var(--so-muted-foreground))]">
              {{ selectedActivity.details || selectedActivity.summary }}
            </p>
          </div>

          <div
            v-if="selectedActivityChanges.length"
            class="space-y-2.5 border-t border-[hsl(var(--so-border))] pt-3"
          >
            <h4 class="so-font-mono mb-2 text-[11px] text-[hsl(var(--so-muted-foreground))]">Changes</h4>
            <div v-for="change in selectedActivityChanges" :key="change.field" class="text-xs">
              <span class="so-font-mono text-[hsl(var(--so-muted-foreground))]">{{ change.field }}</span>
              <div class="mt-0.5 flex items-center gap-2">
                <span class="so-font-mono text-[hsl(var(--so-destructive))/0.7] line-through">{{ change.from }}</span>
                <span class="text-[hsl(var(--so-muted-foreground))]">→</span>
                <span class="so-font-mono text-[hsl(var(--so-success))]">{{ change.to }}</span>
              </div>
            </div>
          </div>

          <div class="border-t border-[hsl(var(--so-border))] pt-3">
            <a
              v-if="selectedActivity.resource_path"
              :href="selectedActivity.resource_path"
              class="so-button-secondary w-full justify-start inline-flex items-center"
            >
              <ArrowUpRight class="h-3 w-3" />
              View resource
            </a>
            <button v-else type="button" class="so-button-secondary w-full justify-start" disabled>
              <ArrowUpRight class="h-3 w-3" />
              Resource link unavailable
            </button>
          </div>
        </div>
      </InspectorPane>
    </div>
  </div>
</template>
