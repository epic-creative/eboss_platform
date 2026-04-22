export type NotificationStatus = "unread" | "read" | "archived"
export type NotificationSeverity = "info" | "success" | "warning" | "error"
export type NotificationChannel = "in_app" | "email" | "sms" | "telegram" | "webhook" | "push"
export type NotificationCadence = "immediate" | "digest" | "disabled"

export interface NotificationDeliverySummary {
  id: string
  channel: NotificationChannel
  endpoint_id: string | null
  status: "pending" | "suppressed" | "not_configured" | "queued" | "sent" | "delivered" | "failed" | "canceled"
  provider: string | null
  provider_message_id: string | null
  attempt_count: number
  last_attempt_at: string | null
  delivered_at: string | null
  error_message: string | null
  metadata: Record<string, unknown>
}

export interface NotificationSummary {
  recipient_id: string
  notification_id: string
  status: NotificationStatus
  read_at: string | null
  archived_at: string | null
  last_seen_at: string | null
  title: string
  body: string | null
  severity: NotificationSeverity
  scope: {
    type: "system" | "user" | "organization" | "workspace" | "app"
    id: string | null
    workspace_id: string | null
    organization_id: string | null
  }
  app_key: string | null
  actor: {
    type: string
    id: string | null
  }
  subject: {
    type: string | null
    id: string | null
    label: string | null
  }
  action_url: string | null
  metadata: Record<string, unknown>
  occurred_at: string | null
  deliveries: NotificationDeliverySummary[]
}

export interface NotificationPreferenceSummary {
  id: string
  scope_type: string
  scope_id: string | null
  app_key: string | null
  notification_key: string | null
  channel: NotificationChannel
  enabled: boolean
  cadence: NotificationCadence
}

export interface NotificationChannelSummary {
  id: string | null
  channel: NotificationChannel
  address: string | null
  external_id: string | null
  status: "unverified" | "verified" | "disabled"
  primary: boolean
  verified_at: string | null
  metadata: Record<string, unknown>
  operational: boolean
}

export interface NotificationBootstrap {
  unread_count: number
  recent: NotificationSummary[]
  preferences: NotificationPreferenceSummary[]
  channels: NotificationChannelSummary[]
  supported_channels: NotificationChannel[]
  inactive_external_channels: NotificationChannel[]
}
