<script setup lang="ts">
import { computed, onMounted, ref, watch } from "vue"
import { Bell } from "lucide-vue-next"

import {
  fetchNotificationBootstrap,
  markAllNotificationsRead,
  updateNotificationStatus,
} from "./http"
import type { NotificationBootstrap, NotificationSummary } from "./types"

const props = defineProps<{
  bootstrap?: NotificationBootstrap
}>()

const loading = ref(false)
const error = ref<string | null>(null)
const bootstrap = ref<NotificationBootstrap | null>(props.bootstrap ?? null)

const unreadCount = computed(() => bootstrap.value?.unread_count ?? 0)
const recent = computed(() => bootstrap.value?.recent ?? [])

const syncBootstrap = (nextBootstrap?: NotificationBootstrap) => {
  if (nextBootstrap) bootstrap.value = nextBootstrap
}

const loadBootstrap = async () => {
  loading.value = true
  error.value = null

  try {
    bootstrap.value = await fetchNotificationBootstrap()
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : "Unable to load notifications"
  } finally {
    loading.value = false
  }
}

const replaceRecent = (notification: NotificationSummary) => {
  if (!bootstrap.value) return

  bootstrap.value = {
    ...bootstrap.value,
    unread_count: Math.max(0, bootstrap.value.unread_count - (notification.status === "read" ? 1 : 0)),
    recent: bootstrap.value.recent.map(item =>
      item.recipient_id === notification.recipient_id ? notification : item,
    ),
  }
}

const markRead = async (notification: NotificationSummary) => {
  if (notification.status !== "unread") return

  const response = await updateNotificationStatus(notification.recipient_id, "read")
  replaceRecent(response.notification)
}

const markAllRead = async () => {
  const response = await markAllNotificationsRead()

  if (bootstrap.value) {
    bootstrap.value = {
      ...bootstrap.value,
      unread_count: response.unread_count,
      recent: bootstrap.value.recent.map(item => ({ ...item, status: "read" })),
    }
  }
}

const severityClass = (severity: NotificationSummary["severity"]) => {
  if (severity === "error") return "bg-red-500"
  if (severity === "warning") return "bg-amber-400"
  if (severity === "success") return "bg-emerald-400"
  return "bg-[hsl(var(--so-primary))]"
}

watch(() => props.bootstrap, syncBootstrap, { deep: true })
onMounted(() => {
  if (!bootstrap.value) void loadBootstrap()
})
</script>

<template>
  <details class="relative">
    <summary class="so-icon-button relative flex list-none items-center justify-center" aria-label="Notifications">
      <Bell class="h-4 w-4" />
      <span
        v-if="unreadCount > 0"
        class="absolute -right-0.5 -top-0.5 flex min-h-4 min-w-4 items-center justify-center rounded-full bg-[hsl(var(--so-primary))] px-1 so-font-mono text-[9px] font-bold text-[hsl(var(--so-primary-foreground))]"
      >
        {{ unreadCount > 9 ? "9+" : unreadCount }}
      </span>
    </summary>

    <div class="so-fade-in absolute right-0 top-[calc(100%+0.5rem)] z-30 w-80 rounded-md border border-[hsl(var(--so-border))] bg-[hsl(var(--so-card))] p-2 shadow-lg">
      <div class="flex items-start justify-between gap-3 border-b border-[hsl(var(--so-border))] px-2 pb-2">
        <div>
          <p class="text-sm font-medium text-[hsl(var(--so-foreground))]">Notifications</p>
          <p class="text-xs text-[hsl(var(--so-muted-foreground))]">{{ unreadCount }} unread</p>
        </div>
        <button
          type="button"
          class="so-button-secondary px-2 py-1 text-xs"
          :disabled="unreadCount === 0"
          @click.prevent="markAllRead"
        >
          Mark all read
        </button>
      </div>

      <div class="max-h-80 overflow-y-auto py-2">
        <p v-if="loading" class="px-2 py-3 text-sm text-[hsl(var(--so-muted-foreground))]">Loading notifications...</p>
        <p v-else-if="error" class="px-2 py-3 text-sm text-red-500">{{ error }}</p>
        <p v-else-if="recent.length === 0" class="px-2 py-3 text-sm text-[hsl(var(--so-muted-foreground))]">No notifications yet.</p>

        <button
          v-for="notification in recent"
          :key="notification.recipient_id"
          type="button"
          class="flex w-full gap-2 rounded-md px-2 py-2 text-left transition-colors hover:bg-[hsl(var(--so-accent))/0.5]"
          @click.prevent="markRead(notification)"
        >
          <span class="mt-1 h-2 w-2 shrink-0 rounded-full" :class="severityClass(notification.severity)" />
          <span class="min-w-0 flex-1">
            <span class="block truncate text-sm font-medium text-[hsl(var(--so-foreground))]">
              {{ notification.title }}
            </span>
            <span class="line-clamp-2 text-xs text-[hsl(var(--so-muted-foreground))]">
              {{ notification.body || notification.scope.type }}
            </span>
          </span>
          <span
            v-if="notification.status === 'unread'"
            class="so-font-mono rounded border border-[hsl(var(--so-primary))/0.35] px-1 py-px text-[9px] uppercase tracking-wider text-[hsl(var(--so-primary))]"
          >
            new
          </span>
        </button>
      </div>

      <div class="border-t border-[hsl(var(--so-border))] px-2 pt-2">
        <a href="/notifications" class="so-button-secondary w-full justify-center text-xs">
          Open notification center
        </a>
      </div>
    </div>
  </details>
</template>
