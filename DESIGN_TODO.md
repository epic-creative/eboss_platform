# DESIGN_TODO.md

## Canonical Reference

The Lovable shell reference for EBoss is:

- Published design: `https://shell-operator-system.lovable.app`
- Local temp clone path found on disk: `/private/tmp/shell-operator-system`
- Existing port blueprint in this repo: `docs/porting/shell_operator_system_port.md`

Important note:

- The local temp clone is now populated from `https://github.com/mikehostetler/shell-operator-system` and currently resolves to commit `5d1dba4161d59341e3a845a990b4fbad7df90534`.
- The expected source files are present there, including:
  - `src/components/layout/DashboardShell.tsx`
  - `src/components/WorkspaceSidebar.tsx`
  - `src/components/InspectorPane.tsx`
  - `src/pages/Landing.tsx`
  - `src/pages/auth/*`
  - `src/pages/dashboard/*`
  - `src/index.css`
- The practical canonical implementation inside this repo is still the shell-operator port already landed under:
  - `apps/eboss_web/assets/css/shell-operator.css`
  - `apps/eboss_web/assets/vue/shell/public/`
  - `apps/eboss_web/assets/vue/shell/workspace/`
  - `apps/eboss_web/lib/eboss_web/components/auth_components.ex`

## Current Status

What is already aligned to the Lovable shell direction:

- Public landing route mounts `ShellOperatorLanding`.
- Canonical workspace routes mount `ShellOperatorWorkspaceApp`.
- Auth shell uses the same shell-operator token family and general visual language.
- The repo already has a port blueprint that maps Lovable source files to Phoenix/Vue targets.

What is still split:

- `DESIGN.md` describes a shared `ui-*` design system as the main contract.
- Runtime home, auth, and workspace surfaces still lean on the parallel `so-*` shell-operator layer.
- The shell-operator layer is therefore the effective runtime reference, but not yet the fully reconciled shared design-system contract.

Decision locked:

- The Lovable shell-operator system is the canonical visual source for EBoss.
- The layered EBoss CSS stack (`tokens.css`, `themes.css`, `primitives.css`, `patterns.css`) is the implementation architecture for that visual system.
- `ui-*` primitives and patterns should converge on the Lovable shell direction instead of acting as a separate art direction.

## Source Mapping

Per `docs/porting/shell_operator_system_port.md`, the intended Lovable source-of-truth files were:

- `/tmp/shell-operator-system/src/components/layout/DashboardShell.tsx`
- `/tmp/shell-operator-system/src/components/WorkspaceSidebar.tsx`
- `/tmp/shell-operator-system/src/components/InspectorPane.tsx`
- `/tmp/shell-operator-system/src/pages/dashboard/*`
- `/tmp/shell-operator-system/src/pages/Landing.tsx`
- `/tmp/shell-operator-system/src/pages/auth/*`
- `/tmp/shell-operator-system/src/index.css`

Current EBoss targets already carrying that port:

- `apps/eboss_web/assets/vue/shell/workspace/ShellOperatorWorkspaceApp.vue`
- `apps/eboss_web/assets/vue/shell/workspace/WorkspaceSidebar.vue`
- `apps/eboss_web/assets/vue/shell/workspace/InspectorPane.vue`
- `apps/eboss_web/assets/vue/shell/public/ShellOperatorLanding.vue`
- `apps/eboss_web/assets/css/shell-operator.css`
- `apps/eboss_web/lib/eboss_web/live/dashboard_live.ex`
- `apps/eboss_web/lib/eboss_web/live/home_live.ex`
- `apps/eboss_web/lib/eboss_web/components/auth_components.ex`

## Design TODO

### 1. Lock The Canonical Decision

- [x] Treat the Lovable shell direction as canonical for runtime surfaces.
- [x] Update `DESIGN.md` so it explicitly states the canonical source and architecture.
- [x] Remove ambiguity between the documented shared design system and the runtime shell-operator implementation.

### 2. Preserve And Recover The Source

- [ ] Keep `/private/tmp/shell-operator-system` noted as the discovered local source path.
- [ ] Copy or mirror the populated temp clone into a durable non-temp reference location such as `docs/reference/shell-operator-system/` if we want it preserved outside `/tmp`.
- [ ] If we do not preserve a durable copy, keep the current EBoss shell files as the canonical in-repo implementation baseline going forward.

### 3. Reconcile Tokens And CSS

- [ ] Audit `apps/eboss_web/assets/css/shell-operator.css` against `apps/eboss_web/assets/css/system/tokens.css` and `themes.css`.
- [ ] Promote duplicated shell-operator values into shared semantic tokens where they are truly foundational.
- [ ] Move the shared `ui-*` token and primitive layer onto Lovable shell values, spacing, radii, and typography.
- [ ] Decide which `so-*` classes are temporary adapters and which ones should become first-class shared primitives/patterns.
- [ ] Avoid leaving two separate token systems in long-term use.

### 4. Converge Auth

- [ ] Refactor `apps/eboss_web/lib/eboss_web/components/auth_components.ex` so auth uses the canonical shell direction without needing a parallel patch layer.
- [ ] Replace shell-specific one-off contracts like `so-auth-card`, `so-underline-tab`, and `so-input-field` with shared equivalents or officially adopt them into the shared system.
- [ ] Keep sign-in, register, forgot-password, reset, confirm, and magic-link flows visually identical in theme and density behavior.

### 5. Converge Public Surfaces

- [ ] Reconcile `apps/eboss_web/assets/vue/shell/public/ShellOperatorLanding.vue` with the public pattern system documented in `DESIGN.md`.
- [ ] Either:
  - rebuild the landing route from shared public patterns, or
  - explicitly adopt the shell-operator landing patterns into the shared system and document them.
- [ ] Keep the public route family in the same product shell language as auth and workspace routes.

### 6. Converge Workspace Surfaces

- [ ] Break `apps/eboss_web/assets/vue/shell/workspace/ShellOperatorWorkspaceApp.vue` into reusable shared patterns instead of one large runtime scene.
- [ ] Promote sidebar, inspector, top bar, search, settings tabs, section headers, list/detail panels, and empty states into reusable design-system-level components where appropriate.
- [ ] Align `apps/eboss_web/lib/eboss_web/components/dashboard_components.ex` with the runtime workspace shell so there is one canonical dashboard/workspace shell direction.

### 7. Align HEEx And Vue Contracts

- [ ] Ensure shared variant names, tone names, spacing rules, and state names match across:
  - `apps/eboss_web/lib/eboss_web/components/ui_components.ex`
  - `apps/eboss_web/lib/eboss_web/components/dashboard_components.ex`
  - `apps/eboss_web/lib/eboss_web/components/auth_components.ex`
  - `apps/eboss_web/assets/vue/components/ui/*`
  - `apps/eboss_web/assets/vue/shell/*`
- [ ] Do not allow HEEx to drift into one visual language and Vue into another.

### 8. Make Review Surfaces Match Runtime

- [ ] Update `/dev/design-system` to preview the real runtime shell-operator-derived patterns, not only abstract design-system examples.
- [ ] Add explicit review coverage for:
  - public landing shell
  - auth shell
  - workspace shell
  - compact density
  - dark/light parity
- [ ] Keep Histoire and `/dev/design-system` synchronized so they reflect the same canonical design direction.

### 9. Reduce Transitional Debt

- [ ] Identify which `so-*` classes are still direct screen-level styling rather than reusable primitives.
- [ ] Replace route-level one-offs with shared contracts wherever they repeat.
- [ ] Delete transitional adapters only after the replacement path is live on all affected routes.

### 10. End-State Cleanup

- [ ] Once the canonical system is settled, remove whichever layer is non-canonical:
  - remove `shell-operator.css` if everything is fully absorbed into the shared `ui-*` system, or
  - remove/rename the older `ui-*` abstractions if the shell-operator system becomes the official design language.
- [ ] Update `DESIGN.md` to match the final reality exactly.
- [ ] Keep `DESIGN_TODO.md` focused on remaining alignment work, not historical ambiguity.

## Recommended Execution Order

1. Canonical naming decision
2. Token/CSS reconciliation
3. Auth convergence
4. Public landing convergence
5. Workspace shell decomposition
6. HEEx/Vue contract alignment
7. Review-surface updates
8. Transitional cleanup

## Immediate Next Step

If continuing from the current branch state, the highest-leverage next move is:

- rebase the shared token and primitive layer onto the Lovable shell values
- then migrate auth onto that single visual contract first

Auth is the smallest surface that already touches both systems, so it is the fastest place to stop the split from getting deeper.
