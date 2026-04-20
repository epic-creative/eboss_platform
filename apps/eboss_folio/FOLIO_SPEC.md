## Folio Specification

See also:
- `/Users/mhostetler/Source/EBoss/eboss_platform/apps/eboss_folio/FOLIO_RULES.md` for the executable business-rule and test matrix.

### 1) Purpose

Build “Folio”: an authoritative personal command center inside an existing Elixir Phoenix application for a single user, implementing an opinionated Getting Things Done (GTD)-based task/project system with:

- Rich modeling of tasks, projects, areas, horizons, contexts, delegation, agents, attachments, and external task intake.
- Extremely granular revision history: every change to all core data must be tracked.
- A policy-driven evolution layer: rules governing status progression, review prompts, retries, and future automation.
- Multiple interaction surfaces:
  - Phoenix LiveView admin UI (primary UI).
  - REST API with simple API-key authentication (for scripts/agents).
  - CLI via `mix` tasks.
  - Telegram LLM companion bot for chat-based interaction (same authority as the user).

Folio is the system of record for the user’s to-dos. External sources (GitHub issues, emails, etc.) are linked, not synchronized.

---

## 2) Guiding Principles

1. **Single-user ownership**
   - There is one primary user/owner, but the system should still model a `User` entity for future-proofing and to support actor attribution in audit logs.

2. **Authoritative record**
   - Folio stores the canonical state. External systems are referenced via links/IDs; no bidirectional sync required.

3. **GTD opinionated baseline**
   - Start with core GTD constructs (projects = anything requiring >1 next action; contexts; areas; horizons; review cycles).
   - “Priority” is primarily list order (“what’s next”), not a complex scoring system.

4. **Extensibility over premature automation**
   - Automation should be conservative by default.
   - “Task breakdown” is user-triggered (button / command), not fully automatic.
   - Policies should be configurable and designed to evolve.

5. **Every change is auditable**
   - All create/update/delete/transition actions generate durable revision events with full before/after snapshots (or equivalent high-fidelity representation).

6. **LLM is an assistant, not the authority**
   - LLM can propose structured output, but the system enforces business rules and retains provenance.
   - Chat bot has broad authority equal to the user but must still pass validations/policies.

---

## 3) High-Level Architecture

### 3.1 Tech Stack

- **Elixir / Phoenix**
- **Phoenix LiveView** for the administrative dashboard and review flows
- **Ash Framework** for declarative resources, validations, actions, and business rules
- **PostgreSQL** as the primary datastore (recommended with AshPostgres)
- **Background jobs** (recommended: Oban) for scheduled policy evaluation and “review prompting” jobs
- **File storage** for attachments:
  - Start with local storage (dev) + configurable adapter for S3-compatible storage (prod)

### 3.2 Core Components

1. **Domain layer (Ash resources)**
   - Tasks, Projects, Areas, Horizons, Contexts, Contacts, Agents, Policies, External Sources, Attachments, Revisions/Audit.

2. **Policy engine**
   - Runs on a schedule and/or via event triggers.
   - Interprets stored policy definitions and applies actions or creates prompts.

3. **Interaction surfaces**
   - LiveView UI
   - REST API (API key)
   - CLI (mix tasks)
   - Telegram bot (chat UI over the same Ash actions)

4. **LLM integration layer**
   - Used for user-triggered “break down task” and future advisory prompts.
   - Produces structured output; system applies changes through normal actions.

---

## 4) Data Model

> All entities should include: `id`, `inserted_at`, `updated_at`, and `user_id` (owner), unless explicitly global/system.

### 4.1 User (single owner)

**User**

- `id`
- `email` (optional if you already have auth elsewhere)
- `timezone` (default: `"America/Chicago"`)
- `settings` (map/json for user preferences)

Purpose:

- Actor attribution
- Ownership scoping on all data
- Future-proofing if multi-user ever emerges

---

### 4.2 Contacts (delegation targets, “contacts only”)

**Contact**

- `id`
- `name` (required)
- `email` (optional but recommended)
- `capability_notes` (rich text / markdown / json)
- Optional future fields:
  - `tags` (array)
  - `reliability_rating` (int/enum)
  - `preferred_channels` (map)

**Delegation (record of delegating a task to a contact)**

- `id`
- `task_id`
- `contact_id`
- `delegated_at` (datetime)
- `delegated_summary` (text): “what I delegated to them”
- `quality_expectations` (text)
- `deadline_expectations_at` (datetime or date)
- Optional:
  - `follow_up_at` (datetime) (recommended for “Waiting For” reviews)
  - `status` (enum: `active | completed | canceled`)

Notes:

- Delegation is not collaborative access; it is tracking for follow-up.

---

### 4.3 Agents (non-human executors)

**Agent**

- `id`
- `name`
- `kind` (enum: `llm_agent | script | webhook | other`)
- `endpoint` (optional; for webhook/remote agent orchestration later)
- `agent_metadata` (json)
- `enabled` (boolean)

**AgentAssignment**

- `id`
- `task_id`
- `agent_id`
- `assigned_at`
- `instructions` (text)
- `expected_response_schema` (json schema-ish or typed map)
- `status` (enum: `assigned | in_progress | succeeded | failed | timed_out | canceled`)
- `last_heartbeat_at` (optional)
- `retry_count` (int)
- `max_retries` (int)
- `retry_policy_id` (optional link to a Policy)

**AgentResult**

- `id`
- `agent_assignment_id`
- `received_at`
- `result_payload` (json) – structured agent output
- `summary` (text)
- `applied_changes` (json) – what the system applied (optional)
- `error` (text) – if agent reported failure

Behavior:

- If agent does not respond, treat as `timed_out` / `failed` based on policy evaluation; retry is policy-driven.

---

### 4.4 GTD Core Modeling

#### Areas

**Area**

- `id`
- `name` (required)
- `description` (optional)
- `review_interval_days` (optional; default may be weekly or monthly depending on preference)
- `status` (active/archived)

Examples: Work, Personal, Open Source, Health.

#### Horizons of Focus

**Horizon**

- `id`
- `name` (e.g., “Now”, “1 year”, “3–5 years”)
- `level` (int for sorting)
- `description`

Used to connect projects/areas to longer-term intent.

#### Contexts

**Context**

- `id`
- `name` (e.g., “Computer”, “Phone”, “Home”, “Errands”, “GitHub”)
- `description`
- `status` (active/archived)

---

### 4.5 Projects

**Project**

- `id`
- `title` (required)
- `description`
- `status` (enum suggested):
  - `active`
  - `on_hold`
  - `completed`
  - `canceled`
  - `archived`

- `area_id` (optional)
- `horizon_id` (optional)
- `context_id` (optional)
- `due_at` (optional)
- `review_at` (optional)
- `priority_position` (optional ordering field if you want ordered projects)
- `metadata` (json) – extensibility
- `notes` (text)
- `source` (optional: manual / external)

Relationship rules:

- A project is “anything that takes more than one next action.”
- Enforce a validation/warning rule: if a project has 0 tasks in `next_action`/`waiting_for` for too long, it should be flagged during reviews (policy).

---

### 4.6 Tasks

**Task**

- `id`
- `title` (required)
- `description`
- `status` (enum; opinionated GTD baseline):
  - `inbox` (captured, unclarified)
  - `next_action`
  - `waiting_for`
  - `scheduled` (hard landscape; has due date/time)
  - `someday_maybe`
  - `done`
  - `canceled`
  - `archived`

- `context_id` (optional)
- `project_id` (optional)
- `area_id` (optional)
- `horizon_id` (optional)
- `due_at` (optional)
- `review_at` (optional)
- `priority_position` (int; ordering within relevant lists; “priority by what’s next”)
- `estimated_minutes` (optional int; for time-to-complete)
- `complexity_score` (optional int/float; typically produced by LLM)
- `notes` (text)

Delegation-related fields (for convenience; canonical record is `Delegation`):

- `delegated_contact_id` (optional)
- `delegated_agent_id` (optional)

Task breakdown lineage:

- `expanded_from_task_id` (nullable FK to Task)
- `expansion_group_id` (optional UUID to group replacement subtasks together)
- `is_expansion_placeholder` (boolean; optional strategy—see breakdown section)

External linkage:

- `external_reference_id` (optional FK)
- `source` (enum: manual, telegram, api, cli, external_import)

Extensibility:

- `metadata` (json) for evolving structure without migrations

---

### 4.7 Attachments

**Attachment**

- `id`
- `owner_type` (enum: `task | project | area | contact`)
- `owner_id`
- `filename`
- `content_type`
- `byte_size`
- `storage_key` (path/key in storage backend)
- `checksum` (optional)
- `uploaded_at`
- `metadata` (json)

Requirements:

- Attach files to tasks and projects at minimum.
- UI supports upload, list, download.
- All attachment operations create revision events.

---

### 4.8 External Sources and Imported Items

**ExternalSource**

- `id`
- `name` (e.g., “GitHub Issues”, “Work Email”)
- `type` (enum: `github_issue | email | url | other`)
- `default_context_id` (optional)
- `default_area_id` (optional)
- `ingestion_template_id` (optional)
- `enabled`

**ExternalReference**

- `id`
- `external_source_id`
- `external_key` (string; e.g., GitHub issue number or email message-id)
- `external_url` (string)
- `external_payload` (json; snapshot of minimal source data if desired)
- `imported_at`
- `dedupe_hash` (string; to prevent duplicates)

No sync:

- Folio does not update external state; it only links.

Special categorization:

- Based on `ExternalSource` + templates/procedures.

---

### 4.9 Procedure Templates (for external intake patterns)

**IngestionTemplate**

- `id`
- `name`
- `external_source_type` (optional constraint)
- `description`
- `task_blueprints` (json array) OR normalized table `TaskBlueprint`

**TaskBlueprint (if normalized)**

- `id`
- `ingestion_template_id`
- `title_template`
- `description_template`
- `default_status`
- `default_context_id`
- `default_area_id`
- `position` (ordering)
- `dependency_position` (optional; simple sequential dependency)

Goal:

- Example: For any GitHub issue, create 3 tasks:
  1. Triage issue
  2. Respond or implement
  3. Follow-up/close loop

---

## 5) Revision History and Audit Requirements

### 5.1 Granularity

Requirement: **Very granular; every revision of the data needs tracked.**

That includes:

- Task edits (title, status, due date, context, etc.)
- Project edits
- Area/context/horizon changes
- Delegation changes
- Policy creation/changes
- External reference creation
- Attachments added/removed
- Agent assignments/results
- Any system-initiated or policy-initiated updates

### 5.2 Audit Data Model

**RevisionEvent**

- `id`
- `resource_type` (string/enum: `task`, `project`, etc.)
- `resource_id`
- `action` (enum: `create | update | delete | transition | attach | detach | expand | import | policy_apply`)
- `actor_type` (enum: `user | telegram_bot | api_key | cli | agent | system`)
- `actor_id` (nullable; e.g., user_id / agent_id)
- `source` (enum: `liveview | rest_api | telegram | cli | policy_engine | migration`)
- `occurred_at`
- `before` (json; full snapshot or per-field)
- `after` (json)
- `diff` (json; optional but recommended for UI)
- `correlation_id` (uuid; tie multiple events together like task expansion)
- `reason` (text; optional; e.g., “LLM breakdown accepted”)

Implementation options:

- Use an Ash-compatible auditing/versioning library if available in your stack, or implement a custom audit table with Ash change hooks.
- The key is durable, queryable, per-change records with actor attribution.

### 5.3 Browsing History

Requirement: **In-system browsing is sufficient** (no export/reporting needed now).

UI features:

- “History” tab for every resource
- Ability to view diffs between revisions
- Show actor and source (LiveView/API/Telegram/Agent/Policy engine)

---

## 6) Policy System

### 6.1 Scope

Policies govern:

- Status progression enforcement (allowed transitions)
- Review intervals and prompting (daily/weekly)
- Waiting-for follow-ups
- Retry policies for agent failures/timeouts
- Conditions for flagging or escalating tasks/projects
- Optional: rules around task breakdown suggestions (but actual breakdown remains user-triggered)

### 6.2 Policy Model

**Policy**

- `id`
- `name`
- `description`
- `enabled`
- `scope` (enum: `task | project | delegation | agent_assignment | external_import | global`)
- `trigger` (enum: `cron | event`)
- `cron_expression` (nullable; used if trigger=cron)
- `event_type` (nullable; e.g., `task_created`, `status_changed`)
- `condition` (stored expression; start simple)
- `action_type` (enum; see below)
- `action_params` (json)
- `priority` (int)
- `created_at`, `updated_at`

**PolicyAction types** (initial set):

- `create_prompt` (create a user prompt)
- `set_review_at`
- `set_status`
- `create_delegation_follow_up`
- `create_agent_retry`
- `flag_task` / `flag_project`
- `apply_template` (e.g., upon import)

### 6.3 Policy Execution

- Run via background jobs:
  - Scheduled cron-like evaluation (recommended: Oban + cron plugin or equivalent).
  - Event-triggered evaluation by publishing events on key actions (task created, status changed, due date set, etc.).

- Each application of a policy creates one or more `RevisionEvent` records (`policy_apply`), including correlation IDs.

### 6.4 Conservative Automation Defaults

- Policies may create prompts rather than automatically changing complex fields.
- Automated changes should be limited to safe operations (e.g., setting `review_at`, creating follow-up prompts, flagging).

---

## 7) Reviews and Prompts (GTD workflow support)

### 7.1 Review Cadence

Start with GTD basics:

- Daily review
- Weekly review

Implementation:

- Store `review_at` on Tasks and Projects.
- Policy engine generates a “Review Queue” based on:
  - items with `review_at <= now`
  - inbox items
  - waiting-for items that need follow-up

### 7.2 Prompt Model

**Prompt**

- `id`
- `prompt_type` (enum: `review | follow_up | retry | clarification | stale_project`)
- `resource_type` + `resource_id` (what it refers to)
- `created_at`
- `due_at` (optional)
- `status` (enum: `open | dismissed | completed`)
- `options` (json; UI can render binary/multi-choice/fill-in)
- `resolution` (json; what user chose)
- `resolved_at`

Requirement alignment:

- The system should be proactive and prompt the user during reviews, optimizing for quick decisions (binary/multi-choice / add context).

---

## 8) Task Breakdown (User-triggered LLM-assisted expansion)

### 8.1 Triggering

- User triggers breakdown explicitly via:
  - LiveView button (“Break down task”)
  - REST API endpoint
  - CLI command
  - Telegram command/message intent

Automation should not run this constantly; it’s conservative and user-initiated.

### 8.2 LLM Behavior

- LLM receives:
  - Task title/description/notes
  - Context/area/project metadata
  - Estimated minutes/time-to-complete
  - Optional policies relevant to breakdown

- LLM returns:
  - `complexity_score` (numeric)
  - Proposed list of subtasks (2+):
    - title
    - description
    - suggested context/status
    - suggested ordering/dependencies (simple sequential)

### 8.3 Expansion Semantics (“Originating task evaporates”)

Required behavior:

- The original task is revised and replaced by multiple subtasks.
- Revision history preserves lineage.

Recommended implementation approach:

1. Create a `correlation_id` for the expansion.
2. Mark original task as:
   - `status = archived` OR `status = canceled` with reason “expanded”
   - Store `expansion_group_id` and `complexity_score`

3. Create new subtasks:
   - `expanded_from_task_id = original_task_id`
   - `expansion_group_id` set to same group
   - Set ordering (`priority_position`) relative to original task position

4. Record revision events:
   - One for original task update
   - One per created subtask
   - All share the same correlation ID

UI behavior options:

- Flattened display by default (still a GTD list), with an optional “show expansions” view.
- Provide a way to navigate from subtasks back to the original expanded task.

---

## 9) External Task Intake

### 9.1 Ingestion Rules

- External tasks are created as Tasks with an `ExternalReference`.
- They may be categorized differently based on source and optionally expanded into multiple steps using an `IngestionTemplate`.

Flow (manual or automated later):

1. Create ExternalReference with URL/key
2. Create Task(s) in Folio
3. Attach ExternalReference to the created task(s)
4. Apply template (if configured)

### 9.2 Deduplication

- Use `dedupe_hash` on ExternalReference (e.g., hash of `source_type + external_key`).
- Ingestion must be idempotent: repeated imports should not create duplicates.

---

## 10) Interaction Surfaces

### 10.1 Phoenix LiveView Admin UI

Minimum initial views:

- Dashboard (overview counts: inbox, next actions, waiting-for, due soon, review due)
- Task list view with filters:
  - by status, context, project, area, horizon, due window

- Project view:
  - project details + tasks

- Review workflow views:
  - Daily review queue
  - Weekly review queue

- Contacts view:
  - manage contacts + capability notes + delegated tasks

- Agents view:
  - manage agents + assignments + results

- Policy management view:
  - list policies, enable/disable, edit parameters

- History viewer:
  - per-item revision timeline + diffs

- Attachments UI:
  - upload + list + download

### 10.2 REST API (API key auth)

Auth requirement:

- “Basic authentication” style API key; simplest is:
  - `Authorization: Bearer <api_key>` OR `X-API-Key: <api_key>`

- Keys stored hashed; rotation supported.

API style:

- Recommended: build on Ash JSON:API tooling if you want quick generation and consistent patterns.
- Otherwise: custom Phoenix controllers calling Ash actions.

Minimum endpoints (illustrative):

- `GET/POST /api/tasks`
- `GET/PATCH/DELETE /api/tasks/:id`
- `POST /api/tasks/:id/breakdown` (user-triggered breakdown; may accept LLM output or trigger LLM)
- `GET/POST /api/projects`
- `GET/POST /api/contacts`
- `GET/POST /api/external_references`
- `GET/POST /api/policies`
- `GET /api/history?resource_type=task&resource_id=...`

Design requirements:

- Every mutating endpoint must set actor/source for audit.
- Validate all state transitions via Ash validations.

### 10.3 CLI via `mix` tasks

Examples:

- `mix folio.task.add "title" --context "Computer" --project "X"`
- `mix folio.task.list --status next_action`
- `mix folio.review.daily`
- `mix folio.task.breakdown <task_id>`

CLI should:

- Either call internal context functions directly (same Ash actions) or call the REST API.
- Always attribute source = `cli` in revisions.

### 10.4 Telegram LLM Companion Bot

Role:

- Chat-based UI for creating/modifying tasks/projects, not an independent authority.

Permissions:

- Same authority as the human user.

Constraints:

- Must still pass all validations and policies.
- All actions recorded with actor_type = `telegram_bot` (and actor_id user if you want it attributed to the user).

Implementation outline:

- Telegram webhook receiver in Phoenix
- Message intent parsing:
  - simple commands (`/add`, `/inbox`, `/next`, `/done`)
  - LLM-based parsing for natural language into structured commands

- Executes Ash actions; returns confirmation summaries

---

## 11) Error Handling Strategies

### 11.1 General Principles

- Fail safely: do not partially apply multi-step operations without a correlation trail.
- Prefer transactional boundaries around multi-write operations (e.g., expansion, ingestion).
- Every failure should be observable and diagnosable:
  - Structured logs
  - Audit events for attempted operations (optional “failed_operation” event type)

### 11.2 Specific Scenarios

#### Task expansion failures

- If LLM call fails: return error; no changes applied.
- If LLM output invalid: reject and return validation errors; no changes applied.
- If DB transaction fails mid-expansion:
  - Roll back entire expansion transaction.
  - Log with correlation ID.

#### Policy engine failures

- Policy evaluation errors:
  - Mark policy run as failed; do not apply partial actions.
  - Record a system alert prompt or log entry.

- Guard against runaway policy loops:
  - per-run maximum operations
  - correlation ID and dedupe for repeated prompts

#### Agent non-response / timeout

- AgentAssignment has timeout window (policy-defined).
- If timed out:
  - status -> `timed_out`
  - policy may schedule retry or create prompt for manual intervention

- Retries:
  - capped by policy (`max_retries`)
  - exponential backoff recommended

#### External ingestion duplicates

- Enforce unique constraint on `(external_source_id, external_key)` or `dedupe_hash`.
- If duplicate import detected:
  - return existing reference/task mapping
  - do not create new tasks

#### Attachment storage errors

- If upload succeeds but DB insert fails (or vice versa):
  - use a staged upload flow:
    1. upload to temp
    2. create DB record
    3. finalize/move storage key

  - or ensure transactional approach with compensation cleanup

### 11.3 Validation and Transition Rules

- Enforce allowed task status transitions (policy/validation):
  - Example: `done` cannot go back to `inbox` without explicit “reopen” action.

- Ensure `waiting_for` tasks have either:
  - a delegation record to a contact, or
  - an agent assignment, or
  - explicit reason in notes/metadata

---

## 12) Security Considerations

- API keys:
  - store hashed (like passwords)
  - support rotation; last_used_at tracking
  - scope to read/write if desired (optional now)

- LiveView admin UI:
  - protected by existing app auth (or implement minimal auth if absent)

- Telegram bot:
  - restrict to authorized Telegram user IDs
  - never accept commands from unknown users

- Audit integrity:
  - revision events should be append-only (no updates except perhaps internal backfills)

---

## 13) Observability

- Structured logging with correlation IDs for:
  - API requests
  - Policy runs
  - Agent assignments
  - LLM calls

- Metrics (optional but recommended):
  - number of tasks created/updated per day
  - policy run durations/failures
  - agent success/failure rates
  - LLM call success rate and latency

---

## 14) Testing Plan

### 14.1 Unit Tests (ExUnit)

- Ash resource validations:
  - required fields
  - status transitions
  - waiting_for requires delegation/agent assignment (if enforced)

- Task ordering logic (`priority_position`):
  - insert/move/reorder behaviors

- Ingestion template application:
  - correct task creation count, ordering, and defaults

- Policy condition parsing/evaluation (for whatever expression mechanism is chosen)

### 14.2 Integration Tests

- REST API tests (Phoenix ConnTest):
  - auth success/failure
  - CRUD for tasks/projects/contacts
  - breakdown endpoint applies expansion semantics correctly
  - idempotent external ingestion

- Policy engine:
  - run scheduled evaluation; verify prompts created and audit events recorded

- Agent workflow:
  - create assignment; simulate success payload; verify task updates + audit log
  - simulate timeout; verify policy-driven retry/prompt behavior

### 14.3 LiveView Tests

- Task list filters and views
- Review queues render correct items (based on `review_at`)
- History viewer loads revision events and shows diffs
- Attachments upload/download (at least one happy path + one failure path)

### 14.4 Property/Generative Tests (StreamData) — recommended for robustness

- Random sequences of task updates must always produce:
  - monotonic revision event count
  - consistent before/after snapshots
  - no invalid states (as defined by validations)

- Random reordering operations preserve stable ordering invariants.

### 14.5 Performance/Load Tests (lightweight, optional initially)

- Large revision table performance:
  - history query performance for a heavily edited task
  - ensure indexes exist on `(resource_type, resource_id, occurred_at)`

---

## 15) Implementation Roadmap (Suggested)

### Phase 1: Data foundation + audit

- Implement Ash resources: User, Task, Project, Area, Horizon, Context, Contact, Attachment, ExternalSource, ExternalReference, RevisionEvent.
- Implement revision tracking hooks across all actions.
- Basic LiveView CRUD for Tasks/Projects/Contacts.
- Basic REST API with API-key auth.

### Phase 2: GTD workflows + reviews

- Status model finalized; ordering (`priority_position`) implemented.
- Review queues (daily/weekly) + Prompt model and UI.
- Delegation and Waiting For tracking.

### Phase 3: External intake + templates

- Ingestion templates and application.
- External reference UI and API.

### Phase 4: Agents + retries

- Agent resources, assignments, results.
- Policy-driven retry scaffolding.

### Phase 5: LLM integration

- User-triggered breakdown endpoint + UI button.
- LLM adapter + structured output validation.
- Telegram bot integration using same Ash actions.

---

## 16) Acceptance Criteria Checklist

A developer can consider the initial implementation complete when:

1. Tasks/projects/contacts can be created/updated via LiveView, REST API, and CLI.
2. All changes generate RevisionEvents with actor/source and before/after.
3. Tasks support GTD statuses, context/project/area/horizon associations, due/review dates, ordering.
4. Delegation to contacts records delegated summary + expectations + deadline expectations.
5. Attachments can be uploaded and linked to tasks/projects.
6. External items can be imported as tasks with references and optional templates.
7. Policy engine can run scheduled checks and generate review prompts (at least weekly/daily basics).
8. User-triggered task breakdown replaces original task with subtasks and preserves lineage + audit trail.
9. Agent assignment model exists with timeout and policy-driven retry scaffolding (even if no real agent executor yet).

---

If you want this turned into an implementation-oriented artifact (Postgres schema outline, Ash resource sketches, and a concrete REST route list with request/response shapes), say so and I will produce it as a follow-on deliverable.
