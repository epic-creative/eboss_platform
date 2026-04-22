import { flushPromises } from "@vue/test-utils"
import { nextTick } from "vue"
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest"

import { mountComponent } from "@/tests/vue/support/mount"
import ChatPage from "@/vue/shell/workspace/ChatPage.vue"
import { chatMessageRowTestId, chatSessionRowTestId, chatSurfaceTestContracts } from "@/vue/shell/workspace/testContracts"
import type {
  ChatLiveState,
  ChatMessageSummary,
  ChatModelOption,
  ChatSessionSummary,
  ChatWorkspaceRef,
} from "@/vue/shell/workspace/chat"
import type { AppNavigation, WorkspaceScope } from "@/vue/shell/workspace/types"

const chatMocks = vi.hoisted(() => ({
  chatWorkspaceRef: vi.fn(),
}))

vi.mock("@/vue/shell/workspace/chat", () => ({
  chatWorkspaceRef: chatMocks.chatWorkspaceRef,
}))

const workspaceRef: ChatWorkspaceRef = {
  ownerSlug: "alpha-team",
  workspaceSlug: "main-workspace",
}

const chatModels: ChatModelOption[] = [
  {
    key: "anthropic_haiku_4_5",
    label: "Claude Haiku 4.5",
    provider: "anthropic",
    model: "anthropic:claude-haiku-4-5-20251001",
  },
  {
    key: "openai_gpt_4o_mini",
    label: "OpenAI GPT-4o mini",
    provider: "openai",
    model: "openai:gpt-4o-mini",
  },
]

const scope = (overrides: Partial<WorkspaceScope> = {}): WorkspaceScope => ({
  empty: false,
  dashboardPath: "/alpha-team/main-workspace",
  currentWorkspace: {
    id: "workspace-1",
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
  apps: {
    chat: {
      key: "chat",
      label: "Chat",
      defaultPath: "/alpha-team/main-workspace/apps/chat",
      enabled: true,
      capabilities: {
        read: true,
        manage: true,
      },
    },
  },
  accessibleWorkspaces: [],
  ...overrides,
})

const appRoute = (appPath: string[] = []): AppNavigation => ({
  type: "app",
  app_key: "chat",
  app_surface: appPath[0] ?? null,
  app_path: appPath,
})

const session = (overrides: Partial<ChatSessionSummary> = {}): ChatSessionSummary => ({
  id: "session-1",
  title: "Launch planning",
  status: "active",
  last_message_at: "2026-04-20T15:00:00Z",
  last_activity_at: "2026-04-20T15:00:00Z",
  message_count: 2,
  usage_totals: {
    input_tokens: 12,
    output_tokens: 21,
    total_tokens: 33,
  },
  created_by_user: {
    id: "user-1",
    username: "operator",
    email: "operator@example.com",
  },
  path: "/alpha-team/main-workspace/apps/chat/sessions/session-1",
  ...overrides,
})

const message = (overrides: Partial<ChatMessageSummary> = {}): ChatMessageSummary => ({
  id: "message-1",
  role: "user",
  body: "What should we do next?",
  status: "complete",
  sequence: 1,
  provider: null,
  model: null,
  input_tokens: 0,
  output_tokens: 0,
  total_tokens: 0,
  finish_reason: null,
  error_message: null,
  inserted_at: "2026-04-20T15:00:00Z",
  author: {
    id: "user-1",
    username: "operator",
    email: "operator@example.com",
  },
  ...overrides,
})

const chatState = (overrides: Partial<ChatLiveState> = {}): ChatLiveState => ({
  surface: "index",
  current_session: null,
  default_model_key: "anthropic_haiku_4_5",
  models: chatModels,
  usage_totals: {
    sessions: 0,
    input_tokens: 0,
    output_tokens: 0,
    total_tokens: 0,
  },
  loading: false,
  error: null,
  ...overrides,
})

const setLiveReply = (
  handler: (eventName: string, params: Record<string, unknown>) => unknown,
) => {
  const liveReply = vi.fn(handler)
  ;(globalThis as typeof globalThis & { __liveVueEventReply: typeof liveReply }).__liveVueEventReply = liveReply
  return liveReply
}

const emitLiveEvent = (eventName: string, payload: unknown) => {
  const handlers =
    (globalThis as typeof globalThis & {
      __liveVueEventHandlers?: Record<string, Array<(payload: unknown) => void>>
    }).__liveVueEventHandlers?.[eventName] ?? []

  for (const handler of handlers) {
    handler(payload)
  }
}

describe("ChatPage", () => {
  beforeEach(() => {
    chatMocks.chatWorkspaceRef.mockReturnValue(workspaceRef)
    vi.spyOn(window.history, "pushState").mockImplementation(() => undefined)
    vi.spyOn(window.history, "replaceState").mockImplementation(() => undefined)
  })

  afterEach(() => {
    vi.restoreAllMocks()
  })

  it("creates a draft session on first send and accumulates the streamed assistant reply", async () => {
    const createdSession = session()
    const userMessage = message()
    const assistantStarted = message({
      id: "message-2",
      role: "assistant",
      body: "",
      status: "pending",
      sequence: 2,
      author: null,
    })
    const assistantCompleted: ChatMessageSummary = {
      ...assistantStarted,
      body: "Haiku mock reply: We should tighten the launch checklist.",
      status: "complete",
      total_tokens: 42,
      provider: "anthropic",
      model: "anthropic:claude-haiku-4-5-20251001",
      output_tokens: 30,
      input_tokens: 12,
      finish_reason: "stop",
    }

    const liveReply = setLiveReply((eventName, params) => {
      expect(eventName).toBe("chat:send_message")
      expect(params).toEqual({
        session_id: undefined,
        body: "We need a launch plan",
        model_key: "openai_gpt_4o_mini",
      })

      return { ok: true, session: createdSession }
    })

    const wrapper = mountComponent(ChatPage, {
      props: {
        currentScope: scope(),
        currentPage: appRoute(["new"]),
        chatState: chatState({
          surface: "new",
        }),
      },
    })

    await flushPromises()

    await wrapper.get(`[data-testid="${chatSurfaceTestContracts.modelPickerTestId}"] select`).setValue("openai_gpt_4o_mini")
    await wrapper.get(`textarea`).setValue("We need a launch plan")
    await wrapper.get(`[data-testid="${chatSurfaceTestContracts.sendButtonTestId}"]`).trigger("click")
    await flushPromises()
    await nextTick()

    expect(liveReply).toHaveBeenCalledTimes(1)
    expect(window.history.replaceState).toHaveBeenCalledWith(
      {},
      "",
      createdSession.path,
    )

    await wrapper.setProps({
      currentPage: appRoute(["sessions", createdSession.id]),
      chatState: chatState({
        surface: "session",
        current_session: createdSession,
      }),
      chatSessions: [createdSession],
      chatMessages: [userMessage, assistantStarted],
    })

    emitLiveEvent("chat:assistant_delta", {
      session_id: createdSession.id,
      delta: "Haiku mock reply: ",
    })
    emitLiveEvent("chat:assistant_delta", {
      session_id: createdSession.id,
      delta: "We should tighten the launch checklist.",
    })
    emitLiveEvent("chat:assistant_completed", {
      session_id: createdSession.id,
      message: assistantCompleted,
    })
    await nextTick()

    expect(wrapper.text()).toContain("Haiku mock reply: We should tighten the launch checklist.")
    expect(wrapper.find(`[data-testid="${chatMessageRowTestId("message-2")}"]`).exists()).toBe(true)
    expect(wrapper.find(`[data-testid="${chatSurfaceTestContracts.pendingStateTestId}"]`).exists()).toBe(
      false,
    )
  })

  it("loads the requested session and switches to another session from the rail", async () => {
    const sessionOne = session()
    const sessionTwo = session({
      id: "session-2",
      title: "Ops review",
      path: "/alpha-team/main-workspace/apps/chat/sessions/session-2",
    })

    const wrapper = mountComponent(ChatPage, {
      props: {
        currentScope: scope(),
        currentPage: appRoute(["sessions", sessionTwo.id]),
        chatState: chatState({
          surface: "session",
          current_session: sessionTwo,
        }),
        chatSessions: [sessionOne, sessionTwo],
        chatMessages: [message({ id: "message-2", body: "Ops check-in" })],
      },
    })

    await flushPromises()

    expect(wrapper.text()).toContain("Ops check-in")

    await wrapper.get(`[data-testid="${chatSessionRowTestId(sessionOne.id)}"]`).trigger("click")
    await flushPromises()

    expect(window.history.pushState).toHaveBeenCalledWith({}, "", sessionOne.path)

    await wrapper.setProps({
      currentPage: appRoute(["sessions", sessionOne.id]),
      chatState: chatState({
        surface: "session",
        current_session: sessionOne,
      }),
      chatSessions: [sessionOne, sessionTwo],
      chatMessages: [message({ body: "Launch check-in" })],
    })
    await flushPromises()

    expect(wrapper.text()).toContain("Launch check-in")
  })

  it("locks the composer while a reply is in progress", async () => {
    const createdSession = session()
    let resolveReply: (() => void) | undefined

    setLiveReply(() =>
      new Promise(resolve => {
        resolveReply = () => resolve({ ok: true, session: createdSession })
      }),
    )

    const wrapper = mountComponent(ChatPage, {
      props: {
        currentScope: scope(),
        currentPage: appRoute(["new"]),
        chatState: chatState({
          surface: "new",
        }),
      },
    })

    await flushPromises()

    await wrapper.get("textarea").setValue("Hold the composer")
    await wrapper.get(`[data-testid="${chatSurfaceTestContracts.sendButtonTestId}"]`).trigger("click")
    await nextTick()

    expect(wrapper.get("textarea").attributes("disabled")).toBeDefined()
    expect(
      wrapper.get(`[data-testid="${chatSurfaceTestContracts.sendButtonTestId}"]`).attributes("disabled"),
    ).toBeDefined()
    expect(wrapper.find(`[data-testid="${chatSurfaceTestContracts.pendingStateTestId}"]`).exists()).toBe(
      true,
    )

    if (resolveReply) {
      resolveReply()
    }

    await flushPromises()

    emitLiveEvent("chat:assistant_completed", {
      session_id: createdSession.id,
      message: message({
        id: "message-2",
        role: "assistant",
        body: "Done.",
        sequence: 2,
      }),
    })
    await nextTick()

    expect(wrapper.find(`[data-testid="${chatSurfaceTestContracts.pendingStateTestId}"]`).exists()).toBe(
      false,
    )
  })

  it("removes an archived session from the rail and returns to draft mode", async () => {
    const activeSession = session()

    const liveReply = setLiveReply((eventName, params) => {
      expect(eventName).toBe("chat:archive_session")
      expect(params).toEqual({ session_id: activeSession.id })

      return {
        ok: true,
        session: { ...activeSession, status: "archived" },
      }
    })

    const wrapper = mountComponent(ChatPage, {
      props: {
        currentScope: scope(),
        currentPage: appRoute(["sessions", activeSession.id]),
        chatState: chatState({
          surface: "session",
          current_session: activeSession,
        }),
        chatSessions: [activeSession],
        chatMessages: [message()],
      },
    })

    await flushPromises()

    await wrapper.get('button.so-button-ghost').trigger("click")
    await flushPromises()

    expect(liveReply).toHaveBeenCalledTimes(1)
    expect(wrapper.find(`[data-testid="${chatSessionRowTestId(activeSession.id)}"]`).exists()).toBe(false)
    expect(window.history.pushState).toHaveBeenCalledWith(
      {},
      "",
      "/alpha-team/main-workspace/apps/chat/new",
    )
    expect(wrapper.find(`[data-testid="${chatSurfaceTestContracts.emptyStateTestId}"]`).exists()).toBe(true)
  })
})
