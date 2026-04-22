export const workspaceAppTestContracts = {
  shellTestId: "workspace-shell",
  shellRegionLabel: "Workspace app shell",
  sidebarTestId: "workspace-sidebar",
  sidebarNavigationLabel: "Workspace navigation",
  sidebarAppsRegionLabel: "Workspace apps",
  currentAppTestId: "workspace-current-app",
  currentAppStatusLabel: "Current workspace app",
} as const

export const folioSurfaceTestContracts = {
  projects: {
    pageTestId: "workspace-page-projects",
    pageRegionLabel: "Folio projects page",
    listRegionLabel: "Folio projects list",
    loadingStateTestId: "projects-state-loading",
    errorStateTestId: "projects-state-error",
    emptyStateTestId: "projects-state-empty",
    emptyFilteredStateTestId: "projects-state-empty-filtered",
    inspectorTestId: "project-inspector",
  },
  tasks: {
    pageTestId: "workspace-page-tasks",
    pageRegionLabel: "Folio tasks page",
    listRegionLabel: "Folio tasks list",
    loadingStateTestId: "tasks-state-loading",
    errorStateTestId: "tasks-state-error",
    emptyStateTestId: "tasks-state-empty",
    emptyFilteredStateTestId: "tasks-state-empty-filtered",
    inspectorTestId: "task-inspector",
  },
  activity: {
    pageTestId: "workspace-page-activity",
    pageRegionLabel: "Folio activity page",
    feedRegionLabel: "Folio activity feed",
    loadingStateTestId: "activity-state-loading",
    errorStateTestId: "activity-state-error",
    emptyStateTestId: "activity-state-empty",
    inspectorTestId: "activity-inspector",
  },
} as const

export const folioProjectRowTestId = (projectId: string): string => `project-row-${projectId}`
export const folioTaskRowTestId = (taskId: string): string => `task-row-${taskId}`
export const folioActivityRowTestId = (eventId: string): string => `activity-row-${eventId}`

export const chatSurfaceTestContracts = {
  pageTestId: "workspace-page-chat",
  pageRegionLabel: "Workspace chat page",
  sessionsRegionLabel: "Chat sessions",
  transcriptRegionLabel: "Chat transcript",
  composerTestId: "chat-composer",
  sendButtonTestId: "chat-send-button",
  modelPickerTestId: "chat-model-picker",
  pendingStateTestId: "chat-state-pending",
  emptyStateTestId: "chat-state-empty",
} as const

export const chatSessionRowTestId = (sessionId: string): string => `chat-session-${sessionId}`
export const chatMessageRowTestId = (messageId: string): string => `chat-message-${messageId}`
