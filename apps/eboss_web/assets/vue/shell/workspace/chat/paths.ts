import type { WorkspaceScope } from "../types"
import type { ChatWorkspaceRef } from "./types"

const API_ROOT = "/api/v1"

const encodeSegment = (value: string): string => encodeURIComponent(value)

const workspacePath = ({ ownerSlug, workspaceSlug }: ChatWorkspaceRef): string =>
  `${API_ROOT}/${encodeSegment(ownerSlug)}/workspaces/${encodeSegment(workspaceSlug)}`

export const chatBasePath = (scope: ChatWorkspaceRef): string =>
  `${workspacePath(scope)}/apps/chat`

export const chatBootstrapPath = (scope: ChatWorkspaceRef): string =>
  `${chatBasePath(scope)}/bootstrap`

export const chatSessionsPath = (scope: ChatWorkspaceRef): string =>
  `${chatBasePath(scope)}/sessions`

export const chatSessionPath = (scope: ChatWorkspaceRef, sessionId: string): string =>
  `${chatSessionsPath(scope)}/${encodeSegment(sessionId)}`

export const chatStreamPath = (scope: ChatWorkspaceRef, sessionId: string): string =>
  `${chatSessionPath(scope, sessionId)}/messages/stream`

export const chatWorkspaceRef = (scope: WorkspaceScope | null): ChatWorkspaceRef | null => {
  const workspace = scope?.currentWorkspace

  if (!workspace) return null

  return {
    ownerSlug: workspace.ownerSlug,
    workspaceSlug: workspace.slug,
  }
}
