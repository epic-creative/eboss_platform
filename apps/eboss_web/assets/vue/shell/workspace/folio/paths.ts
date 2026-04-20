import type { WorkspaceScope } from "../types"
import type { FolioWorkspaceRef } from "./types"

const API_ROOT = "/api/v1"

const encodeSegment = (value: string): string => encodeURIComponent(value)

const workspacePath = ({ ownerSlug, workspaceSlug }: FolioWorkspaceRef): string =>
  `${API_ROOT}/${encodeSegment(ownerSlug)}/workspaces/${encodeSegment(workspaceSlug)}`

export const folioBasePath = (scope: FolioWorkspaceRef): string =>
  `${workspacePath(scope)}/apps/folio`

export const folioBootstrapPath = (scope: FolioWorkspaceRef): string =>
  `${folioBasePath(scope)}/bootstrap`

export const folioProjectsPath = (scope: FolioWorkspaceRef): string =>
  `${folioBasePath(scope)}/projects`

export const folioProjectPath = (scope: FolioWorkspaceRef, projectId: string): string =>
  `${folioProjectsPath(scope)}/${encodeSegment(projectId)}`

export const folioTasksPath = (scope: FolioWorkspaceRef): string =>
  `${folioBasePath(scope)}/tasks`

export const folioTaskPath = (scope: FolioWorkspaceRef, taskId: string): string =>
  `${folioTasksPath(scope)}/${encodeSegment(taskId)}`

export const folioActivityPath = (scope: FolioWorkspaceRef): string =>
  `${folioBasePath(scope)}/activity`

export const folioWorkspaceRef = (scope: WorkspaceScope | null): FolioWorkspaceRef | null => {
  const workspace = scope?.currentWorkspace

  if (!workspace) return null

  return {
    ownerSlug: workspace.ownerSlug,
    workspaceSlug: workspace.slug,
  }
}
