# Agenda — Full Day (DRAFT)

**Workshop:** Azure SQL or Fabric SQL: Deploying Infrastructure and Databases as Code
**Presenters:** Jess Pomfret & Rob Sewell · **Event:** FabCon Europe 2026, Barcelona

> Status: **DRAFT** — five teaching sections (~5.75 hours) around the venue's fixed
> break/lunch times, 09:00–17:00. **Demos are now mapped per section below** (see each
> `## Morning/Afternoon` block); slides track them (task #25). Every section: short concept
> → live demo (Terraform + GitHub Actions + SQL projects) → optional follow-along. Azure SQL
> and Fabric SQL are shown side by side throughout. Log timing surprises in
> [`../notes/LEARNINGS.md`](../notes/LEARNINGS.md).

> **No workshop-provided lab.** Per [D6](../notes/decisions.md) it's **bring-your-own**:
> attendees follow along on their own Azure / Fabric kit if they have it, or just watch.

| Time | Session | Content |
|------|---------|---------|
| **09:00 – 10:30** | **Morning 1** · 90 min | Intro · the hardest part of IT · source control foundations |
| 10:30 – 11:00 | ☕ Break | |
| **11:00 – 12:15** | **Morning 2** · 75 min | Infrastructure as code — Azure SQL + Fabric SQL, side by side |
| **12:15 – 12:45** | **Morning 3** · 30 min | Database as code — database → DACPAC |
| 12:45 – 14:00 | 🍽 Lunch | |
| **14:00 – 15:15** | **Afternoon 1** · 75 min | SQL projects — making changes, breaking things, testing |
| 15:15 – 15:45 | ☕ Break | |
| **15:45 – 17:00** | **Afternoon 2** · 75 min | Pulling it together · Q&A |
| 17:00 | End | |

**Next:** feed real durations into the full dry run (task #13 in
[`../planning/tasks.md`](../planning/tasks.md)) — the demo map below is untimed and the
afternoon in particular is demo-heavy.

## Morning 1 — the hardest part of IT (hook)

> First up, let's talk about the hardest part of IT.
>
> We can show you the tech part — hell, most of you will probably Copilot it anyway. But
> here's the bits Copilot doesn't know: it's the blood balloons with egos… and feelings.
> This is what we have learnt.

**Why it opens the day:** the tooling is the easy half. It goes **before** the first line of
Terraform deliberately — everything after it (branching, PR review, approval gates, who's
allowed to drop a column) is a people problem wearing a YAML costume, and the room should hear
that framing first. It hands straight off into the **source control** part of the same section.

**To build (task #24):** the actual war stories, and the handoff line into source control.

**Demos in this section (source-control half):**
- Live git on **this repo** — a branch + a pull request, so the room sees *change = PR*
  before any infra shows up. This is the "everything is code, nothing is clicked" opening.
- A first look at **plan-on-PR**: [`azure-sql-plan.yml`](../.github/workflows/azure-sql-plan.yml)
  runs `terraform fmt`/`validate`/`plan` (read-only) on a PR — plant the idea here, pay it
  off in Morning 2. No apply yet.
- **Follow-along:** attendees fork/branch on their own kit if they want; watchers just watch.

## Morning 2 — Infrastructure as code (Azure SQL + Fabric SQL, side by side)

*11:00 – 12:15 · 75 min · the content-focus IaC block.* Concept (~10) → live apply (~50) → recap.

**Demos (Terraform + GitHub Actions lead):**
- **Azure SQL:** walk [`infra/azure-sql/terraform`](../infra/azure-sql/terraform) (RG →
  server → serverless DB → firewall, CAF naming, **passwordless/Entra-only**), then dispatch
  [`azure-sql-apply.yml`](../.github/workflows/azure-sql-apply.yml) live.
- **Fabric SQL, side by side:** walk [`infra/fabric-sql/terraform`](../infra/fabric-sql/terraform)
  (**capacity → workspace → SQL DB**, two providers), then
  [`fabric-sql-apply.yml`](../.github/workflows/fabric-sql-apply.yml). Contrast the shapes:
  Azure SQL is *server → DB*, Fabric is *capacity → workspace → DB*.
- **Timing (revised):** the apply **runs live inside this block** — the old plan hid it behind
  the 10:30 break, but IaC now sits entirely *after* the break, so there's nowhere to hide it.
  Kick each apply off early and narrate the module config while it provisions (~4–5 min for
  Azure SQL; Fabric is faster here because the **capacity is pre-provisioned** —
  `use_existing_capacity`, so only workspace + DB apply). Have a completed run open as a
  fallback if a live apply stalls. **This is the section most at risk of overrun — flag for #13.**
- **The "one number → a reviewed plan" beat (change = plan).** On a branch, bump
  `attendee_count` in [`infra/azure-sql/shared-endpoint`](../infra/azure-sql/shared-endpoint)
  from 10 to 15, commit, push — the PR's **`terraform plan (shared endpoint)`** job (a second
  Terraform flow in [`azure-sql-plan.yml`](../.github/workflows/azure-sql-plan.yml)) prints
  *"+5 databases, +5 logins, +5 users — 15 to add"*. The most visceral IaC moment of the day:
  a one-line change produces a precise, reviewable plan of exactly what it will do. Ties back
  to the plan-on-PR idea planted in Morning 1. The PR plan is read-only; **close the loop** by
  running [`azure-sql-apply.yml`](../.github/workflows/azure-sql-apply.yml) with `target:
  attendee` (the `attendee-endpoint` job — or a local apply against the same remote state) so
  the extra databases actually appear — destroyed again nightly. Have the endpoint pre-deployed
  (10) so the live bump shows a clean "+5", not a from-scratch build.
- **Backup/stretch:** the Bicep equivalents ([`azure-sql/bicep`](../infra/azure-sql/bicep)),
  and the teaching point that **Fabric can't be fully done in Bicep** (workspace + DB have no
  ARM type — capacity only); ADO pipeline equivalents.

## Morning 3 — Database as code (database → DACPAC)

*12:15 – 12:45 · 30 min · short, tight, right before lunch.* Concept → build → CI.

**Demos (SQL projects lead):**
- Build the football **SQL project** — [`FabConFootball.sqlproj`](../database/sql-projects/) →
  `dotnet build` → a **DACPAC**. Show the schema is *just code in git* (tables/views/procs +
  a set-based post-deploy seed).
- **CI checks our code:** [`ci.yml`](../.github/workflows/ci.yml)'s `database` job runs the
  build **plus T-SQL static code analysis** (`-warnaserror`, **zero findings**) — the
  Cláudio-Silva-front-row bar, enforced on every push.
- Point at the ER diagram page ([`docs/database/sample-database.md`](../docs/database/sample-database.md)).
- **No live deploy here** — this section produces the artifact; deploying it is the afternoon.

## Afternoon 1 — SQL projects: making changes, breaking things, testing

*14:00 – 15:15 · 75 min · the "ship changes as code" story starts.* Increments 1–2 of the
[ship-changes design](../planning/ship-changes-increments.md).

**Demos:**
- **Increment 1 — additive, hands-off.** A PR adds `vw_SquadAges`. The pipeline's
  **`sqlpackage /Action:DeployReport`** (the DB's `terraform plan`) shows *"1 view to create,
  0 data-loss operations"*; merge → auto-publish. Safe changes automate end to end.
- **Increment 2 — the trap (the punchline).** A PR **drops the populated `Player.ShirtNumber`**,
  bundled with an innocent view add so it's easy to miss in review. Show it **two ways**:
  the YOLO `BlockOnPossibleDataLoss=false` publish that **silently loses the data**, then the
  guardrail we already ship (`BlockOnPossibleDataLoss=True`) that **fails loudly** — and the
  DeployReport that flagged it *before* merge. Leave time for the silent-loss moment to land.
- **Both platforms** — identical flow, per-target publish profile only.
- **Follow-along:** Increment 1 is the safe one to invite attendees to try on their own kit;
  Increment 2 is presenter-led (easier to *watch* the trap than to hit it).

## Afternoon 2 — Pulling it together · Q&A

*15:45 – 17:00 · 75 min · close the loop, then questions.*

**Demos:**
- **Increment 3 — ship the destructive change *safely*.** Retire `ShirtNumber` **without data
  loss**: a **pre-deploy migration** (or a rename via SqlPackage's refactorlog) that moves the
  data first, plus a **human approval gate** (GitHub Environment required reviewer — documented
  pattern; see the [increment-3 write-up](../database/demo/ship-changes/increment-3_safe-retire.md)).
- **The whole pipeline, both platforms:** apply → **deploy-report** → publish → **smoke test**,
  green end to end on Azure SQL *and* Fabric SQL — the payoff of the day in one run.
- **Teardown & drift:** the `*-destroy.yml` workflows (nothing bills overnight), plus the
  migrations/drift/teardown wrap-up ([`docs/wrap-up/migrations-drift-teardown.md`](../docs/wrap-up/migrations-drift-teardown.md)).
- **Q&A** — leave a genuine buffer; this is the flex if the afternoon ran long.

## Backup / stretch material (if ahead of schedule)
- Bicep equivalents of each Terraform demo.
- Azure DevOps pipeline equivalents of the GitHub Actions demos.
- Flyway and dbatools/dbops migration demos against the same schema.

## Timing discipline
- Breaks and lunch are **fixed by the venue** (morning 10:30–11:00, lunch 12:45–14:00,
  afternoon 15:15–15:45) — the five teaching sections flex, the anchors don't.
- Each follow-along segment has a hard "we move on" time; publish the checkpoint state so
  anyone following along on their own kit can catch up (and anyone just watching stays in sync).
- Note actual vs planned durations during dry runs and log them (#13).
