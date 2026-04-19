<script setup lang="ts">
import { computed } from "vue"
import {
  Activity,
  AlertTriangle,
  Copy,
  FileText,
  Key,
  Lock,
  Plus,
  Shield,
  Trash2,
  Users,
} from "lucide-vue-next"

import InspectorPane from "../InspectorPane.vue"
import WorkspaceEmptyState from "../WorkspaceEmptyState.vue"
import WorkspacePageHeader from "../WorkspacePageHeader.vue"
import type {
  AccessAuditRecord,
  AccessTab,
  ApiKeyRecord,
  RoleRecord,
} from "../types"

const props = defineProps<{
  workspaceReference: string
  activeAccessTab: AccessTab
  roles: RoleRecord[]
  selectedRole: RoleRecord | null
  apiKeys: ApiKeyRecord[]
  selectedKey: ApiKeyRecord | null
  accessAudit: AccessAuditRecord[]
  selectedAccessAudit: AccessAuditRecord | null
}>()

const emit = defineEmits<{
  "update:activeAccessTab": [value: AccessTab]
  "update:selectedRole": [value: RoleRecord | null]
  "update:selectedKey": [value: ApiKeyRecord | null]
  "update:selectedAccessAudit": [value: AccessAuditRecord | null]
}>()

const accessHasInspector = computed(
  () =>
    (props.activeAccessTab === "roles" && !!props.selectedRole) ||
    (props.activeAccessTab === "api-keys" && !!props.selectedKey) ||
    (props.activeAccessTab === "audit" && !!props.selectedAccessAudit),
)

const setTab = (tab: AccessTab) => {
  emit("update:activeAccessTab", tab)
  emit("update:selectedRole", null)
  emit("update:selectedKey", null)
  emit("update:selectedAccessAudit", null)
}

const toggleRole = (role: RoleRecord) => {
  emit("update:selectedRole", props.selectedRole?.id === role.id ? null : role)
}

const toggleKey = (record: ApiKeyRecord) => {
  emit("update:selectedKey", props.selectedKey?.id === record.id ? null : record)
}

const toggleAudit = (entry: AccessAuditRecord) => {
  emit("update:selectedAccessAudit", props.selectedAccessAudit?.id === entry.id ? null : entry)
}
</script>

<template>
  <div class="ui-workspace-page" data-testid="workspace-page-access">
    <WorkspacePageHeader title="Access Control" :subtitle="workspaceReference" />

    <div class="border-b border-[hsl(var(--so-border))]">
      <nav class="-mb-px flex items-center gap-0">
        <button
          type="button"
          class="so-underline-tab flex items-center gap-1.5 whitespace-nowrap"
          :data-active="activeAccessTab === 'roles'"
          @click="setTab('roles')"
        >
          <Shield class="h-3.5 w-3.5" />
          <span>Roles</span>
        </button>

        <button
          type="button"
          class="so-underline-tab flex items-center gap-1.5 whitespace-nowrap"
          :data-active="activeAccessTab === 'policies'"
          @click="setTab('policies')"
        >
          <FileText class="h-3.5 w-3.5" />
          <span>Policies</span>
        </button>

        <button
          type="button"
          class="so-underline-tab flex items-center gap-1.5 whitespace-nowrap"
          :data-active="activeAccessTab === 'api-keys'"
          @click="setTab('api-keys')"
        >
          <Key class="h-3.5 w-3.5" />
          <span>API Keys</span>
        </button>

        <button
          type="button"
          class="so-underline-tab flex items-center gap-1.5 whitespace-nowrap"
          :data-active="activeAccessTab === 'audit'"
          @click="setTab('audit')"
        >
          <Activity class="h-3.5 w-3.5" />
          <span>Audit</span>
        </button>
      </nav>
    </div>

    <div class="flex gap-0">
      <div class="min-w-0 flex-1" :class="accessHasInspector ? 'mr-0' : ''">
        <div v-if="activeAccessTab === 'roles'" class="space-y-3">
          <div class="flex items-center justify-between">
            <p class="text-xs text-[hsl(var(--so-muted-foreground))]">{{ roles.length }} roles configured</p>
            <button type="button" class="so-button-primary">
              <Plus class="h-3 w-3" />
              Create role
            </button>
          </div>

          <div
            class="divide-y divide-[hsl(var(--so-border))] rounded-md border border-[hsl(var(--so-border))] bg-[hsl(var(--so-card))]"
            :class="selectedRole ? 'rounded-r-none border-r-0' : ''"
          >
            <button
              v-for="role in roles"
              :key="role.id"
              type="button"
              class="flex w-full items-center gap-4 px-4 py-3 text-left transition-colors"
              :class="selectedRole?.id === role.id ? 'so-row-selected' : 'hover:bg-[hsl(var(--so-accent))/0.3]'"
              @click="toggleRole(role)"
            >
              <Shield class="h-4 w-4 shrink-0 text-[hsl(var(--so-muted-foreground))]" />

              <div class="min-w-0 flex-1">
                <p class="text-sm font-medium">{{ role.name }}</p>
                <p class="text-[11px] text-[hsl(var(--so-muted-foreground))]">{{ role.description }}</p>
              </div>

              <div class="hidden text-right sm:block">
                <p class="so-font-mono text-xs">{{ role.members }} members</p>
                <p class="so-font-mono text-[11px] text-[hsl(var(--so-muted-foreground))]">{{ role.permissions }} permissions</p>
              </div>
            </button>
          </div>
        </div>

        <WorkspaceEmptyState
          v-else-if="activeAccessTab === 'policies'"
          :icon="FileText"
          title="No custom policies"
          copy="Define access policies to control workspace permissions at a granular level."
          compact
        >
          <template #actions>
            <button type="button" class="so-button-primary">
              <Plus class="h-3 w-3" />
              Create policy
            </button>
          </template>
        </WorkspaceEmptyState>

        <div v-else-if="activeAccessTab === 'api-keys'" class="space-y-3">
          <div class="flex items-center justify-between">
            <p class="text-xs text-[hsl(var(--so-muted-foreground))]">{{ apiKeys.length }} keys</p>
            <button type="button" class="so-button-primary">
              <Plus class="h-3 w-3" />
              Create key
            </button>
          </div>

          <div
            class="divide-y divide-[hsl(var(--so-border))] rounded-md border border-[hsl(var(--so-border))] bg-[hsl(var(--so-card))]"
            :class="selectedKey ? 'rounded-r-none border-r-0' : ''"
          >
            <button
              v-for="record in apiKeys"
              :key="record.id"
              type="button"
              class="flex w-full items-center gap-4 px-4 py-3 text-left transition-colors"
              :class="selectedKey?.id === record.id ? 'so-row-selected' : 'hover:bg-[hsl(var(--so-accent))/0.3]'"
              @click="toggleKey(record)"
            >
              <Key class="h-4 w-4 shrink-0 text-[hsl(var(--so-muted-foreground))]" />

              <div class="min-w-0 flex-1">
                <div class="flex items-center gap-2">
                  <p class="text-sm font-medium">{{ record.name }}</p>
                  <AlertTriangle
                    v-if="record.status === 'expiring'"
                    class="h-3 w-3 text-[hsl(var(--so-warning))]"
                  />
                </div>
                <p class="so-font-mono text-[11px] text-[hsl(var(--so-muted-foreground))]">{{ record.prefix }}••••••••</p>
              </div>

              <div class="hidden text-right sm:block">
                <p class="so-font-mono text-[11px] text-[hsl(var(--so-muted-foreground))]">Last used {{ record.lastUsed }}</p>
              </div>
            </button>
          </div>
        </div>

        <div
          v-else
          class="divide-y divide-[hsl(var(--so-border))] rounded-md border border-[hsl(var(--so-border))] bg-[hsl(var(--so-card))]"
          :class="selectedAccessAudit ? 'rounded-r-none border-r-0' : ''"
        >
          <button
            v-for="entry in accessAudit"
            :key="entry.id"
            type="button"
            class="flex w-full items-start gap-3 px-4 py-3 text-left transition-colors"
            :class="selectedAccessAudit?.id === entry.id ? 'so-row-selected' : 'hover:bg-[hsl(var(--so-accent))/0.3]'"
            @click="toggleAudit(entry)"
          >
            <AlertTriangle
              v-if="entry.severity === 'warn'"
              class="mt-0.5 h-4 w-4 shrink-0 text-[hsl(var(--so-warning))]"
            />
            <Activity
              v-else
              class="mt-0.5 h-4 w-4 shrink-0 text-[hsl(var(--so-muted-foreground))]"
            />

            <div class="min-w-0 flex-1">
              <p class="text-sm">{{ entry.action }}</p>
              <p class="mt-0.5 text-[11px] text-[hsl(var(--so-muted-foreground))]">
                <span class="so-font-mono text-[hsl(var(--so-primary))]">{{ entry.actor }}</span>
                · {{ entry.resource }}
              </p>
            </div>

            <span class="so-font-mono shrink-0 text-[11px] text-[hsl(var(--so-muted-foreground))]">
              {{ entry.time }}
            </span>
          </button>
        </div>
      </div>

      <InspectorPane
        v-if="activeAccessTab === 'roles'"
        :open="!!selectedRole"
        :title="selectedRole?.name || ''"
        subtitle="Role"
        @close="emit('update:selectedRole', null)"
      >
        <div v-if="selectedRole" class="space-y-4">
          <p class="text-xs text-[hsl(var(--so-muted-foreground))]">{{ selectedRole.description }}</p>

          <div class="space-y-2.5 border-t border-[hsl(var(--so-border))] pt-3 first:border-t-0 first:pt-0">
            <div class="flex items-center justify-between">
              <span class="so-font-mono text-[11px] text-[hsl(var(--so-muted-foreground))]">Members</span>
              <span class="so-font-mono text-xs">{{ selectedRole.members }}</span>
            </div>

            <div class="flex items-center justify-between">
              <span class="so-font-mono text-[11px] text-[hsl(var(--so-muted-foreground))]">Permissions</span>
              <span class="so-font-mono text-xs">{{ selectedRole.permissions }}</span>
            </div>

            <div class="flex items-center justify-between">
              <span class="so-font-mono text-[11px] text-[hsl(var(--so-muted-foreground))]">Created</span>
              <span class="so-font-mono text-xs">{{ selectedRole.created }}</span>
            </div>

            <div class="flex items-center justify-between">
              <span class="so-font-mono text-[11px] text-[hsl(var(--so-muted-foreground))]">Deletable</span>
              <span class="text-xs">{{ selectedRole.canDelete ? "Yes" : "No (system)" }}</span>
            </div>
          </div>

          <div class="space-y-2.5 border-t border-[hsl(var(--so-border))] pt-3">
            <h4 class="so-font-mono mb-1 text-[11px] text-[hsl(var(--so-muted-foreground))]">Assigned members</h4>
            <div class="flex items-center gap-2 text-xs">
              <Users class="h-3 w-3 text-[hsl(var(--so-muted-foreground))]" />
              <span class="so-font-mono">john@acme.com</span>
            </div>
            <div v-if="selectedRole.members > 1" class="flex items-center gap-2 text-xs">
              <Users class="h-3 w-3 text-[hsl(var(--so-muted-foreground))]" />
              <span class="so-font-mono">sarah@acme.com</span>
            </div>
          </div>

          <div class="space-y-2 border-t border-[hsl(var(--so-border))] pt-3">
            <button type="button" class="so-button-secondary w-full justify-start">
              <Shield class="h-3 w-3" />
              Edit permissions
            </button>

            <button
              v-if="selectedRole.canDelete"
              type="button"
              class="so-button-secondary w-full justify-start text-[hsl(var(--so-destructive))] hover:text-[hsl(var(--so-destructive))]"
            >
              <Trash2 class="h-3 w-3" />
              Delete role
            </button>
          </div>
        </div>
      </InspectorPane>

      <InspectorPane
        v-if="activeAccessTab === 'api-keys'"
        :open="!!selectedKey"
        :title="selectedKey?.name || ''"
        :subtitle="selectedKey ? `${selectedKey.prefix}••••` : ''"
        @close="emit('update:selectedKey', null)"
      >
        <div v-if="selectedKey" class="space-y-4">
          <div class="space-y-2.5 border-t border-[hsl(var(--so-border))] pt-3 first:border-t-0 first:pt-0">
            <div class="flex items-center justify-between">
              <span class="so-font-mono text-[11px] text-[hsl(var(--so-muted-foreground))]">Status</span>
              <span
                class="flex items-center gap-1.5 capitalize"
                :class="selectedKey.status === 'expiring' ? 'text-[hsl(var(--so-warning))]' : 'text-[hsl(var(--so-success))]'"
              >
                <span class="h-1.5 w-1.5 rounded-full bg-current" />
                {{ selectedKey.status }}
              </span>
            </div>

            <div class="flex items-center justify-between">
              <span class="so-font-mono text-[11px] text-[hsl(var(--so-muted-foreground))]">Created</span>
              <span class="so-font-mono text-xs">{{ selectedKey.created }}</span>
            </div>

            <div class="flex items-center justify-between">
              <span class="so-font-mono text-[11px] text-[hsl(var(--so-muted-foreground))]">Last used</span>
              <span class="so-font-mono text-xs">{{ selectedKey.lastUsed }}</span>
            </div>

            <div class="flex items-center justify-between">
              <span class="so-font-mono text-[11px] text-[hsl(var(--so-muted-foreground))]">Expires</span>
              <span class="so-font-mono text-xs">{{ selectedKey.expiresAt }}</span>
            </div>
          </div>

          <div class="space-y-2.5 border-t border-[hsl(var(--so-border))] pt-3">
            <h4 class="so-font-mono mb-1 text-[11px] text-[hsl(var(--so-muted-foreground))]">Scopes</h4>
            <div class="flex flex-wrap gap-1">
              <span
                v-for="scope in selectedKey.scopes"
                :key="scope"
                class="so-font-mono rounded border border-[hsl(var(--so-border))] px-1.5 py-0.5 text-[11px] text-[hsl(var(--so-muted-foreground))]"
              >
                {{ scope }}
              </span>
            </div>
          </div>

          <div class="space-y-2 border-t border-[hsl(var(--so-border))] pt-3">
            <button type="button" class="so-button-secondary w-full justify-start">
              <Copy class="h-3 w-3" />
              Copy key
            </button>

            <button type="button" class="so-button-secondary w-full justify-start">
              <Lock class="h-3 w-3" />
              Rotate key
            </button>

            <button
              type="button"
              class="so-button-secondary w-full justify-start text-[hsl(var(--so-destructive))] hover:text-[hsl(var(--so-destructive))]"
            >
              <Trash2 class="h-3 w-3" />
              Revoke key
            </button>
          </div>
        </div>
      </InspectorPane>

      <InspectorPane
        v-if="activeAccessTab === 'audit'"
        :open="!!selectedAccessAudit"
        :title="selectedAccessAudit?.action || ''"
        :subtitle="selectedAccessAudit?.time"
        @close="emit('update:selectedAccessAudit', null)"
      >
        <div v-if="selectedAccessAudit" class="space-y-4">
          <div class="space-y-2.5 border-t border-[hsl(var(--so-border))] pt-3 first:border-t-0 first:pt-0">
            <div class="flex items-center justify-between">
              <span class="so-font-mono text-[11px] text-[hsl(var(--so-muted-foreground))]">Actor</span>
              <span class="text-xs text-[hsl(var(--so-primary))]">{{ selectedAccessAudit.actor }}</span>
            </div>

            <div class="flex items-center justify-between">
              <span class="so-font-mono text-[11px] text-[hsl(var(--so-muted-foreground))]">Resource</span>
              <span class="text-xs">{{ selectedAccessAudit.resource }}</span>
            </div>

            <div class="flex items-center justify-between">
              <span class="so-font-mono text-[11px] text-[hsl(var(--so-muted-foreground))]">Time</span>
              <span class="so-font-mono text-xs">{{ selectedAccessAudit.time }}</span>
            </div>

            <div class="flex items-center justify-between">
              <span class="so-font-mono text-[11px] text-[hsl(var(--so-muted-foreground))]">Severity</span>
              <span
                class="text-xs capitalize"
                :class="selectedAccessAudit.severity === 'warn' ? 'text-[hsl(var(--so-warning))]' : 'text-[hsl(var(--so-muted-foreground))]'"
              >
                {{ selectedAccessAudit.severity }}
              </span>
            </div>

            <div class="flex items-center justify-between">
              <span class="so-font-mono text-[11px] text-[hsl(var(--so-muted-foreground))]">IP</span>
              <span class="so-font-mono text-xs">{{ selectedAccessAudit.ip }}</span>
            </div>
          </div>

          <div class="space-y-2.5 border-t border-[hsl(var(--so-border))] pt-3">
            <h4 class="so-font-mono mb-1 text-[11px] text-[hsl(var(--so-muted-foreground))]">Details</h4>
            <p class="text-xs text-[hsl(var(--so-muted-foreground))]">{{ selectedAccessAudit.details }}</p>
          </div>
        </div>
      </InspectorPane>
    </div>
  </div>
</template>
