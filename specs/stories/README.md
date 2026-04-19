# Stories Backlog

This directory contains the story backlog consumed by `ralph_wiggum_loop.sh`.

The loop works best when stories are:

- small enough to complete in one Codex run
- independent enough to land in one commit
- explicit about dependencies
- explicit about acceptance criteria and verification

## File layout

- `00_traceability_matrix.md`
  Cross-reference of story IDs, epics, surfaces, verification types, and dependencies.
- `01_*.md`, `02_*.md`, ...
  Story files grouped by epic.

## Story ID prefixes

- `ST-DSN-*`
  Design foundation and system work.
- `ST-AUTH-*`
  Auth surface work.
- `ST-PUB-*`
  Public and marketing surface work.
- `ST-DSH-*`
  Dashboard and operator-surface work.
- `ST-TST-*`
  Frontend testability and browser confidence work.
- `ST-WAP-*`
  Workspace app platform work.
- `ST-FOL-*`
  Folio app API, UI, and workflow work.

## Story card shape

Each story card should follow this structure:

### ST-XXX-000 Story title
#### Goal
#### Scope
#### Acceptance Criteria
#### Verification
#### Dependencies

`ralph_wiggum_loop.sh` extracts dependencies from the `#### Dependencies` section, so dependency IDs must be written exactly, for example:

- `ST-DSN-001`
- `ST-AUTH-002`

## Execution order

The intended sequence for this backlog is:

1. Design foundation
2. Auth and public surfaces
3. Auth and public browser confidence
4. Dashboard convergence
5. Dashboard and component confidence
6. Cleanup and deprecation retirement
7. Workspace app platform
8. Folio API foundation
9. Folio UI read surfaces
10. Folio mutations and workflows
11. Folio confidence and browser coverage

That order reflects the current product need: stabilize the design layer first, harden auth and public surfaces, add the earliest browser protection where it already pays off, then converge the dashboard and add the deeper product-facing confidence work after that shell settles.

The workspace-app and Folio milestone comes after that stabilization work. The shell and design system are now far enough along that the next step is to turn the workspace into a platform that can host multiple apps, then ship Folio as the first real app on that platform.

## Testing lane assumptions

The current intended frontend testing stack is:

- `Phoenix.LiveViewTest` for server-driven behavior and routing
- Playwright for end-to-end browser flows
- `Vitest` with `@vue/test-utils` for Vue and `live_vue` component behavior
- Histoire for visual state review, not as a replacement for automated tests
- Playwright suites should run against deterministic seeded or scripted state, not manual dev accounts
- Once the suites exist, Playwright and Vitest should be wired into an automated repo gate rather than staying local-only

## Recommended Ralph usage

Dry-run the queue first:

```bash
./ralph_wiggum_loop.sh --dry-run
```

Run one story:

```bash
./ralph_wiggum_loop.sh --only ST-DSN-001 --no-push
```

Run a small batch from the top of the backlog:

```bash
./ralph_wiggum_loop.sh --start-at ST-DSN-001 --max 3 --no-push
```
