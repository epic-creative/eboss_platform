import { requestJson } from "./http"
import {
  folioActivityPath,
  folioBootstrapPath,
  folioProjectPath,
  folioProjectsPath,
  folioTaskPath,
  folioTasksPath,
} from "./paths"
import type {
  FolioActivityResponse,
  FolioBootstrapResponse,
  FolioProjectCreatePayload,
  FolioProjectCreateResponse,
  FolioProjectUpdatePayload,
  FolioProjectUpdateResponse,
  FolioProjectsResponse,
  FolioTaskCreatePayload,
  FolioTaskCreateResponse,
  FolioTaskTransitionPayload,
  FolioTaskTransitionResponse,
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

export const createFolioProject = (
  scope: FolioWorkspaceRef,
  payload: FolioProjectCreatePayload,
): Promise<FolioProjectCreateResponse> =>
  requestJson<FolioProjectCreateResponse>(folioProjectsPath(scope), {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(payload),
  })

export const createFolioTask = (
  scope: FolioWorkspaceRef,
  payload: FolioTaskCreatePayload,
): Promise<FolioTaskCreateResponse> =>
  requestJson<FolioTaskCreateResponse>(folioTasksPath(scope), {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(payload),
  })

export const transitionFolioTask = (
  scope: FolioWorkspaceRef,
  taskId: string,
  payload: FolioTaskTransitionPayload,
): Promise<FolioTaskTransitionResponse> =>
  requestJson<FolioTaskTransitionResponse>(folioTaskPath(scope, taskId), {
    method: "PATCH",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(payload),
  })

export const updateFolioProject = (
  scope: FolioWorkspaceRef,
  projectId: string,
  payload: FolioProjectUpdatePayload,
): Promise<FolioProjectUpdateResponse> =>
  requestJson<FolioProjectUpdateResponse>(folioProjectPath(scope, projectId), {
    method: "PATCH",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(payload),
  })
