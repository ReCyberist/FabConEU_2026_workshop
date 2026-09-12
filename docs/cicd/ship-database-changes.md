# CI/CD part 3 — ship database changes

--8<-- "includes/clock-afternoon-2.md"

The punchline of the day: **a database change is a pull request, and the pipeline tells you exactly
what it will do to your data before it does it** — the database's answer to `terraform plan`.
Additive changes flow automatically; destructive ones stop for a human.

!!! tip "The hands-on part is on the demo page"
    This page is the *why*. All three increments are run step by step in Part 2 of the
    **[Database demo](../database/demo.md)**.

## What gets built

Three schema changes, each a pull request, each teaching one thing:

1. **Additive** — add a read-only view. The pipeline reports *"1 view to create, 0 data-loss
   operations"* → it merges and auto-publishes. Safe, hands-off.
2. **Destructive (the trap)** — drop a **populated** column, slipped in alongside a harmless view so
   it's easy to miss in review. The guard we already ship makes the deploy **fail loudly** instead of
   silently losing the data.
3. **Safe retire** — actually remove the column *without* losing data: **preserve it first** (a
   pre-deploy migration, or model it as a rename so SqlPackage uses `sp_rename`), then ship behind a
   **human approval**.

## The concept

- **`DeployReport` is the database's `plan`.** `sqlpackage /Action:DeployReport` emits exactly what a
  publish *would* do — including a `DataIssue` alert for possible data loss — **without applying
  anything**. The pipeline posts it before every publish.
- **The guard we already ship.** Our publish profiles set `BlockOnPossibleDataLoss=True`, so a change
  that would drop data **fails** rather than silently succeeding — you have to *choose* to lose data.
- **Destructive changes ship as code too** — with a data-preserving migration **and** a human
  approval gate, never a blind auto-apply.

## Azure SQL / Fabric SQL

The flow is identical on both — only the publish profile changes.

=== "Azure SQL"
    The live-verified path (`AzureSql.publish.xml`).

=== "Fabric SQL"
    The same flow with `FabricSql.publish.xml`, verified live end-to-end on the cross-tenant Fabric
    capacity — see the [Fabric SQL](../infra/fabric-sql.md) page.

## The demo

👉 **[Database demo — Part 2](../database/demo.md)** — publish the baseline, add the view, spring
the trap, then retire the column safely. **[CI/CD demo](demo.md)** shows the same story driven
from the pipeline.

## The code

The three increments — real, runnable SQL plus a follow-along README with the exact commands — live
in
[`database/demo/ship-changes`](https://github.com/JessAndRob/FabConEU_2026_workshop/tree/main/database/demo/ship-changes).

## Checkpoint

Increment 1 auto-publishes; increment 2's column drop is **blocked** (and was flagged on the PR by
the DeployReport before merge); increment 3 ships the removal safely, behind an approval — no data
lost.

## Gotchas

- **`DeployReport` writes with `/OutputPath`** — `/DeployReportPath` is an MSBuild property, not a
  CLI argument, and fails the action.
- **The approval gate is documented, not wired** on this repo — GitHub Environment required-reviewer
  rules need a paid plan on a private repo (task #21); the production-grade pattern is in the demo's
  `increment-3` notes.
- **The seed populates the dropped column**, so the data loss in increment 2 is genuine — a plain
  `SELECT` proves it before and after.

## What's next

Next: [Migrations, drift & teardown](../wrap-up/migrations-drift-teardown.md).
