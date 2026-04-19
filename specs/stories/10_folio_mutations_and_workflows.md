# Epic 10: Folio Mutations and Workflows

This epic turns the first real Folio read surfaces into an actual operator workflow surface.

The order here matters:

- get real reads in place first
- add focused creation and edit flows second
- add status and delegation workflows third

### ST-FOL-020 Add the create-project workflow
#### Goal
Let a workspace user create real Folio projects from the app instead of treating the projects page as read-only.

#### Scope
- Add the first create-project UI flow inside the Folio app.
- Wire the flow through the workspace-scoped Folio action surface.
- Reuse shared form and shell patterns rather than inventing a one-off modal or page treatment.
- Keep the story focused on project creation, not broad project editing.

#### Acceptance Criteria
- Users can create a project from the Folio app in the current workspace.
- The flow respects workspace scope and Folio permissions.
- Successful creation lands back in a coherent real-data projects view.

#### Verification
- Review the create-project flow in the browser.
- Add or update targeted backend/frontend coverage for the creation path.

#### Dependencies
- `ST-FOL-010`
- `ST-FOL-014`

### ST-FOL-021 Add project editing and detail updates
#### Goal
Make the project surface useful beyond creation by supporting real project detail edits.

#### Scope
- Add a focused edit flow for project details such as title, description, and planning metadata.
- Keep the edit path scoped to the fields the current UI can represent well.
- Ensure project updates feed back into real detail and activity views.
- Avoid bundling project status transitions into the same story.

#### Acceptance Criteria
- Users can update supported project details from the Folio app.
- The edit path uses the real Folio mutation surface.
- Updated project details appear correctly in the read surfaces afterward.

#### Verification
- Review project edit flows in the browser.
- Add or update targeted backend/frontend coverage for supported updates.

#### Dependencies
- `ST-FOL-020`

### ST-FOL-022 Add the create-task workflow
#### Goal
Make Folio useful at the task level by supporting real task creation in the current workspace.

#### Scope
- Add a create-task UI flow within the Folio app.
- Support creating standalone or project-linked tasks where appropriate for the current design.
- Keep the flow aligned with the task list/detail patterns already established.
- Avoid bundling task status management into the same story.

#### Acceptance Criteria
- Users can create tasks from the Folio app in the current workspace.
- The task appears correctly in the real task surfaces after creation.
- The flow uses shared form and state patterns rather than ad hoc UI.

#### Verification
- Review the create-task flow in the browser.
- Add or update targeted backend/frontend coverage for task creation.

#### Dependencies
- `ST-FOL-012`
- `ST-FOL-014`

### ST-FOL-023 Add task status transitions
#### Goal
Support the first true GTD workflow movement by letting tasks move through their intended state model.

#### Scope
- Add the first UI for task status transitions such as inbox, next action, waiting for, scheduled, someday/maybe, done, or canceled as supported by the domain.
- Ensure the UI respects the real Folio action model and validation rules.
- Reflect resulting changes in task lists and activity views.
- Keep the story focused on status movement rather than broader task editing.

#### Acceptance Criteria
- Supported task status transitions can be performed from the Folio app.
- Invalid transitions are handled clearly.
- Successful transitions update the visible UI state and activity feed coherently.

#### Verification
- Review task transition flows in the browser.
- Add or update targeted backend/frontend coverage for transition behavior.

#### Dependencies
- `ST-FOL-022`
- `ST-FOL-011`

### ST-FOL-024 Add project status transitions
#### Goal
Bring the same real workflow behavior to projects so the Folio app reflects actual project lifecycle movement.

#### Scope
- Add the first UI for supported project status transitions such as activate, hold, complete, cancel, or archive.
- Ensure project status changes feed through detail views, list filtering, and activity.
- Keep the story focused on project lifecycle movement rather than wide project editing.

#### Acceptance Criteria
- Supported project status transitions can be performed from the Folio app.
- The projects surface reflects new status state coherently after transitions.
- Project transitions generate visible activity results where expected.

#### Verification
- Review project transition flows in the browser.
- Add or update targeted backend/frontend coverage for project status changes.

#### Dependencies
- `ST-FOL-021`
- `ST-FOL-011`

### ST-FOL-025 Add delegation and waiting-for workflow support
#### Goal
Support the first meaningful delegated-work workflow in Folio rather than stopping at solo project/task tracking.

#### Scope
- Add a focused workflow for delegating tasks and representing waiting-for state coherently.
- Use the existing contact and delegation model where applicable.
- Ensure delegation results are visible in tasks and activity.
- Keep the first pass focused on practical delegated-work tracking rather than every future collaboration scenario.

#### Acceptance Criteria
- Users can represent delegated or waiting-for work through the Folio app.
- The resulting state is visible in the task surfaces and activity history.
- The workflow reflects the existing Folio domain model instead of inventing a parallel one.

#### Verification
- Review the delegation flow in the browser.
- Add or update targeted backend/frontend coverage for delegated-work behavior.

#### Dependencies
- `ST-FOL-022`
- `ST-FOL-023`
