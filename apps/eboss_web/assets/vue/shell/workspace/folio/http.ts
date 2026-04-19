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

export const requestJson = async <T>(url: string, init: FolioApiRequestInit = {}): Promise<T> => {
  const response = await fetch(url, {
    credentials: "same-origin",
    headers: {
      Accept: "application/json",
      ...init.headers,
    },
    ...init,
  })

  const payload = await response.json().catch(() => null)

  if (!response.ok) {
    throw new FolioApiError(response.status, response.statusText, payload as FolioApiErrorPayload | null)
  }

  return payload as T
}
