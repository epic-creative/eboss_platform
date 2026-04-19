import { afterEach, describe, expect, it, vi } from "vitest"
import { nextTick } from "vue"

import {
  folioProjectsPath,
  useFolioProjects,
  useFolioWorkspaceScope,
} from "@/vue/shell/workspace/folio"
import type { WorkspaceScope } from "@/vue/shell/workspace/types"

const scope = (): WorkspaceScope => ({
  empty: false,
  dashboardPath: "/alpha-team/main-workspace",
  currentWorkspace: {
    id: "workspace-id",
    name: "Main Workspace",
    slug: "main-workspace",
    fullPath: "/alpha-team/main-workspace",
    visibility: "private",
    ownerType: "user",
    ownerSlug: "alpha-team",
    ownerDisplayName: "Alpha Team",
    dashboardPath: "/alpha-team/main-workspace",
    current: true,
  },
  owner: {
    type: "user",
    slug: "alpha-team",
    displayName: "Alpha Team",
  },
  capabilities: {
    readWorkspace: true,
    manageWorkspace: true,
    readFolio: true,
    manageFolio: true,
  },
  accessibleWorkspaces: [],
})

describe("folio composables", () => {
  afterEach(() => {
    vi.restoreAllMocks()
  })

  it("loads a projects response and exposes projects list", async () => {
    vi.spyOn(global, "fetch").mockResolvedValue({
      ok: true,
      status: 200,
      json: async () => ({
        scope: {
          app_key: "folio",
          workspace: {
            id: "workspace-id",
            name: "Main Workspace",
            slug: "main-workspace",
            full_path: "/alpha-team/main-workspace",
            visibility: "private",
            owner_type: "user",
            owner_id: "owner-id",
            owner_slug: "alpha-team",
            owner_display_name: "Alpha Team",
            dashboard_path: "/alpha-team/main-workspace",
            "current?": true,
          },
          owner: {
            type: "user",
            id: "owner-id",
            slug: "alpha-team",
            display_name: "Alpha Team",
          },
          app: {
            key: "folio",
            label: "Folio",
            default_path: "/alpha-team/main-workspace/apps/folio",
            enabled: true,
            capabilities: { read: true, manage: true },
          },
          capabilities: { read: true, manage: true },
          workspace_path: "/alpha-team/main-workspace",
          app_path: "/alpha-team/main-workspace/apps/folio",
        },
        projects: [
          {
            id: "project-id",
            title: "New project",
            status: "active",
            priority_position: 0,
            due_at: null,
            review_at: null,
          },
        ],
      }),
    } as Response)

    const scopeRef = useFolioWorkspaceScope(scope())
    const projectsQuery = useFolioProjects(scopeRef, { autoFetch: true })

    await nextTick()

    expect(global.fetch).toHaveBeenCalledWith(
      folioProjectsPath({ ownerSlug: "alpha-team", workspaceSlug: "main-workspace" }),
      expect.any(Object),
    )
    expect(projectsQuery.projects.value).toHaveLength(1)
    expect(projectsQuery.projects.value[0].title).toBe("New project")
  })

  it("suppresses auto-fetch when disabled and can be refreshed manually", async () => {
    const fetchMock = vi.spyOn(global, "fetch").mockResolvedValue({
      ok: true,
      status: 200,
      json: async () => ({
        scope: {},
        projects: [],
      }),
    } as Response)

    const scopeRef = useFolioWorkspaceScope(scope())
    const projectsQuery = useFolioProjects(scopeRef, {
      autoFetch: false,
      enabled: false,
    })

    expect(fetchMock).toHaveBeenCalledTimes(0)

    await projectsQuery.refresh()

    expect(global.fetch).toHaveBeenCalledTimes(1)
    expect(projectsQuery.projects.value).toHaveLength(0)
    expect(projectsQuery.error.value).toBeNull()
  })
})
