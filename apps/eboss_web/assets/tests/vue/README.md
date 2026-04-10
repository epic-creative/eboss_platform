# Vitest Layout

Local Vue component behavior confidence lives in this tree.

- `tests/vue/components`: behavior specs for shared Vue primitives and scenes
- `tests/vue/support`: shared mount helpers and other test-only utilities
- `tests/vue/setup.ts`: Vitest setup that keeps component wrappers cleaned up between runs

Run from `apps/eboss_web/assets`:

```bash
npm run vue:test
npm run vue:check
```

Automated repo gate from the umbrella root:

```bash
mix frontend.gate
```

The `Frontend Confidence` GitHub Actions workflow runs that gate on pushes and pull requests. The automated lane keeps the Vue check focused on `npm run vue:test`.

Tooling decisions:

- `Vitest` with `@vue/test-utils` is the default component-test stack for Vue work in this repo.
- `vitest.config.ts` reuses the asset Vite resolve and dependency settings so Vue tests follow the same component authoring path as `live_vue`.
