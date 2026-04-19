<script setup lang="ts">
import {
  Activity,
  CheckCircle2,
  Clock,
  FolderKanban,
  Key,
  Mail,
  Plus,
  Search,
  Shield,
  Trash2,
} from "lucide-vue-next"

import InspectorPane from "../InspectorPane.vue"
import WorkspacePageHeader from "../WorkspacePageHeader.vue"
import { memberInitials, roleBadgeClass } from "../presenters"
import type { Member } from "../types"

const props = defineProps<{
  workspaceReference: string
  members: Member[]
  selectedMember: Member | null
}>()

const emit = defineEmits<{
  "update:selectedMember": [value: Member | null]
}>()

const toggleMember = (member: Member) => {
  emit("update:selectedMember", props.selectedMember?.id === member.id ? null : member)
}
</script>

<template>
  <div class="ui-workspace-page" data-testid="workspace-page-members">
    <WorkspacePageHeader
      title="Members"
      :subtitle="`${workspaceReference} · ${members.length} members`"
    >
      <template #actions>
        <button type="button" class="so-button-primary">
          <Plus class="h-3 w-3" />
          Invite member
        </button>
      </template>
    </WorkspacePageHeader>

    <div class="relative max-w-xs flex-1">
      <Search class="pointer-events-none absolute left-2.5 top-1/2 h-3.5 w-3.5 -translate-y-1/2 text-[hsl(var(--so-muted-foreground))]" />
      <input placeholder="Filter members..." class="so-input-field pl-8" />
    </div>

    <div class="flex gap-0">
      <div
        class="min-w-0 flex-1 rounded-md border border-[hsl(var(--so-border))] bg-[hsl(var(--so-card))]"
        :class="selectedMember ? 'rounded-r-none border-r-0' : ''"
      >
        <div class="so-font-mono flex items-center gap-4 border-b border-[hsl(var(--so-border))] px-4 py-2 text-[11px] text-[hsl(var(--so-muted-foreground))]">
          <span class="flex-1">Member</span>
          <span class="hidden w-20 text-center sm:block">Role</span>
          <span class="hidden w-20 text-center md:block">Status</span>
          <span class="hidden w-24 text-right lg:block">Last seen</span>
        </div>

        <div class="divide-y divide-[hsl(var(--so-border))]">
          <button
            v-for="member in members"
            :key="member.id"
            type="button"
            class="flex w-full items-center gap-4 px-4 py-3 text-left transition-colors"
            :class="selectedMember?.id === member.id ? 'so-row-selected' : 'hover:bg-[hsl(var(--so-accent))/0.3]'"
            @click="toggleMember(member)"
          >
            <div class="min-w-0 flex-1">
              <div class="flex items-center gap-2">
                <div class="flex h-6 w-6 shrink-0 items-center justify-center rounded-full bg-[hsl(var(--so-accent))]">
                  <span class="text-[10px] font-medium">
                    {{ memberInitials(member.name) }}
                  </span>
                </div>
                <span class="truncate text-sm font-medium">{{ member.name }}</span>
              </div>

              <p class="ml-8 mt-0.5 truncate text-[11px] text-[hsl(var(--so-muted-foreground))]">{{ member.email }}</p>
            </div>

            <span class="hidden w-20 text-center sm:block">
              <span class="so-font-mono rounded border px-1.5 py-0.5 text-[11px]" :class="roleBadgeClass(member.role)">
                {{ member.role }}
              </span>
            </span>

            <span class="hidden w-20 text-center md:block">
              <CheckCircle2
                v-if="member.status === 'active'"
                class="mx-auto h-3.5 w-3.5 text-[hsl(var(--so-success))]"
              />
              <Clock
                v-else
                class="mx-auto h-3.5 w-3.5 text-[hsl(var(--so-warning))]"
              />
            </span>

            <span class="so-font-mono hidden w-24 text-right text-[11px] text-[hsl(var(--so-muted-foreground))] lg:block">
              {{ member.lastSeen }}
            </span>
          </button>
        </div>
      </div>

      <InspectorPane
        :open="!!selectedMember"
        :title="selectedMember?.name || ''"
        :subtitle="selectedMember?.email"
        @close="emit('update:selectedMember', null)"
      >
        <div v-if="selectedMember" class="space-y-4">
          <div class="flex items-center gap-3">
            <div class="flex h-10 w-10 items-center justify-center rounded-full bg-[hsl(var(--so-accent))]">
              <span class="text-sm font-medium">
                {{ memberInitials(selectedMember.name) }}
              </span>
            </div>

            <div>
              <p class="text-sm font-medium">{{ selectedMember.name }}</p>
              <span class="so-font-mono rounded border px-1.5 py-0.5 text-[11px]" :class="roleBadgeClass(selectedMember.role)">
                {{ selectedMember.role }}
              </span>
            </div>
          </div>

          <div class="space-y-2.5 border-t border-[hsl(var(--so-border))] pt-3 first:border-t-0 first:pt-0">
            <div class="flex items-center justify-between">
              <span class="so-font-mono text-[11px] text-[hsl(var(--so-muted-foreground))]">Status</span>
              <span class="flex items-center gap-1.5 text-xs capitalize">
                <span
                  class="h-1.5 w-1.5 rounded-full"
                  :class="selectedMember.status === 'active' ? 'bg-[hsl(var(--so-success))]' : 'bg-[hsl(var(--so-warning))]'"
                />
                {{ selectedMember.status }}
              </span>
            </div>

            <div class="flex items-center justify-between">
              <span class="so-font-mono text-[11px] text-[hsl(var(--so-muted-foreground))]">Joined</span>
              <span class="so-font-mono text-xs">{{ selectedMember.joinedAt }}</span>
            </div>

            <div class="flex items-center justify-between">
              <span class="so-font-mono text-[11px] text-[hsl(var(--so-muted-foreground))]">Last seen</span>
              <span class="so-font-mono text-xs">{{ selectedMember.lastSeen }}</span>
            </div>

            <div class="flex items-center justify-between">
              <span class="so-font-mono text-[11px] text-[hsl(var(--so-muted-foreground))]">2FA</span>
              <span class="text-xs">{{ selectedMember.twoFactor ? "Enabled" : "Disabled" }}</span>
            </div>
          </div>

          <div class="space-y-2.5 border-t border-[hsl(var(--so-border))] pt-3">
            <h4 class="so-font-mono mb-1 text-[11px] text-[hsl(var(--so-muted-foreground))]">Access</h4>

            <div class="flex items-center gap-2 text-xs text-[hsl(var(--so-muted-foreground))]">
              <FolderKanban class="h-3.5 w-3.5" />
              <span>{{ selectedMember.projects }} projects</span>
            </div>

            <div class="flex items-center gap-2 text-xs text-[hsl(var(--so-muted-foreground))]">
              <Key class="h-3.5 w-3.5" />
              <span>{{ selectedMember.permissions }} permissions</span>
            </div>
          </div>

          <div v-if="selectedMember.teams.length" class="space-y-2.5 border-t border-[hsl(var(--so-border))] pt-3">
            <h4 class="so-font-mono mb-1 text-[11px] text-[hsl(var(--so-muted-foreground))]">Teams</h4>

            <div class="flex flex-wrap gap-1">
              <span
                v-for="team in selectedMember.teams"
                :key="team"
                class="so-font-mono rounded border border-[hsl(var(--so-border))] px-1.5 py-0.5 text-[11px] text-[hsl(var(--so-muted-foreground))]"
              >
                {{ team }}
              </span>
            </div>
          </div>

          <div class="space-y-2.5 border-t border-[hsl(var(--so-border))] pt-3">
            <h4 class="so-font-mono mb-2 text-[11px] text-[hsl(var(--so-muted-foreground))]">Recent activity</h4>

            <div class="flex items-center gap-2 text-xs">
              <Activity class="h-3 w-3 shrink-0 text-[hsl(var(--so-muted-foreground))]" />
              <span class="flex-1 truncate">Accessed API Gateway</span>
              <span class="so-font-mono shrink-0 text-[10px] text-[hsl(var(--so-muted-foreground))]">2h ago</span>
            </div>

            <div class="flex items-center gap-2 text-xs">
              <Activity class="h-3 w-3 shrink-0 text-[hsl(var(--so-muted-foreground))]" />
              <span class="flex-1 truncate">Updated profile</span>
              <span class="so-font-mono shrink-0 text-[10px] text-[hsl(var(--so-muted-foreground))]">1d ago</span>
            </div>

            <div class="flex items-center gap-2 text-xs">
              <Activity class="h-3 w-3 shrink-0 text-[hsl(var(--so-muted-foreground))]" />
              <span class="flex-1 truncate">Joined Engineering team</span>
              <span class="so-font-mono shrink-0 text-[10px] text-[hsl(var(--so-muted-foreground))]">5d ago</span>
            </div>
          </div>

          <div class="space-y-2 border-t border-[hsl(var(--so-border))] pt-3">
            <button type="button" class="so-button-secondary w-full justify-start">
              <Shield class="h-3 w-3" />
              Change role
            </button>

            <button type="button" class="so-button-secondary w-full justify-start">
              <Mail class="h-3 w-3" />
              Resend invite
            </button>

            <button
              type="button"
              class="so-button-secondary w-full justify-start text-[hsl(var(--so-destructive))] hover:text-[hsl(var(--so-destructive))]"
            >
              <Trash2 class="h-3 w-3" />
              Remove member
            </button>
          </div>
        </div>
      </InspectorPane>
    </div>
  </div>
</template>
