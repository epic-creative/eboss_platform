import type { Component } from "vue"

export type WorkspaceSurface = "dashboard" | "members" | "access" | "settings"
export interface WorkspaceNavigation {
  type: "workspace"
  surface: WorkspaceSurface
}

export interface AppNavigation {
  type: "app"
  app_key: string
  app_surface: string | null
}

export type WorkspaceNavigationContext = WorkspaceNavigation | AppNavigation
export type ProjectStatus = "active" | "paused" | "archived"
export type MemberRole = "owner" | "admin" | "member" | "viewer"
export type MemberStatus = "active" | "invited" | "suspended"
export type AccessTab = "roles" | "policies" | "api-keys" | "audit"
export type SettingsTab = "general" | "billing" | "integrations" | "danger"
export type ProjectFilter = "all" | ProjectStatus

export interface CurrentUser {
  username: string
  email: string
}

export interface WorkspaceSummary {
  id: string
  name: string
  slug: string
  fullPath: string | null
  visibility: string | null
  ownerType: "user" | "organization"
  ownerSlug: string
  ownerDisplayName: string
  dashboardPath: string
  current: boolean
}

export interface OwnerSummary {
  type: "user" | "organization"
  slug: string
  displayName: string
}

export interface WorkspaceCapabilities {
  readWorkspace: boolean
  manageWorkspace: boolean
  readFolio: boolean
  manageFolio: boolean
}

export interface WorkspaceAppCapabilities {
  read: boolean
  manage: boolean
}

export interface WorkspaceApp {
  key: string
  label: string
  defaultPath: string
  enabled: boolean
  capabilities: WorkspaceAppCapabilities
}

export interface WorkspaceScope {
  empty: boolean
  dashboardPath: string
  currentWorkspace: WorkspaceSummary | null
  owner: OwnerSummary | null
  capabilities: WorkspaceCapabilities
  apps?: Record<string, WorkspaceApp>
  accessibleWorkspaces: WorkspaceSummary[]
}

export interface Project {
  id: string
  name: string
  slug: string
  status: ProjectStatus
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

export interface Member {
  id: string
  name: string
  email: string
  role: MemberRole
  status: MemberStatus
  joinedAt: string
  lastSeen: string
  projects: number
  teams: string[]
  permissions: number
  twoFactor: boolean
}

export interface RoleRecord {
  id: string
  name: string
  description: string
  members: number
  permissions: number
  canDelete: boolean
  created: string
}

export interface ApiKeyRecord {
  id: string
  name: string
  prefix: string
  created: string
  lastUsed: string
  status: "active" | "expiring"
  scopes: string[]
  expiresAt: string
}

export interface AccessAuditRecord {
  id: string
  time: string
  actor: string
  action: string
  resource: string
  severity: "info" | "warn"
  details: string
  ip: string
}

export interface ActivityChange {
  field: string
  from: string
  to: string
}

export interface ActivityEvent {
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
  changes?: ActivityChange[]
}

export interface OverviewEvent {
  hash: string
  action: string
  time: string
  user: string
  status: "success" | "pending"
}

export interface PostureItem {
  label: string
  value: string
  icon: Component
  status: "ok" | "warn"
}
