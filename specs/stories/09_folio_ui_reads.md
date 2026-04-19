# Epic 09: Folio UI Read Surfaces

This epic replaces the current mock-backed workspace app pages with real Folio read surfaces inside the workspace shell.

The priority here is to make the first app feel real:

- real projects
- real activity
- real tasks
- real empty, loading, and error states

### ST-FOL-010 Replace the mock projects page with real Folio projects
#### Goal
Make the first major Folio screen read from real workspace-scoped data instead of mock structures.

#### Scope
- Replace the current mock project list/detail experience with real Folio project reads.
- Preserve the shell quality and selection behavior where it already works well.
- Keep the first pass focused on read behavior and browseability.
- Avoid bundling project creation or mutation flows into this story.

#### Acceptance Criteria
- The projects page renders real Folio project data for the current workspace.
- The page no longer depends on the current mock project dataset.
- Project browsing, selection, and detail display remain coherent within the shell.

#### Verification
- Review the projects surface in the browser against real seeded or dev data.
- Run relevant frontend and LiveView coverage where data wiring changes materially.

#### Dependencies
- `ST-FOL-003`
- `ST-FOL-006`

### ST-FOL-011 Replace the mock activity page with real Folio activity
#### Goal
Turn the activity page into the first real workspace activity feed backed by Folio audit history.

#### Scope
- Replace the mock activity list and inspector state with real Folio activity feed data.
- Preserve the shell’s operator-grade feed browsing and detail affordances.
- Keep the first pass focused on read fidelity and inspector clarity.
- Avoid adding non-Folio activity sources in this story.

#### Acceptance Criteria
- The activity page renders real Folio-backed workspace activity.
- The page no longer depends on mock activity records.
- Event selection and inspection remain usable and coherent with real data.

#### Verification
- Review the activity page in the browser with real Folio events present.
- Run relevant frontend and server-side coverage where the data contract changes.

#### Dependencies
- `ST-FOL-005`
- `ST-FOL-006`

### ST-FOL-012 Add a real Folio tasks list surface
#### Goal
Expose the core GTD unit of work inside the workspace app rather than limiting Folio to projects and activity.

#### Scope
- Add the first real task list view for the current workspace.
- Reuse the shell and existing layout patterns where they fit.
- Focus on read and navigation behavior, not mutation workflows.
- Keep the first task surface coherent with the rest of the Folio app.

#### Acceptance Criteria
- The Folio app includes a real task list surface backed by workspace-scoped task data.
- The task surface fits cleanly into the app-aware shell and navigation model.
- The implementation avoids introducing a second parallel visual language.

#### Verification
- Review the task list surface in the browser with real data.
- Run the relevant frontend and server-side checks for the new route and data wiring.

#### Dependencies
- `ST-WAP-004`
- `ST-FOL-004`
- `ST-FOL-006`

### ST-FOL-013 Add project and task detail patterns for real data
#### Goal
Tighten the app’s read experience by making detail views feel intentional under real project and task data.

#### Scope
- Refine or extract reusable detail patterns for project and task inspection.
- Ensure the inspector/detail treatment works with real Folio fields and metadata.
- Reduce leftover assumptions from the earlier mock structures.
- Keep the story focused on read-state structure rather than edit forms.

#### Acceptance Criteria
- Project and task detail surfaces feel systematic and app-specific.
- The detail patterns work with the actual Folio data model.
- The implementation reduces mock-era structural debt in the page components.

#### Verification
- Review project and task detail behavior in the browser.
- Review the affected Vue components for cleaner composition and reuse.

#### Dependencies
- `ST-FOL-010`
- `ST-FOL-012`

### ST-FOL-014 Standardize Folio empty, loading, and error states
#### Goal
Make the first real app feel production-minded even where data is sparse or unavailable.

#### Scope
- Define empty, loading, and error treatments for Folio projects, tasks, and activity surfaces.
- Reuse workspace and design-system state patterns where possible.
- Preserve layout coherence while data is being loaded or when the app is empty.
- Avoid temporary-looking placeholder states.

#### Acceptance Criteria
- Folio read surfaces use a consistent state contract for empty, loading, and error cases.
- The states feel like part of the product rather than generic framework fallbacks.
- The surfaces remain readable and structured when no data exists yet.

#### Verification
- Review representative Folio state cases in the browser.
- Update component or LiveView coverage where state-specific markup becomes important.

#### Dependencies
- `ST-WAP-006`
- `ST-FOL-010`
- `ST-FOL-011`
- `ST-FOL-012`
