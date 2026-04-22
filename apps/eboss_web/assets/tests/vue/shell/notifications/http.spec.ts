import { afterEach, beforeEach, describe, expect, it, vi } from "vitest"

import {
  fetchNotificationBootstrap,
  updateNotificationChannel,
  updateNotificationPreferences,
  updateNotificationStatus,
} from "@/vue/shell/notifications/http"

const jsonResponse = (payload: unknown, init: ResponseInit = {}) =>
  new Response(JSON.stringify(payload), {
    status: 200,
    headers: { "content-type": "application/json" },
    ...init,
  })

describe("notification http client", () => {
  beforeEach(() => {
    document.head.innerHTML = '<meta name="csrf-token" content="csrf-token-123" />'
    vi.stubGlobal("fetch", vi.fn().mockResolvedValue(jsonResponse({})))
  })

  afterEach(() => {
    vi.unstubAllGlobals()
    document.head.innerHTML = ""
  })

  it("does not attach csrf tokens to safe notification reads", async () => {
    await fetchNotificationBootstrap()

    const [, init] = vi.mocked(fetch).mock.calls[0]
    const headers = new Headers(init?.headers)

    expect(init?.method).toBe("GET")
    expect(headers.has("x-csrf-token")).toBe(false)
  })

  it("attaches csrf tokens to notification recipient mutations", async () => {
    await updateNotificationStatus("recipient-1", "read")

    const [url, init] = vi.mocked(fetch).mock.calls[0]
    const headers = new Headers(init?.headers)

    expect(url).toBe("/api/v1/notifications/recipient-1")
    expect(init?.method).toBe("PATCH")
    expect(headers.get("x-csrf-token")).toBe("csrf-token-123")
    expect(headers.get("content-type")).toBe("application/json")
  })

  it("posts preferences and channel endpoint updates through the notification API", async () => {
    vi.mocked(fetch)
      .mockResolvedValueOnce(jsonResponse({ preferences: [] }))
      .mockResolvedValueOnce(jsonResponse({ channel: { id: "endpoint-1" } }))

    await updateNotificationPreferences([
      {
        scope_type: "system",
        channel: "telegram",
        enabled: true,
        cadence: "immediate",
      },
    ])

    await updateNotificationChannel("endpoint-1", { status: "disabled" })

    expect(vi.mocked(fetch).mock.calls[0][0]).toBe("/api/v1/notifications/preferences")
    expect(vi.mocked(fetch).mock.calls[1][0]).toBe("/api/v1/notifications/channels/endpoint-1")
  })
})
