# Workspace Activity Feed Contract

## Purpose

The workspace shell needs one stable activity feed envelope regardless of which app
produces the events. This contract keeps activity aggregation app-aware without
forcing a separate persisted global activity domain.

## Contract shape

The shared envelope lives in [`EBoss.Workspaces.ActivityFeed`](/Users/mhostetler/Source/EBoss/eboss_platform/apps/eboss_workspaces/lib/eboss_workspaces/activity_feed.ex)
and has the following required keys:

- `id` - feed entry id used by UI for dedupe.
- `app_key` - source app owner (for example `"folio"` or
  `EBoss.Workspaces.ActivityFeed.platform_app_key()` for platform events).
- `provider_key` - source provider identity inside that app.
- `provider_event_id` - source event id from the provider.
- `occurred_at` - ISO-8601 timestamp string.
- `actor` - map with at least `type` and optional `id`/`label`.
- `action` - short action string.
- `summary` - human-readable line summarizing the event.
- `subject` - map with `type` and `id`.

Optional keys can include:

- `details` - human-readable context string.
- `status` - one of `:success`, `:warning`, `:pending`, `:info`, `:error`.
- `changes` - event-specific change map.
- `metadata` - provider-owned extra values.
- `resource_path` - optional shell route hint for deep-links.

## App/provider-aware providers

Apps contribute events through modules implementing
[`EBoss.Workspaces.ActivityFeed.Provider`](/Users/mhostetler/Source/EBoss/eboss_platform/apps/eboss_workspaces/lib/eboss_workspaces/activity_feed.ex).
They expose:

- `app_key/0` - app bucket (`"folio"` today).
- `provider_key/0` - event source (`"revision_event"` for Folio today).
- `to_entry/2` - map one source event to an activity envelope.

For convenience, a provider can map entire event sets via
`EBoss.Workspaces.ActivityFeed.Provider.map_events/3`.

## Current provider: Folio revision events

`EBossFolio.ActivityFeedProvider` maps `EBossFolio.RevisionEvent` rows to the
shared contract so Folio history can populate workspace activity without adding a
new activity persistence domain.

### Mapping notes

- `app_key`: `"folio"`
- `provider_key`: `"revision_event"`
- `action`: `to_string(event.action)`
- `subject.type`: `to_string(event.resource_type)`
- `subject.id`: `event.resource_id`
- `subject.label`: currently `nil` (can be enriched later without breaking contract)
- `actor.type`: `event.actor_type`
- `actor.id`: `event.actor_id`
- `summary`: generated from action + resource type + resource id
- `metadata`:
  - `workspace_id`
  - `source`
  - `reason`
  - `correlation_id`

The provider is intentionally additive and can be expanded to include additional
platform sources (`membership`, `access`, etc.) later by creating additional
provider modules using the same contract.
