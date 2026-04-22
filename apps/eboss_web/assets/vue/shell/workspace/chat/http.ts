export interface ChatApiErrorPayload {
  error?: {
    code?: string
    message?: string
  }
}

export interface ChatApiRequestInit extends RequestInit {
  headers?: Record<string, string>
}

export class ChatApiError extends Error {
  public readonly status: number
  public readonly statusText: string
  public readonly code?: string

  constructor(status: number, statusText: string, payload?: ChatApiErrorPayload | null) {
    super(payload?.error?.message || `Request failed (${status} ${statusText})`)
    this.name = "ChatApiError"
    this.status = status
    this.statusText = statusText
    this.code = payload?.error?.code
  }
}

const csrfTokenFromMeta = (): string | null => {
  if (typeof document === "undefined") return null

  const token = document.querySelector<HTMLMetaElement>('meta[name="csrf-token"]')?.content
  return token && token.trim() !== "" ? token : null
}

const withHeaders = (headers?: Record<string, string>, method = "GET"): Headers => {
  const nextHeaders = new Headers({ Accept: "application/json" })

  for (const [key, value] of Object.entries(headers ?? {})) {
    nextHeaders.set(key, value)
  }

  if (!["GET", "HEAD", "OPTIONS"].includes(method.toUpperCase()) && !nextHeaders.has("x-csrf-token")) {
    const csrfToken = csrfTokenFromMeta()

    if (csrfToken) {
      nextHeaders.set("x-csrf-token", csrfToken)
    }
  }

  return nextHeaders
}

export const requestJson = async <T>(url: string, init: ChatApiRequestInit = {}): Promise<T> => {
  const method = init.method ?? "GET"
  const response = await fetch(url, {
    credentials: "same-origin",
    ...init,
    method,
    headers: withHeaders(init.headers, method),
  })

  const payload = await response.json().catch(() => null)

  if (!response.ok) {
    throw new ChatApiError(response.status, response.statusText, payload as ChatApiErrorPayload | null)
  }

  return payload as T
}

export const openEventStream = async (url: string, init: ChatApiRequestInit = {}): Promise<Response> => {
  const method = init.method ?? "POST"

  const response = await fetch(url, {
    credentials: "same-origin",
    ...init,
    method,
    headers: withHeaders(init.headers, method),
  })

  if (!response.ok) {
    const payload = await response.json().catch(() => null)
    throw new ChatApiError(response.status, response.statusText, payload as ChatApiErrorPayload | null)
  }

  return response
}
