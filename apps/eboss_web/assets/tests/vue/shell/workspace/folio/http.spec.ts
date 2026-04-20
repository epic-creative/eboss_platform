import { afterEach, describe, expect, it, vi } from "vitest"

import { FolioApiError, requestJson } from "@/vue/shell/workspace/folio/http"

describe("folio http client", () => {
  afterEach(() => {
    vi.restoreAllMocks()
    document.head.innerHTML = ""
  })

  it("parses successful JSON responses", async () => {
    vi.spyOn(global, "fetch").mockResolvedValue({
      ok: true,
      status: 200,
      json: async () => ({ value: 42 }),
    } as Response)

    const payload = await requestJson<{ value: number }>("/api/v1/test")

    expect(payload).toEqual({ value: 42 })
    expect(global.fetch).toHaveBeenCalledWith("/api/v1/test", expect.objectContaining({ credentials: "same-origin" }))
  })

  it("throws typed errors when response is not ok", async () => {
    vi.spyOn(global, "fetch").mockResolvedValue({
      ok: false,
      status: 403,
      statusText: "Forbidden",
      json: async () => ({
        error: {
          code: "workspace_forbidden",
          message: "Workspace access is forbidden",
        },
      }),
    } as Response)

    await expect(requestJson("/api/v1/test")).rejects.toBeInstanceOf(FolioApiError)
    await expect(requestJson("/api/v1/test")).rejects.toMatchObject({
      status: 403,
      statusText: "Forbidden",
      code: "workspace_forbidden",
    })
  })

  it("attaches the csrf token for unsafe browser-session requests", async () => {
    document.head.innerHTML = '<meta name="csrf-token" content="csrf-token-123" />'

    vi.spyOn(global, "fetch").mockResolvedValue({
      ok: true,
      status: 200,
      json: async () => ({ ok: true }),
    } as Response)

    await requestJson("/api/v1/test", {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ status: "done" }),
    })

    const [, requestInit] = vi.mocked(global.fetch).mock.calls[0]
    const headers = new Headers(requestInit?.headers)

    expect(headers.get("x-csrf-token")).toBe("csrf-token-123")
    expect(headers.get("content-type")).toBe("application/json")
  })

  it("does not attach a csrf token for safe requests", async () => {
    document.head.innerHTML = '<meta name="csrf-token" content="csrf-token-123" />'

    vi.spyOn(global, "fetch").mockResolvedValue({
      ok: true,
      status: 200,
      json: async () => ({ ok: true }),
    } as Response)

    await requestJson("/api/v1/test")

    const [, requestInit] = vi.mocked(global.fetch).mock.calls[0]
    const headers = new Headers(requestInit?.headers)

    expect(headers.has("x-csrf-token")).toBe(false)
  })
})
