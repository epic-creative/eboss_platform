<script setup lang="ts">
import {
  AlertTriangle,
  ArrowUpRight,
  CheckCircle2,
  Clock,
  Search,
} from "lucide-vue-next"

import InspectorPane from "../InspectorPane.vue"
import WorkspacePageHeader from "../WorkspacePageHeader.vue"
import type { ActivityEvent } from "../types"

const props = defineProps<{
  workspaceReference: string
  activityEvents: ActivityEvent[]
  selectedActivity: ActivityEvent | null
}>()

const emit = defineEmits<{
  "update:selectedActivity": [value: ActivityEvent | null]
}>()

const toggleActivity = (event: ActivityEvent) => {
  emit("update:selectedActivity", props.selectedActivity?.id === event.id ? null : event)
}
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

        <div class="divide-y divide-[hsl(var(--so-border))]">
          <button
            v-for="event in activityEvents"
            :key="event.id"
            type="button"
            class="flex w-full items-start gap-4 px-4 py-3 text-left transition-colors"
            :class="selectedActivity?.id === event.id ? 'so-row-selected' : 'hover:bg-[hsl(var(--so-accent))/0.3]'"
            @click="toggleActivity(event)"
          >
            <span class="so-font-mono w-20 shrink-0 pt-0.5 text-[11px] text-[hsl(var(--so-primary))]">{{ event.hash }}</span>

            <div class="min-w-0 flex-1">
              <p class="text-sm">{{ event.action }}</p>
              <p class="mt-0.5 text-[11px] text-[hsl(var(--so-muted-foreground))]">
                by <span class="so-font-mono">{{ event.user }}</span>
                <CheckCircle2
                  v-if="event.status === 'success'"
                  class="ml-1.5 inline h-3 w-3 text-[hsl(var(--so-success))]"
                />
                <Clock
                  v-else-if="event.status === 'pending'"
                  class="ml-1.5 inline h-3 w-3 text-[hsl(var(--so-warning))]"
                />
                <AlertTriangle
                  v-else
                  class="ml-1.5 inline h-3 w-3 text-[hsl(var(--so-warning))]"
                />
              </p>
            </div>

            <span class="hidden w-16 text-center sm:block">
              <span class="so-font-mono rounded border border-[hsl(var(--so-border))] px-1.5 py-0.5 text-[10px] text-[hsl(var(--so-muted-foreground))]">
                {{ event.type }}
              </span>
            </span>

            <span class="so-font-mono w-24 shrink-0 text-right text-[11px] text-[hsl(var(--so-muted-foreground))]">
              {{ event.time }}
            </span>
          </button>
        </div>
      </div>

      <InspectorPane
        :open="!!selectedActivity"
        :title="selectedActivity?.action || ''"
        :subtitle="selectedActivity?.hash"
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
              <span class="text-xs text-[hsl(var(--so-primary))]">{{ selectedActivity.user }}</span>
            </div>

            <div class="flex items-center justify-between">
              <span class="so-font-mono text-[11px] text-[hsl(var(--so-muted-foreground))]">Resource</span>
              <span class="text-xs">{{ selectedActivity.resource }}</span>
            </div>

            <div class="flex items-center justify-between">
              <span class="so-font-mono text-[11px] text-[hsl(var(--so-muted-foreground))]">Type</span>
              <span class="text-xs capitalize">{{ selectedActivity.type }}</span>
            </div>

            <div class="flex items-center justify-between">
              <span class="so-font-mono text-[11px] text-[hsl(var(--so-muted-foreground))]">Status</span>
              <span
                class="flex items-center gap-1.5 capitalize"
                :class="selectedActivity.status === 'success' ? 'text-[hsl(var(--so-success))]' : 'text-[hsl(var(--so-warning))]'"
              >
                <span class="h-1.5 w-1.5 rounded-full bg-current" />
                {{ selectedActivity.status }}
              </span>
            </div>

            <div class="flex items-center justify-between">
              <span class="so-font-mono text-[11px] text-[hsl(var(--so-muted-foreground))]">Time</span>
              <span class="so-font-mono text-xs">{{ selectedActivity.time }}</span>
            </div>

            <div class="flex items-center justify-between">
              <span class="so-font-mono text-[11px] text-[hsl(var(--so-muted-foreground))]">IP</span>
              <span class="so-font-mono text-xs">{{ selectedActivity.ip }}</span>
            </div>
          </div>

          <div class="space-y-2.5 border-t border-[hsl(var(--so-border))] pt-3">
            <h4 class="so-font-mono mb-1 text-[11px] text-[hsl(var(--so-muted-foreground))]">Details</h4>
            <p class="text-xs text-[hsl(var(--so-muted-foreground))]">{{ selectedActivity.details }}</p>
          </div>

          <div v-if="selectedActivity.changes?.length" class="space-y-2.5 border-t border-[hsl(var(--so-border))] pt-3">
            <h4 class="so-font-mono mb-2 text-[11px] text-[hsl(var(--so-muted-foreground))]">Changes</h4>
            <div v-for="change in selectedActivity.changes" :key="change.field" class="text-xs">
              <span class="so-font-mono text-[hsl(var(--so-muted-foreground))]">{{ change.field }}</span>
              <div class="mt-0.5 flex items-center gap-2">
                <span class="so-font-mono text-[hsl(var(--so-destructive))/0.7] line-through">{{ change.from }}</span>
                <span class="text-[hsl(var(--so-muted-foreground))]">→</span>
                <span class="so-font-mono text-[hsl(var(--so-success))]">{{ change.to }}</span>
              </div>
            </div>
          </div>

          <div class="border-t border-[hsl(var(--so-border))] pt-3">
            <button type="button" class="so-button-secondary w-full justify-start">
              <ArrowUpRight class="h-3 w-3" />
              View resource
            </button>
          </div>
        </div>
      </InspectorPane>
    </div>
  </div>
</template>
