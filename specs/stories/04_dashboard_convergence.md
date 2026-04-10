# Epic 04: Dashboard Convergence

This epic takes the strongest structural ideas from `jido_hub`'s dashboard and adapts them into the EBoss design system.

The goal is not to clone `jido_hub`.
The goal is to bring over the parts that worked:

- operator-grade shell clarity
- strong sectional organization
- compact but readable density
- command-oriented affordances
- calm, disciplined panel composition

### ST-DSH-001 Define the EBoss dashboard shell scaffold and contract
#### Goal
Establish the dashboard shell contract before fully migrating the main dashboard route onto it.

#### Scope
- Define the dashboard frame, primary layout rhythm, and shell-level structure for authenticated product surfaces.
- Clarify what belongs in shell chrome versus page content.
- Keep the story focused on the shell contract and scaffold rather than full dashboard adoption.

#### Acceptance Criteria
- The dashboard has a clear shell identity separate from auth and public surfaces.
- The layout feels operator-oriented and product-specific.
- The shell pattern is reusable for future authenticated surfaces.
- The shell scaffold holds together on desktop and smaller breakpoints.
- The shell remains coherent across supported theme and density states.

#### Verification
- Visual review of the dashboard route.
- LiveView coverage for dashboard route rendering and auth gating.

#### Dependencies
- `ST-DSN-002`
- `ST-DSN-003`
- `ST-DSN-004`
- `ST-DSN-005`
- `ST-DSN-006`
- `ST-DSN-009`

### ST-DSH-002 Adopt the EBoss dashboard shell on the main dashboard route
#### Goal
Move the real dashboard surface onto the shell contract defined earlier.

#### Scope
- Apply the dashboard shell scaffold to the actual dashboard route.
- Keep the work focused on shell adoption rather than broader dashboard feature polish.
- Ensure the route reads as part of the EBoss product system.

#### Acceptance Criteria
- The dashboard route is using the new shell pattern.
- The route remains functional and visually coherent after adoption.
- Shell-level composition is easier to reuse for future authenticated surfaces.

#### Verification
- Visual review of the dashboard route.
- LiveView coverage for dashboard route rendering and auth gating.

#### Dependencies
- `ST-DSH-001`

### ST-DSH-003 Standardize dashboard section headers, action bars, and panel groupings
#### Goal
Make dashboard content areas feel organized and scannable under real product usage.

#### Scope
- Define reusable dashboard section headers and action-bar patterns.
- Standardize panel grouping and spacing rules inside the dashboard.
- Reduce ad hoc content framing inside authenticated product areas.

#### Acceptance Criteria
- Dashboard sections have a clear and repeatable header/action structure.
- Panel groupings feel systematic instead of page-specific.
- Shared dashboard composition patterns are visible in code and in the browser.

#### Verification
- Visual review of dashboard composition.
- LiveView coverage where shared markup structure changes materially.

#### Dependencies
- `ST-DSH-002`

### ST-DSH-004 Standardize dashboard empty, loading, and error states
#### Goal
Make product states predictable and readable before deeper workflow implementation arrives.

#### Scope
- Define dashboard-facing empty, loading, and error treatments using shared design-system patterns.
- Ensure these states work in both sparse and dense dashboard contexts.
- Avoid placeholder screens that look temporary or off-system.

#### Acceptance Criteria
- Dashboard states use a clear shared visual contract.
- Empty and loading surfaces preserve layout structure where possible.
- Error states communicate clearly without looking like generic framework alerts.

#### Verification
- Visual review of representative state examples.
- LiveView coverage for any state-specific rendering helpers introduced.

#### Dependencies
- `ST-DSH-002`

### ST-DSH-005 Add command-oriented quick action and utility patterns
#### Goal
Bring more of the operator-grade interaction language into EBoss without overbuilding early workflow UI.

#### Scope
- Introduce lightweight command-oriented patterns such as quick actions, utility strips, or command-surface cues where appropriate.
- Keep the interaction model aligned with EBoss rather than copying `jido_hub` wholesale.
- Use the design system to make these affordances feel intentional.

#### Acceptance Criteria
- Dashboard utility patterns improve task orientation and action clarity.
- New utility patterns feel native to EBoss.
- The added affordances do not overload the dashboard visually.

#### Verification
- Visual and interaction review in the browser.
- Keyboard or interaction coverage if new client behavior is introduced.

#### Dependencies
- `ST-DSH-002`
- `ST-DSH-003`

### ST-DSH-006 Align dashboard navigation density and hierarchy
#### Goal
Make dashboard navigation easier to scan and more obviously hierarchical.

#### Scope
- Refine dashboard nav density, group hierarchy, active-state treatment, and supporting metadata.
- Clarify the relationship between primary and secondary navigation affordances.
- Remove visual ambiguity around what is actionable, selected, or contextual.

#### Acceptance Criteria
- Dashboard navigation is easier to scan at a glance.
- Active and contextual states are visually unambiguous.
- Navigation density supports operator workflows without becoming noisy.

#### Verification
- Visual review on desktop and smaller breakpoints.
- LiveView coverage where navigation markup contracts change materially.

#### Dependencies
- `ST-DSH-002`
- `ST-DSH-003`
