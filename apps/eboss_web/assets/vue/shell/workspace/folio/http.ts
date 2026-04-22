/**
 * External Folio HTTP primitives.
 *
 * Browser-rendered workspace surfaces should not use this as their default data
 * path; use LiveVue events/props unless intentionally testing or consuming the
 * public REST contract.
 */
export interface FolioApiErrorPayload {
  error?: {
    code?: string
    message?: string
  }
}

export interface FolioApiRequestInit extends RequestInit {
  headers?: Record<string, string>
}

export class FolioApiError extends Error {
  public readonly status: number
  public readonly statusText: string
  public readonly code?: string

  constructor(status: number, statusText: string, payload?: FolioApiErrorPayload | null) {
    const message = payload?.error?.message || `Request failed (${status} ${statusText})`

    super(message)
    this.name = "FolioApiError"
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

const shouldAttachCsrfToken = (method: string): boolean => {
  return !["GET", "HEAD", "OPTIONS"].includes(method.toUpperCase())
}

export const requestJson = async <T>(url: string, init: FolioApiRequestInit = {}): Promise<T> => {
  const headers = new Headers({
    Accept: "application/json",
  })

  for (const [key, value] of Object.entries(init.headers ?? {})) {
    headers.set(key, value)
  }

  const method = init.method ?? "GET"

  if (shouldAttachCsrfToken(method) && !headers.has("x-csrf-token")) {
    const csrfToken = csrfTokenFromMeta()

    if (csrfToken) {
      headers.set("x-csrf-token", csrfToken)
    }
  }

  const response = await fetch(url, {
    credentials: "same-origin",
    ...init,
    headers,
  })

  const payload = await response.json().catch(() => null)

  if (!response.ok) {
    throw new FolioApiError(response.status, response.statusText, payload as FolioApiErrorPayload | null)
  }

  return payload as T
}
