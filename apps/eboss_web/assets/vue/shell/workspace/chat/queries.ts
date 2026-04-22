/**
 * External Chat REST/SSE client helpers.
 *
 * The signed-in browser UI should prefer LiveVue props, event replies, pushed
 * events, and Phoenix streams. Keep this module for external clients,
 * automation, and API contract tests.
 */
import { openEventStream, requestJson } from "./http"
import { chatBootstrapPath, chatSessionPath, chatSessionsPath, chatStreamPath } from "./paths"
import type {
  ChatBootstrapResponse,
  ChatSessionCreatePayload,
  ChatSessionDetailResponse,
  ChatSessionResponse,
  ChatSessionUpdatePayload,
  ChatStreamEventMap,
  ChatStreamEventName,
  ChatStreamPayload,
  ChatWorkspaceRef,
} from "./types"

export const fetchChatBootstrap = (scope: ChatWorkspaceRef): Promise<ChatBootstrapResponse> =>
  requestJson<ChatBootstrapResponse>(chatBootstrapPath(scope))

export const fetchChatSession = (
  scope: ChatWorkspaceRef,
  sessionId: string,
): Promise<ChatSessionDetailResponse> =>
  requestJson<ChatSessionDetailResponse>(chatSessionPath(scope, sessionId))

export const createChatSession = (
  scope: ChatWorkspaceRef,
  payload: ChatSessionCreatePayload,
): Promise<ChatSessionResponse> =>
  requestJson<ChatSessionResponse>(chatSessionsPath(scope), {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(payload),
  })

export const archiveChatSession = (
  scope: ChatWorkspaceRef,
  sessionId: string,
  payload: ChatSessionUpdatePayload,
): Promise<ChatSessionResponse> =>
  requestJson<ChatSessionResponse>(chatSessionPath(scope, sessionId), {
    method: "PATCH",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(payload),
  })

export interface ChatStreamHandlers {
  onEvent: <T extends ChatStreamEventName>(event: T, payload: ChatStreamEventMap[T]) => void
}

export const streamChatReply = async (
  scope: ChatWorkspaceRef,
  sessionId: string,
  payload: ChatStreamPayload,
  handlers: ChatStreamHandlers,
): Promise<void> => {
  const response = await openEventStream(chatStreamPath(scope, sessionId), {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(payload),
  })

  const reader = response.body?.getReader()

  if (!reader) return

  const decoder = new TextDecoder()
  let buffer = ""

  while (true) {
    const { done, value } = await reader.read()

    if (done) break

    buffer += decoder.decode(value, { stream: true })

    while (buffer.includes("\n\n")) {
      const boundary = buffer.indexOf("\n\n")
      const chunk = buffer.slice(0, boundary)
      buffer = buffer.slice(boundary + 2)

      const eventName = chunk
        .split("\n")
        .find(line => line.startsWith("event:"))
        ?.replace(/^event:\s*/, "")

      const dataLine = chunk
        .split("\n")
        .find(line => line.startsWith("data:"))
        ?.replace(/^data:\s*/, "")

      if (!eventName || !dataLine) continue

      handlers.onEvent(
        eventName as ChatStreamEventName,
        JSON.parse(dataLine) as ChatStreamEventMap[ChatStreamEventName],
      )
    }
  }
}
