# Seeding And Mocking

## Goals

Keep local data generation simple, deterministic, and close to production behavior.

The project should prefer:

- idempotent demo seeds for local development
- boundary-first scenario builders for domain tests
- black-box HTTP integration tests for the public API

The project should avoid treating fake data generation as a separate persistence model.

## Local Seed Strategy

Use the umbrella-root seed command:

```bash
mix seed
```

Optional:

```bash
EBOSS_SEED_PASSWORD=supersecret123 mix seed
```

The seed entrypoint lives at [apps/eboss_data/priv/repo/seeds.exs](/Users/mhostetler/Source/EBoss/eboss_platform/apps/eboss_data/priv/repo/seeds.exs).

Principles:

- Seed through domain boundaries wherever practical.
- Use raw Ash reads only for idempotent lookup or actions that do not yet have a boundary helper.
- Keep the seeded graph small, named, and stable.
- Prefer realistic relationships over random volume.
- Make reruns safe for active seeded records.

Current seeded graph:

- example users
- one organization
- one public user workspace
- one private org workspace
- a small Folio scenario in each workspace

## Test Data Strategy

### Domain Tests

Use boundary-oriented scenario helpers.

Examples:

- `EBoss.Accounts.register_with_password!/2`
- `EBoss.Organizations.create_organization!/2`
- `EBoss.Workspaces.create_workspace!/2`
- `EBoss.Folio.create_project!/2`

This keeps tests aligned with the contracts other apps should use.

### API Tests

Use real HTTP tests against the mounted API surface.

The project already has this pattern in [apps/eboss_web/test/eboss_web/integration/json_api_http_test.exs](/Users/mhostetler/Source/EBoss/eboss_platform/apps/eboss_web/test/eboss_web/integration/json_api_http_test.exs).

That should remain the preferred approach for:

- route behavior
- auth behavior
- response envelopes
- OpenAPI contract checks

### Resource-Internal Tests

Use direct resource tests only for sharp internals:

- custom changes
- custom validations
- calculations
- authorization edge cases

## Where `ash_mock` Fits

`ash_mock` is useful for generated mock Ash resources, especially when you want
ephemeral in-memory resources and deep relationship mocking in narrow tests.

It is **not** the primary solution for this project's dev-data or integration-data needs.

Use `ash_mock` when:

- a test needs a lightweight fake Ash resource graph
- the test does not care about Postgres behavior
- you want isolated mock records without provisioning a realistic scenario

Do not use `ash_mock` for:

- local development seeds
- API contract data
- end-to-end browser or HTTP integration flows
- anything that should reflect the real Postgres-backed resource behavior

## Recommendation

Keep the main strategy simple:

1. `mix seed` for local demo data
2. boundary-first scenario helpers for domain tests
3. live HTTP integration tests for the public API
4. `ash_mock` only for narrow, in-memory test doubles when a full scenario would be overkill
