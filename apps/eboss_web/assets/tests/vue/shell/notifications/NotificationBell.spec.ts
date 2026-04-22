import { flushPromises } from "@vue/test-utils"
import { beforeEach, describe, expect, it, vi } from "vitest"

import { mountComponent } from "@/tests/vue/support/mount"
import NotificationBell from "@/vue/shell/notifications/NotificationBell.vue"
import type { NotificationBootstrap, NotificationSummary } from "@/vue/shell/notifications"

const notificationMocks = vi.hoisted(() => ({
  fetchNotificationBootstrap: vi.fn(),
  markAllNotificationsRead: vi.fn(),
  updateNotificationStatus: vi.fn(),
}))

vi.mock("@/vue/shell/notifications/http", () => ({
  fetchNotificationBootstrap: notificationMocks.fetchNotificationBootstrap,
  markAllNotificationsRead: notificationMocks.markAllNotificationsRead,
  updateNotificationStatus: notificationMocks.updateNotificationStatus,
}))

const notification = (overrides: Partial<NotificationSummary> = {}): NotificationSummary => ({
  recipient_id: "recipient-1",
  notification_id: "notification-1",
  status: "unread",
  read_at: null,
  archived_at: null,
  last_seen_at: null,
  title: "Task delegated",
  body: "A Folio task needs attention.",
  severity: "info",
  scope: {
    type: "app",
    id: "workspace-1",
    workspace_id: "workspace-1",
    organization_id: null,
  },
  app_key: "folio",
  actor: {
    type: "user",
    id: "user-1",
  },
  subject: {
    type: "task",
    id: "task-1",
    label: "Review launch plan",
  },
  action_url: "/alpha/workspace/apps/folio/tasks",
  metadata: {},
  occurred_at: "2026-04-21T12:00:00Z",
  deliveries: [
    {
      id: "delivery-1",
      channel: "in_app",
      endpoint_id: null,
      status: "delivered",
      provider: null,
      provider_message_id: null,
      attempt_count: 0,
      last_attempt_at: null,
      delivered_at: "2026-04-21T12:00:00Z",
      error_message: null,
      metadata: {},
    },
  ],
  ...overrides,
})

const bootstrap = (recent: NotificationSummary[] = [notification()]): NotificationBootstrap => ({
  unread_count: recent.filter(item => item.status === "unread").length,
  recent,
  preferences: [],
  channels: [],
  supported_channels: ["in_app", "email", "sms", "telegram", "webhook", "push"],
  inactive_external_channels: ["email", "sms", "telegram", "webhook", "push"],
})

describe("NotificationBell", () => {
  beforeEach(() => {
    notificationMocks.fetchNotificationBootstrap.mockReset()
    notificationMocks.markAllNotificationsRead.mockReset()
    notificationMocks.updateNotificationStatus.mockReset()
  })

  it("renders unread state and marks a recent notification read", async () => {
    notificationMocks.updateNotificationStatus.mockResolvedValue({
      notification: notification({ status: "read", read_at: "2026-04-21T12:01:00Z" }),
    })

    const wrapper = mountComponent(NotificationBell, {
      props: {
        bootstrap: bootstrap(),
      },
    })

    expect(wrapper.text()).toContain("1 unread")
    expect(wrapper.text()).toContain("Task delegated")

    const item = wrapper.findAll("button").find(button => button.text().includes("Task delegated"))
    expect(item).toBeTruthy()

    await item!.trigger("click")
    await flushPromises()

    expect(notificationMocks.updateNotificationStatus).toHaveBeenCalledWith("recipient-1", "read")
    expect(wrapper.text()).toContain("0 unread")
  })

  it("marks all recent notifications read from the popover", async () => {
    notificationMocks.markAllNotificationsRead.mockResolvedValue({
      unread_count: 0,
      notifications: [],
    })

    const wrapper = mountComponent(NotificationBell, {
      props: {
        bootstrap: bootstrap([notification(), notification({ recipient_id: "recipient-2" })]),
      },
    })

    const button = wrapper.findAll("button").find(candidate => candidate.text().includes("Mark all read"))
    expect(button).toBeTruthy()

    await button!.trigger("click")
    await flushPromises()

    expect(notificationMocks.markAllNotificationsRead).toHaveBeenCalled()
    expect(wrapper.text()).toContain("0 unread")
  })
})
