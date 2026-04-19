<script setup lang="ts">
import {
  Activity,
  AlertTriangle,
  ArrowUpRight,
  CheckCircle2,
  Clock,
  Key,
  Terminal,
  Users,
} from "lucide-vue-next"

import WorkspacePageHeader from "../WorkspacePageHeader.vue"
import WorkspacePanel from "../WorkspacePanel.vue"
import type { OverviewEvent, PostureItem } from "../types"

defineProps<{
  workspaceReference: string
  postureItems: PostureItem[]
  overviewEvents: OverviewEvent[]
}>()
</script>

<template>
  <div class="ui-workspace-page" data-testid="workspace-page-dashboard">
    <WorkspacePageHeader title="Overview" :subtitle="workspaceReference">
      <template #actions>
        <button type="button" class="so-button-primary">
          New project
        </button>
      </template>
    </WorkspacePageHeader>

    <div class="grid grid-cols-2 gap-3 lg:grid-cols-4">
      <div
        v-for="item in postureItems"
        :key="item.label"
        class="flex items-center gap-3 rounded-md border border-[hsl(var(--so-border))] bg-[hsl(var(--so-card))] p-3"
      >
        <div class="flex h-8 w-8 shrink-0 items-center justify-center rounded-md bg-[hsl(var(--so-accent))]">
          <component :is="item.icon" class="h-4 w-4 text-[hsl(var(--so-muted-foreground))]" />
        </div>

        <div class="min-w-0">
          <p class="so-font-mono text-lg font-semibold leading-none">{{ item.value }}</p>
          <p class="mt-0.5 text-[11px] text-[hsl(var(--so-muted-foreground))]">{{ item.label }}</p>
        </div>

        <AlertTriangle
          v-if="item.status === 'warn'"
          class="ml-auto h-3.5 w-3.5 shrink-0 text-[hsl(var(--so-warning))]"
        />
      </div>
    </div>

    <div class="grid grid-cols-1 gap-5 xl:grid-cols-3">
      <WorkspacePanel
        title="Recent activity"
        :icon="Activity"
        class="xl:col-span-2"
        body-class="p-0"
      >
        <template #actions>
          <button type="button" class="so-button-ghost">
            View all
            <ArrowUpRight class="h-3 w-3" />
          </button>
        </template>

        <div class="divide-y divide-[hsl(var(--so-border))]">
          <div
            v-for="event in overviewEvents"
            :key="event.hash"
            class="flex items-start gap-3 px-4 py-3 transition-colors hover:bg-[hsl(var(--so-accent))/0.3]"
          >
            <Activity class="mt-0.5 h-4 w-4 shrink-0 text-[hsl(var(--so-muted-foreground))]" />

            <div class="min-w-0 flex-1">
              <p class="text-sm text-[hsl(var(--so-foreground))]">{{ event.action }}</p>
              <div class="mt-0.5 flex items-center gap-2">
                <span class="so-font-mono text-[11px] text-[hsl(var(--so-primary))]">{{ event.hash }}</span>
                <span class="text-[11px] text-[hsl(var(--so-muted-foreground))]">by {{ event.user }}</span>
                <CheckCircle2
                  v-if="event.status === 'success'"
                  class="h-3 w-3 text-[hsl(var(--so-success))]"
                />
                <Clock
                  v-else
                  class="h-3 w-3 text-[hsl(var(--so-warning))]"
                />
              </div>
            </div>

            <span class="so-font-mono shrink-0 text-[11px] text-[hsl(var(--so-muted-foreground))]">
              {{ event.time }}
            </span>
          </div>
        </div>
      </WorkspacePanel>

      <div class="space-y-4">
        <WorkspacePanel title="Workspace" body-class="space-y-3">
          <div class="flex items-center justify-between">
            <span class="so-font-mono text-[11px] text-[hsl(var(--so-muted-foreground))]">Status</span>
            <div class="flex items-center gap-1.5">
              <span class="h-2 w-2 rounded-full bg-[hsl(var(--so-success))]" />
              <span class="text-xs">Active</span>
            </div>
          </div>

          <div class="flex items-center justify-between">
            <span class="so-font-mono text-[11px] text-[hsl(var(--so-muted-foreground))]">Plan</span>
            <span class="so-font-mono rounded border border-[hsl(var(--so-border))] px-1.5 py-0.5 text-xs text-[hsl(var(--so-muted-foreground))]">
              Pro
            </span>
          </div>

          <div class="flex items-center justify-between">
            <span class="so-font-mono text-[11px] text-[hsl(var(--so-muted-foreground))]">Region</span>
            <span class="so-font-mono text-xs">us-east-1</span>
          </div>

          <div class="flex items-center justify-between">
            <span class="so-font-mono text-[11px] text-[hsl(var(--so-muted-foreground))]">Created</span>
            <span class="so-font-mono text-xs text-[hsl(var(--so-muted-foreground))]">2024-01-15</span>
          </div>
        </WorkspacePanel>

        <WorkspacePanel title="Quick actions" body-class="space-y-0.5 p-2">
          <button
            type="button"
            class="flex w-full items-center gap-2 rounded-md px-2.5 py-1.5 text-sm text-[hsl(var(--so-muted-foreground))] transition-colors hover:bg-[hsl(var(--so-accent))/0.5] hover:text-[hsl(var(--so-foreground))]"
          >
            <Users class="h-3.5 w-3.5" />
            Invite member
          </button>

          <button
            type="button"
            class="flex w-full items-center gap-2 rounded-md px-2.5 py-1.5 text-sm text-[hsl(var(--so-muted-foreground))] transition-colors hover:bg-[hsl(var(--so-accent))/0.5] hover:text-[hsl(var(--so-foreground))]"
          >
            <Key class="h-3.5 w-3.5" />
            Create API key
          </button>

          <button
            type="button"
            class="flex w-full items-center gap-2 rounded-md px-2.5 py-1.5 text-sm text-[hsl(var(--so-muted-foreground))] transition-colors hover:bg-[hsl(var(--so-accent))/0.5] hover:text-[hsl(var(--so-foreground))]"
          >
            <Activity class="h-3.5 w-3.5" />
            View audit log
          </button>
        </WorkspacePanel>

        <WorkspacePanel title="Quick start" :icon="Terminal" body-class="p-3">
          <div class="so-surface-2 so-font-mono rounded p-3 text-xs text-[hsl(var(--so-muted-foreground))]">
            <p><span class="text-[hsl(var(--so-success))]">$</span> eboss auth login</p>
            <p><span class="text-[hsl(var(--so-success))]">$</span> eboss ws use {{ workspaceReference }}</p>
          </div>
        </WorkspacePanel>
      </div>
    </div>
  </div>
</template>
