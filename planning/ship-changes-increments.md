# "Ship database changes as code" — increment design (task #15)

**Feeds:** the **15:30** agenda module — *CI/CD part 3: ship database changes automatically*
(45 min: ~5 concept → ~40 live demo with optional follow-along). Builds on the
[blind-deploy-vs-schema-compare demo idea](../notes/Ideas.md).

**The one-line thesis of the module:** a database change is a **pull request**, and the
pipeline tells you *exactly what it will do to your data before it does it* — the database
analog of `terraform plan`. Additive changes flow automatically; destructive ones stop for a
human.

We ship the same DACPAC to **Azure SQL and Fabric SQL** — the flow below is identical for
both (per-target publish profile only). Two environments: **Dev** and **Test**; **Test holds
seeded data** so data loss is real and visible.

---

## The narrative arc — three increments, each a PR

Each increment is one branch/PR against the football schema, prepared as a **demo checkpoint**
(presenter can `git checkout` each state; attendees can follow along on their own kit if they
have it — there's no provided lab).

### Increment 1 — Additive change (the safe, automatable path)
**Change:** add a read-only view `football.vw_SquadAges` (players + age from `DateOfBirth`).
Purely additive — no existing object touched.

**Pipeline:** PR → CI builds the DACPAC and runs **`sqlpackage /Action:DeployReport`** against
Test → the report shows *"1 view to create, **0 data-loss operations**"* (surfaced as a PR
artifact/comment). Merge → auto-publish Dev → Test. **Green, hands-off.**

**Lesson:** schema change = a PR; the pipeline produces a **deploy report** (the DB's `plan`)
so you see the change before it lands; additive changes are safe to automate end-to-end.

### Increment 2 — Destructive change (the trap / climax)
**Change:** a PR that **drops `Player.ShirtNumber`** — framed as an innocent *"we don't track
squad numbers here anymore"* cleanup, **bundled with an unrelated view add** so the drop is
easy to miss in review (exactly how it happens in real life). `ShirtNumber` **is populated by
the seed**, so in Test it holds real data.

Show it two ways, back to back:

- **2a — the YOLO trap.** A naive publish with `/p:BlockOnPossibleDataLoss=false` pushes Dev's
  schema straight to Test. The column drop goes through and **the data is silently gone.**
  Prove it with a `SELECT ShirtNumber` before (rows) and after (column doesn't exist). *"This
  is why you can't just publish the DACPAC and hope."*
- **2b — the guardrail we already ship.** Our real profiles set
  **`BlockOnPossibleDataLoss=True`** ([`AzureSql`](../database/sql-projects/PublishProfiles/AzureSql.publish.xml) /
  [`FabricSql`](../database/sql-projects/PublishProfiles/FabricSql.publish.xml)), so the *same*
  deploy **fails loudly** — *"possible data loss"* — and Test is never touched. And the
  **DeployReport on the PR already flagged the drop** as a data-loss operation *before* merge.

**Lesson:** the block-on-data-loss guard + the pre-deploy report turn a silent disaster into a
**visible, reviewable decision**.

### Increment 3 — Ship the destructive change *safely* (the right way)
**Change:** actually retire `ShirtNumber` **without losing data**, two techniques shown:

1. **Preserve first.** A **pre-deploy migration** copies the data to its new home (e.g. a new
   `Player.SquadNumber` on a related table, or an archive) *before* the drop — so the DACPAC's
   drop is safe because the data already moved. (Bonus variant: model it as a **rename** so
   SqlPackage uses its **refactorlog** to `sp_rename` instead of drop+recreate — zero data
   loss, no migration script.)
2. **Gate it.** The destructive deploy runs only after a **GitHub Environment required-reviewer
   approval** on the `test` (and `prod`) environment — a human reads the DeployReport diff and
   approves. Same automated publish, deliberately gated. Nothing is clicked *in the database*.

**Lesson:** destructive changes ship as code too — with a data-preserving migration **and** a
human gate, never a blind auto-apply.

---

## Answers to the open questions from [`Ideas.md`](../notes/Ideas.md)

| Question | Decision |
|----------|----------|
| **What drives the compare?** | **`sqlpackage /Action:DeployReport`** in the PR/plan job — an XML/summary of exactly what a publish *would* do, including `<Alert Name="DataIssue">` data-loss operations, **without applying**. It's the DB's `terraform plan`. (Interactive **SSDT/ADS Schema Compare** is the desktop equivalent we mention; DeployReport is the CI one.) Works against a **Fabric SQL** item identically — Entra token + `…database.fabric.microsoft.com` endpoint, with the `AllowIncompatiblePlatform`/`ExcludeObjectTypes` flags already in the Fabric profile. |
| **"Apply manually" = ?** | A **GitHub Environment protection rule** (required reviewer) on the deploy job — the *same* automated publish, held for approval. Deliberate, but still "as code / nothing clicked in the DB." Azure DevOps equivalent: an **Environment approval check**. |
| **Seed a populated column?** | ✅ Already done — the [seed](../database/sql-projects/Scripts/PostDeployment/Seed.sql) populates `Player.ShirtNumber` (and `DateOfBirth`). The data loss is genuine and demonstrable with a simple `SELECT`. |

---

## What we need to build to make this run (follow-on work → task #21)

1. **A `deploy-report` step** on the build/PR pipeline: `sqlpackage /Action:DeployReport`
   against the Test DB, upload the report as an artifact and/or post the data-loss alerts as a
   PR comment. (Extends `azure-sql-plan.yml` / a DB-plan job — the DB analog of `terraform
   plan` on PR.)
2. **The three increment branches** as reproducible demo checkpoints (+ a short follow-along
   script with hard "we move on" checkpoints per the agenda's timing discipline).
3. **A two-stage Dev → Test promotion** with a **Test environment approval gate** (GitHub
   Environment + required reviewer). Reuses the existing apply/publish workflows.
4. **A throwaway "naive" publish** for demo 2a only (`BlockOnPossibleDataLoss=false`) — clearly
   labelled as the anti-pattern; our shipped profiles stay `True`.
5. Run it on **both** Azure SQL and Fabric SQL (Fabric gated on the capacity — issue #20).

## Timing / delivery notes
- Demo order = the three increments; **Increment 2 is the punchline** — leave time to let the
  silent-data-loss moment land before showing the guardrail.
- Follow-along (optional, bring-your-own — **no provided lab**): Increment 1 is the one to
  invite attendees to try on their own kit (safe, confidence-building); Increments 2–3 are
  presenter-led with attendees watching/following, since the trap is easier to *watch* than to hit.
- Log actual vs planned timings in [`../notes/LEARNINGS.md`](../notes/LEARNINGS.md) on the dry run.
