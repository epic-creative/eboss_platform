export interface FolioWorkspaceRef {
  ownerSlug: string
  workspaceSlug: string
}

export type FolioProjectStatus = "active" | "on_hold" | "completed" | "canceled" | "archived"
export type FolioTaskStatus =
  | "inbox"
  | "next_action"
  | "waiting_for"
  | "scheduled"
  | "someday_maybe"
  | "done"
  | "canceled"
  | "archived"

export interface FolioWorkspaceSummary {
  id: string
  name: string
  slug: string
  full_path: string | null
  visibility: string | null
  owner_type: string
  owner_id: string
  owner_slug: string
  owner_display_name: string
  dashboard_path: string
  "current?": boolean
}

export interface FolioOwnerSummary {
  type: string
  id: string
  slug: string
  display_name: string
}

export interface FolioWorkspaceAppCapabilities {
  read: boolean
  manage: boolean
}

export interface FolioWorkspaceApp {
  key: string
  label: string
  default_path: string
  enabled: boolean
  capabilities: FolioWorkspaceAppCapabilities
}

export interface FolioScope {
  app_key: "folio"
  workspace: FolioWorkspaceSummary
  owner: FolioOwnerSummary
  app: FolioWorkspaceApp
  capabilities: FolioWorkspaceAppCapabilities
  workspace_path: string
  app_path: string
}

export interface FolioSummaryCounts {
  projects: number
  tasks: number
}

export interface FolioBootstrapResponse {
  scope: FolioScope
  summary_counts: FolioSummaryCounts
}

export interface FolioProjectSummary {
  id: string
  title: string
  description: string | null
  status: FolioProjectStatus
  priority_position: number | null
  due_at: string | null
  review_at: string | null
  notes: string | null
  metadata: Record<string, unknown>
}

export interface FolioProjectCreatePayload {
  title: string
}

export interface FolioProjectCreateResponse {
  scope: FolioScope
  project: FolioProjectSummary
}

export interface FolioProjectUpdatePayload {
  title?: string
  description?: string | null
  due_at?: string | null
  review_at?: string | null
  notes?: string | null
  metadata?: Record<string, unknown>
}

export interface FolioProjectUpdateResponse {
  scope: FolioScope
  project: FolioProjectSummary
}

export interface FolioProjectTransitionPayload {
  status: FolioProjectStatus
}

export interface FolioProjectTransitionResponse {
  scope: FolioScope
  project: FolioProjectSummary
}

export interface FolioTaskSummary {
  id: string
  title: string
  status: FolioTaskStatus
  project_id: string | null
  priority_position: number | null
  due_at: string | null
  review_at: string | null
}

export interface FolioTaskCreatePayload {
  title: string
  project_id?: string | null
}

export interface FolioTaskCreateResponse {
  scope: FolioScope
  task: FolioTaskSummary
}

export interface FolioTaskTransitionPayload {
  status: FolioTaskStatus
}

export interface FolioTaskTransitionResponse {
  scope: FolioScope
  task: FolioTaskSummary
}

export interface FolioActivityActor {
  type: string
  id: string | null
  label: string | null
}

export interface FolioActivitySubject {
  type: string
  id: string
  label: string | null
}

export interface FolioActivityEvent {
  id: string
  app_key: string
  provider_key: string
  provider_event_id: string
  occurred_at: string
  actor: FolioActivityActor
  action: string
  summary: string
  subject: FolioActivitySubject
  details: string | null
  status: string | null
  changes: Record<string, unknown> | null
  metadata: Record<string, unknown>
  resource_path: string | null
}

export interface FolioProjectsResponse {
  scope: FolioScope
  projects: FolioProjectSummary[]
}

export interface FolioTasksResponse {
  scope: FolioScope
  tasks: FolioTaskSummary[]
}

export interface FolioActivityResponse {
  scope: FolioScope
  events: FolioActivityEvent[]
}
