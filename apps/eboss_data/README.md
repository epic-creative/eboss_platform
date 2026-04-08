# EBoss Data

Shared persistence infrastructure for the umbrella, including `EBoss.Repo`,
database migrations, resource snapshots, and test support.

## Seeding

Run seeds from the umbrella root, not from `apps/eboss_data`:

```bash
cd /Users/mhostetler/Source/EBoss/eboss_platform
mix seed
```

Optional:

```bash
EBOSS_SEED_PASSWORD=supersecret123 mix seed
```

The seed script is intentionally scenario-based and idempotent for local demo data.
It creates a small but realistic graph across accounts, organizations, workspaces,
and Folio so browser flows and API integration tests have something stable to hit.
