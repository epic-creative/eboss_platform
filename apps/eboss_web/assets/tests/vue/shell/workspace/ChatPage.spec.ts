import { flushPromises } from "@vue/test-utils"
import { nextTick } from "vue"
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest"

import { mountComponent } from "@/tests/vue/support/mount"
import ChatPage from "@/vue/shell/workspace/ChatPage.vue"
import { chatMessageRowTestId, chatSessionRowTestId, chatSurfaceTestContracts } from "@/vue/shell/workspace/testContracts"
import type {
  ChatBootstrapResponse,
  ChatMessageSummary,
  ChatModelOption,
  ChatSessionDetailResponse,
  ChatSessionSummary,
  ChatWorkspaceRef,
} from "@/vue/shell/workspace/chat"
import type { AppNavigation, WorkspaceScope } from "@/vue/shell/workspace/types"

const chatMocks = vi.hoisted(() => ({
  fetchChatBootstrap: vi.fn(),
  fetchChatSession: vi.fn(),
  createChatSession: vi.fn(),
  archiveChatSession: vi.fn(),
  streamChatReply: vi.fn(),
  chatWorkspaceRef: vi.fn(),
}))

vi.mock("@/vue/shell/workspace/chat", () => ({
  fetchChatBootstrap: chatMocks.fetchChatBootstrap,
  fetchChatSession: chatMocks.fetchChatSession,
  createChatSession: chatMocks.createChatSession,
  archiveChatSession: chatMocks.archiveChatSession,
  streamChatReply: chatMocks.streamChatReply,
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

const bootstrapResponse = (
  sessions: ChatSessionSummary[] = [],
): ChatBootstrapResponse => ({
  scope: {} as never,
  default_model_key: "anthropic_haiku_4_5",
  models: chatModels,
  usage_totals: {
    sessions: sessions.length,
    input_tokens: 0,
    output_tokens: 0,
    total_tokens: 0,
  },
  sessions,
})

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

const sessionDetail = (
  currentSession: ChatSessionSummary,
  messages: ChatMessageSummary[],
): ChatSessionDetailResponse => ({
  scope: {
    app_key: "chat",
    workspace: {
      id: "workspace-1",
      name: "Main Workspace",
      slug: "main-workspace",
      dashboard_path: "/alpha-team/main-workspace",
      owner_slug: "alpha-team",
    },
    owner: {
      type: "user",
      id: "user-1",
      slug: "alpha-team",
      display_name: "Alpha Team",
    },
    app: {
      key: "chat",
      label: "Chat",
      default_path: "/alpha-team/main-workspace/apps/chat",
      enabled: true,
      capabilities: { read: true, manage: true },
    },
    capabilities: { read: true, manage: true },
    workspace_path: "/alpha-team/main-workspace",
    app_path: currentSession.path,
  },
  session: currentSession,
  messages,
})

describe("ChatPage", () => {
  beforeEach(() => {
    chatMocks.chatWorkspaceRef.mockReturnValue(workspaceRef)
    chatMocks.fetchChatBootstrap.mockReset()
    chatMocks.fetchChatSession.mockReset()
    chatMocks.createChatSession.mockReset()
    chatMocks.archiveChatSession.mockReset()
    chatMocks.streamChatReply.mockReset()
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

    chatMocks.fetchChatBootstrap
      .mockResolvedValueOnce(bootstrapResponse())
      .mockResolvedValueOnce(bootstrapResponse([createdSession]))
    chatMocks.createChatSession.mockResolvedValue({ scope: {} as never, session: createdSession })
    chatMocks.fetchChatSession.mockResolvedValue(
      sessionDetail(createdSession, [userMessage, assistantCompleted]),
    )
    chatMocks.streamChatReply.mockImplementation(async (_scope, _sessionId, _payload, handlers) => {
      handlers.onEvent("user_message_committed", {
        session: { id: createdSession.id, workspace_id: "workspace-1" },
        message: userMessage,
      })
      handlers.onEvent("assistant_started", {
        session: { id: createdSession.id, workspace_id: "workspace-1" },
        message: assistantStarted,
      })
      handlers.onEvent("assistant_delta", {
        session_id: createdSession.id,
        delta: "Haiku mock reply: ",
      })
      handlers.onEvent("assistant_delta", {
        session_id: createdSession.id,
        delta: "We should tighten the launch checklist.",
      })
      handlers.onEvent("assistant_completed", {
        session: { id: createdSession.id, workspace_id: "workspace-1" },
        message: assistantCompleted,
      })
    })

    const wrapper = mountComponent(ChatPage, {
      props: {
        currentScope: scope(),
        currentPage: appRoute(["new"]),
      },
    })

    await flushPromises()

    await wrapper.get(`[data-testid="${chatSurfaceTestContracts.modelPickerTestId}"] select`).setValue("openai_gpt_4o_mini")
    await wrapper.get(`textarea`).setValue("We need a launch plan")
    await wrapper.get(`[data-testid="${chatSurfaceTestContracts.sendButtonTestId}"]`).trigger("click")
    await flushPromises()
    await nextTick()

    expect(chatMocks.createChatSession).toHaveBeenCalledWith(workspaceRef, { title_seed: "We need a launch plan" })
    expect(chatMocks.streamChatReply).toHaveBeenCalledWith(
      workspaceRef,
      createdSession.id,
      { body: "We need a launch plan", model_key: "openai_gpt_4o_mini" },
      expect.any(Object),
    )
    expect(window.history.replaceState).toHaveBeenCalledWith(
      {},
      "",
      createdSession.path,
    )
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

    chatMocks.fetchChatBootstrap.mockResolvedValue(bootstrapResponse([sessionOne, sessionTwo]))
    chatMocks.fetchChatSession
      .mockResolvedValueOnce(sessionDetail(sessionTwo, [message({ id: "message-2", body: "Ops check-in" })]))
      .mockResolvedValueOnce(sessionDetail(sessionOne, [message({ body: "Launch check-in" })]))

    const wrapper = mountComponent(ChatPage, {
      props: {
        currentScope: scope(),
        currentPage: appRoute(["sessions", sessionTwo.id]),
      },
    })

    await flushPromises()

    expect(chatMocks.fetchChatSession).toHaveBeenCalledWith(workspaceRef, sessionTwo.id)
    expect(wrapper.text()).toContain("Ops check-in")

    await wrapper.get(`[data-testid="${chatSessionRowTestId(sessionOne.id)}"]`).trigger("click")
    await flushPromises()

    expect(chatMocks.fetchChatSession).toHaveBeenCalledWith(workspaceRef, sessionOne.id)
    expect(window.history.pushState).toHaveBeenCalledWith({}, "", sessionOne.path)
    expect(wrapper.text()).toContain("Launch check-in")
  })

  it("locks the composer while a reply is in progress", async () => {
    const createdSession = session()
    let resolveStream: (() => void) | undefined

    chatMocks.fetchChatBootstrap
      .mockResolvedValueOnce(bootstrapResponse())
      .mockResolvedValueOnce(bootstrapResponse([createdSession]))
    chatMocks.createChatSession.mockResolvedValue({ scope: {} as never, session: createdSession })
    chatMocks.fetchChatSession.mockResolvedValue(sessionDetail(createdSession, []))
    chatMocks.streamChatReply.mockImplementation(
      () =>
        new Promise<void>((resolve) => {
          resolveStream = resolve
        }),
    )

    const wrapper = mountComponent(ChatPage, {
      props: {
        currentScope: scope(),
        currentPage: appRoute(["new"]),
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

    if (resolveStream) {
      resolveStream()
    }
    await flushPromises()
  })

  it("removes an archived session from the rail and returns to draft mode", async () => {
    const activeSession = session()

    chatMocks.fetchChatBootstrap.mockResolvedValue(bootstrapResponse([activeSession]))
    chatMocks.fetchChatSession.mockResolvedValue(sessionDetail(activeSession, [message()]))
    chatMocks.archiveChatSession.mockResolvedValue({
      scope: {} as never,
      session: { ...activeSession, status: "archived" },
    })

    const wrapper = mountComponent(ChatPage, {
      props: {
        currentScope: scope(),
        currentPage: appRoute(["sessions", activeSession.id]),
      },
    })

    await flushPromises()

    await wrapper.get('button.so-button-ghost').trigger("click")
    await flushPromises()

    expect(chatMocks.archiveChatSession).toHaveBeenCalledWith(workspaceRef, activeSession.id, {
      status: "archived",
    })
    expect(wrapper.find(`[data-testid="${chatSessionRowTestId(activeSession.id)}"]`).exists()).toBe(false)
    expect(window.history.pushState).toHaveBeenCalledWith(
      {},
      "",
      "/alpha-team/main-workspace/apps/chat/new",
    )
    expect(wrapper.find(`[data-testid="${chatSurfaceTestContracts.emptyStateTestId}"]`).exists()).toBe(true)
  })
})
