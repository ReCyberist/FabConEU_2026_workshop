# Database as Code

Ship database schema changes as code, deployed through the pipelines. Everything targets
one **canonical sample database** (football-themed candidate) so the three approaches stay
comparable.

## Layout

```
database/
├── sql-projects/     ← FOCUS: .sqlproj / DACPAC (state-based)
├── flyway/           ← reference/bonus (migration-based)
└── dbatools-dbops/   ← reference/bonus (PowerShell migrations)
```

## Rules
- **One canonical schema.** The same tables/objects across all three approaches; don't let
  them drift.
- **Deployed by pipeline, not by hand.** Local runs are for authoring; the source of truth
  for "deployed" is the CI/CD run.
- **Targets both** Azure SQL and Fabric SQL — note any object that behaves differently on
  Fabric.

Learnings (a DACPAC deployment quirk, a Fabric T-SQL surface-area gap) →
[`../notes/LEARNINGS.md`](../notes/LEARNINGS.md).
