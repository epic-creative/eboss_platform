export type PageKey = "dashboard" | "projects" | "members" | "access" | "activity" | "settings"

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

export interface WorkspaceScope {
  empty: boolean
  dashboardPath: string
  currentWorkspace: WorkspaceSummary | null
  owner: OwnerSummary | null
  capabilities: WorkspaceCapabilities
  accessibleWorkspaces: WorkspaceSummary[]
}
