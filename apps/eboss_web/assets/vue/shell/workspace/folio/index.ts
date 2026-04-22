// LiveVue browser UI barrel.
// Keep REST helpers out of this entrypoint so workspace surfaces default to
// LiveView-owned state and event replies. External/API clients that need HTTP
// contracts should import from ./queries or ./http directly.
export {
  folioActivityPath,
  folioBasePath,
  folioBootstrapPath,
  folioProjectPath,
  folioProjectsPath,
  folioTaskPath,
  folioTasksPath,
  folioWorkspaceRef,
} from "./paths"
export type {
  FolioProjectStatus,
  FolioTaskStatus,
  FolioActivityEvent,
  FolioActivityResponse,
  FolioBootstrapResponse,
  FolioProjectSummary,
  FolioTaskActiveDelegationSummary,
  FolioTaskCreatePayload,
  FolioTaskCreateResponse,
  FolioTaskDelegatePayload,
  FolioTaskDelegationContactSummary,
  FolioTaskTransitionPayload,
  FolioTaskTransitionResponse,
  FolioProjectTransitionPayload,
  FolioProjectTransitionResponse,
  FolioProjectUpdatePayload,
  FolioProjectUpdateResponse,
  FolioProjectsResponse,
  FolioScope,
  FolioSummaryCounts,
  FolioTaskSummary,
  FolioTasksResponse,
  FolioWorkspaceApp,
  FolioWorkspaceAppCapabilities,
  FolioWorkspaceRef,
  FolioWorkspaceSummary,
  FolioOwnerSummary,
} from "./types"
