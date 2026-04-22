import { afterEach, describe, expect, it, vi } from "vitest"
import { nextTick } from "vue"

import {
  folioProjectsPath,
  folioActivityPath,
  useFolioProjects,
  useFolioActivity,
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
    readChat: true,
    manageChat: true,
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
    await projectsQuery.refresh()

    expect(global.fetch).toHaveBeenCalledWith(
      folioProjectsPath({ ownerSlug: "alpha-team", workspaceSlug: "main-workspace" }),
      expect.any(Object),
    )
    expect(projectsQuery.projects.value).toHaveLength(1)
    expect(projectsQuery.projects.value[0].title).toBe("New project")
  })

  it("loads an activity response and exposes events", async () => {
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
        events: [
          {
            id: "event-001",
            app_key: "folio",
            provider_key: "activity",
            provider_event_id: "evt-20260419",
            occurred_at: "2026-04-19T12:00:00Z",
            actor: {
              type: "system",
              id: "system-operator",
              label: "Builder",
            },
            action: "created",
            summary: "Project Atlas was created",
            subject: {
              type: "project",
              id: "project-1",
              label: "Atlas Service",
            },
            details: "A new project has been provisioned.",
            status: "success",
            changes: {
              status: { before: "pending", after: "active" },
            },
            metadata: {
              source: "bootstrap",
            },
            resource_path: "/alpha-team/main-workspace/projects/project-1",
          },
        ],
      }),
    } as Response)

    const scopeRef = useFolioWorkspaceScope(scope())
    const activityQuery = useFolioActivity(scopeRef, { autoFetch: true })

    await nextTick()
    await activityQuery.refresh()

    expect(global.fetch).toHaveBeenCalledWith(
      folioActivityPath({ ownerSlug: "alpha-team", workspaceSlug: "main-workspace" }),
      expect.any(Object),
    )
    expect(activityQuery.events.value).toHaveLength(1)
    expect(activityQuery.events.value[0].id).toBe("event-001")
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
