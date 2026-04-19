# Epic 08: Folio API Foundation

This epic turns Folio into the first real workspace app by exposing a workspace-scoped API surface that the frontend can consume cleanly.

The goal is not to publish a huge generic API all at once.
The goal is to give the workspace shell and Folio UI a stable, app-scoped read layer:

- Folio bootstrap
- projects
- tasks
- activity
- typed frontend client helpers

### ST-FOL-001 Define the workspace-scoped Folio app API contract
#### Goal
Establish the first real app contract for a workspace by defining the Folio API surface before wiring UI reads onto it.

#### Scope
- Define the intended route and payload shape for workspace-scoped Folio endpoints.
- Clarify the relationship between workspace bootstrap and Folio bootstrap.
- Keep the contract focused on the first read surfaces rather than every future Folio resource.
- Make the contract app-aware so it fits the broader workspace app platform.

#### Acceptance Criteria
- The Folio API contract is explicit about route shape, payload structure, and scope rules.
- The contract fits cleanly under the workspace app platform.
- The contract is narrow enough to implement incrementally without overdesigning.

#### Verification
- Review the route and payload contract in code or supporting docs.
- Confirm the contract aligns with the existing workspace bootstrap and scope model.

#### Dependencies
- `ST-WAP-001`
- `ST-WAP-002`
- `ST-WAP-003`

### ST-FOL-002 Add a workspace-scoped Folio bootstrap endpoint
#### Goal
Expose the minimum Folio bootstrap payload needed for the frontend to mount the app inside a workspace.

#### Scope
- Add a Folio bootstrap endpoint under the workspace app route structure.
- Return Folio-relevant capabilities, summary counts, and app navigation context needed at mount time.
- Keep the first payload intentionally lean and app-specific.
- Avoid duplicating the full workspace bootstrap payload unnecessarily.

#### Acceptance Criteria
- A workspace-scoped Folio bootstrap endpoint exists and resolves through the current workspace scope.
- The payload is sufficient to mount Folio UI state without relying on mock bootstrap data.
- The endpoint respects workspace authorization and app capabilities.

#### Verification
- Review the endpoint response against the intended Folio bootstrap contract.
- Add or update controller/integration coverage for the endpoint.

#### Dependencies
- `ST-FOL-001`

### ST-FOL-003 Add workspace-scoped Folio projects reads
#### Goal
Expose real project data to the first Folio read surface.

#### Scope
- Add domain-facing read interfaces for listing and fetching projects inside a workspace.
- Add the corresponding workspace-scoped web/API surface.
- Include the fields needed by the first real projects UI without overbuilding.
- Keep filtering and sorting pragmatic for the first slice.

#### Acceptance Criteria
- The backend can list Folio projects for a workspace through a clean code interface.
- The web/API layer exposes workspace-scoped projects reads.
- The returned project data is suitable for replacing the current mock projects page.

#### Verification
- Add or update Folio boundary tests for workspace-scoped project reads.
- Add or update endpoint coverage for the projects read surface.

#### Dependencies
- `ST-FOL-001`
- `ST-FOL-002`

### ST-FOL-004 Add workspace-scoped Folio tasks reads
#### Goal
Expose real task data so the Folio app can expand beyond projects into actual GTD workflow surfaces.

#### Scope
- Add domain-facing read interfaces for listing and fetching tasks inside a workspace.
- Add the corresponding workspace-scoped web/API surface.
- Support the fields needed for the first list/detail task views.
- Keep the first pass focused on useful workspace task reads rather than exhaustive query flexibility.

#### Acceptance Criteria
- The backend can list Folio tasks for a workspace through a clean code interface.
- The web/API layer exposes workspace-scoped tasks reads.
- The returned task data is sufficient for the first Folio task surfaces.

#### Verification
- Add or update Folio boundary tests for workspace-scoped task reads.
- Add or update endpoint coverage for the tasks read surface.

#### Dependencies
- `ST-FOL-001`
- `ST-FOL-002`

### ST-FOL-005 Add a Folio activity provider backed by revision events
#### Goal
Make the first real workspace activity feed come from actual Folio revision history instead of mock events.

#### Scope
- Map Folio `RevisionEvent` records into the workspace activity feed contract.
- Expose the mapped feed through a workspace-scoped Folio activity read surface.
- Keep the first provider implementation focused on Folio resources already emitting audit events.
- Avoid introducing a speculative separate persisted workspace activity domain in this story.

#### Acceptance Criteria
- Folio revision events can be read as a workspace activity feed.
- The feed shape matches the workspace activity contract defined at the platform layer.
- The first real activity surface no longer depends on mock activity data.

#### Verification
- Add or update tests for revision-event listing and feed mapping.
- Add or update endpoint coverage for the Folio activity read surface.

#### Dependencies
- `ST-WAP-005`
- `ST-FOL-001`
- `ST-FOL-002`

### ST-FOL-006 Add a typed frontend Folio data client and composable layer
#### Goal
Keep the Vue shell and Folio pages simple by introducing a thin typed data-access layer between UI code and the new Folio endpoints.

#### Scope
- Add typed Folio client modules and composables for bootstrap, projects, tasks, and activity reads.
- Centralize workspace-app URL handling and response typing.
- Keep the layer narrow and app-focused rather than building a generic frontend SDK.
- Avoid leaving page components responsible for request shape and route assembly.

#### Acceptance Criteria
- Folio UI code can consume typed composables or client helpers instead of hand-building requests.
- Workspace and app scoping logic is centralized in one frontend layer.
- The new client layer is ready to replace the current mock-data imports on the first read surfaces.

#### Verification
- Run the relevant frontend type checks.
- Review the page code to confirm endpoint and typing concerns are no longer inlined there.

#### Dependencies
- `ST-FOL-002`
- `ST-FOL-003`
- `ST-FOL-004`
- `ST-FOL-005`
