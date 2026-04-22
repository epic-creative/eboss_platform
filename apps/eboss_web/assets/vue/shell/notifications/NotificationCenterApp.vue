<script setup lang="ts">
import { computed, ref, watch } from "vue"
import { useEventReply } from "live_vue"
import { Archive, Bell, Check, Mail, MessageCircle, Radio, Send, Smartphone } from "lucide-vue-next"

import ThemeToggleButton from "../shared/ThemeToggleButton.vue"
import type {
  NotificationBootstrap,
  NotificationChannel,
  NotificationPreferenceSummary,
  NotificationStatus,
  NotificationSummary,
} from "./types"

const props = defineProps<{
  currentUser: {
    username: string
    email: string
  }
  notificationBootstrap: NotificationBootstrap
  notifications?: NotificationSummary[]
  activeStatus?: "active" | "unread" | "read" | "archived" | "all"
  activeScope?: string
  dashboardPath: string
  signOutPath: string
  csrfToken: string
}>()

interface NotificationLiveReply {
  ok: boolean
  bootstrap?: NotificationBootstrap
  notifications?: NotificationSummary[]
  filters?: {
    status: "active" | "unread" | "read" | "archived" | "all"
    scope: string
  }
  error?: string
}

const bootstrap = ref<NotificationBootstrap>(props.notificationBootstrap)
const notifications = ref<NotificationSummary[]>(props.notifications ?? props.notificationBootstrap.recent)
const activeStatus = ref<"active" | "unread" | "read" | "archived" | "all">(props.activeStatus ?? "active")
const activeScope = ref<string>(props.activeScope ?? "all")
const error = ref<string | null>(null)
const statusTabs = ["active", "unread", "read", "archived", "all"] as const
const filterEvent = useEventReply<NotificationLiveReply, { status: string; scope: string }>("notifications:filter")
const markReadEvent = useEventReply<NotificationLiveReply, { recipient_id: string }>("notifications:mark_read")
const archiveEvent = useEventReply<NotificationLiveReply, { recipient_id: string }>("notifications:archive")
const markAllReadEvent = useEventReply<NotificationLiveReply, Record<string, never>>("notifications:mark_all_read")
const preferenceEvent = useEventReply<NotificationLiveReply, { channel: NotificationChannel; enabled: boolean }>("notifications:set_preference")

const unreadCount = computed(() => bootstrap.value.unread_count)
const loading = computed(() => filterEvent.isLoading.value)
const saving = computed(
  () =>
    markReadEvent.isLoading.value ||
    archiveEvent.isLoading.value ||
    markAllReadEvent.isLoading.value ||
    preferenceEvent.isLoading.value,
)
const supportedChannels = computed(() => bootstrap.value.supported_channels)
const inactiveChannels = computed(() => new Set(bootstrap.value.inactive_external_channels))
const visibleScopes = computed(() => ["all", "system", "user", "organization", "workspace", "app"])
const avatarInitials = computed(() => props.currentUser.username.slice(0, 2).toUpperCase())

const channelIcon = (channel: NotificationChannel) => {
  if (channel === "email") return Mail
  if (channel === "sms") return Smartphone
  if (channel === "telegram") return Send
  if (channel === "webhook") return Radio
  if (channel === "push") return MessageCircle
  return Bell
}

const channelLabel = (channel: NotificationChannel) =>
  channel
    .split("_")
    .map(segment => `${segment[0].toUpperCase()}${segment.slice(1)}`)
    .join(" ")

const preferenceFor = (channel: NotificationChannel): NotificationPreferenceSummary | undefined =>
  bootstrap.value.preferences.find(preference =>
    preference.channel === channel &&
    preference.scope_type === "system" &&
    preference.scope_id === null &&
    preference.app_key === null &&
    preference.notification_key === null,
  )

const channelEnabled = (channel: NotificationChannel): boolean => {
  const preference = preferenceFor(channel)
  if (preference) return preference.enabled && preference.cadence !== "disabled"
  return channel === "in_app"
}

const applyReply = (reply: NotificationLiveReply) => {
  if (!reply.ok) {
    error.value = reply.error || "Unable to update notifications"
    return
  }

  if (reply.bootstrap) bootstrap.value = reply.bootstrap
  if (reply.notifications) notifications.value = reply.notifications
  if (reply.filters) {
    activeStatus.value = reply.filters.status
    activeScope.value = reply.filters.scope
  }

  error.value = null
}

const loadNotifications = async () => {
  applyReply(await filterEvent.execute({ status: activeStatus.value, scope: activeScope.value }))
}

const markRead = async (notification: NotificationSummary) => {
  if (notification.status !== "unread") return

  applyReply(await markReadEvent.execute({ recipient_id: notification.recipient_id }))
}

const archiveNotification = async (notification: NotificationSummary) => {
  applyReply(await archiveEvent.execute({ recipient_id: notification.recipient_id }))
}

const markAllRead = async () => {
  applyReply(await markAllReadEvent.execute({}))
}

const toggleChannel = async (channel: NotificationChannel) => {
  applyReply(await preferenceEvent.execute({ channel, enabled: !channelEnabled(channel) }))
}

const selectStatus = async (status: "active" | "unread" | "read" | "archived" | "all") => {
  activeStatus.value = status
  await loadNotifications()
}

const selectScope = async (scope: string) => {
  activeScope.value = scope
  await loadNotifications()
}

const severityClass = (severity: NotificationSummary["severity"]) => {
  if (severity === "error") return "border-red-500/40 bg-red-500/10 text-red-600"
  if (severity === "warning") return "border-amber-400/40 bg-amber-400/10 text-amber-600"
  if (severity === "success") return "border-emerald-400/40 bg-emerald-400/10 text-emerald-600"
  return "border-[hsl(var(--so-primary))/0.35] bg-[hsl(var(--so-primary))/0.08] text-[hsl(var(--so-primary))]"
}

const formatScope = (notification: NotificationSummary) => {
  if (notification.app_key) return `${notification.app_key} · ${notification.scope.type}`
  return notification.scope.type
}

watch(() => props.notificationBootstrap, value => {
  bootstrap.value = value
}, { deep: true })

watch(() => props.notifications, value => {
  if (value) notifications.value = value
}, { deep: true })

watch(() => props.activeStatus, value => {
  if (value) activeStatus.value = value
})

watch(() => props.activeScope, value => {
  if (value) activeScope.value = value
})
</script>

<template>
  <div class="so-theme min-h-[70vh] text-[hsl(var(--so-foreground))]">
    <header class="mb-6 flex flex-wrap items-center justify-between gap-4">
      <div>
        <p class="so-font-mono text-[11px] uppercase tracking-[0.22em] text-[hsl(var(--so-muted-foreground))]">
          Notification center
        </p>
        <h1 class="mt-2 text-3xl font-semibold tracking-tight">Signals across every workspace</h1>
        <p class="mt-2 max-w-2xl text-sm text-[hsl(var(--so-muted-foreground))]">
          System, workspace, app, and account events land here first. External channels are preference-backed now and provider-backed later.
        </p>
      </div>

      <div class="flex items-center gap-2">
        <ThemeToggleButton />
        <a :href="dashboardPath" class="so-button-secondary">Dashboard</a>
        <details class="so-avatar-menu relative">
          <summary
            class="flex h-8 w-8 cursor-pointer items-center justify-center rounded-full border border-[hsl(var(--so-border))] bg-[hsl(var(--so-surface-2))] text-[10px] font-medium"
            aria-label="Account menu"
          >
            {{ avatarInitials }}
          </summary>
          <div class="so-fade-in absolute right-0 top-[calc(100%+0.5rem)] z-30 w-56 rounded-md border border-[hsl(var(--so-border))] bg-[hsl(var(--so-card))] p-2 shadow-lg">
            <div class="border-b border-[hsl(var(--so-border))] px-2 pb-2">
              <p class="text-sm font-medium">{{ currentUser.username }}</p>
              <p class="text-xs text-[hsl(var(--so-muted-foreground))]">{{ currentUser.email }}</p>
            </div>
            <form :action="signOutPath" method="post" class="pt-2">
              <input type="hidden" name="_method" value="delete" />
              <input type="hidden" name="_csrf_token" :value="csrfToken" />
              <button type="submit" class="so-button-secondary w-full justify-start">Sign out</button>
            </form>
          </div>
        </details>
      </div>
    </header>

    <div class="grid gap-5 xl:grid-cols-[minmax(0,1fr)_360px]">
      <section class="rounded-xl border border-[hsl(var(--so-border))] bg-[hsl(var(--so-card))]">
        <div class="flex flex-wrap items-center justify-between gap-3 border-b border-[hsl(var(--so-border))] p-4">
          <div>
            <p class="text-sm font-medium">Inbox</p>
            <p class="text-xs text-[hsl(var(--so-muted-foreground))]">{{ unreadCount }} unread notifications</p>
          </div>
          <button type="button" class="so-button-secondary" :disabled="unreadCount === 0" @click="markAllRead">
            <Check class="h-4 w-4" />
            Mark all read
          </button>
        </div>

        <div class="flex flex-wrap gap-2 border-b border-[hsl(var(--so-border))] p-3">
          <button
            v-for="status in statusTabs"
            :key="status"
            type="button"
            class="rounded-md px-3 py-1.5 text-xs font-medium transition-colors"
            :class="activeStatus === status ? 'bg-[hsl(var(--so-accent))] text-[hsl(var(--so-foreground))]' : 'text-[hsl(var(--so-muted-foreground))] hover:bg-[hsl(var(--so-accent))/0.5]'"
            @click="selectStatus(status)"
          >
            {{ status }}
          </button>
        </div>

        <div class="flex flex-wrap gap-2 border-b border-[hsl(var(--so-border))] p-3">
          <button
            v-for="scope in visibleScopes"
            :key="scope"
            type="button"
            class="so-font-mono rounded border px-2 py-1 text-[10px] uppercase tracking-wider transition-colors"
            :class="activeScope === scope ? 'border-[hsl(var(--so-primary))/0.35] text-[hsl(var(--so-primary))]' : 'border-[hsl(var(--so-border))] text-[hsl(var(--so-muted-foreground))] hover:bg-[hsl(var(--so-accent))/0.5]'"
            @click="selectScope(scope)"
          >
            {{ scope }}
          </button>
        </div>

        <div class="divide-y divide-[hsl(var(--so-border))]">
          <p v-if="loading" class="p-6 text-sm text-[hsl(var(--so-muted-foreground))]">Loading notifications...</p>
          <p v-else-if="error" class="p-6 text-sm text-red-500">{{ error }}</p>
          <p v-else-if="notifications.length === 0" class="p-6 text-sm text-[hsl(var(--so-muted-foreground))]">
            No notifications match this view.
          </p>

          <article
            v-for="notification in notifications"
            :key="notification.recipient_id"
            class="grid gap-3 p-4 transition-colors hover:bg-[hsl(var(--so-accent))/0.25] md:grid-cols-[1fr_auto]"
          >
            <div class="min-w-0">
              <div class="flex flex-wrap items-center gap-2">
                <span class="rounded border px-2 py-0.5 text-[11px] font-medium" :class="severityClass(notification.severity)">
                  {{ notification.severity }}
                </span>
                <span class="so-font-mono text-[10px] uppercase tracking-wider text-[hsl(var(--so-muted-foreground))]">
                  {{ formatScope(notification) }}
                </span>
                <span
                  v-if="notification.status === 'unread'"
                  class="so-font-mono rounded bg-[hsl(var(--so-primary))/0.1] px-1.5 py-0.5 text-[9px] uppercase tracking-wider text-[hsl(var(--so-primary))]"
                >
                  unread
                </span>
              </div>
              <h2 class="mt-2 text-base font-semibold">{{ notification.title }}</h2>
              <p v-if="notification.body" class="mt-1 whitespace-pre-wrap text-sm text-[hsl(var(--so-muted-foreground))]">
                {{ notification.body }}
              </p>
              <div class="mt-3 flex flex-wrap gap-2">
                <span
                  v-for="delivery in notification.deliveries"
                  :key="delivery.id"
                  class="so-font-mono rounded border border-[hsl(var(--so-border))] px-2 py-1 text-[10px] uppercase tracking-wider text-[hsl(var(--so-muted-foreground))]"
                >
                  {{ delivery.channel }} · {{ delivery.status }}
                </span>
              </div>
            </div>

            <div class="flex items-start gap-2">
              <a v-if="notification.action_url" :href="notification.action_url" class="so-button-secondary text-xs">
                Open
              </a>
              <button
                v-if="notification.status === 'unread'"
                type="button"
                class="so-button-secondary text-xs"
                @click="markRead(notification)"
              >
                Read
              </button>
              <button type="button" class="so-button-secondary text-xs" @click="archiveNotification(notification)">
                <Archive class="h-3.5 w-3.5" />
                Archive
              </button>
            </div>
          </article>
        </div>
      </section>

      <aside class="space-y-5">
        <section class="rounded-xl border border-[hsl(var(--so-border))] bg-[hsl(var(--so-card))] p-4">
          <p class="text-sm font-medium">Delivery channels</p>
          <p class="mt-1 text-xs text-[hsl(var(--so-muted-foreground))]">
            In-app delivery is active. Other channels are schema-backed for future providers.
          </p>

          <div class="mt-4 space-y-2">
            <button
              v-for="channel in supportedChannels"
              :key="channel"
              type="button"
              class="flex w-full items-center gap-3 rounded-lg border border-[hsl(var(--so-border))] p-3 text-left transition-colors hover:bg-[hsl(var(--so-accent))/0.35]"
              :disabled="saving"
              @click="toggleChannel(channel)"
            >
              <component :is="channelIcon(channel)" class="h-4 w-4 text-[hsl(var(--so-muted-foreground))]" />
              <span class="min-w-0 flex-1">
                <span class="block text-sm font-medium">{{ channelLabel(channel) }}</span>
                <span class="block text-xs text-[hsl(var(--so-muted-foreground))]">
                  {{ channel === 'in_app' ? 'Operational now' : inactiveChannels.has(channel) ? 'Configured for future delivery' : 'Available' }}
                </span>
              </span>
              <span
                class="so-font-mono rounded px-2 py-1 text-[10px] uppercase tracking-wider"
                :class="channelEnabled(channel) ? 'bg-[hsl(var(--so-primary))/0.1] text-[hsl(var(--so-primary))]' : 'bg-[hsl(var(--so-muted))/0.5] text-[hsl(var(--so-muted-foreground))]'"
              >
                {{ channelEnabled(channel) ? 'on' : 'off' }}
              </span>
            </button>
          </div>
        </section>

        <section class="rounded-xl border border-[hsl(var(--so-border))] bg-[hsl(var(--so-card))] p-4">
          <p class="text-sm font-medium">Configured endpoints</p>
          <div class="mt-3 space-y-2">
            <div
              v-for="channel in bootstrap.channels"
              :key="channel.channel"
              class="rounded-lg border border-[hsl(var(--so-border))] p-3"
            >
              <div class="flex items-center justify-between gap-2">
                <p class="text-sm font-medium">{{ channelLabel(channel.channel) }}</p>
                <span class="so-font-mono text-[10px] uppercase tracking-wider text-[hsl(var(--so-muted-foreground))]">
                  {{ channel.status }}
                </span>
              </div>
              <p class="mt-1 truncate text-xs text-[hsl(var(--so-muted-foreground))]">
                {{ channel.address || channel.external_id || 'No endpoint configured yet' }}
              </p>
            </div>
          </div>
        </section>
      </aside>
    </div>
  </div>
</template>
