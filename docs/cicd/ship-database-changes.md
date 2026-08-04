<!-- DRAFT: skeleton only. Prose to be fleshed out (task #22, Phase 3). -->

# CI/CD part 3 — ship database changes

<!-- INTRO: a database change is a PR, and the pipeline shows exactly what it will do to your data
     before it does it — the DB's answer to `terraform plan`. -->

!!! note "Follow along — or just watch"
    A target SQL with seeded data to see data-loss safely. See [Prerequisites](../setup/prerequisites.md).

## What you'll build

<!-- Three PR increments: additive (safe/auto) → destructive drop (the trap) → safe retire + gate. -->

## The concept

<!-- DeployReport = the DB plan (flags data-loss ops before deploy); BlockOnPossibleDataLoss=True
     makes a blind publish fail loudly; destructive changes ship via a migration + a human gate. -->

## Azure SQL / Fabric SQL

=== "Azure SQL"
    <!-- The live-verified path (AzureSql.publish.xml). -->

=== "Fabric SQL"
    <!-- Same flow, FabricSql.publish.xml — gated on the capacity (#20). -->

## The code

The runnable demo (three increments + a follow-along README) is in
[`database/demo/ship-changes`](https://github.com/JessAndRob/FabConEU_2026_workshop/tree/main/database/demo/ship-changes).

## Checkpoint

<!-- Increment 1 auto-publishes; increment 2's drop is blocked/flagged; increment 3 ships safely. -->

## Gotchas

<!-- DeployReport writes with /OutputPath (not /DeployReportPath); the approval gate is documented,
     not wired (#21); the seed populates ShirtNumber so the data loss is real. -->

## What's next

Next: [Migrations, drift & teardown](../wrap-up/migrations-drift-teardown.md).
