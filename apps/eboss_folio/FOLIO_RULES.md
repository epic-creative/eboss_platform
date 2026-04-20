# Folio Rulebook

This file turns the highest-signal Folio business rules into named, reviewable contracts.
The intent is to keep Folio behavior executable across three layers:

- domain/resource rules
- workspace app HTTP boundaries
- browser E2E flows

## Rule Set

### FR-001 Workspace scope is absolute

Every Folio record belongs to exactly one workspace, and cross-workspace references are invalid.

Enforced in:
- `/Users/mhostetler/Source/EBoss/eboss_platform/apps/eboss_folio/lib/eboss_folio/validations/belongs_to_workspace.ex`

Covered by:
- `/Users/mhostetler/Source/EBoss/eboss_platform/apps/eboss_folio/test/eboss_folio/resource_rules_test.exs`

### FR-002 `waiting_for` must mean something concrete

A task may only enter `waiting_for` when it has notes or an active delegation.

Enforced in:
- `/Users/mhostetler/Source/EBoss/eboss_platform/apps/eboss_folio/lib/eboss_folio/validations/task_waiting_for.ex`

Covered by:
- `/Users/mhostetler/Source/EBoss/eboss_platform/apps/eboss_folio/test/eboss_folio/task_and_project_test.exs`
- `/Users/mhostetler/Source/EBoss/eboss_platform/apps/eboss_web/test/eboss_web/controllers/json_api_test.exs`

### FR-003 A task can have only one active delegation

Delegation is a live handoff state, not an append-only list of simultaneous owners.

Enforced in:
- `/Users/mhostetler/Source/EBoss/eboss_platform/apps/eboss_folio/lib/eboss_folio/delegation.ex`

Covered by:
- `/Users/mhostetler/Source/EBoss/eboss_platform/apps/eboss_folio/test/eboss_folio/task_and_project_test.exs`

### FR-004 Terminal task transitions reconcile delegations

If a task is completed, its active delegation must complete. If a task is canceled or archived, its active delegation must cancel.

Enforced in:
- `/Users/mhostetler/Source/EBoss/eboss_platform/apps/eboss_folio/lib/eboss_folio/changes/reconcile_task_delegations.ex`
- `/Users/mhostetler/Source/EBoss/eboss_platform/apps/eboss_folio/lib/eboss_folio/task.ex`

Covered by:
- `/Users/mhostetler/Source/EBoss/eboss_platform/apps/eboss_folio/test/eboss_folio/task_and_project_test.exs`
- `/Users/mhostetler/Source/EBoss/eboss_platform/apps/eboss_web/assets/tests/playwright/smoke/folio-mutation-smoke.spec.ts`

### FR-005 Every meaningful Folio change is auditable

Create, update, transition, and delegation flows emit revision events that back the shared activity feed.

Enforced in:
- `/Users/mhostetler/Source/EBoss/eboss_platform/apps/eboss_folio/lib/eboss_folio/changes/audit_action.ex`
- `/Users/mhostetler/Source/EBoss/eboss_platform/apps/eboss_folio/lib/eboss_folio/activity_feed_provider.ex`

Covered by:
- `/Users/mhostetler/Source/EBoss/eboss_platform/apps/eboss_folio/test/eboss_folio/audit_test.exs`
- `/Users/mhostetler/Source/EBoss/eboss_platform/apps/eboss_folio/test/eboss_folio/folio_boundary_test.exs`
- `/Users/mhostetler/Source/EBoss/eboss_platform/apps/eboss_web/assets/tests/playwright/smoke/folio-smoke.spec.ts`

### FR-006 Workspace app APIs must work for browser sessions

Signed-in browser users must be able to read and mutate Folio through same-origin workspace app APIs without requiring API keys.

Enforced in:
- `/Users/mhostetler/Source/EBoss/eboss_platform/apps/eboss_web/lib/eboss_web/router.ex`
- `/Users/mhostetler/Source/EBoss/eboss_platform/apps/eboss_web/lib/eboss_web/plugs/session_api_csrf.ex`
- `/Users/mhostetler/Source/EBoss/eboss_platform/apps/eboss_web/assets/vue/shell/workspace/folio/http.ts`

Covered by:
- `/Users/mhostetler/Source/EBoss/eboss_platform/apps/eboss_web/test/eboss_web/controllers/json_api_test.exs`
- `/Users/mhostetler/Source/EBoss/eboss_platform/apps/eboss_web/assets/tests/vue/shell/workspace/folio/http.spec.ts`
- `/Users/mhostetler/Source/EBoss/eboss_platform/apps/eboss_web/assets/tests/playwright/smoke/folio-smoke.spec.ts`
- `/Users/mhostetler/Source/EBoss/eboss_platform/apps/eboss_web/assets/tests/playwright/smoke/folio-mutation-smoke.spec.ts`

### FR-007 Unsafe browser-session mutations require CSRF

Cookie-backed workspace app mutations must send a valid CSRF token. Bearer/API-key flows remain stateless.

Enforced in:
- `/Users/mhostetler/Source/EBoss/eboss_platform/apps/eboss_web/lib/eboss_web/plugs/session_api_csrf.ex`
- `/Users/mhostetler/Source/EBoss/eboss_platform/apps/eboss_web/assets/vue/shell/workspace/folio/http.ts`

Covered by:
- `/Users/mhostetler/Source/EBoss/eboss_platform/apps/eboss_web/test/eboss_web/controllers/json_api_test.exs`
- `/Users/mhostetler/Source/EBoss/eboss_platform/apps/eboss_web/assets/tests/vue/shell/workspace/folio/http.spec.ts`

### FR-008 Bootstrap counts are workspace-scoped app summary data

Folio bootstrap should expose project/task counts for the active workspace only.

Enforced in:
- `/Users/mhostetler/Source/EBoss/eboss_platform/apps/eboss_folio/lib/eboss_folio/eboss_folio.ex`
- `/Users/mhostetler/Source/EBoss/eboss_platform/apps/eboss_web/lib/eboss_web/controllers/folio_bootstrap_controller.ex`

Covered by:
- `/Users/mhostetler/Source/EBoss/eboss_platform/apps/eboss_folio/test/eboss_folio/folio_boundary_test.exs`
- `/Users/mhostetler/Source/EBoss/eboss_platform/apps/eboss_web/test/eboss_web/controllers/json_api_test.exs`
- `/Users/mhostetler/Source/EBoss/eboss_platform/apps/eboss_web/test/eboss_web/integration/json_api_http_test.exs`

## Testing Shape

Use this as the default stack for new Folio rules:

1. Put the invariant in the Ash resource/change/validation first.
2. Add a domain or boundary test that proves the invariant without HTTP.
3. Add a web/API test only if auth, serialization, or route semantics matter.
4. Add a Playwright flow only when the rule is user-visible in the workspace app.

This keeps browser confidence real without turning Playwright into the only place Folio behavior is specified.
