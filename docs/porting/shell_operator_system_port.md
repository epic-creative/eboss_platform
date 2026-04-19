# Shell Operator System Port Blueprint

## Goal

Port the published Lovable shell from `/tmp/shell-operator-system` into EBoss so the Phoenix + `live_vue` app matches the reference product shell 1:1 in layout, hierarchy, spacing, and responsive behavior.

Phoenix keeps routing, auth, and server state. Vue owns the shell presentation and local interaction state.

## Source Of Truth

- `/tmp/shell-operator-system/src/components/layout/DashboardShell.tsx`
- `/tmp/shell-operator-system/src/components/WorkspaceSidebar.tsx`
- `/tmp/shell-operator-system/src/components/InspectorPane.tsx`
- `/tmp/shell-operator-system/src/pages/dashboard/*`
- `/tmp/shell-operator-system/src/pages/Landing.tsx`
- `/tmp/shell-operator-system/src/pages/auth/*`
- `/tmp/shell-operator-system/src/index.css`

## Target Mapping

- Routes:
  - `/dashboard` remains redirect-only
  - canonical workspace route families gain `dashboard`, `projects`, `members`, `access`, `activity`, `settings`

- Elixir handoff points:
  - `/Users/mhostetler/Source/EBoss/eboss_platform/apps/eboss_web/lib/eboss_web/router.ex`
  - `/Users/mhostetler/Source/EBoss/eboss_platform/apps/eboss_web/lib/eboss_web/live/dashboard_live.ex`
  - `/Users/mhostetler/Source/EBoss/eboss_platform/apps/eboss_web/lib/eboss_web/components/layouts.ex`

- Vue shell targets:
  - `/Users/mhostetler/Source/EBoss/eboss_platform/apps/eboss_web/assets/vue/shell/workspace/*`

- Styling targets:
  - `/Users/mhostetler/Source/EBoss/eboss_platform/apps/eboss_web/assets/css/shell-operator.css`
  - `/Users/mhostetler/Source/EBoss/eboss_platform/apps/eboss_web/assets/css/app.css`

## Rules

- Do not port React.
- Do not mix the old dashboard shell and the new shell on the same routes.
- Keep real workspace ownership semantics from `AppScope`.
- Demo page data is acceptable while the shell parity is being established.

## Delivery Order

1. Route parity and workspace layout mount point
2. Signed-in workspace shell
3. Overview, Projects, Members, Access, Activity, Settings parity
4. Public landing shell
5. Auth shell
6. Replace demo content with real domain/bootstrap data
