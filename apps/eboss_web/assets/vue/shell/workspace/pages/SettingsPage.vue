<script setup lang="ts">
import {
  AlertTriangle,
  CreditCard,
  Globe,
  Puzzle,
  Save,
  Settings,
  Shield,
} from "lucide-vue-next"

import WorkspaceEmptyState from "../WorkspaceEmptyState.vue"
import WorkspacePageHeader from "../WorkspacePageHeader.vue"
import WorkspacePanel from "../WorkspacePanel.vue"
import type { SettingsTab, WorkspaceSummary } from "../types"

defineProps<{
  workspaceReference: string
  activeSettingsTab: SettingsTab
  currentWorkspace: WorkspaceSummary
}>()

const emit = defineEmits<{
  "update:activeSettingsTab": [value: SettingsTab]
}>()
</script>

<template>
  <div class="ui-workspace-page" data-testid="workspace-page-settings">
    <WorkspacePageHeader title="Settings" :subtitle="workspaceReference" />

    <div class="flex gap-6">
      <nav class="hidden w-44 shrink-0 space-y-0.5 md:block">
        <button
          type="button"
          class="flex w-full items-center gap-2 rounded-md px-2.5 py-1.5 text-left text-sm transition-colors"
          :class="
            activeSettingsTab === 'general'
              ? 'bg-[hsl(var(--so-accent))] font-medium text-[hsl(var(--so-foreground))]'
              : 'text-[hsl(var(--so-muted-foreground))] hover:bg-[hsl(var(--so-accent))/0.5] hover:text-[hsl(var(--so-foreground))]'
          "
          @click="emit('update:activeSettingsTab', 'general')"
        >
          <Settings class="h-3.5 w-3.5" />
          General
        </button>

        <button
          type="button"
          class="flex w-full items-center gap-2 rounded-md px-2.5 py-1.5 text-left text-sm transition-colors"
          :class="
            activeSettingsTab === 'billing'
              ? 'bg-[hsl(var(--so-accent))] font-medium text-[hsl(var(--so-foreground))]'
              : 'text-[hsl(var(--so-muted-foreground))] hover:bg-[hsl(var(--so-accent))/0.5] hover:text-[hsl(var(--so-foreground))]'
          "
          @click="emit('update:activeSettingsTab', 'billing')"
        >
          <CreditCard class="h-3.5 w-3.5" />
          Billing
        </button>

        <button
          type="button"
          class="flex w-full items-center gap-2 rounded-md px-2.5 py-1.5 text-left text-sm transition-colors"
          :class="
            activeSettingsTab === 'integrations'
              ? 'bg-[hsl(var(--so-accent))] font-medium text-[hsl(var(--so-foreground))]'
              : 'text-[hsl(var(--so-muted-foreground))] hover:bg-[hsl(var(--so-accent))/0.5] hover:text-[hsl(var(--so-foreground))]'
          "
          @click="emit('update:activeSettingsTab', 'integrations')"
        >
          <Puzzle class="h-3.5 w-3.5" />
          Integrations
        </button>

        <button
          type="button"
          class="flex w-full items-center gap-2 rounded-md px-2.5 py-1.5 text-left text-sm transition-colors"
          :class="
            activeSettingsTab === 'danger'
              ? 'bg-[hsl(var(--so-accent))] font-medium text-[hsl(var(--so-foreground))]'
              : 'text-[hsl(var(--so-muted-foreground))] hover:bg-[hsl(var(--so-accent))/0.5] hover:text-[hsl(var(--so-foreground))]'
          "
          @click="emit('update:activeSettingsTab', 'danger')"
        >
          <AlertTriangle class="h-3.5 w-3.5" />
          Danger Zone
        </button>
      </nav>

      <div class="mb-4 w-full border-b border-[hsl(var(--so-border))] md:hidden">
        <nav class="-mb-px flex items-center gap-0 overflow-x-auto">
          <button type="button" class="so-underline-tab flex items-center gap-1.5 whitespace-nowrap text-xs" :data-active="activeSettingsTab === 'general'" @click="emit('update:activeSettingsTab', 'general')"><Settings class="h-3.5 w-3.5" />General</button>
          <button type="button" class="so-underline-tab flex items-center gap-1.5 whitespace-nowrap text-xs" :data-active="activeSettingsTab === 'billing'" @click="emit('update:activeSettingsTab', 'billing')"><CreditCard class="h-3.5 w-3.5" />Billing</button>
          <button type="button" class="so-underline-tab flex items-center gap-1.5 whitespace-nowrap text-xs" :data-active="activeSettingsTab === 'integrations'" @click="emit('update:activeSettingsTab', 'integrations')"><Puzzle class="h-3.5 w-3.5" />Integrations</button>
          <button type="button" class="so-underline-tab flex items-center gap-1.5 whitespace-nowrap text-xs" :data-active="activeSettingsTab === 'danger'" @click="emit('update:activeSettingsTab', 'danger')"><AlertTriangle class="h-3.5 w-3.5" />Danger Zone</button>
        </nav>
      </div>

      <div class="min-w-0 flex-1">
        <div v-if="activeSettingsTab === 'general'" class="space-y-6">
          <WorkspacePanel title="Workspace details" body-class="space-y-4">
            <div class="space-y-1.5">
              <label class="text-xs font-medium text-[hsl(var(--so-muted-foreground))]">Workspace name</label>
              <input class="so-input-field" :value="currentWorkspace.name" />
            </div>

            <div class="space-y-1.5">
              <label class="text-xs font-medium text-[hsl(var(--so-muted-foreground))]">Slug</label>
              <input class="so-input-field so-font-mono" :value="currentWorkspace.slug" />
              <p class="text-[11px] text-[hsl(var(--so-muted-foreground))]">Used in URLs and CLI commands</p>
            </div>

            <div class="space-y-1.5">
              <label class="text-xs font-medium text-[hsl(var(--so-muted-foreground))]">Description</label>
              <textarea class="so-input-field h-20 resize-none py-2" placeholder="Optional workspace description..." />
            </div>

            <div class="flex justify-end">
              <button type="button" class="so-button-primary">
                <Save class="h-3 w-3" />
                Save changes
              </button>
            </div>
          </WorkspacePanel>

          <WorkspacePanel title="Region & availability" body-class="space-y-3">
            <div class="flex items-center justify-between">
              <div class="flex items-center gap-2">
                <Globe class="h-3.5 w-3.5 text-[hsl(var(--so-muted-foreground))]" />
                <span class="text-sm">Primary region</span>
              </div>
              <span class="so-font-mono text-xs text-[hsl(var(--so-muted-foreground))]">us-east-1</span>
            </div>

            <div class="flex items-center justify-between">
              <div class="flex items-center gap-2">
                <Shield class="h-3.5 w-3.5 text-[hsl(var(--so-muted-foreground))]" />
                <span class="text-sm">Encryption</span>
              </div>
              <span class="so-font-mono text-xs text-[hsl(var(--so-muted-foreground))]">AES-256</span>
            </div>
          </WorkspacePanel>
        </div>

        <WorkspacePanel
          v-else-if="activeSettingsTab === 'billing'"
          title="Current plan"
          body-class="space-y-4"
        >
          <div class="flex items-center justify-between">
            <div>
              <p class="text-sm font-medium">Pro</p>
              <p class="text-xs text-[hsl(var(--so-muted-foreground))]">$49/month · billed monthly</p>
            </div>
            <button type="button" class="so-button-secondary">Change plan</button>
          </div>

          <div class="space-y-2 border-t border-[hsl(var(--so-border))] pt-3">
            <div class="flex items-center justify-between">
              <span class="text-xs text-[hsl(var(--so-muted-foreground))]">Members</span>
              <span class="so-font-mono text-xs">8 / 25</span>
            </div>

            <div class="flex items-center justify-between">
              <span class="text-xs text-[hsl(var(--so-muted-foreground))]">Projects</span>
              <span class="so-font-mono text-xs">12 / 50</span>
            </div>

            <div class="flex items-center justify-between">
              <span class="text-xs text-[hsl(var(--so-muted-foreground))]">API keys</span>
              <span class="so-font-mono text-xs">4 / 20</span>
            </div>
          </div>
        </WorkspacePanel>

        <WorkspaceEmptyState
          v-else-if="activeSettingsTab === 'integrations'"
          :icon="Puzzle"
          title="No integrations configured"
          copy="Connect external services to extend your workspace capabilities."
          compact
        >
          <template #actions>
            <button type="button" class="so-button-secondary">Browse integrations</button>
          </template>
        </WorkspaceEmptyState>

        <div v-else class="space-y-4">
          <div class="so-alert-panel so-alert-panel-error">
            <div class="mb-2 flex items-center gap-2">
              <AlertTriangle class="h-4 w-4 text-[hsl(var(--so-destructive))]" />
              <h3 class="text-sm font-medium text-[hsl(var(--so-destructive))]">Transfer workspace</h3>
            </div>
            <p class="mb-3 text-xs text-[hsl(var(--so-muted-foreground))]">
              Transfer this workspace to another organization or user.
            </p>
            <button
              type="button"
              class="so-button-secondary text-[hsl(var(--so-destructive))] hover:text-[hsl(var(--so-destructive))]"
            >
              Transfer ownership
            </button>
          </div>

          <div class="so-alert-panel so-alert-panel-error">
            <div class="mb-2 flex items-center gap-2">
              <AlertTriangle class="h-4 w-4 text-[hsl(var(--so-destructive))]" />
              <h3 class="text-sm font-medium text-[hsl(var(--so-destructive))]">Delete workspace</h3>
            </div>
            <p class="mb-3 text-xs text-[hsl(var(--so-muted-foreground))]">
              Permanently delete this workspace and all associated data. This action cannot be undone.
            </p>
            <button
              type="button"
              class="so-button-secondary text-[hsl(var(--so-destructive))] hover:text-[hsl(var(--so-destructive))]"
            >
              Delete workspace
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
