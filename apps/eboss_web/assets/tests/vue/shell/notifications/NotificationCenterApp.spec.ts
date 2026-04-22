import { flushPromises } from "@vue/test-utils"
import { describe, expect, it, vi } from "vitest"

import { mountComponent } from "@/tests/vue/support/mount"
import NotificationCenterApp from "@/vue/shell/notifications/NotificationCenterApp.vue"
import type {
  NotificationBootstrap,
  NotificationChannelSummary,
  NotificationPreferenceSummary,
  NotificationSummary,
} from "@/vue/shell/notifications"

vi.mock("@/vue/shell/shared/ThemeToggleButton.vue", () => ({
  default: {
    name: "ThemeToggleButton",
    template: "<button type=\"button\">Theme</button>",
  },
}))

const delivery = {
  id: "delivery-1",
  channel: "in_app" as const,
  endpoint_id: null,
  status: "delivered" as const,
  provider: null,
  provider_message_id: null,
  attempt_count: 0,
  last_attempt_at: null,
  delivered_at: "2026-04-21T12:00:00Z",
  error_message: null,
  metadata: {},
}

const notification = (overrides: Partial<NotificationSummary> = {}): NotificationSummary => ({
  recipient_id: "recipient-1",
  notification_id: "notification-1",
  status: "unread",
  read_at: null,
  archived_at: null,
  last_seen_at: null,
  title: "Chat run failed",
  body: "The shared chat assistant failed to finish.",
  severity: "error",
  scope: {
    type: "app",
    id: "workspace-1",
    workspace_id: "workspace-1",
    organization_id: null,
  },
  app_key: "chat",
  actor: {
    type: "agent",
    id: null,
  },
  subject: {
    type: "chat_session",
    id: "session-1",
    label: "Launch planning",
  },
  action_url: "/alpha/workspace/apps/chat/sessions/session-1",
  metadata: {},
  occurred_at: "2026-04-21T12:00:00Z",
  deliveries: [delivery],
  ...overrides,
})

const preference = (
  overrides: Partial<NotificationPreferenceSummary> = {},
): NotificationPreferenceSummary => ({
  id: "preference-1",
  scope_type: "system",
  scope_id: null,
  app_key: null,
  notification_key: null,
  channel: "in_app",
  enabled: true,
  cadence: "immediate",
  ...overrides,
})

const channel = (
  channelName: NotificationChannelSummary["channel"],
  overrides: Partial<NotificationChannelSummary> = {},
): NotificationChannelSummary => ({
  id: channelName === "in_app" ? "endpoint-in-app" : null,
  channel: channelName,
  address: channelName === "email" ? "operator@example.com" : null,
  external_id: null,
  status: channelName === "in_app" || channelName === "email" ? "verified" : "unverified",
  primary: channelName === "in_app" || channelName === "email",
  verified_at: null,
  metadata: {},
  operational: channelName === "in_app",
  ...overrides,
})

const bootstrap = (): NotificationBootstrap => ({
  unread_count: 1,
  recent: [notification()],
  preferences: [
    preference({ channel: "in_app" }),
    preference({ id: "preference-email", channel: "email", enabled: false, cadence: "disabled" }),
  ],
  channels: [
    channel("in_app"),
    channel("email"),
    channel("sms"),
    channel("telegram"),
    channel("webhook"),
    channel("push"),
  ],
  supported_channels: ["in_app", "email", "sms", "telegram", "webhook", "push"],
  inactive_external_channels: ["email", "sms", "telegram", "webhook", "push"],
})

const mountCenter = () =>
  mountComponent(NotificationCenterApp, {
    props: {
      currentUser: {
        username: "operator",
        email: "operator@example.com",
      },
      notificationBootstrap: bootstrap(),
      notifications: [notification()],
      activeStatus: "active",
      activeScope: "all",
      dashboardPath: "/dashboard",
      signOutPath: "/logout",
      csrfToken: "csrf-token",
    },
})

describe("NotificationCenterApp", () => {
  it("renders server-provided notifications and multi-channel future delivery state", async () => {
    const wrapper = mountCenter()
    await flushPromises()

    expect(wrapper.text()).toContain("Chat run failed")
    expect(wrapper.text()).toContain("In-app delivery is active")
    expect(wrapper.text()).toContain("Configured for future delivery")
    expect(wrapper.text()).toContain("operator@example.com")
  })

  it("marks notifications read and archives them through LiveView events", async () => {
    const liveReply = vi
      .fn()
      .mockReturnValueOnce({
        ok: true,
        bootstrap: bootstrap(),
        notifications: [notification({ status: "read", read_at: "2026-04-21T12:01:00Z" })],
      })
      .mockReturnValueOnce({
        ok: true,
        bootstrap: bootstrap(),
        notifications: [],
      })
    ;(globalThis as typeof globalThis & { __liveVueEventReply: typeof liveReply }).__liveVueEventReply = liveReply

    const wrapper = mountCenter()
    await flushPromises()

    const readButton = wrapper.findAll("button").find(button => button.text().includes("Read"))
    expect(readButton).toBeTruthy()
    await readButton!.trigger("click")
    await flushPromises()

    expect(liveReply).toHaveBeenCalledWith("notifications:mark_read", { recipient_id: "recipient-1" })

    const archiveButton = wrapper.findAll("button").find(button => button.text().includes("Archive"))
    expect(archiveButton).toBeTruthy()
    await archiveButton!.trigger("click")
    await flushPromises()

    expect(liveReply).toHaveBeenCalledWith("notifications:archive", { recipient_id: "recipient-1" })
  })

  it("toggles system channel preferences", async () => {
    const liveReply = vi.fn(() => ({
      ok: true,
      bootstrap: {
        ...bootstrap(),
        preferences: [
          ...bootstrap().preferences,
          preference({
            id: "preference-telegram",
            channel: "telegram",
            enabled: true,
            cadence: "immediate",
          }),
        ],
      },
      notifications: [notification()],
    }))
    ;(globalThis as typeof globalThis & { __liveVueEventReply: typeof liveReply }).__liveVueEventReply = liveReply

    const wrapper = mountCenter()
    await flushPromises()

    const telegramButton = wrapper.findAll("button").find(button => button.text().includes("Telegram"))
    expect(telegramButton).toBeTruthy()

    await telegramButton!.trigger("click")
    await flushPromises()

    expect(liveReply).toHaveBeenCalledWith("notifications:set_preference", {
      channel: "telegram",
      enabled: true,
    })
  })

  it("refreshes the visible default inbox from pushed bootstrap props", async () => {
    const wrapper = mountCenter()
    await flushPromises()

    expect(wrapper.text()).toContain("Chat run failed")

    await wrapper.setProps({
      notificationBootstrap: {
        ...bootstrap(),
        unread_count: 2,
      },
      notifications: [
        notification({
          recipient_id: "recipient-2",
          notification_id: "notification-2",
          title: "Workspace role changed",
          body: "Your workspace role changed.",
          severity: "warning",
        }),
      ],
    })
    await flushPromises()

    expect(wrapper.text()).toContain("Workspace role changed")
  })
})
