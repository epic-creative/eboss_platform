<script setup lang="ts">
import { computed, ref } from "vue"
import {
  Activity,
  AlertTriangle,
  ArrowUpRight,
  Bell,
  CheckCircle2,
  Clock,
  Copy,
  CreditCard,
  ExternalLink,
  FileText,
  FolderKanban,
  GitBranch,
  GitCommit,
  Globe,
  Key,
  Lock,
  Mail,
  Menu,
  Plus,
  Puzzle,
  Rocket,
  Save,
  Search,
  Settings,
  Shield,
  Terminal,
  Trash2,
  Users,
} from "lucide-vue-next"

import InspectorPane from "./InspectorPane.vue"
import ThemeToggleButton from "../shared/ThemeToggleButton.vue"
import WorkspaceSidebar from "./WorkspaceSidebar.vue"
import type { CurrentUser, PageKey, WorkspaceScope } from "./types"

interface Project {
  id: string
  name: string
  slug: string
  status: "active" | "paused" | "archived"
  lastDeploy: string
  members: number
  branches: number
  description: string
  region: string
  created: string
  environment: string
  lastCommit: string
  uptime: string
}

interface Member {
  id: string
  name: string
  email: string
  role: "owner" | "admin" | "member" | "viewer"
  status: "active" | "invited" | "suspended"
  joinedAt: string
  lastSeen: string
  projects: number
  teams: string[]
  permissions: number
  twoFactor: boolean
}

interface RoleRecord {
  id: string
  name: string
  description: string
  members: number
  permissions: number
  canDelete: boolean
  created: string
}

interface ApiKeyRecord {
  id: string
  name: string
  prefix: string
  created: string
  lastUsed: string
  status: "active" | "expiring"
  scopes: string[]
  expiresAt: string
}

interface AccessAuditRecord {
  id: string
  time: string
  actor: string
  action: string
  resource: string
  severity: "info" | "warn"
  details: string
  ip: string
}

interface ActivityEvent {
  id: string
  hash: string
  action: string
  time: string
  user: string
  type: "project" | "member" | "deploy" | "access" | "billing"
  status: "success" | "pending" | "warning"
  resource: string
  details: string
  ip: string
  changes?: { field: string; from: string; to: string }[]
}

const props = defineProps<{
  currentUser: CurrentUser
  currentScope: WorkspaceScope
  currentPage: PageKey
  currentPath: string
  signOutPath: string
  csrfToken: string
}>()

const mobileNavOpen = ref(false)
const activeAccessTab = ref<"roles" | "policies" | "api-keys" | "audit">("roles")
const activeSettingsTab = ref<"general" | "billing" | "integrations" | "danger">("general")
const selectedProject = ref<Project | null>(null)
const selectedMember = ref<Member | null>(null)
const selectedRole = ref<RoleRecord | null>(null)
const selectedKey = ref<ApiKeyRecord | null>(null)
const selectedAccessAudit = ref<AccessAuditRecord | null>(null)
const selectedActivity = ref<ActivityEvent | null>(null)
const projectFilter = ref<"all" | "active" | "paused" | "archived">("all")
const projectFilters = ["all", "active", "paused", "archived"] as const

const currentWorkspace = computed(() => props.currentScope.currentWorkspace)
const workspaceReference = computed(() =>
  currentWorkspace.value ? `${currentWorkspace.value.ownerSlug}/${currentWorkspace.value.slug}` : "No workspace",
)
const basePath = computed(() => props.currentScope.dashboardPath || props.currentPath)
const avatarInitials = computed(() => props.currentUser.username.slice(0, 2).toUpperCase())
const accessHasInspector = computed(
  () =>
    (activeAccessTab.value === "roles" && !!selectedRole.value) ||
    (activeAccessTab.value === "api-keys" && !!selectedKey.value) ||
    (activeAccessTab.value === "audit" && !!selectedAccessAudit.value),
)

const postureItems = [
  { label: "Members", value: "8", icon: Users, status: "ok" },
  { label: "Projects", value: "12", icon: FolderKanban, status: "ok" },
  { label: "Roles", value: "3", icon: Shield, status: "ok" },
  { label: "API keys", value: "4", icon: Key, status: "warn" },
]

const overviewEvents = [
  { hash: "a3f2c1d", action: "Project 'api-gateway' created", time: "2 min ago", user: "jdoe", status: "success" as const },
  { hash: "b7e4a9f", action: "Member 'sarah@acme.com' invited as admin", time: "15 min ago", user: "jdoe", status: "pending" as const },
  { hash: "c9d1e3b", action: "Deployment #142 completed", time: "1 hour ago", user: "system", status: "success" as const },
  { hash: "d2f5g8h", action: "API key rotated for production", time: "3 hours ago", user: "system", status: "success" as const },
  { hash: "e4h6j2k", action: "Billing plan upgraded to Pro", time: "5 hours ago", user: "jdoe", status: "success" as const },
]

const projects = [
  { id: "1", name: "API Gateway", slug: "api-gateway", status: "active", lastDeploy: "2 hours ago", members: 4, branches: 3, description: "Core API gateway service for routing and authentication", region: "us-east-1", created: "2024-01-20", environment: "production", lastCommit: "a3f2c1d", uptime: "99.98%" },
  { id: "2", name: "Dashboard UI", slug: "dashboard-ui", status: "active", lastDeploy: "1 day ago", members: 3, branches: 5, description: "Main dashboard frontend application", region: "us-east-1", created: "2024-02-01", environment: "production", lastCommit: "b7e4a9f", uptime: "99.95%" },
  { id: "3", name: "Auth Service", slug: "auth-service", status: "active", lastDeploy: "3 days ago", members: 2, branches: 2, description: "Authentication and authorization microservice", region: "us-east-1", created: "2024-01-15", environment: "staging", lastCommit: "c9d1e3b", uptime: "99.99%" },
  { id: "4", name: "Billing Engine", slug: "billing-engine", status: "paused", lastDeploy: "1 week ago", members: 2, branches: 1, description: "Subscription and payment processing", region: "eu-west-1", created: "2024-03-01", environment: "staging", lastCommit: "d2f5g8h", uptime: "—" },
  { id: "5", name: "Legacy Importer", slug: "legacy-importer", status: "archived", lastDeploy: "2 months ago", members: 1, branches: 0, description: "Data migration tool from legacy systems", region: "us-east-1", created: "2023-11-10", environment: "—", lastCommit: "e4h6j2k", uptime: "—" },
] satisfies Project[]

const members = [
  { id: "1", name: "John Doe", email: "john@acme.com", role: "owner", status: "active", joinedAt: "2024-01-15", lastSeen: "Just now", projects: 12, teams: ["Engineering", "Platform"], permissions: 24, twoFactor: true },
  { id: "2", name: "Sarah Chen", email: "sarah@acme.com", role: "admin", status: "active", joinedAt: "2024-02-01", lastSeen: "2 hours ago", projects: 8, teams: ["Engineering"], permissions: 18, twoFactor: true },
  { id: "3", name: "Mike Torres", email: "mike@acme.com", role: "member", status: "active", joinedAt: "2024-02-15", lastSeen: "1 day ago", projects: 5, teams: ["Design"], permissions: 12, twoFactor: false },
  { id: "4", name: "Emma Wilson", email: "emma@acme.com", role: "member", status: "active", joinedAt: "2024-03-01", lastSeen: "3 days ago", projects: 3, teams: ["Engineering"], permissions: 12, twoFactor: true },
  { id: "5", name: "Alex Kim", email: "alex@acme.com", role: "viewer", status: "invited", joinedAt: "—", lastSeen: "—", projects: 0, teams: [], permissions: 6, twoFactor: false },
] satisfies Member[]

const roles = [
  { id: "r1", name: "Owner", description: "Full workspace access", members: 1, permissions: 24, canDelete: false, created: "2024-01-15" },
  { id: "r2", name: "Admin", description: "Manage members, projects, and settings", members: 2, permissions: 18, canDelete: false, created: "2024-01-15" },
  { id: "r3", name: "Member", description: "Access assigned projects", members: 4, permissions: 12, canDelete: true, created: "2024-01-15" },
  { id: "r4", name: "Viewer", description: "Read-only access to assigned projects", members: 1, permissions: 6, canDelete: true, created: "2024-02-01" },
] satisfies RoleRecord[]

const apiKeys = [
  { id: "k1", name: "Production API", prefix: "eboss_prod_", created: "2024-01-20", lastUsed: "2 min ago", status: "active", scopes: ["read", "write", "deploy"], expiresAt: "2025-01-20" },
  { id: "k2", name: "Staging API", prefix: "eboss_stg_", created: "2024-02-15", lastUsed: "1 day ago", status: "active", scopes: ["read", "write"], expiresAt: "2025-02-15" },
  { id: "k3", name: "CI/CD Pipeline", prefix: "eboss_ci_", created: "2024-03-01", lastUsed: "3 hours ago", status: "active", scopes: ["deploy"], expiresAt: "2025-03-01" },
  { id: "k4", name: "Legacy Key", prefix: "eboss_leg_", created: "2023-11-01", lastUsed: "30 days ago", status: "expiring", scopes: ["read"], expiresAt: "2024-05-01" },
] satisfies ApiKeyRecord[]

const accessAudit = [
  { id: "a1", time: "2 min ago", actor: "jdoe", action: "Rotated API key", resource: "Production API", severity: "info", details: "Key prefix eboss_prod_ was regenerated", ip: "192.168.1.1" },
  { id: "a2", time: "1 hour ago", actor: "sarah", action: "Updated role permissions", resource: "Member role", severity: "warn", details: "Added 'deploy' permission to Member role", ip: "10.0.0.42" },
  { id: "a3", time: "3 hours ago", actor: "system", action: "Key expiry warning", resource: "Legacy Key", severity: "warn", details: "Key eboss_leg_ expires in 30 days", ip: "—" },
  { id: "a4", time: "1 day ago", actor: "jdoe", action: "Created API key", resource: "CI/CD Pipeline", severity: "info", details: "New key with deploy scope created", ip: "192.168.1.1" },
  { id: "a5", time: "2 days ago", actor: "mike", action: "Accessed workspace settings", resource: "Settings", severity: "info", details: "Viewed general workspace settings", ip: "172.16.0.5" },
] satisfies AccessAuditRecord[]

const activityEvents = [
  { id: "1", hash: "a3f2c1d", action: "Project 'api-gateway' created", time: "2 min ago", user: "jdoe", type: "project", status: "success", resource: "api-gateway", details: "New project created with production environment", ip: "192.168.1.1" },
  { id: "2", hash: "b7e4a9f", action: "Member 'sarah@acme.com' invited as admin", time: "15 min ago", user: "jdoe", type: "member", status: "pending", resource: "sarah@acme.com", details: "Invitation sent with admin role", ip: "192.168.1.1", changes: [{ field: "role", from: "—", to: "admin" }] },
  { id: "3", hash: "c9d1e3b", action: "Deployment #142 completed", time: "1 hour ago", user: "system", type: "deploy", status: "success", resource: "api-gateway", details: "Deployed commit a3f2c1d to production us-east-1", ip: "—" },
  { id: "4", hash: "d2f5g8h", action: "API key rotated for production", time: "3 hours ago", user: "system", type: "access", status: "success", resource: "Production API", details: "Key prefix eboss_prod_ regenerated, old key invalidated", ip: "—" },
  { id: "5", hash: "e4h6j2k", action: "Billing plan upgraded to Pro", time: "5 hours ago", user: "jdoe", type: "billing", status: "success", resource: "Billing", details: "Plan changed from Starter to Pro ($49/mo)", ip: "192.168.1.1", changes: [{ field: "plan", from: "Starter", to: "Pro" }, { field: "price", from: "$19/mo", to: "$49/mo" }] },
  { id: "6", hash: "f1g3h5j", action: "Role 'Viewer' permissions updated", time: "8 hours ago", user: "sarah", type: "access", status: "success", resource: "Viewer role", details: "Added read access to activity logs", ip: "10.0.0.42", changes: [{ field: "permissions", from: "5", to: "6" }] },
  { id: "7", hash: "g2h4j6k", action: "Member 'mike@acme.com' role changed to member", time: "1 day ago", user: "jdoe", type: "member", status: "success", resource: "mike@acme.com", details: "Role downgraded from admin to member", ip: "192.168.1.1", changes: [{ field: "role", from: "admin", to: "member" }] },
  { id: "8", hash: "h3j5k7l", action: "Project 'legacy-importer' archived", time: "2 days ago", user: "jdoe", type: "project", status: "success", resource: "legacy-importer", details: "Project moved to archived state", ip: "192.168.1.1", changes: [{ field: "status", from: "active", to: "archived" }] },
  { id: "9", hash: "j4k6l8m", action: "API key 'Legacy Key' expiry warning", time: "3 days ago", user: "system", type: "access", status: "warning", resource: "Legacy Key", details: "Key eboss_leg_ expires in 30 days", ip: "—" },
] satisfies ActivityEvent[]

const filteredProjects = computed(() =>
  projectFilter.value === "all"
    ? projects
    : projects.filter(project => project.status === projectFilter.value),
)

const roleBadgeClass = (role: Member["role"]) => {
  if (role === "owner") return "border-[hsl(var(--so-primary))] text-[hsl(var(--so-primary))]"
  if (role === "admin") return "border-[hsl(var(--so-warning))] text-[hsl(var(--so-warning))]"
  return "border-[hsl(var(--so-border))] text-[hsl(var(--so-muted-foreground))]"
}

const clearAccessSelections = () => {
  selectedRole.value = null
  selectedKey.value = null
  selectedAccessAudit.value = null
}

const setAccessTab = (tab: typeof activeAccessTab.value) => {
  activeAccessTab.value = tab
  clearAccessSelections()
}
</script>

<template>
  <div class="so-theme flex min-h-screen bg-[hsl(var(--so-background))] text-[hsl(var(--so-foreground))]">
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
            <ThemeToggleButton />
            <button type="button" class="so-icon-button relative">
              <Bell class="h-4 w-4" />
              <span class="absolute right-1.5 top-1.5 h-2 w-2 rounded-full bg-[hsl(var(--so-primary))]" />
            </button>

            <details class="so-avatar-menu relative">
              <summary class="flex h-7 w-7 cursor-pointer items-center justify-center rounded-full border border-[hsl(var(--so-border))] bg-[hsl(var(--so-surface-2))] text-[10px] font-medium">
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
                    :href="currentScope.dashboardPath"
                    class="block rounded-md px-2 py-1.5 text-sm text-[hsl(var(--so-muted-foreground))] transition-colors hover:bg-[hsl(var(--so-accent))/0.5] hover:text-[hsl(var(--so-foreground))]"
                  >
                    Dashboard
                  </a>
                </div>

                <form :action="signOutPath" method="post" class="border-t border-[hsl(var(--so-border))] pt-2">
                  <input type="hidden" name="_method" value="delete" />
                  <input type="hidden" name="_csrf_token" :value="csrfToken" />
                  <button type="submit" class="so-button-secondary w-full justify-start">Sign out</button>
                </form>
              </div>
            </details>
          </div>
        </div>
      </header>

      <main class="flex-1 overflow-y-auto">
        <div class="max-w-[1400px] p-5 lg:p-6">
          <div v-if="currentWorkspace" class="so-fade-in">
            <template v-if="currentPage === 'dashboard'">
              <div class="space-y-5">
                <div class="flex items-center justify-between">
                  <div>
                    <h1 class="text-lg font-semibold">Overview</h1>
                    <p class="so-font-mono mt-0.5 text-xs text-[hsl(var(--so-muted-foreground))]">
                      {{ workspaceReference }}
                    </p>
                  </div>
                  <button type="button" class="so-button-primary">
                    <Plus class="h-3 w-3" />
                    New project
                  </button>
                </div>

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
                  <div class="overflow-hidden rounded-md border border-[hsl(var(--so-border))] bg-[hsl(var(--so-card))] xl:col-span-2">
                    <div class="flex items-center justify-between border-b border-[hsl(var(--so-border))] px-4 py-2.5">
                      <div class="flex items-center gap-2">
                        <Activity class="h-3.5 w-3.5 text-[hsl(var(--so-muted-foreground))]" />
                        <h2 class="text-sm font-medium">Recent activity</h2>
                      </div>
                      <button type="button" class="so-button-ghost">
                        View all
                        <ArrowUpRight class="h-3 w-3" />
                      </button>
                    </div>
                    <div class="divide-y divide-[hsl(var(--so-border))]">
                      <div
                        v-for="event in overviewEvents"
                        :key="event.hash"
                        class="flex items-start gap-3 px-4 py-3 transition-colors hover:bg-[hsl(var(--so-accent))/0.3]"
                      >
                        <GitCommit class="mt-0.5 h-4 w-4 shrink-0 text-[hsl(var(--so-muted-foreground))]" />
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
                  </div>

                  <div class="space-y-4">
                    <div class="rounded-md border border-[hsl(var(--so-border))] bg-[hsl(var(--so-card))]">
                      <div class="border-b border-[hsl(var(--so-border))] px-4 py-2.5">
                        <h2 class="text-sm font-medium">Workspace</h2>
                      </div>
                      <div class="space-y-3 p-4">
                        <div class="flex items-center justify-between">
                          <span class="so-font-mono text-[11px] text-[hsl(var(--so-muted-foreground))]">Status</span>
                          <div class="flex items-center gap-1.5">
                            <span class="h-2 w-2 rounded-full bg-[hsl(var(--so-success))]" />
                            <span class="text-xs">Active</span>
                          </div>
                        </div>
                        <div class="flex items-center justify-between">
                          <span class="so-font-mono text-[11px] text-[hsl(var(--so-muted-foreground))]">Plan</span>
                          <span class="so-font-mono rounded border border-[hsl(var(--so-border))] px-1.5 py-0.5 text-xs text-[hsl(var(--so-muted-foreground))]">Pro</span>
                        </div>
                        <div class="flex items-center justify-between">
                          <span class="so-font-mono text-[11px] text-[hsl(var(--so-muted-foreground))]">Region</span>
                          <span class="so-font-mono text-xs">us-east-1</span>
                        </div>
                        <div class="flex items-center justify-between">
                          <span class="so-font-mono text-[11px] text-[hsl(var(--so-muted-foreground))]">Created</span>
                          <span class="so-font-mono text-xs text-[hsl(var(--so-muted-foreground))]">2024-01-15</span>
                        </div>
                      </div>
                    </div>

                    <div class="rounded-md border border-[hsl(var(--so-border))] bg-[hsl(var(--so-card))]">
                      <div class="border-b border-[hsl(var(--so-border))] px-4 py-2.5">
                        <h2 class="text-sm font-medium">Quick actions</h2>
                      </div>
                      <div class="space-y-0.5 p-2">
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
                      </div>
                    </div>

                    <div class="rounded-md border border-[hsl(var(--so-border))] bg-[hsl(var(--so-card))]">
                      <div class="flex items-center gap-2 border-b border-[hsl(var(--so-border))] px-4 py-2.5">
                        <Terminal class="h-3.5 w-3.5 text-[hsl(var(--so-muted-foreground))]" />
                        <h2 class="text-sm font-medium">Quick start</h2>
                      </div>
                      <div class="p-3">
                        <div class="so-surface-2 so-font-mono rounded p-3 text-xs text-[hsl(var(--so-muted-foreground))]">
                          <p><span class="text-[hsl(var(--so-success))]">$</span> eboss auth login</p>
                          <p><span class="text-[hsl(var(--so-success))]">$</span> eboss ws use {{ workspaceReference }}</p>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </template>

            <template v-else-if="currentPage === 'projects'">
              <div>
                <div class="mb-4 flex items-center justify-between">
                  <div>
                    <h1 class="text-lg font-semibold">Projects</h1>
                    <p class="so-font-mono mt-0.5 text-xs text-[hsl(var(--so-muted-foreground))]">{{ workspaceReference }}</p>
                  </div>
                  <button type="button" class="so-button-primary">
                    <Plus class="h-3 w-3" />
                    New project
                  </button>
                </div>

                <div class="mb-3 flex items-center gap-2">
                  <div class="relative max-w-xs flex-1">
                    <Search class="pointer-events-none absolute left-2.5 top-1/2 h-3.5 w-3.5 -translate-y-1/2 text-[hsl(var(--so-muted-foreground))]" />
                    <input placeholder="Filter projects..." class="so-input-field pl-8" />
                  </div>
                  <div class="flex items-center gap-1 rounded-md border border-[hsl(var(--so-border))] p-0.5">
                    <button
                      v-for="filter in projectFilters"
                      :key="filter"
                      type="button"
                      class="rounded px-2.5 py-1 text-xs capitalize transition-colors"
                      :class="
                        projectFilter === filter
                          ? 'bg-[hsl(var(--so-accent))] font-medium text-[hsl(var(--so-foreground))]'
                          : 'text-[hsl(var(--so-muted-foreground))] hover:text-[hsl(var(--so-foreground))]'
                      "
                      @click="projectFilter = filter"
                    >
                      {{ filter }}
                    </button>
                  </div>
                </div>

                <div class="flex gap-0">
                  <div
                    class="min-w-0 flex-1 rounded-md border border-[hsl(var(--so-border))] bg-[hsl(var(--so-card))]"
                    :class="selectedProject ? 'rounded-r-none border-r-0' : ''"
                  >
                    <div class="so-font-mono flex items-center gap-4 border-b border-[hsl(var(--so-border))] px-4 py-2 text-[11px] text-[hsl(var(--so-muted-foreground))]">
                      <span class="flex-1">Name</span>
                      <span class="hidden w-16 text-center sm:block">Status</span>
                      <span class="hidden w-24 text-right md:block">Last deploy</span>
                      <span class="hidden w-16 text-center lg:block">Members</span>
                    </div>
                    <div class="divide-y divide-[hsl(var(--so-border))]">
                      <button
                        v-for="project in filteredProjects"
                        :key="project.id"
                        type="button"
                        class="flex w-full items-center gap-4 px-4 py-3 text-left transition-colors"
                        :class="
                          selectedProject?.id === project.id
                            ? 'so-row-selected'
                            : 'hover:bg-[hsl(var(--so-accent))/0.3]'
                        "
                        @click="selectedProject = selectedProject?.id === project.id ? null : project"
                      >
                        <div class="min-w-0 flex-1">
                          <div class="flex items-center gap-2">
                            <FolderKanban class="h-3.5 w-3.5 shrink-0 text-[hsl(var(--so-muted-foreground))]" />
                            <span class="truncate text-sm font-medium">{{ project.name }}</span>
                            <span class="so-font-mono hidden text-[11px] text-[hsl(var(--so-muted-foreground))] sm:inline">{{ project.slug }}</span>
                          </div>
                          <p class="ml-[22px] mt-0.5 truncate text-[11px] text-[hsl(var(--so-muted-foreground))]">{{ project.description }}</p>
                        </div>
                        <span class="hidden w-16 text-center sm:block">
                          <CheckCircle2
                            v-if="project.status === 'active'"
                            class="mx-auto h-3.5 w-3.5 text-[hsl(var(--so-success))]"
                          />
                          <Clock
                            v-else-if="project.status === 'paused'"
                            class="mx-auto h-3.5 w-3.5 text-[hsl(var(--so-warning))]"
                          />
                          <FolderKanban
                            v-else
                            class="mx-auto h-3.5 w-3.5 text-[hsl(var(--so-muted-foreground))]"
                          />
                        </span>
                        <span class="so-font-mono hidden w-24 text-right text-[11px] text-[hsl(var(--so-muted-foreground))] md:block">{{ project.lastDeploy }}</span>
                        <span class="so-font-mono hidden w-16 text-center text-[11px] text-[hsl(var(--so-muted-foreground))] lg:block">{{ project.members }}</span>
                      </button>
                    </div>
                    <div class="so-font-mono border-t border-[hsl(var(--so-border))] px-4 py-2 text-[11px] text-[hsl(var(--so-muted-foreground))]">
                      {{ filteredProjects.length }} project<span v-if="filteredProjects.length !== 1">s</span>
                    </div>
                  </div>

                  <InspectorPane
                    :open="!!selectedProject"
                    :title="selectedProject?.name || ''"
                    :subtitle="selectedProject?.slug"
                    @close="selectedProject = null"
                  >
                    <template #actions>
                      <button type="button" class="so-icon-button">
                        <ExternalLink class="h-3 w-3" />
                      </button>
                    </template>

                    <div v-if="selectedProject" class="space-y-4">
                      <p class="text-xs text-[hsl(var(--so-muted-foreground))]">{{ selectedProject.description }}</p>

                      <div class="space-y-2.5">
                        <div class="flex items-center justify-between">
                          <span class="so-font-mono text-[11px] text-[hsl(var(--so-muted-foreground))]">Status</span>
                          <span
                            class="flex items-center gap-1.5 capitalize"
                            :class="
                              selectedProject.status === 'active'
                                ? 'text-[hsl(var(--so-success))]'
                                : selectedProject.status === 'paused'
                                  ? 'text-[hsl(var(--so-warning))]'
                                  : 'text-[hsl(var(--so-muted-foreground))]'
                            "
                          >
                            <span class="h-1.5 w-1.5 rounded-full bg-current" />
                            {{ selectedProject.status }}
                          </span>
                        </div>
                        <div class="flex items-center justify-between">
                          <span class="so-font-mono text-[11px] text-[hsl(var(--so-muted-foreground))]">Environment</span>
                          <span class="so-font-mono text-xs capitalize">{{ selectedProject.environment }}</span>
                        </div>
                        <div class="flex items-center justify-between">
                          <span class="so-font-mono text-[11px] text-[hsl(var(--so-muted-foreground))]">Region</span>
                          <span class="flex items-center gap-1 text-xs"><Globe class="h-3 w-3 text-[hsl(var(--so-muted-foreground))]" />{{ selectedProject.region }}</span>
                        </div>
                        <div class="flex items-center justify-between">
                          <span class="so-font-mono text-[11px] text-[hsl(var(--so-muted-foreground))]">Uptime</span>
                          <span class="so-font-mono text-xs">{{ selectedProject.uptime }}</span>
                        </div>
                      </div>

                      <div class="space-y-2.5 border-t border-[hsl(var(--so-border))] pt-3">
                        <div class="flex items-center justify-between">
                          <span class="so-font-mono text-[11px] text-[hsl(var(--so-muted-foreground))]">Last deploy</span>
                          <span class="so-font-mono text-xs">{{ selectedProject.lastDeploy }}</span>
                        </div>
                        <div class="flex items-center justify-between">
                          <span class="so-font-mono text-[11px] text-[hsl(var(--so-muted-foreground))]">Last commit</span>
                          <span class="so-font-mono text-xs text-[hsl(var(--so-primary))]">{{ selectedProject.lastCommit }}</span>
                        </div>
                        <div class="flex items-center justify-between">
                          <span class="so-font-mono text-[11px] text-[hsl(var(--so-muted-foreground))]">Created</span>
                          <span class="so-font-mono text-xs">{{ selectedProject.created }}</span>
                        </div>
                      </div>

                      <div class="space-y-2.5 border-t border-[hsl(var(--so-border))] pt-3">
                        <div class="flex items-center gap-2 text-xs text-[hsl(var(--so-muted-foreground))]">
                          <Users class="h-3.5 w-3.5" />
                          <span>{{ selectedProject.members }} members</span>
                        </div>
                        <div class="flex items-center gap-2 text-xs text-[hsl(var(--so-muted-foreground))]">
                          <GitBranch class="h-3.5 w-3.5" />
                          <span>{{ selectedProject.branches }} branches</span>
                        </div>
                      </div>

                      <div class="space-y-2.5 border-t border-[hsl(var(--so-border))] pt-3">
                        <h4 class="so-font-mono mb-2 text-[11px] text-[hsl(var(--so-muted-foreground))]">Recent activity</h4>
                        <div class="flex items-center gap-2 text-xs">
                          <Rocket class="h-3 w-3 shrink-0 text-[hsl(var(--so-muted-foreground))]" />
                          <span class="flex-1 truncate">Deployed to production</span>
                          <span class="so-font-mono shrink-0 text-[10px] text-[hsl(var(--so-muted-foreground))]">2h ago</span>
                        </div>
                        <div class="flex items-center gap-2 text-xs">
                          <Settings class="h-3 w-3 shrink-0 text-[hsl(var(--so-muted-foreground))]" />
                          <span class="flex-1 truncate">Config updated</span>
                          <span class="so-font-mono shrink-0 text-[10px] text-[hsl(var(--so-muted-foreground))]">1d ago</span>
                        </div>
                        <div class="flex items-center gap-2 text-xs">
                          <Users class="h-3 w-3 shrink-0 text-[hsl(var(--so-muted-foreground))]" />
                          <span class="flex-1 truncate">Member added</span>
                          <span class="so-font-mono shrink-0 text-[10px] text-[hsl(var(--so-muted-foreground))]">3d ago</span>
                        </div>
                      </div>

                      <div class="space-y-2 border-t border-[hsl(var(--so-border))] pt-3">
                        <button type="button" class="so-button-secondary w-full justify-start">
                          <ExternalLink class="h-3 w-3" />
                          Open project
                        </button>
                        <button type="button" class="so-button-secondary w-full justify-start">
                          <Settings class="h-3 w-3" />
                          Project settings
                        </button>
                      </div>
                    </div>
                  </InspectorPane>
                </div>
              </div>
            </template>

            <template v-else-if="currentPage === 'members'">
              <div>
                <div class="mb-4 flex items-center justify-between">
                  <div>
                    <h1 class="text-lg font-semibold">Members</h1>
                    <p class="so-font-mono mt-0.5 text-xs text-[hsl(var(--so-muted-foreground))]">
                      {{ workspaceReference }} · {{ members.length }} members
                    </p>
                  </div>
                  <button type="button" class="so-button-primary">
                    <Plus class="h-3 w-3" />
                    Invite member
                  </button>
                </div>

                <div class="mb-3 flex items-center gap-2">
                  <div class="relative max-w-xs flex-1">
                    <Search class="pointer-events-none absolute left-2.5 top-1/2 h-3.5 w-3.5 -translate-y-1/2 text-[hsl(var(--so-muted-foreground))]" />
                    <input placeholder="Filter members..." class="so-input-field pl-8" />
                  </div>
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
                        @click="selectedMember = selectedMember?.id === member.id ? null : member"
                      >
                        <div class="min-w-0 flex-1">
                          <div class="flex items-center gap-2">
                            <div class="flex h-6 w-6 shrink-0 items-center justify-center rounded-full bg-[hsl(var(--so-accent))]">
                              <span class="text-[10px] font-medium">
                                {{ member.name.split(' ').map(part => part[0]).join('') }}
                              </span>
                            </div>
                            <span class="truncate text-sm font-medium">{{ member.name }}</span>
                          </div>
                          <p class="ml-8 mt-0.5 truncate text-[11px] text-[hsl(var(--so-muted-foreground))]">{{ member.email }}</p>
                        </div>
                        <span class="hidden w-20 text-center sm:block">
                          <span class="so-font-mono rounded border px-1.5 py-0.5 text-[11px]" :class="roleBadgeClass(member.role)">{{ member.role }}</span>
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
                        <span class="so-font-mono hidden w-24 text-right text-[11px] text-[hsl(var(--so-muted-foreground))] lg:block">{{ member.lastSeen }}</span>
                      </button>
                    </div>
                  </div>

                  <InspectorPane
                    :open="!!selectedMember"
                    :title="selectedMember?.name || ''"
                    :subtitle="selectedMember?.email"
                    @close="selectedMember = null"
                  >
                    <div v-if="selectedMember" class="space-y-4">
                      <div class="flex items-center gap-3">
                        <div class="flex h-10 w-10 items-center justify-center rounded-full bg-[hsl(var(--so-accent))]">
                          <span class="text-sm font-medium">
                            {{ selectedMember.name.split(' ').map(part => part[0]).join('') }}
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

            <template v-else-if="currentPage === 'access'">
              <div>
                <div class="mb-4">
                  <h1 class="text-lg font-semibold">Access Control</h1>
                  <p class="so-font-mono mt-0.5 text-xs text-[hsl(var(--so-muted-foreground))]">{{ workspaceReference }}</p>
                </div>

                <div class="mb-4 border-b border-[hsl(var(--so-border))]">
                  <nav class="-mb-px flex items-center gap-0">
                    <button
                      type="button"
                      class="so-underline-tab flex items-center gap-1.5 whitespace-nowrap"
                      :data-active="activeAccessTab === 'roles'"
                      @click="setAccessTab('roles')"
                    >
                      <Shield class="h-3.5 w-3.5" />
                      <span>Roles</span>
                    </button>
                    <button
                      type="button"
                      class="so-underline-tab flex items-center gap-1.5 whitespace-nowrap"
                      :data-active="activeAccessTab === 'policies'"
                      @click="setAccessTab('policies')"
                    >
                      <FileText class="h-3.5 w-3.5" />
                      <span>Policies</span>
                    </button>
                    <button
                      type="button"
                      class="so-underline-tab flex items-center gap-1.5 whitespace-nowrap"
                      :data-active="activeAccessTab === 'api-keys'"
                      @click="setAccessTab('api-keys')"
                    >
                      <Key class="h-3.5 w-3.5" />
                      <span>API Keys</span>
                    </button>
                    <button
                      type="button"
                      class="so-underline-tab flex items-center gap-1.5 whitespace-nowrap"
                      :data-active="activeAccessTab === 'audit'"
                      @click="setAccessTab('audit')"
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
                          @click="selectedRole = selectedRole?.id === role.id ? null : role"
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

                    <div
                      v-else-if="activeAccessTab === 'policies'"
                      class="rounded-md border border-[hsl(var(--so-border))] bg-[hsl(var(--so-card))] p-8 text-center"
                    >
                      <FileText class="mx-auto mb-3 h-8 w-8 text-[hsl(var(--so-muted-foreground))]" />
                      <h3 class="mb-1 text-sm font-medium">No custom policies</h3>
                      <p class="mb-4 text-xs text-[hsl(var(--so-muted-foreground))]">
                        Define access policies to control workspace permissions at a granular level.
                      </p>
                      <button type="button" class="so-button-primary">
                        <Plus class="h-3 w-3" />
                        Create policy
                      </button>
                    </div>

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
                          @click="selectedKey = selectedKey?.id === record.id ? null : record"
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
                        @click="selectedAccessAudit = selectedAccessAudit?.id === entry.id ? null : entry"
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
                        <span class="so-font-mono shrink-0 text-[11px] text-[hsl(var(--so-muted-foreground))]">{{ entry.time }}</span>
                      </button>
                    </div>
                  </div>

                  <InspectorPane
                    v-if="activeAccessTab === 'roles'"
                    :open="!!selectedRole"
                    :title="selectedRole?.name || ''"
                    subtitle="Role"
                    @close="selectedRole = null"
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
                    @close="selectedKey = null"
                  >
                    <div v-if="selectedKey" class="space-y-4">
                      <div class="space-y-2.5 border-t border-[hsl(var(--so-border))] pt-3 first:border-t-0 first:pt-0">
                        <div class="flex items-center justify-between">
                          <span class="so-font-mono text-[11px] text-[hsl(var(--so-muted-foreground))]">Status</span>
                          <span
                            class="flex items-center gap-1.5 capitalize"
                            :class="
                              selectedKey.status === 'expiring'
                                ? 'text-[hsl(var(--so-warning))]'
                                : 'text-[hsl(var(--so-success))]'
                            "
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
                    @close="selectedAccessAudit = null"
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

            <template v-else-if="currentPage === 'activity'">
              <div>
                <div class="mb-4">
                  <h1 class="text-lg font-semibold">Activity</h1>
                  <p class="so-font-mono mt-0.5 text-xs text-[hsl(var(--so-muted-foreground))]">{{ workspaceReference }}</p>
                </div>

                <div class="mb-3 flex items-center gap-2">
                  <div class="relative max-w-xs flex-1">
                    <Search class="pointer-events-none absolute left-2.5 top-1/2 h-3.5 w-3.5 -translate-y-1/2 text-[hsl(var(--so-muted-foreground))]" />
                    <input placeholder="Filter activity..." class="so-input-field pl-8" />
                  </div>
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
                        @click="selectedActivity = selectedActivity?.id === event.id ? null : event"
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
                          <span class="so-font-mono rounded border border-[hsl(var(--so-border))] px-1.5 py-0.5 text-[10px] text-[hsl(var(--so-muted-foreground))]">{{ event.type }}</span>
                        </span>
                        <span class="so-font-mono w-24 shrink-0 text-right text-[11px] text-[hsl(var(--so-muted-foreground))]">{{ event.time }}</span>
                      </button>
                    </div>
                  </div>

                  <InspectorPane
                    :open="!!selectedActivity"
                    :title="selectedActivity?.action || ''"
                    :subtitle="selectedActivity?.hash"
                    @close="selectedActivity = null"
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
                            :class="
                              selectedActivity.status === 'success'
                                ? 'text-[hsl(var(--so-success))]'
                                : 'text-[hsl(var(--so-warning))]'
                            "
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

                      <div
                        v-if="selectedActivity.changes?.length"
                        class="space-y-2.5 border-t border-[hsl(var(--so-border))] pt-3"
                      >
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

            <template v-else-if="currentPage === 'settings'">
              <div>
                <div class="mb-4">
                  <h1 class="text-lg font-semibold">Settings</h1>
                  <p class="so-font-mono mt-0.5 text-xs text-[hsl(var(--so-muted-foreground))]">{{ workspaceReference }}</p>
                </div>

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
                      @click="activeSettingsTab = 'general'"
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
                      @click="activeSettingsTab = 'billing'"
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
                      @click="activeSettingsTab = 'integrations'"
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
                      @click="activeSettingsTab = 'danger'"
                    >
                      <AlertTriangle class="h-3.5 w-3.5" />
                      Danger Zone
                    </button>
                  </nav>

                  <div class="mb-4 w-full border-b border-[hsl(var(--so-border))] md:hidden">
                    <nav class="-mb-px flex items-center gap-0 overflow-x-auto">
                      <button type="button" class="so-underline-tab flex items-center gap-1.5 whitespace-nowrap text-xs" :data-active="activeSettingsTab === 'general'" @click="activeSettingsTab = 'general'"><Settings class="h-3.5 w-3.5" />General</button>
                      <button type="button" class="so-underline-tab flex items-center gap-1.5 whitespace-nowrap text-xs" :data-active="activeSettingsTab === 'billing'" @click="activeSettingsTab = 'billing'"><CreditCard class="h-3.5 w-3.5" />Billing</button>
                      <button type="button" class="so-underline-tab flex items-center gap-1.5 whitespace-nowrap text-xs" :data-active="activeSettingsTab === 'integrations'" @click="activeSettingsTab = 'integrations'"><Puzzle class="h-3.5 w-3.5" />Integrations</button>
                      <button type="button" class="so-underline-tab flex items-center gap-1.5 whitespace-nowrap text-xs" :data-active="activeSettingsTab === 'danger'" @click="activeSettingsTab = 'danger'"><AlertTriangle class="h-3.5 w-3.5" />Danger Zone</button>
                    </nav>
                  </div>

                  <div class="min-w-0 flex-1">
                    <div v-if="activeSettingsTab === 'general'" class="space-y-6">
                      <div class="rounded-md border border-[hsl(var(--so-border))] bg-[hsl(var(--so-card))]">
                        <div class="border-b border-[hsl(var(--so-border))] px-4 py-2.5">
                          <h2 class="text-sm font-medium">Workspace details</h2>
                        </div>
                        <div class="space-y-4 p-4">
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
                        </div>
                      </div>

                      <div class="rounded-md border border-[hsl(var(--so-border))] bg-[hsl(var(--so-card))]">
                        <div class="border-b border-[hsl(var(--so-border))] px-4 py-2.5">
                          <h2 class="text-sm font-medium">Region & availability</h2>
                        </div>
                        <div class="space-y-3 p-4">
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
                        </div>
                      </div>
                    </div>

                    <div
                      v-else-if="activeSettingsTab === 'billing'"
                      class="rounded-md border border-[hsl(var(--so-border))] bg-[hsl(var(--so-card))]"
                    >
                      <div class="border-b border-[hsl(var(--so-border))] px-4 py-2.5">
                        <h2 class="text-sm font-medium">Current plan</h2>
                      </div>
                      <div class="space-y-4 p-4">
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
                      </div>
                    </div>

                    <div
                      v-else-if="activeSettingsTab === 'integrations'"
                      class="rounded-md border border-[hsl(var(--so-border))] bg-[hsl(var(--so-card))] p-8 text-center"
                    >
                      <Puzzle class="mx-auto mb-3 h-8 w-8 text-[hsl(var(--so-muted-foreground))]" />
                      <h3 class="mb-1 text-sm font-medium">No integrations configured</h3>
                      <p class="mb-4 text-xs text-[hsl(var(--so-muted-foreground))]">
                        Connect external services to extend your workspace capabilities.
                      </p>
                      <button type="button" class="so-button-secondary">Browse integrations</button>
                    </div>

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
          </div>

          <div
            v-else
            class="so-fade-in rounded-md border border-dashed border-[hsl(var(--so-border))] bg-[hsl(var(--so-card))] p-10 text-center"
          >
            <h1 class="text-xl font-semibold">No accessible workspaces yet</h1>
            <p class="mx-auto mt-2 max-w-xl text-sm text-[hsl(var(--so-muted-foreground))]">
              The signed-in shell is active, but this account does not have a workspace route to mount yet.
            </p>
            <div class="mt-6 flex justify-center gap-2">
              <a href="/" class="so-button-secondary">Back to home</a>
              <a :href="currentScope.dashboardPath || '/dashboard'" class="so-button-primary">Refresh route</a>
            </div>
          </div>
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
