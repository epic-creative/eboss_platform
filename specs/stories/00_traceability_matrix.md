# Story Traceability Matrix

| Story ID | Epic | Outcome | Primary surfaces | Verification | Dependencies |
| --- | --- | --- | --- | --- | --- |
| ST-DSN-001 | Design Foundation | Codify EBoss visual DNA and dashboard-derived aesthetic rules | `DESIGN.md`, design previews | doc review, preview review | None |
| ST-DSN-002 | Design Foundation | Normalize semantic typography roles across shared UI | CSS foundations, HEEx, Vue | visual review, story review | `ST-DSN-001` |
| ST-DSN-003 | Design Foundation | Normalize tone and color semantics across the design system | CSS foundations, HEEx, Vue | visual review, story review | `ST-DSN-001` |
| ST-DSN-004 | Design Foundation | Normalize surfaces, elevation, radius, and shadow rules | CSS foundations, HEEx, Vue | visual review, preview review | `ST-DSN-001`, `ST-DSN-003` |
| ST-DSN-005 | Design Foundation | Add accessibility and interaction rules to the shared design system | shared primitives, shell states | visual review, keyboard review | `ST-DSN-002`, `ST-DSN-003`, `ST-DSN-004` |
| ST-DSN-006 | Design Foundation | Add theme and density parity review to the shared design system | shared primitives, shell states | visual review, state review | `ST-DSN-002`, `ST-DSN-003`, `ST-DSN-004` |
| ST-DSN-007 | Design Foundation | Expand HEEx design preview coverage | `/dev/design-system`, shared HEEx primitives | LiveView test, manual review | `ST-DSN-002`, `ST-DSN-003`, `ST-DSN-004`, `ST-DSN-005`, `ST-DSN-006` |
| ST-DSN-008 | Design Foundation | Expand Histoire coverage for shared Vue primitives with reusable state vocabulary | Histoire, Vue UI components | `npm run histoire:build`, `npm run vue:check` | `ST-DSN-002`, `ST-DSN-003`, `ST-DSN-004`, `ST-DSN-005`, `ST-DSN-006` |
| ST-DSN-009 | Design Foundation | Align HEEx and Vue primitive contracts | HEEx primitives, Vue primitives | preview review, story review | `ST-DSN-002`, `ST-DSN-003`, `ST-DSN-004`, `ST-DSN-005`, `ST-DSN-006` |
| ST-AUTH-001 | Auth and Public Surfaces | Unify auth shell layout and hierarchy | sign-in, register, forgot/reset, confirm | LiveView test, visual review | `ST-DSN-002`, `ST-DSN-003`, `ST-DSN-004`, `ST-DSN-005`, `ST-DSN-006`, `ST-DSN-009` |
| ST-AUTH-002 | Auth and Public Surfaces | Unify auth fields, validation, and feedback states | auth forms, auth shared components | LiveView test, manual review | `ST-AUTH-001` |
| ST-AUTH-003 | Auth and Public Surfaces | Fix browser-visible sign-in field retention regressions | `/sign-in` | manual browser verification, LiveView test where applicable | `ST-AUTH-001`, `ST-AUTH-002` |
| ST-PUB-001 | Auth and Public Surfaces | Unify public navigation, footer, and CTA frame with product system | public shell, home surface | visual review, route smoke | `ST-DSN-002`, `ST-DSN-003`, `ST-DSN-004`, `ST-DSN-005`, `ST-DSN-006`, `ST-DSN-009` |
| ST-PUB-002 | Auth and Public Surfaces | Reframe landing page hero and narrative rhythm using dashboard-derived DNA | home page | visual review, responsive review | `ST-DSN-001`, `ST-PUB-001` |
| ST-PUB-003 | Auth and Public Surfaces | Define reusable public section patterns | home page sections, public shell patterns | visual review, preview review | `ST-PUB-001`, `ST-PUB-002` |
| ST-PUB-004 | Auth and Public Surfaces | Migrate the public page to standardized section patterns | home page sections, public shell patterns | visual review, route smoke | `ST-PUB-003` |
| ST-TST-001 | Auth and Public Confidence | Add stable test contracts for auth and public surfaces | auth and public pages, shared selectors | selector review, accessibility review | `ST-AUTH-001`, `ST-PUB-001` |
| ST-TST-002 | Auth and Public Confidence | Bootstrap Playwright tooling and local smoke execution | Playwright setup | Playwright run | `ST-TST-001` |
| ST-TST-003 | Auth and Public Confidence | Add deterministic browser test data and session setup for auth and public flows | auth accounts, browser sessions, smoke setup | setup run, Playwright run | `ST-TST-002` |
| ST-TST-004 | Auth and Public Confidence | Add Playwright auth and public smoke harness | auth and public flows | Playwright run | `ST-TST-003`, `ST-AUTH-001`, `ST-PUB-001` |
| ST-TST-005 | Auth and Public Confidence | Add sign-in browser regression coverage | `/sign-in` | Playwright run | `ST-TST-004`, `ST-AUTH-003` |
| ST-DSH-001 | Dashboard Convergence | Define the EBoss dashboard shell scaffold and contract | dashboard shell, layout frame | LiveView test, visual review | `ST-DSN-002`, `ST-DSN-003`, `ST-DSN-004`, `ST-DSN-005`, `ST-DSN-006`, `ST-DSN-009` |
| ST-DSH-002 | Dashboard Convergence | Adopt the EBoss dashboard shell on the main dashboard route | dashboard route, layout frame | LiveView test, visual review | `ST-DSH-001` |
| ST-DSH-003 | Dashboard Convergence | Standardize dashboard section headers, action bars, and panel groupings | dashboard components | LiveView test, visual review | `ST-DSH-002` |
| ST-DSH-004 | Dashboard Convergence | Standardize dashboard empty, loading, and error states | dashboard states | LiveView test, visual review | `ST-DSH-002` |
| ST-DSH-005 | Dashboard Convergence | Add command-oriented quick action and utility patterns | dashboard actions, command surfaces | visual review, interaction review | `ST-DSH-002`, `ST-DSH-003` |
| ST-DSH-006 | Dashboard Convergence | Align dashboard navigation density and hierarchy | dashboard nav, shell chrome | LiveView test, visual review | `ST-DSH-002`, `ST-DSH-003` |
| ST-TST-006 | Dashboard and Component Confidence | Add stable test contracts for dashboard surfaces | dashboard shell, dashboard states | selector review, route review | `ST-DSH-002` |
| ST-TST-007 | Dashboard and Component Confidence | Bootstrap Vitest and Vue component behavior test tooling | Vue test setup, test helpers | Vitest run, `npm run vue:check` | `ST-DSN-008`, `ST-DSN-009` |
| ST-TST-008 | Dashboard and Component Confidence | Add Vitest component behavior tests for stable LiveVue primitives | Vue UI primitives | Vitest run, `npm run vue:check` | `ST-TST-007`, `ST-DSN-008`, `ST-DSN-009` |
| ST-TST-009 | Dashboard and Component Confidence | Add dashboard smoke coverage after shell stabilization | dashboard | Playwright run, route smoke | `ST-TST-004`, `ST-TST-006`, `ST-DSH-002`, `ST-DSH-003`, `ST-DSH-004` |
| ST-TST-010 | Dashboard and Component Confidence | Wire Playwright and Vitest lanes into an automated repo gate | CI or repo automation, frontend test lanes | automated gate run, config review | `ST-TST-005`, `ST-TST-008`, `ST-TST-009` |
| ST-DSN-010 | Cleanup and Deprecation | Remove deprecated shared UI paths after system convergence | shared primitives, legacy UI paths | code review, route smoke | `ST-DSN-007`, `ST-DSN-008`, `ST-DSN-009`, `ST-AUTH-002`, `ST-PUB-004`, `ST-DSH-006`, `ST-TST-004`, `ST-TST-005`, `ST-TST-008`, `ST-TST-009`, `ST-TST-010` |
| ST-WAP-001 | Workspace App Platform | Define the multi-app workspace platform contract | workspace shell, routing, bootstrap contract | spec review, implementation review | `ST-DSH-002`, `ST-DSH-003`, `ST-TST-006` |
| ST-WAP-002 | Workspace App Platform | Add an app registry to workspace scope and bootstrap payloads | `AppScope`, workspace bootstrap, shell inputs | controller/integration review, focused tests | `ST-WAP-001` |
| ST-WAP-003 | Workspace App Platform | Add app-aware workspace routes and route resolution | router, `DashboardLive`, scope resolution | LiveView test, route review | `ST-WAP-001`, `ST-WAP-002` |
| ST-WAP-004 | Workspace App Platform | Refactor the workspace shell for app-aware navigation and chrome | workspace shell Vue app, shell navigation | visual review, Vue test | `ST-WAP-002`, `ST-WAP-003` |
| ST-WAP-005 | Workspace App Platform | Define a provider-backed workspace activity feed contract | workspace activity contract, Folio event mapping | code review, contract review | `ST-WAP-001`, `ST-WAP-002` |
| ST-WAP-006 | Workspace App Platform | Normalize generic workspace platform surfaces | overview, members, access, settings, shell nav | browser review, route review | `ST-WAP-003`, `ST-WAP-004`, `ST-WAP-005` |
| ST-FOL-001 | Folio API Foundation | Define the workspace-scoped Folio app API contract | Folio routes, payloads, app scope | spec review, contract review | `ST-WAP-001`, `ST-WAP-002`, `ST-WAP-003` |
| ST-FOL-002 | Folio API Foundation | Add a workspace-scoped Folio bootstrap endpoint | Folio bootstrap endpoint, app mount data | controller test, integration test | `ST-FOL-001` |
| ST-FOL-003 | Folio API Foundation | Add workspace-scoped Folio projects reads | Folio domain interface, projects endpoint | boundary test, endpoint test | `ST-FOL-001`, `ST-FOL-002` |
| ST-FOL-004 | Folio API Foundation | Add workspace-scoped Folio tasks reads | Folio domain interface, tasks endpoint | boundary test, endpoint test | `ST-FOL-001`, `ST-FOL-002` |
| ST-FOL-005 | Folio API Foundation | Add a Folio activity provider backed by revision events | revision events, activity feed endpoint | boundary test, endpoint test | `ST-WAP-005`, `ST-FOL-001`, `ST-FOL-002` |
| ST-FOL-006 | Folio API Foundation | Add a typed frontend Folio data client and composable layer | Vue data client, composables, app data wiring | `npm run vue:check`, code review | `ST-FOL-002`, `ST-FOL-003`, `ST-FOL-004`, `ST-FOL-005` |
| ST-FOL-010 | Folio UI Read Surfaces | Replace the mock projects page with real Folio projects | Folio projects page, workspace app shell | browser review, focused test updates | `ST-FOL-003`, `ST-FOL-006` |
| ST-FOL-011 | Folio UI Read Surfaces | Replace the mock activity page with real Folio activity | Folio activity page, workspace activity feed | browser review, focused test updates | `ST-FOL-005`, `ST-FOL-006` |
| ST-FOL-012 | Folio UI Read Surfaces | Add a real Folio tasks list surface | Folio tasks page, app navigation | browser review, focused test updates | `ST-WAP-004`, `ST-FOL-004`, `ST-FOL-006` |
| ST-FOL-013 | Folio UI Read Surfaces | Add project and task detail patterns for real data | project detail, task detail, inspectors | browser review, component review | `ST-FOL-010`, `ST-FOL-012` |
| ST-FOL-014 | Folio UI Read Surfaces | Standardize Folio empty, loading, and error states | Folio app states, shared shell patterns | browser review, state coverage | `ST-WAP-006`, `ST-FOL-010`, `ST-FOL-011`, `ST-FOL-012` |
| ST-FOL-020 | Folio Mutations and Workflows | Add the create-project workflow | Folio projects UI, project create action | browser review, targeted test updates | `ST-FOL-010`, `ST-FOL-014` |
| ST-FOL-021 | Folio Mutations and Workflows | Add project editing and detail updates | project detail UI, update action | browser review, targeted test updates | `ST-FOL-020` |
| ST-FOL-022 | Folio Mutations and Workflows | Add the create-task workflow | task UI, task create action | browser review, targeted test updates | `ST-FOL-012`, `ST-FOL-014` |
| ST-FOL-023 | Folio Mutations and Workflows | Add task status transitions | task workflow UI, task transition actions | browser review, targeted test updates | `ST-FOL-022`, `ST-FOL-011` |
| ST-FOL-024 | Folio Mutations and Workflows | Add project status transitions | projects UI, project transition actions | browser review, targeted test updates | `ST-FOL-021`, `ST-FOL-011` |
| ST-FOL-025 | Folio Mutations and Workflows | Add delegation and waiting-for workflow support | contacts, delegations, tasks, activity | browser review, targeted test updates | `ST-FOL-022`, `ST-FOL-023` |
| ST-FOL-030 | Folio Confidence | Add stable test contracts for workspace-app and Folio surfaces | app-aware shell, Folio pages, selectors | selector review, accessibility review | `ST-WAP-004`, `ST-FOL-010`, `ST-FOL-011`, `ST-FOL-012` |
| ST-FOL-031 | Folio Confidence | Add Vue behavior coverage for the app-aware shell and Folio read states | workspace shell Vue app, Folio page components | Vitest run, `npm run vue:check` | `ST-FOL-030`, `ST-FOL-014` |
| ST-FOL-032 | Folio Confidence | Add LiveView and server coverage for workspace-app and Folio routing/bootstrap wiring | router, `DashboardLive`, controllers, scope | LiveView test, server test | `ST-WAP-003`, `ST-WAP-004`, `ST-FOL-002`, `ST-FOL-006` |
| ST-FOL-033 | Folio Confidence | Add Playwright smoke coverage for real Folio read flows | app-aware workspace shell, Folio reads | Playwright run | `ST-FOL-030`, `ST-FOL-032` |
| ST-FOL-034 | Folio Confidence | Add focused confidence for Folio mutation workflows and repo gating | Folio write paths, repo automation | automated gate run, config review | `ST-FOL-023`, `ST-FOL-024`, `ST-FOL-025`, `ST-FOL-031`, `ST-FOL-032`, `ST-FOL-033`, `ST-TST-010` |
