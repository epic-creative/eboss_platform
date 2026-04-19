# Epic 07: Workspace App Platform

This epic turns the current workspace shell into a platform that can host multiple apps instead of assuming a single fixed product surface.

Folio is the first app, not the workspace itself.

The goal here is to establish the platform contract before deeper Folio implementation arrives:

- app-aware workspace routing
- app-aware shell navigation
- shared workspace bootstrap/app registry
- generic workspace platform surfaces
- a provider-backed activity contract rather than a premature global activity domain

### ST-WAP-001 Define the workspace app platform contract
#### Goal
Establish the architectural contract for workspaces that host multiple apps before implementation hardens around Folio-specific assumptions.

#### Scope
- Define what belongs to the workspace platform versus what belongs to an individual app.
- Document the intended route shape for workspace-level and app-level surfaces.
- Clarify how app capabilities, navigation, and bootstrap payloads should be represented.
- Keep the story focused on contract definition rather than full implementation.

#### Acceptance Criteria
- The repo has a clear written contract for multi-app workspaces.
- It is explicit that Folio is the first app in a workspace rather than the workspace model itself.
- The contract distinguishes generic workspace surfaces from app-owned surfaces.
- The contract is concrete enough to guide later routing, shell, and API work.

#### Verification
- Review the updated spec and implementation notes for route, scope, and app-model clarity.
- Confirm the contract maps cleanly onto the existing workspace shell and scope code.

#### ST-WAP-001 Contract Draft

##### 1) Workspace model and ownership
- A workspace is the tenant container and shell boundary.
- App surfaces are mounted **inside** a workspace; they do not replace the workspace model.
- Scope resolution must always resolve:
  - `workspace` (identity, owner context, `dashboard_path`)
  - `owner` (for owner/workspace switcher labels)
  - `capabilities` (workspace-level permissions + app capability channel)
  - `accessible_workspaces` (for owner/workspace switching)

##### 2) Route shape (contract)
- Workspace-level route family (canonical, stable today):
  - `/:owner_slug/:workspace_slug`
  - `/:owner_slug/:workspace_slug/:workspace_surface`
- `workspace_surface` is a platform-owned surface for the current shell, initially:
  - `dashboard`, `projects`, `members`, `access`, `activity`, `settings`
- App-aware route family (contract target for this platform):
  - `/:owner_slug/:workspace_slug/apps/:app_key`
  - `/:owner_slug/:workspace_slug/apps/:app_key/:app_surface`
- `Folio` is the first app (`app_key = "folio"`) and must be represented as a member of `app_key`, not as the workspace itself.

##### 3) Capability and navigation representation
- Navigation and permissions must be expressed as two layers:
  1. **Workspace capabilities**: permissions required to access or manage the workspace shell.
  2. **App capabilities**: permissions scoped to each app entry.
- Temporary compatibility for legacy consumers is allowed only inside `workspace` scope shape while `app_key` registry is being introduced in ST-WAP-002.
- The bootstrap payload should be readable as:
  - `workspace` + `owner` + `capabilities` + `accessible_workspaces`
  - with a future `apps` map keyed by `app_key` once ST-WAP-002 lands.

##### 4) Implementation mapping for this story
- Route contract source-of-truth: `apps/eboss_web/lib/eboss_web/router.ex` and `apps/eboss_web/lib/eboss_web/live/dashboard_live.ex`.
- Scope contract source-of-truth: `apps/eboss_web/lib/eboss_web/app_scope.ex` and `apps/eboss_web/lib/eboss_web/controllers/workspace_bootstrap_controller.ex`.
- Bootstrap serialization remains `AppScope.bootstrap_payload/1` while app ownership is generalized in later stories.

#### Dependencies
- `ST-DSH-002`
- `ST-DSH-003`
- `ST-TST-006`

### ST-WAP-002 Add an app registry to the workspace scope and bootstrap payload
#### Goal
Expose the available workspace apps through the same scope/bootstrap mechanism that already drives the shell.

#### Scope
- Extend workspace scope and bootstrap payloads with an app registry.
- Represent app metadata such as key, label, default path, enabled state, and capabilities.
- Keep the first implementation focused on Folio plus any generic workspace platform surfaces.
- Avoid coupling the payload shape to a single app implementation.

#### Acceptance Criteria
- Workspace bootstrap data includes a stable app registry.
- The payload can represent more than one workspace app without changing shape.
- App capability data is exposed in an app-aware format instead of one-off Folio booleans.
- Existing workspace shell consumers can evolve cleanly onto the new payload.

#### Verification
- Review the bootstrap payload shape in code and through the workspace bootstrap endpoint.
- Update or add focused tests for scope/bootstrap serialization where the contract changes materially.

#### Dependencies
- `ST-WAP-001`

### ST-WAP-003 Add app-aware workspace routes and route resolution
#### Goal
Move the workspace from a fixed page map to an app-aware route model that can support multiple apps.

#### Scope
- Define route patterns for workspace-level surfaces and app-level surfaces.
- Update route resolution, current-page derivation, and shell inputs accordingly.
- Keep canonical owner/workspace slugs intact.
- Do not build the full Folio UI in this story.

#### Acceptance Criteria
- The router supports app-aware workspace routes.
- Route resolution can distinguish generic workspace surfaces from app-owned surfaces.
- The shell input model no longer assumes one fixed list of workspace pages.
- The route model is reusable for future apps without revisiting the platform contract.

#### Verification
- Review router and scope code for app-aware route behavior.
- Add or update LiveView coverage for app-aware route rendering and auth gating.

#### Dependencies
- `ST-WAP-001`
- `ST-WAP-002`

### ST-WAP-004 Refactor the workspace shell for app-aware navigation and chrome
#### Goal
Make the runtime shell understand apps as first-class navigation units instead of treating every surface as one flat page list.

#### Scope
- Refactor the shell data model away from a fixed `PageKey` union toward an app-aware navigation structure.
- Add shell support for app switching, current app state, and app-level navigation.
- Preserve the existing shell quality and responsiveness during the refactor.
- Keep the story focused on shell structure and navigation, not on wiring all Folio data.

#### Acceptance Criteria
- The workspace shell renders app-aware navigation and current-app chrome.
- Navigation state is represented in a reusable way for future apps.
- The refactor reduces fixed Folio/dashboard assumptions in the shell code.
- The shell remains coherent on desktop and smaller breakpoints.

#### Verification
- Review the workspace shell in the browser across generic workspace and app-aware routes.
- Run existing workspace shell tests and update them where the contract changes intentionally.

#### Dependencies
- `ST-WAP-002`
- `ST-WAP-003`

### ST-WAP-005 Define a provider-backed workspace activity feed contract
#### Goal
Introduce a formal workspace activity contract without prematurely building a separate persisted global activity domain.

#### Scope
- Define the shared activity event envelope the workspace shell will consume.
- Clarify how individual apps can provide activity entries into the workspace feed.
- Support platform activity providers later without requiring them immediately.
- Keep persistence strategy minimal and avoid adding a speculative global activity table unless required.

#### Acceptance Criteria
- The workspace has a clear activity feed contract that is app/provider aware.
- The contract can represent Folio revision activity cleanly.
- The contract leaves room for future platform activity sources such as memberships or access changes.
- The story avoids introducing a new persisted domain unless it is required by current implementation needs.

#### Verification
- Review the activity contract and provider mapping in code and docs.
- Confirm the contract can be populated by the existing Folio revision-event model.

#### Dependencies
- `ST-WAP-001`
- `ST-WAP-002`

### ST-WAP-006 Normalize generic workspace platform surfaces
#### Goal
Limit the generic workspace surface area to the concerns that truly belong to the workspace platform.

#### Scope
- Clarify which surfaces remain generic workspace concerns, such as overview, members, access, and settings.
- Tighten shell navigation and page ownership boundaries accordingly.
- Reduce placeholder surfaces that should become app-owned later.
- Keep the story focused on platform boundaries rather than deep feature work inside those pages.

#### Acceptance Criteria
- Generic workspace surfaces are clearly distinguished from app-owned surfaces.
- The shell no longer implies that all future product functionality belongs directly to the workspace platform.
- Platform surfaces remain coherent and useful after the boundary cleanup.

#### Verification
- Review workspace routes and shell navigation for clear platform versus app ownership.
- Review the affected generic workspace pages in the browser.

#### Dependencies
- `ST-WAP-003`
- `ST-WAP-004`
- `ST-WAP-005`
