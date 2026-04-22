# EBoss Notify Rules

## NR-001 Notifications are immutable event envelopes

`EBossNotify.Notification` records describe what happened. They are append-only after
creation. User-specific state lives on recipient and delivery records.

## NR-002 Recipient state is per user

Read, unread, and archived state belongs to `NotificationRecipient`. One user reading
or archiving a notification must not affect another user.

## NR-003 Channels are modeled independently

Every delivery channel is represented with endpoint, preference, and delivery rows.
Only `in_app` delivers in v1; Email, SMS, Telegram, webhook, and push are persisted
for future provider integrations.

## NR-004 In-app inbox state is independent from channel delivery

The in-app unread count comes only from `NotificationRecipient.status`. External
delivery status must not mark an in-app item read.

## NR-005 Preferences are evaluated at recipient expansion time

If a user disables `in_app` for a matching notification preference, no in-app
recipient is created for that notification.

## NR-006 Idempotency protects producer retries

Producers should pass an `idempotency_key`. Reusing the same key returns the existing
notification instead of creating duplicates.

## NR-007 Users can only mutate their own notification state

All public read/update actions for recipients, preferences, endpoints, and deliveries
must be scoped to the current actor.
