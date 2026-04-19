<script setup lang="ts">
import { computed, ref, watch } from "vue"
import { Bell, Menu, Search } from "lucide-vue-next"

import ThemeToggleButton from "../shared/ThemeToggleButton.vue"
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
import SettingsPage from "./pages/SettingsPage.vue"
import type {
  AccessAuditRecord,
  AccessTab,
  ApiKeyRecord,
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

const props = defineProps<{
  currentUser: CurrentUser
  currentScope: WorkspaceScope
  currentPage: WorkspaceNavigationContext
  currentPath: string
  signOutPath: string
  csrfToken: string
}>()

const mobileNavOpen = ref(false)
const activeAccessTab = ref<AccessTab>("roles")
const activeSettingsTab = ref<SettingsTab>("general")
const selectedMember = ref<Member | null>(null)
const selectedRole = ref<RoleRecord | null>(null)
const selectedKey = ref<ApiKeyRecord | null>(null)
const selectedAccessAudit = ref<AccessAuditRecord | null>(null)

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
const isWorkspaceRoute = computed(() => props.currentPage.type === "workspace")
const isAppRoute = computed(() => props.currentPage.type === "app")
const isAppNavigation = (page: WorkspaceNavigationContext): page is AppNavigation =>
  page.type === "app"
const currentAppPage = computed<AppNavigation | null>(() =>
  isAppNavigation(props.currentPage) ? props.currentPage : null,
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
    : "Home",
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
}

const resetWorkspaceState = () => {
  clearInspectors()
  activeAccessTab.value = "roles"
  activeSettingsTab.value = "general"
}

watch(() => props.currentPage, () => {
  mobileNavOpen.value = false
  clearInspectors()
})

watch(currentWorkspaceKey, () => {
  mobileNavOpen.value = false
  resetWorkspaceState()
})

</script>

<template>
  <div
    class="so-theme flex min-h-screen bg-[hsl(var(--so-background))] text-[hsl(var(--so-foreground))]"
    data-testid="workspace-shell"
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
            data-testid="workspace-current-app"
          >
            <span class="so-font-mono">App</span>
            <span class="font-medium text-[hsl(var(--so-foreground))]">
              {{ currentWorkspaceApp?.label ?? currentAppPage?.app_key }}
            </span>
            <span class="hidden text-[hsl(var(--so-muted-foreground))] lg:inline">
              · {{ appSurfaceTitle }}
            </span>
          </span>

          <ThemeToggleButton />

            <button type="button" class="so-icon-button relative">
              <Bell class="h-4 w-4" />
              <span class="absolute right-1.5 top-1.5 h-2 w-2 rounded-full bg-[hsl(var(--so-primary))]" />
            </button>

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
                  <a
                    :href="dashboardHref"
                    data-testid="workspace-avatar-dashboard-link"
                    class="block rounded-md px-2 py-1.5 text-sm text-[hsl(var(--so-muted-foreground))] transition-colors hover:bg-[hsl(var(--so-accent))/0.5] hover:text-[hsl(var(--so-foreground))]"
                  >
                    Dashboard
                  </a>
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
