// LiveVue browser UI barrel.
// Keep REST/SSE helpers out of this entrypoint so workspace surfaces default to
// LiveView-owned state, event replies, and Phoenix streams. External/API clients
// that need HTTP contracts should import from ./queries or ./http directly.
export {
  chatBasePath,
  chatBootstrapPath,
  chatSessionPath,
  chatSessionsPath,
  chatStreamPath,
  chatWorkspaceRef,
} from "./paths"
export type {
  ChatBootstrapResponse,
  ChatLiveState,
  ChatMessageSummary,
  ChatModelOption,
  ChatScope,
  ChatSessionCreatePayload,
  ChatSessionDetailResponse,
  ChatSessionResponse,
  ChatSessionSummary,
  ChatSessionUpdatePayload,
  ChatStreamEventMap,
  ChatStreamEventName,
  ChatStreamPayload,
  ChatUsageTotals,
  ChatUserSummary,
  ChatWorkspaceRef,
  ChatWorkspaceUsageTotals,
} from "./types"
