import { afterEach, describe, expect, it, vi } from "vitest"

import { FolioApiError, requestJson } from "@/vue/shell/workspace/folio/http"

describe("folio http client", () => {
  afterEach(() => {
    vi.restoreAllMocks()
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
})
