<script setup lang="ts">
import { computed, ref, watch } from "vue"
import { Archive, MessageSquarePlus, Sparkles } from "lucide-vue-next"

import WorkspaceEmptyState from "./WorkspaceEmptyState.vue"
import WorkspacePageHeader from "./WorkspacePageHeader.vue"
import WorkspacePanel from "./WorkspacePanel.vue"
import { chatSessionRowTestId, chatMessageRowTestId, chatSurfaceTestContracts } from "./testContracts"
import {
  archiveChatSession,
  chatWorkspaceRef,
  createChatSession,
  fetchChatBootstrap,
  fetchChatSession,
  streamChatReply,
} from "./chat"
import type { ChatMessageSummary, ChatModelOption, ChatSessionSummary } from "./chat"
import type { AppNavigation, WorkspaceScope } from "./types"

const props = defineProps<{
  currentScope: WorkspaceScope
  currentPage: AppNavigation
}>()

const scopeRef = computed(() => chatWorkspaceRef(props.currentScope))
const appBasePath = computed(() => props.currentScope.apps?.chat?.defaultPath || `${props.currentScope.dashboardPath}/apps/chat`)
const routeSessionId = computed(() =>
  props.currentPage.app_key === "chat" && props.currentPage.app_path[0] === "sessions"
    ? props.currentPage.app_path[1] || null
    : null,
)
const routeIsDraft = computed(
  () => props.currentPage.app_key === "chat" && props.currentPage.app_path[0] === "new",
)

const sessions = ref<ChatSessionSummary[]>([])
const modelOptions = ref<ChatModelOption[]>([])
const selectedModelKey = ref("")
const currentSession = ref<ChatSessionSummary | null>(null)
const messages = ref<ChatMessageSummary[]>([])
const composer = ref("")
const loading = ref(false)
const sending = ref(false)
const archiving = ref(false)
const error = ref<string | null>(null)
const selectedSessionId = ref<string | null>(routeSessionId.value)
const draftMode = ref(routeIsDraft.value || (!routeSessionId.value && props.currentPage.app_path.length === 0))

const hasSessions = computed(() => sessions.value.length > 0)
const selectedModel = computed(() =>
  modelOptions.value.find(model => model.key === selectedModelKey.value) || modelOptions.value[0] || null,
)
const selectedModelLabel = computed(() => selectedModel.value?.label || "Workspace chat")
const transcriptTitle = computed(() => {
  if (draftMode.value) return "New chat"
  if (currentSession.value) return currentSession.value.title
  return hasSessions.value ? "Select a chat" : "Start your first chat"
})

const transcriptSubtitle = computed(() => {
  if (sending.value) return `${selectedModelLabel.value} is replying...`
  if (draftMode.value) return "The first message creates a shared workspace session."
  if (currentSession.value) return `${currentSession.value.message_count} messages · ${currentSession.value.usage_totals.total_tokens} tokens`
  return "Shared sessions are visible to workspace members."
})

const composerDisabled = computed(() => sending.value || archiving.value || !scopeRef.value)

const syncPath = (path: string, replace = false) => {
  if (typeof window === "undefined") return

  const method = replace ? "replaceState" : "pushState"
  window.history[method]({}, "", path)
}

const upsertSession = (session: ChatSessionSummary) => {
  const existingIndex = sessions.value.findIndex(existing => existing.id === session.id)

  if (existingIndex === -1) {
    sessions.value = [session, ...sessions.value]
    return
  }

  const next = [...sessions.value]
  next.splice(existingIndex, 1)
  sessions.value = [session, ...next]
}

const replaceMessage = (message: ChatMessageSummary) => {
  const existingIndex = messages.value.findIndex(existing => existing.id === message.id)

  if (existingIndex === -1) {
    messages.value = [...messages.value, message].sort((left, right) => left.sequence - right.sequence)
    return
  }

  const next = [...messages.value]
  next[existingIndex] = message
  messages.value = next
}

const appendAssistantDelta = (delta: string) => {
  const assistantIndex = [...messages.value].reverse().findIndex(message => message.role === "assistant" && message.status === "pending")

  if (assistantIndex === -1) return

  const actualIndex = messages.value.length - 1 - assistantIndex
  const next = [...messages.value]
  next[actualIndex] = {
    ...next[actualIndex],
    body: `${next[actualIndex].body}${delta}`,
  }
  messages.value = next
}

const loadBootstrap = async () => {
  if (!scopeRef.value) return

  loading.value = true
  error.value = null

  try {
    const response = await fetchChatBootstrap(scopeRef.value)
    sessions.value = response.sessions
    modelOptions.value = response.models || []

    if (!selectedModelKey.value || !modelOptions.value.some(model => model.key === selectedModelKey.value)) {
      selectedModelKey.value = response.default_model_key || modelOptions.value[0]?.key || ""
    }

    if (selectedSessionId.value) {
      const selected = response.sessions.find(session => session.id === selectedSessionId.value) || null
      currentSession.value = selected
    }
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : "Unexpected chat bootstrap error"
  } finally {
    loading.value = false
  }
}

const loadSession = async (sessionId: string) => {
  if (!scopeRef.value) return

  loading.value = true
  error.value = null

  try {
    const response = await fetchChatSession(scopeRef.value, sessionId)
    currentSession.value = response.session
    messages.value = response.messages
    upsertSession(response.session)
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : "Unexpected chat session error"
  } finally {
    loading.value = false
  }
}

const selectSession = async (session: ChatSessionSummary) => {
  draftMode.value = false
  selectedSessionId.value = session.id
  currentSession.value = session
  syncPath(session.path)
  await loadSession(session.id)
}

const startNewChat = () => {
  draftMode.value = true
  selectedSessionId.value = null
  currentSession.value = null
  messages.value = []
  error.value = null
  syncPath(`${appBasePath.value}/new`)
}

const archiveCurrentSession = async () => {
  if (!scopeRef.value || !currentSession.value || archiving.value) return

  archiving.value = true
  error.value = null

  try {
    await archiveChatSession(scopeRef.value, currentSession.value.id, { status: "archived" })
    sessions.value = sessions.value.filter(session => session.id !== currentSession.value?.id)
    startNewChat()
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : "Unexpected archive error"
  } finally {
    archiving.value = false
  }
}

const sendMessage = async () => {
  const messageBody = composer.value.trim()

  if (!scopeRef.value || messageBody === "" || composerDisabled.value) return

  sending.value = true
  error.value = null
  composer.value = ""

  try {
    let session = currentSession.value

    if (!session || draftMode.value) {
      const created = await createChatSession(scopeRef.value, { title_seed: messageBody })
      session = created.session
      currentSession.value = session
      selectedSessionId.value = session.id
      draftMode.value = false
      messages.value = []
      upsertSession(session)
      syncPath(session.path, true)
    }

    await streamChatReply(scopeRef.value, session.id, { body: messageBody, model_key: selectedModelKey.value }, {
      onEvent: (event, payload) => {
        if (
          (event === "user_message_committed" || event === "assistant_started" || event === "assistant_completed") &&
          "message" in payload
        ) {
          replaceMessage(payload.message)
        }

        if (event === "assistant_delta" && "delta" in payload) {
          appendAssistantDelta(payload.delta)
        }

        if (event === "assistant_failed" && "message" in payload) {
          replaceMessage(payload.message)
          error.value = payload.message.error_message || "The assistant reply failed."
        }
      },
    })

    await loadBootstrap()

    if (session) {
      await loadSession(session.id)
    }
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : "Unexpected chat stream error"
  } finally {
    sending.value = false
  }
}

watch(
  () => [scopeRef.value?.ownerSlug, scopeRef.value?.workspaceSlug],
  () => {
    void loadBootstrap()
  },
  { immediate: true },
)

watch(routeSessionId, sessionId => {
  selectedSessionId.value = sessionId
  draftMode.value = routeIsDraft.value || !sessionId

  if (sessionId) {
    void loadSession(sessionId)
  } else if (routeIsDraft.value) {
    currentSession.value = null
    messages.value = []
  }
}, { immediate: true })
</script>

<template>
  <section
    class="ui-workspace-page ui-workspace-chat"
    :data-testid="chatSurfaceTestContracts.pageTestId"
    :aria-label="chatSurfaceTestContracts.pageRegionLabel"
  >
    <WorkspacePageHeader title="Chat" subtitle="Shared, multi-session workspace conversations powered by Claude Haiku 4.5 and OpenAI">
      <template #actions>
        <label
          v-if="modelOptions.length"
          class="ui-workspace-chat__model-picker"
          :data-testid="chatSurfaceTestContracts.modelPickerTestId"
        >
          <span>Model</span>
          <select v-model="selectedModelKey" class="so-input-field">
            <option
              v-for="model in modelOptions"
              :key="model.key"
              :value="model.key"
            >
              {{ model.label }}
            </option>
          </select>
        </label>
        <button type="button" class="so-button-secondary" @click="startNewChat">
          <MessageSquarePlus class="h-4 w-4" />
          New chat
        </button>
      </template>
    </WorkspacePageHeader>

    <div class="ui-workspace-chat__grid">
      <WorkspacePanel
        title="Sessions"
        subtitle="Workspace-visible conversation threads"
        body-class="ui-workspace-chat__sessions-body"
      >
        <section
          class="ui-workspace-chat__sessions"
          role="region"
          :aria-label="chatSurfaceTestContracts.sessionsRegionLabel"
        >
          <button type="button" class="so-button-secondary w-full justify-start" @click="startNewChat">
            <MessageSquarePlus class="h-4 w-4" />
            Start a fresh session
          </button>

          <div v-if="!hasSessions" :data-testid="chatSurfaceTestContracts.emptyStateTestId">
            <WorkspaceEmptyState
              title="No chat sessions yet"
              copy="The first message creates a shared workspace conversation."
              compact
              dashed
            />
          </div>

          <button
            v-for="session in sessions"
            :key="session.id"
            type="button"
            class="ui-workspace-chat__session-row"
            :data-testid="chatSessionRowTestId(session.id)"
            :class="{ 'ui-workspace-chat__session-row--active': session.id === selectedSessionId }"
            @click="selectSession(session)"
          >
            <div class="ui-workspace-chat__session-row-top">
              <span class="ui-workspace-chat__session-title">{{ session.title }}</span>
              <span class="so-font-mono text-[10px] uppercase tracking-[0.18em] text-[hsl(var(--so-muted-foreground))]">
                {{ session.usage_totals.total_tokens }} tok
              </span>
            </div>
            <div class="ui-workspace-chat__session-row-meta">
              <span>{{ session.created_by_user.username }}</span>
              <span>{{ session.message_count }} messages</span>
            </div>
          </button>
        </section>
      </WorkspacePanel>

      <WorkspacePanel
        :title="transcriptTitle"
        :subtitle="transcriptSubtitle"
        body-class="ui-workspace-chat__transcript-shell"
      >
        <template #actions>
          <button
            v-if="currentSession"
            type="button"
            class="so-button-ghost"
            :disabled="archiving || sending"
            @click="archiveCurrentSession"
          >
            <Archive class="h-4 w-4" />
            Archive
          </button>
        </template>

        <section
          class="ui-workspace-chat__transcript"
          role="region"
          :aria-label="chatSurfaceTestContracts.transcriptRegionLabel"
        >
          <div v-if="error" class="rounded-xl border border-[hsl(var(--so-destructive))/0.3] bg-[hsl(var(--so-destructive))/0.08] px-4 py-3 text-sm text-[hsl(var(--so-destructive))]">
            {{ error }}
          </div>

          <WorkspaceEmptyState
            v-if="!messages.length && !loading"
            :title="draftMode ? 'Start the conversation' : 'No messages yet'"
            :copy="draftMode ? 'Write the first prompt below to create this shared chat session.' : 'Send the next prompt to continue the session.'"
            :icon="Sparkles"
            dashed
          />

          <article
            v-for="message in messages"
            :key="message.id"
            class="ui-workspace-chat__message"
            :class="`ui-workspace-chat__message--${message.role}`"
            :data-testid="chatMessageRowTestId(message.id)"
          >
            <header class="ui-workspace-chat__message-header">
              <span class="ui-workspace-chat__message-role">
                {{
                  message.role === "assistant"
                    ? "Assistant"
                    : message.author?.username || "Workspace member"
                }}
              </span>
              <span class="so-font-mono text-[10px] uppercase tracking-[0.18em] text-[hsl(var(--so-muted-foreground))]">
                {{ message.status }}
              </span>
            </header>
            <pre class="ui-workspace-chat__message-body">{{ message.body }}</pre>
          </article>
        </section>

        <template #footer>
          <div class="ui-workspace-chat__composer" :data-testid="chatSurfaceTestContracts.composerTestId">
            <textarea
              v-model="composer"
              class="so-input-field ui-workspace-chat__composer-input"
              :disabled="composerDisabled"
              placeholder="Message the workspace assistant..."
              rows="4"
            />

            <div class="ui-workspace-chat__composer-actions">
              <span
                v-if="sending"
                class="so-font-mono text-[11px] uppercase tracking-[0.18em] text-[hsl(var(--so-primary))]"
                :data-testid="chatSurfaceTestContracts.pendingStateTestId"
              >
                Reply in progress
              </span>
              <button
                type="button"
                class="so-button-primary"
                :disabled="composerDisabled || composer.trim() === ''"
                :data-testid="chatSurfaceTestContracts.sendButtonTestId"
                @click="sendMessage"
              >
                {{ sending ? "Sending..." : draftMode ? "Create and send" : "Send" }}
              </button>
            </div>
          </div>
        </template>
      </WorkspacePanel>
    </div>
  </section>
</template>
