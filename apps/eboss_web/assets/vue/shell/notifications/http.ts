import type {
  NotificationBootstrap,
  NotificationChannelSummary,
  NotificationPreferenceSummary,
  NotificationStatus,
  NotificationSummary,
} from "./types"

interface ApiErrorPayload {
  error?: {
    code?: string
    message?: string
  }
}

export class NotificationApiError extends Error {
  public readonly status: number
  public readonly code?: string

  constructor(status: number, statusText: string, payload?: ApiErrorPayload | null) {
    super(payload?.error?.message || `Request failed (${status} ${statusText})`)
    this.name = "NotificationApiError"
    this.status = status
    this.code = payload?.error?.code
  }
}

const csrfTokenFromMeta = (): string | null => {
  if (typeof document === "undefined") return null

  const token = document.querySelector<HTMLMetaElement>('meta[name="csrf-token"]')?.content
  return token && token.trim() !== "" ? token : null
}

const requestJson = async <T>(url: string, init: RequestInit = {}): Promise<T> => {
  const method = init.method ?? "GET"
  const headers = new Headers({ Accept: "application/json" })

  if (init.body && !headers.has("content-type")) {
    headers.set("content-type", "application/json")
  }

  if (!["GET", "HEAD", "OPTIONS"].includes(method.toUpperCase())) {
    const csrfToken = csrfTokenFromMeta()

    if (csrfToken) headers.set("x-csrf-token", csrfToken)
  }

  const response = await fetch(url, {
    credentials: "same-origin",
    ...init,
    method,
    headers,
  })

  const payload = await response.json().catch(() => null)

  if (!response.ok) {
    throw new NotificationApiError(response.status, response.statusText, payload as ApiErrorPayload | null)
  }

  return payload as T
}

export const fetchNotificationBootstrap = (): Promise<NotificationBootstrap> =>
  requestJson<NotificationBootstrap>("/api/v1/notifications/bootstrap")

export const fetchNotifications = (params: Record<string, string | null | undefined> = {}): Promise<{ notifications: NotificationSummary[] }> => {
  const search = new URLSearchParams()

  for (const [key, value] of Object.entries(params)) {
    if (value) search.set(key, value)
  }

  const suffix = search.toString()
  return requestJson<{ notifications: NotificationSummary[] }>(`/api/v1/notifications${suffix ? `?${suffix}` : ""}`)
}

export const updateNotificationStatus = (
  recipientId: string,
  status: Extract<NotificationStatus, "read" | "archived">,
): Promise<{ notification: NotificationSummary }> =>
  requestJson<{ notification: NotificationSummary }>(`/api/v1/notifications/${recipientId}`, {
    method: "PATCH",
    body: JSON.stringify({ status }),
  })

export const markAllNotificationsRead = (): Promise<{ unread_count: number; notifications: NotificationSummary[] }> =>
  requestJson<{ unread_count: number; notifications: NotificationSummary[] }>("/api/v1/notifications/read-all", {
    method: "POST",
    body: JSON.stringify({}),
  })

export const fetchNotificationPreferences = (): Promise<{ preferences: NotificationPreferenceSummary[] }> =>
  requestJson<{ preferences: NotificationPreferenceSummary[] }>("/api/v1/notifications/preferences")

export const updateNotificationPreferences = (
  preferences: Array<Partial<NotificationPreferenceSummary>>,
): Promise<{ preferences: NotificationPreferenceSummary[] }> =>
  requestJson<{ preferences: NotificationPreferenceSummary[] }>("/api/v1/notifications/preferences", {
    method: "PATCH",
    body: JSON.stringify({ preferences }),
  })

export const fetchNotificationChannels = (): Promise<{ channels: NotificationChannelSummary[] }> =>
  requestJson<{ channels: NotificationChannelSummary[] }>("/api/v1/notifications/channels")

export const updateNotificationChannel = (
  endpointId: string,
  attrs: Partial<Pick<NotificationChannelSummary, "address" | "external_id" | "status" | "primary" | "metadata">>,
): Promise<{ channel: NotificationChannelSummary }> =>
  requestJson<{ channel: NotificationChannelSummary }>(`/api/v1/notifications/channels/${endpointId}`, {
    method: "PATCH",
    body: JSON.stringify(attrs),
  })
