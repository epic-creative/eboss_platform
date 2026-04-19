<script setup lang="ts">
import { computed, ref } from "vue"
import {
  Activity,
  AlertTriangle,
  Bot,
  Building2,
  ChevronDown,
  ChevronRight,
  Clock,
  CreditCard,
  Database,
  FolderKanban,
  LayoutDashboard,
  MoreHorizontal,
  Puzzle,
  Settings,
  Shield,
  Star,
  Users,
  Zap,
} from "lucide-vue-next"

import type { CurrentUser, PageKey, WorkspaceScope, WorkspaceSummary } from "./types"

const props = defineProps<{
  currentUser: CurrentUser
  currentScope: WorkspaceScope
  currentPage: PageKey
  basePath: string
}>()

const emit = defineEmits<{
  navigate: []
}>()

const groups = ref({
  favorites: true,
  views: false,
  teams: false,
  automation: false,
  more: false,
  switcher: false,
})

const currentWorkspace = computed(() => props.currentScope.currentWorkspace)
const currentOwner = computed(() => props.currentScope.owner)
const personalWorkspaces = computed(() =>
  props.currentScope.accessibleWorkspaces.filter(workspace => workspace.ownerType === "user"),
)
const organizationWorkspaces = computed(() =>
  props.currentScope.accessibleWorkspaces.filter(workspace => workspace.ownerType === "organization"),
)

const linkFor = (segment: PageKey) => (segment === "dashboard" ? props.basePath : `${props.basePath}/${segment}`)
const isActive = (segment: PageKey) => props.currentPage === segment
const onNavigate = () => emit("navigate")

const roleLabel = computed(() => {
  if (!currentWorkspace.value) return "member"

  if (currentWorkspace.value.ownerType === "user" && props.currentScope.capabilities.manageWorkspace) {
    return "owner"
  }

  return props.currentScope.capabilities.manageWorkspace ? "admin" : "member"
})

const workspaceLabel = computed(() =>
  currentOwner.value?.type === "organization"
    ? currentOwner.value?.displayName || currentWorkspace.value?.ownerDisplayName || "Organization"
    : "Personal",
)

const toggle = (key: keyof typeof groups.value) => {
  groups.value[key] = !groups.value[key]
}

const workspaceKey = (workspace: WorkspaceSummary) => `${workspace.ownerSlug}/${workspace.slug}`
</script>

<template>
  <div class="flex h-full flex-col">
    <details class="border-b border-[hsl(var(--so-border))]" :open="groups.switcher" @toggle="groups.switcher = !groups.switcher">
      <summary
        class="flex w-full cursor-pointer list-none items-center gap-2.5 px-3 py-2.5 text-left transition-colors hover:bg-[hsl(var(--so-accent))/0.5]"
      >
        <div
          class="flex h-7 w-7 shrink-0 items-center justify-center rounded-md bg-[hsl(var(--so-foreground))]"
        >
          <Building2
            v-if="currentOwner?.type === 'organization'"
            class="h-3.5 w-3.5 text-[hsl(var(--so-background))]"
          />
          <span v-else class="so-font-mono text-[10px] font-bold text-[hsl(var(--so-background))]">
            E
          </span>
        </div>

        <div class="min-w-0 flex-1">
          <div class="flex items-center gap-1.5">
            <p class="truncate text-sm font-medium text-[hsl(var(--so-foreground))]">
              {{ workspaceLabel }}
            </p>
            <span
              class="so-font-mono shrink-0 rounded border px-1 py-px text-[9px] uppercase tracking-wider"
              :class="
                currentOwner?.type === 'organization'
                  ? 'border-[hsl(var(--so-primary))/0.3] text-[hsl(var(--so-primary))]'
                  : 'border-[hsl(var(--so-border))] text-[hsl(var(--so-muted-foreground))]'
              "
            >
              {{ roleLabel }}
            </span>
          </div>
          <p class="truncate text-[11px] text-[hsl(var(--so-muted-foreground))]">
            {{ currentOwner?.slug || currentWorkspace?.ownerSlug }}/{{ currentWorkspace?.slug }}
          </p>
        </div>

        <ChevronDown class="h-3.5 w-3.5 shrink-0 text-[hsl(var(--so-muted-foreground))]" />
      </summary>

      <div class="space-y-2 border-t border-[hsl(var(--so-border))] px-2 py-2">
        <input placeholder="Find workspace..." class="so-input-field h-7 text-xs" />

        <div class="space-y-1">
          <p class="so-font-mono px-1 text-[11px] uppercase tracking-wider text-[hsl(var(--so-muted-foreground))]">
            Personal
          </p>
          <a
            v-for="workspace in personalWorkspaces"
            :key="workspaceKey(workspace)"
            :href="workspace.dashboardPath"
            class="flex items-center justify-between rounded-md px-2 py-1.5 text-sm transition-colors hover:bg-[hsl(var(--so-accent))/0.5]"
            @click="onNavigate"
          >
            <span class="truncate text-[hsl(var(--so-foreground))]">{{ workspace.name }}</span>
            <span
              v-if="workspace.current"
              class="so-font-mono text-[10px] uppercase tracking-wider text-[hsl(var(--so-primary))]"
            >
              current
            </span>
          </a>
        </div>

        <div class="space-y-1">
          <p class="so-font-mono px-1 text-[11px] uppercase tracking-wider text-[hsl(var(--so-muted-foreground))]">
            Organizations
          </p>
          <a
            v-for="workspace in organizationWorkspaces"
            :key="workspaceKey(workspace)"
            :href="workspace.dashboardPath"
            class="flex items-center justify-between rounded-md px-2 py-1.5 text-sm transition-colors hover:bg-[hsl(var(--so-accent))/0.5]"
            @click="onNavigate"
          >
            <div class="min-w-0">
              <p class="truncate text-[hsl(var(--so-foreground))]">{{ workspace.ownerDisplayName }} · {{ workspace.name }}</p>
            </div>
            <span
              v-if="workspace.current"
              class="so-font-mono text-[10px] uppercase tracking-wider text-[hsl(var(--so-primary))]"
            >
              current
            </span>
          </a>
        </div>
      </div>
    </details>

    <nav class="flex-1 overflow-y-auto py-1.5">
      <div class="py-0.5">
        <a
          :href="linkFor('dashboard')"
          class="mx-1.5 flex items-center gap-2 rounded-md px-2 py-[5px] text-sm transition-colors"
          :class="
            isActive('dashboard')
              ? 'bg-[hsl(var(--so-accent))] font-medium text-[hsl(var(--so-foreground))]'
              : 'text-[hsl(var(--so-muted-foreground))] hover:bg-[hsl(var(--so-accent))/0.5] hover:text-[hsl(var(--so-foreground))]'
          "
          @click="onNavigate"
        >
          <LayoutDashboard class="h-4 w-4 shrink-0" />
          <span class="flex-1 truncate">Overview</span>
        </a>
        <a
          :href="linkFor('projects')"
          class="mx-1.5 flex items-center gap-2 rounded-md px-2 py-[5px] text-sm transition-colors"
          :class="
            isActive('projects')
              ? 'bg-[hsl(var(--so-accent))] font-medium text-[hsl(var(--so-foreground))]'
              : 'text-[hsl(var(--so-muted-foreground))] hover:bg-[hsl(var(--so-accent))/0.5] hover:text-[hsl(var(--so-foreground))]'
          "
          @click="onNavigate"
        >
          <FolderKanban class="h-4 w-4 shrink-0" />
          <span class="flex-1 truncate">Projects</span>
          <span class="so-font-mono min-w-[1.25rem] text-right text-[11px] text-[hsl(var(--so-muted-foreground))]">12</span>
        </a>
        <a
          :href="linkFor('members')"
          class="mx-1.5 flex items-center gap-2 rounded-md px-2 py-[5px] text-sm transition-colors"
          :class="
            isActive('members')
              ? 'bg-[hsl(var(--so-accent))] font-medium text-[hsl(var(--so-foreground))]'
              : 'text-[hsl(var(--so-muted-foreground))] hover:bg-[hsl(var(--so-accent))/0.5] hover:text-[hsl(var(--so-foreground))]'
          "
          @click="onNavigate"
        >
          <Users class="h-4 w-4 shrink-0" />
          <span class="flex-1 truncate">Members</span>
          <span class="so-font-mono min-w-[1.25rem] text-right text-[11px] text-[hsl(var(--so-muted-foreground))]">8</span>
        </a>
        <a
          :href="linkFor('access')"
          class="mx-1.5 flex items-center gap-2 rounded-md px-2 py-[5px] text-sm transition-colors"
          :class="
            isActive('access')
              ? 'bg-[hsl(var(--so-accent))] font-medium text-[hsl(var(--so-foreground))]'
              : 'text-[hsl(var(--so-muted-foreground))] hover:bg-[hsl(var(--so-accent))/0.5] hover:text-[hsl(var(--so-foreground))]'
          "
          @click="onNavigate"
        >
          <Shield class="h-4 w-4 shrink-0" />
          <span class="flex-1 truncate">Access</span>
          <AlertTriangle class="h-3 w-3 shrink-0 text-[hsl(var(--so-warning))]" />
        </a>
        <a
          :href="linkFor('activity')"
          class="mx-1.5 flex items-center gap-2 rounded-md px-2 py-[5px] text-sm transition-colors"
          :class="
            isActive('activity')
              ? 'bg-[hsl(var(--so-accent))] font-medium text-[hsl(var(--so-foreground))]'
              : 'text-[hsl(var(--so-muted-foreground))] hover:bg-[hsl(var(--so-accent))/0.5] hover:text-[hsl(var(--so-foreground))]'
          "
          @click="onNavigate"
        >
          <Activity class="h-4 w-4 shrink-0" />
          <span class="flex-1 truncate">Activity</span>
          <span class="h-2 w-2 shrink-0 rounded-full bg-[hsl(var(--so-success))]" />
        </a>
      </div>

      <div class="mx-3 my-1 border-t border-[hsl(var(--so-border))]" />

      <div class="py-1">
        <button
          type="button"
          class="group flex w-full items-center gap-1 px-3 py-1 text-[11px] font-medium uppercase tracking-wider text-[hsl(var(--so-muted-foreground))] transition-colors hover:text-[hsl(var(--so-foreground))]"
          @click="toggle('favorites')"
        >
          <ChevronRight class="h-3 w-3 shrink-0 transition-transform" :class="groups.favorites ? 'rotate-90' : ''" />
          <span class="flex-1 text-left">Favorites</span>
          <span class="so-font-mono text-[10px] text-[hsl(var(--so-muted-foreground))]">3</span>
        </button>
        <div v-if="groups.favorites" class="mt-0.5">
          <a
            :href="linkFor('projects')"
            class="mx-1.5 flex items-center gap-2 rounded-md py-[4px] pl-7 pr-2 text-[13px] text-[hsl(var(--so-muted-foreground))] transition-colors hover:bg-[hsl(var(--so-accent))/0.5] hover:text-[hsl(var(--so-foreground))]"
            @click="onNavigate"
          >
            <span class="flex-1 truncate">api-gateway</span>
            <span class="so-font-mono text-[10px]">4</span>
          </a>
          <a
            :href="linkFor('projects')"
            class="mx-1.5 flex items-center gap-2 rounded-md py-[4px] pl-7 pr-2 text-[13px] text-[hsl(var(--so-muted-foreground))] transition-colors hover:bg-[hsl(var(--so-accent))/0.5] hover:text-[hsl(var(--so-foreground))]"
            @click="onNavigate"
          >
            <span class="flex-1 truncate">auth-service</span>
            <span class="so-font-mono text-[10px]">2</span>
          </a>
          <a
            :href="linkFor('members')"
            class="mx-1.5 flex items-center gap-2 rounded-md py-[4px] pl-7 pr-2 text-[13px] text-[hsl(var(--so-muted-foreground))] transition-colors hover:bg-[hsl(var(--so-accent))/0.5] hover:text-[hsl(var(--so-foreground))]"
            @click="onNavigate"
          >
            <span class="flex-1 truncate">Platform team</span>
          </a>
        </div>
      </div>

      <div class="py-1">
        <button
          type="button"
          class="group flex w-full items-center gap-1 px-3 py-1 text-[11px] font-medium uppercase tracking-wider text-[hsl(var(--so-muted-foreground))] transition-colors hover:text-[hsl(var(--so-foreground))]"
          @click="toggle('views')"
        >
          <ChevronRight class="h-3 w-3 shrink-0 transition-transform" :class="groups.views ? 'rotate-90' : ''" />
          <span class="flex-1 text-left">Views</span>
        </button>
        <div v-if="groups.views" class="mt-0.5">
          <a
            :href="linkFor('projects')"
            class="mx-1.5 flex items-center gap-2 rounded-md py-[4px] pl-7 pr-2 text-[13px] text-[hsl(var(--so-muted-foreground))] transition-colors hover:bg-[hsl(var(--so-accent))/0.5] hover:text-[hsl(var(--so-foreground))]"
            @click="onNavigate"
          >
            <span class="flex-1 truncate">Active deployments</span>
            <span class="so-font-mono text-[10px]">6</span>
          </a>
          <a
            :href="linkFor('activity')"
            class="mx-1.5 flex items-center gap-2 rounded-md py-[4px] pl-7 pr-2 text-[13px] text-[hsl(var(--so-muted-foreground))] transition-colors hover:bg-[hsl(var(--so-accent))/0.5] hover:text-[hsl(var(--so-foreground))]"
            @click="onNavigate"
          >
            <span class="flex-1 truncate">My recent activity</span>
          </a>
          <a
            :href="linkFor('members')"
            class="mx-1.5 flex items-center gap-2 rounded-md py-[4px] pl-7 pr-2 text-[13px] text-[hsl(var(--so-muted-foreground))] transition-colors hover:bg-[hsl(var(--so-accent))/0.5] hover:text-[hsl(var(--so-foreground))]"
            @click="onNavigate"
          >
            <span class="flex-1 truncate">Pending invites</span>
            <span class="so-font-mono text-[10px]">1</span>
          </a>
          <a
            :href="linkFor('access')"
            class="mx-1.5 flex items-center gap-2 rounded-md py-[4px] pl-7 pr-2 text-[13px] text-[hsl(var(--so-muted-foreground))] transition-colors hover:bg-[hsl(var(--so-accent))/0.5] hover:text-[hsl(var(--so-foreground))]"
            @click="onNavigate"
          >
            <span class="flex-1 truncate">Expiring keys</span>
            <span class="so-font-mono text-[10px]">2</span>
          </a>
        </div>
      </div>

      <div v-if="currentOwner?.type === 'organization'" class="py-1">
        <button
          type="button"
          class="group flex w-full items-center gap-1 px-3 py-1 text-[11px] font-medium uppercase tracking-wider text-[hsl(var(--so-muted-foreground))] transition-colors hover:text-[hsl(var(--so-foreground))]"
          @click="toggle('teams')"
        >
          <ChevronRight class="h-3 w-3 shrink-0 transition-transform" :class="groups.teams ? 'rotate-90' : ''" />
          <span class="flex-1 text-left">Teams</span>
          <span class="so-font-mono text-[10px] text-[hsl(var(--so-muted-foreground))]">3</span>
        </button>
        <div v-if="groups.teams" class="mt-0.5">
          <a
            :href="linkFor('members')"
            class="mx-1.5 flex items-center gap-2 rounded-md py-[4px] pl-7 pr-2 text-[13px] text-[hsl(var(--so-muted-foreground))] transition-colors hover:bg-[hsl(var(--so-accent))/0.5] hover:text-[hsl(var(--so-foreground))]"
            @click="onNavigate"
          >
            <span class="flex-1 truncate">Engineering</span>
            <span class="so-font-mono text-[10px]">5</span>
          </a>
          <a
            :href="linkFor('members')"
            class="mx-1.5 flex items-center gap-2 rounded-md py-[4px] pl-7 pr-2 text-[13px] text-[hsl(var(--so-muted-foreground))] transition-colors hover:bg-[hsl(var(--so-accent))/0.5] hover:text-[hsl(var(--so-foreground))]"
            @click="onNavigate"
          >
            <span class="flex-1 truncate">Platform</span>
            <span class="so-font-mono text-[10px]">3</span>
          </a>
          <a
            :href="linkFor('members')"
            class="mx-1.5 flex items-center gap-2 rounded-md py-[4px] pl-7 pr-2 text-[13px] text-[hsl(var(--so-muted-foreground))] transition-colors hover:bg-[hsl(var(--so-accent))/0.5] hover:text-[hsl(var(--so-foreground))]"
            @click="onNavigate"
          >
            <span class="flex-1 truncate">Security</span>
            <span class="so-font-mono text-[10px]">2</span>
          </a>
        </div>
      </div>

      <div class="mx-3 my-1 border-t border-[hsl(var(--so-border))]" />

      <div class="py-1">
        <button
          type="button"
          class="group flex w-full items-center gap-1 px-3 py-1 text-[11px] font-medium uppercase tracking-wider text-[hsl(var(--so-muted-foreground))] transition-colors hover:text-[hsl(var(--so-foreground))]"
          @click="toggle('automation')"
        >
          <ChevronRight class="h-3 w-3 shrink-0 transition-transform" :class="groups.automation ? 'rotate-90' : ''" />
          <span class="flex-1 text-left">Automation</span>
        </button>
        <div v-if="groups.automation" class="mt-0.5">
          <a
            :href="linkFor('dashboard')"
            class="mx-1.5 flex items-center gap-2 rounded-md px-2 py-[5px] text-sm text-[hsl(var(--so-muted-foreground))] transition-colors hover:bg-[hsl(var(--so-accent))/0.5] hover:text-[hsl(var(--so-foreground))]"
            @click="onNavigate"
          >
            <Bot class="h-4 w-4 shrink-0" />
            <span class="flex-1 truncate">Agents</span>
          </a>
          <a
            :href="linkFor('dashboard')"
            class="mx-1.5 flex items-center gap-2 rounded-md px-2 py-[5px] text-sm text-[hsl(var(--so-muted-foreground))] transition-colors hover:bg-[hsl(var(--so-accent))/0.5] hover:text-[hsl(var(--so-foreground))]"
            @click="onNavigate"
          >
            <Zap class="h-4 w-4 shrink-0" />
            <span class="flex-1 truncate">Workflows</span>
          </a>
          <a
            :href="linkFor('dashboard')"
            class="mx-1.5 flex items-center gap-2 rounded-md px-2 py-[5px] text-sm text-[hsl(var(--so-muted-foreground))] transition-colors hover:bg-[hsl(var(--so-accent))/0.5] hover:text-[hsl(var(--so-foreground))]"
            @click="onNavigate"
          >
            <Database class="h-4 w-4 shrink-0" />
            <span class="flex-1 truncate">Datasets</span>
          </a>
        </div>
      </div>

      <details class="px-1.5 py-0.5" :open="groups.more" @toggle="groups.more = !groups.more">
        <summary
          class="mx-0 flex w-full cursor-pointer list-none items-center gap-2 rounded-md px-2 py-[5px] text-sm text-[hsl(var(--so-muted-foreground))] transition-colors hover:bg-[hsl(var(--so-accent))/0.5] hover:text-[hsl(var(--so-foreground))]"
        >
          <MoreHorizontal class="h-4 w-4 shrink-0" />
          <span>More</span>
        </summary>
        <div class="space-y-0.5 px-1 pb-1 pt-1">
          <button
            type="button"
            class="flex w-full items-center gap-2 rounded-md px-2 py-[5px] text-left text-sm text-[hsl(var(--so-muted-foreground))] transition-colors hover:bg-[hsl(var(--so-accent))/0.5] hover:text-[hsl(var(--so-foreground))]"
          >
            <Puzzle class="h-3.5 w-3.5" />
            Integrations
          </button>
          <button
            type="button"
            class="flex w-full items-center gap-2 rounded-md px-2 py-[5px] text-left text-sm text-[hsl(var(--so-muted-foreground))] transition-colors hover:bg-[hsl(var(--so-accent))/0.5] hover:text-[hsl(var(--so-foreground))]"
          >
            <CreditCard class="h-3.5 w-3.5" />
            Billing
          </button>
          <button
            type="button"
            class="flex w-full items-center gap-2 rounded-md px-2 py-[5px] text-left text-sm text-[hsl(var(--so-muted-foreground))] transition-colors hover:bg-[hsl(var(--so-accent))/0.5] hover:text-[hsl(var(--so-foreground))]"
          >
            <Star class="h-3.5 w-3.5" />
            Customize sidebar
          </button>
        </div>
      </details>

      <div class="px-0 py-0.5">
        <a
          :href="linkFor('settings')"
          class="mx-1.5 flex items-center gap-2 rounded-md px-2 py-[5px] text-sm transition-colors"
          :class="
            isActive('settings')
              ? 'bg-[hsl(var(--so-accent))] font-medium text-[hsl(var(--so-foreground))]'
              : 'text-[hsl(var(--so-muted-foreground))] hover:bg-[hsl(var(--so-accent))/0.5] hover:text-[hsl(var(--so-foreground))]'
          "
          @click="onNavigate"
        >
          <Settings class="h-4 w-4 shrink-0" />
          <span class="flex-1 truncate">Settings</span>
        </a>
      </div>
    </nav>

    <div class="space-y-2 border-t border-[hsl(var(--so-border))] px-3 py-2.5">
      <div class="rounded-md border border-[hsl(var(--so-border))] bg-[hsl(var(--so-surface-2))] p-2.5">
        <div class="mb-1.5 flex items-center justify-between">
          <span class="so-font-mono text-[11px] uppercase tracking-wider text-[hsl(var(--so-muted-foreground))]">
            Status
          </span>
          <div class="flex items-center gap-1">
            <span class="h-1.5 w-1.5 rounded-full bg-[hsl(var(--so-success))]" />
            <span class="text-[11px] text-[hsl(var(--so-foreground))/0.7]">Operational</span>
          </div>
        </div>
        <div class="so-font-mono flex items-center gap-3 text-[11px] text-[hsl(var(--so-foreground))/0.6]">
          <span>Pro</span>
          <span>·</span>
          <span>us-east-1</span>
          <span>·</span>
          <span class="flex items-center gap-1">
            <Clock class="h-2.5 w-2.5" />
            3ms
          </span>
        </div>
      </div>
    </div>
  </div>
</template>
