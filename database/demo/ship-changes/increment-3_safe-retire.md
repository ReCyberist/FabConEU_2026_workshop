# Increment 3 — retire the column *safely* (the right way)

Same goal as Increment 2 (stop carrying `ShirtNumber` on `Player`), but **without losing
data** — two techniques, both shipped as runnable files. This page is the *why*; the exact
copy-and-publish steps are in [`README.md`](README.md). Both options end at the same schema
(`Player.SquadNumber` replaces `Player.ShirtNumber`) and share the seed
[`increment-3_Seed.sql`](increment-3_Seed.sql).

## Why you can't just copy the column across in one script

SqlPackage runs a publish in three phases, in this order: **pre-deploy script → schema change
→ post-deploy script**. Two facts about that order shape everything here:

1. **The plan is computed once, up front, against the target's original state** — before the
   pre-deploy script runs, and it is never re-computed. (Microsoft Learn, *pre/post-deployment
   scripts*.)
2. So at pre-deploy time the **new `SquadNumber` column does not exist yet**, and there is **no
   hook between the generated `ADD [SquadNumber]` and `DROP [ShirtNumber]`** in the schema step.

That kills the obvious one-liner. A pre-deploy `UPDATE ... SET [SquadNumber] = [ShirtNumber]`
**fails to compile** on any database that already has `Player`, with
`Msg 207, Invalid column name 'SquadNumber'` — SQL Server's deferred name resolution covers a
missing *table*, never a missing *column* of a table that exists, and the whole batch is bound
before the `IF` guard can run. The data-preserving copy therefore has to be split across the
pre-deploy and post-deploy phases (Option A), or avoided entirely by modelling the change as a
rename (Option B).

## Option A — preserve first (pre-deploy stash + post-deploy restore)

The canonical single-deployment pattern for a genuine data move. Runnable files:

| File | Copied to | Does |
|------|-----------|------|
| [`increment-3_Player.sql`](increment-3_Player.sql) | `Tables/Player.sql` | drops `ShirtNumber`, adds `SquadNumber TINYINT NULL` |
| [`increment-3_Migrate-ShirtNumber.sql`](increment-3_Migrate-ShirtNumber.sql) | `Scripts/PreDeployment/Migrate-ShirtNumber.sql` | **pre-deploy**: copies `ShirtNumber` into a staging table while it still exists |
| [`increment-3_Seed.sql`](increment-3_Seed.sql) | `Scripts/PostDeployment/Seed.sql` | **post-deploy**: lands the stashed values in `SquadNumber`, then drops the staging table |
| [`increment-3A_FabConFootball.sqlproj`](increment-3A_FabConFootball.sqlproj) | `FabConFootball.sqlproj` | adds the `<PreDeploy Include="…" />` item |

Each script only ever references columns that exist **at its own phase**, so both compile: the
pre-deploy reads `ShirtNumber` (still present); the post-deploy writes `SquadNumber` (created by
the schema step just before it) and reads the staging table.

**Be honest about the report.** The schema step genuinely drops `ShirtNumber`, so the
DeployReport **still shows** `<Alert Name="DataIssue">` for that drop. Option A preserves the
*data*, not the *column* — so the publish must explicitly allow the drop with
`/p:BlockOnPossibleDataLoss=false`. That is the same flag as Increment 2's YOLO, but here it is a
considered decision: the migration already moved the data to safety.

**Wiring is a demo step, not committed.** A `<PreDeploy Include="…" />` that points at a file
which is not on disk fails the build (`SQL72006: Could not find a part of the path`). The
committed `FabConFootball.sqlproj` therefore stays clean, and the presenter copies in
`increment-3A_FabConFootball.sqlproj` alongside the migration script.

## Option B — model it as a rename (refactorlog → `sp_rename`)

When the change is really just a rename, record the intent in the project's **refactorlog** and
SqlPackage emits `sp_rename` instead of drop-and-add — **zero data movement, and a clean
report**. Runnable files:

| File | Copied to | Does |
|------|-----------|------|
| [`increment-3_Player.sql`](increment-3_Player.sql) | `Tables/Player.sql` | the same end schema (`SquadNumber`, no `ShirtNumber`) |
| [`increment-3_Seed.sql`](increment-3_Seed.sql) | `Scripts/PostDeployment/Seed.sql` | the same seed (its backfill block is a no-op here — no staging table) |
| [`increment-3_FabConFootball.refactorlog`](increment-3_FabConFootball.refactorlog) | `FabConFootball.refactorlog` | records the `ShirtNumber → SquadNumber` column rename |
| [`increment-3B_FabConFootball.sqlproj`](increment-3B_FabConFootball.sqlproj) | `FabConFootball.sqlproj` | adds the `<RefactorLog Include="…" />` item |

SDK-style projects (`Microsoft.Build.Sql`) do **not** pick a `.refactorlog` up by filename — it
needs an explicit `<RefactorLog Include="FabConFootball.refactorlog" />` item, which is why
Option B also swaps in a wired project file. With it, the DeployReport is empty (`<Alerts />`)
and the publish runs under the shipped profile **unchanged** (`BlockOnPossibleDataLoss=True`).

## The gate (either option)

Ship the destructive deploy behind a **GitHub Environment required-reviewer approval** so a
human reads the DeployReport diff and approves — the *same* automated publish, just gated:

```yaml
# in the deploy job
jobs:
  publish:
    environment: test        # protection rule: required reviewers
    # …unchanged publish steps…
```

Nothing is clicked *in the database* — the approval is the only manual step, and it's still
"as code." Azure DevOps equivalent: an Environment **approval check**.

> **Plan note.** GitHub **required-reviewer** (and wait-timer) environment protection rules need
> a **Team or Enterprise** plan on **private** repos (they're free on public repos). On a plan
> that doesn't support them, the API/UI rejects the rule — this is the production-grade pattern;
> enable it where your plan allows. Also note: adding `environment:` to a job changes its OIDC
> subject to `repo:<org>/<repo>:environment:<name>`, so the deploy principal needs a matching
> **federated credential** for that subject (alongside the existing `ref:refs/heads/main` one).

**Lesson:** destructive changes ship as code too — with a data-preserving migration (A) or a
rename refactor (B), **and** a human gate. Never a blind auto-apply.
