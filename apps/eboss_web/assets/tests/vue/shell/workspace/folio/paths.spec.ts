import { describe, expect, it } from "vitest"

import {
  folioActivityPath,
  folioBootstrapPath,
  folioProjectsPath,
  folioTasksPath,
  folioWorkspaceRef,
} from "@/vue/shell/workspace/folio/paths"
import type { WorkspaceScope } from "@/vue/shell/workspace/types"

const workspaceScope = (): WorkspaceScope => ({
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

describe("folio paths", () => {
  it("builds API URLs from workspace scope", () => {
    const scope = folioWorkspaceRef(workspaceScope())
    if (!scope) throw new Error("Expected workspace scope")

    expect(folioBootstrapPath(scope)).toBe(
      "/api/v1/alpha-team/workspaces/main-workspace/apps/folio/bootstrap",
    )
    expect(folioProjectsPath(scope)).toBe(
      "/api/v1/alpha-team/workspaces/main-workspace/apps/folio/projects",
    )
    expect(folioTasksPath(scope)).toBe("/api/v1/alpha-team/workspaces/main-workspace/apps/folio/tasks")
    expect(folioActivityPath(scope)).toBe("/api/v1/alpha-team/workspaces/main-workspace/apps/folio/activity")
  })

  it("percent-encodes owner and workspace path segments", () => {
    const encodedWorkspace = workspaceScope()
    if (!encodedWorkspace.currentWorkspace) {
      throw new Error("Expected workspace")
    }

    encodedWorkspace.currentWorkspace.ownerSlug = "acme team"
    encodedWorkspace.currentWorkspace.slug = "team workspace"
    const encodedScope = folioWorkspaceRef(encodedWorkspace)

    if (!encodedScope) throw new Error("Expected workspace scope")

    expect(folioBootstrapPath(encodedScope)).toBe(
      "/api/v1/acme%20team/workspaces/team%20workspace/apps/folio/bootstrap",
    )
  })

  it("returns null when no workspace is available", () => {
    expect(
      folioWorkspaceRef({
        ...workspaceScope(),
        currentWorkspace: null,
      }),
    ).toBeNull()
  })
})
