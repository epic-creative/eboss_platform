export interface ChatWorkspaceRef {
  ownerSlug: string
  workspaceSlug: string
}

export interface ChatScope {
  app_key: "chat"
  workspace: {
    id: string
    name: string
    slug: string
    dashboard_path: string
    owner_slug: string
  }
  owner: {
    type: string
    id: string
    slug: string
    display_name: string
  }
  app: {
    key: string
    label: string
    default_path: string
    enabled: boolean
    capabilities: { read: boolean; manage: boolean }
  }
  capabilities: {
    read: boolean
    manage: boolean
  }
  workspace_path: string
  app_path: string
}

export interface ChatUserSummary {
  id: string
  username: string
  email: string
}

export interface ChatUsageTotals {
  input_tokens: number
  output_tokens: number
  total_tokens: number
}

export interface ChatWorkspaceUsageTotals extends ChatUsageTotals {
  sessions: number
}

export interface ChatModelOption {
  key: string
  label: string
  provider: "anthropic" | "openai" | string
  model: string
}

export interface ChatSessionSummary {
  id: string
  title: string
  status: "active" | "archived"
  last_message_at: string | null
  last_activity_at: string | null
  message_count: number
  usage_totals: ChatUsageTotals
  created_by_user: ChatUserSummary
  path: string
}

export interface ChatMessageSummary {
  id: string
  role: "user" | "assistant" | "system"
  body: string
  status: "pending" | "complete" | "error"
  sequence: number
  provider: string | null
  model: string | null
  input_tokens: number
  output_tokens: number
  total_tokens: number
  finish_reason: string | null
  error_message: string | null
  inserted_at: string
  author: ChatUserSummary | null
}

export interface ChatBootstrapResponse {
  scope: ChatScope
  default_model_key: string
  models: ChatModelOption[]
  usage_totals: ChatWorkspaceUsageTotals
  sessions: ChatSessionSummary[]
}

export interface ChatLiveState {
  surface: "index" | "new" | "session" | string | null
  current_session: ChatSessionSummary | null
  default_model_key: string
  models: ChatModelOption[]
  usage_totals: ChatWorkspaceUsageTotals
  loading: boolean
  error: string | null
}

export interface ChatSessionsResponse {
  scope: ChatScope
  sessions: ChatSessionSummary[]
}

export interface ChatSessionResponse {
  scope: ChatScope
  session: ChatSessionSummary
}

export interface ChatSessionDetailResponse {
  scope: ChatScope
  session: ChatSessionSummary
  messages: ChatMessageSummary[]
}

export interface ChatSessionCreatePayload {
  title_seed?: string
}

export interface ChatSessionUpdatePayload {
  status: "archived"
}

export interface ChatStreamPayload {
  body: string
  model_key?: string
}

export type ChatStreamEventName =
  | "stream_ready"
  | "user_message_committed"
  | "assistant_started"
  | "assistant_delta"
  | "assistant_completed"
  | "assistant_failed"

export interface ChatStreamEventMap {
  stream_ready: { session_id: string }
  user_message_committed: { session: { id: string; workspace_id: string }; message: ChatMessageSummary }
  assistant_started: { session: { id: string; workspace_id: string }; message: ChatMessageSummary }
  assistant_delta: { session_id: string; delta: string }
  assistant_completed: { session: { id: string; workspace_id: string }; message: ChatMessageSummary }
  assistant_failed: { session: { id: string; workspace_id: string }; message: ChatMessageSummary }
}
