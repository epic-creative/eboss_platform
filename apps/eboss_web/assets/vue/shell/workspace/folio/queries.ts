import { requestJson } from "./http"
import { folioActivityPath, folioBootstrapPath, folioProjectsPath, folioTasksPath } from "./paths"
import type {
  FolioActivityResponse,
  FolioBootstrapResponse,
  FolioProjectsResponse,
  FolioTasksResponse,
  FolioWorkspaceRef,
} from "./types"

export const fetchFolioBootstrap = (scope: FolioWorkspaceRef): Promise<FolioBootstrapResponse> =>
  requestJson<FolioBootstrapResponse>(folioBootstrapPath(scope))

export const fetchFolioProjects = (scope: FolioWorkspaceRef): Promise<FolioProjectsResponse> =>
  requestJson<FolioProjectsResponse>(folioProjectsPath(scope))

export const fetchFolioTasks = (scope: FolioWorkspaceRef): Promise<FolioTasksResponse> =>
  requestJson<FolioTasksResponse>(folioTasksPath(scope))

export const fetchFolioActivity = (scope: FolioWorkspaceRef): Promise<FolioActivityResponse> =>
  requestJson<FolioActivityResponse>(folioActivityPath(scope))
