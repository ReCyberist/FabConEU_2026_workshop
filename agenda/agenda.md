# Agenda — Full Day (DRAFT)

**Workshop:** Azure SQL or Fabric SQL: Deploying Infrastructure and Databases as Code
**Presenters:** Jess Pomfret & Rob Sewell · **Event:** FabCon Europe 2026, Barcelona

> Status: **DRAFT** — refine timings against real demo runs. Log every timing surprise
> in [`../notes/LEARNINGS.md`](../notes/LEARNINGS.md).

Assumes ~6.5 hours of teaching within a 09:00–17:00 day. Every module = short concept →
live demo (Terraform + GitHub Actions + SQL projects) → optional follow-along on your own kit.
Azure SQL and Fabric SQL are shown side by side throughout.

> **No workshop-provided lab.** Per [D6](../notes/decisions.md) it's **bring-your-own**:
> attendees follow along on their own Azure / Fabric kit if they have it, or just watch. The
> "follow-along" segments below are **optional and self-paced** — nothing is provisioned for
> attendees, and there are no facilitated lab exercises.

| Time | Module | Format | Notes |
|------|--------|--------|-------|
| 09:00 | Welcome & why infrastructure-as-code for data | Talk | Set the "no clicking required" promise. Story hook. |
| 09:20 | Environment check & prerequisites | Follow-along | Quick "does your kit work" sweep. **Deliberately short** — it's BYO, so stragglers get helped during breaks rather than holding the room. |
| 09:30 | **The hardest part of IT** | Talk + discussion | 🆕 **Front-of-day, before any tech.** The people bit — egos, feelings, what we've learnt. Hook text below. |
| 10:00 | Source control foundations for databases | Concept + demo | Git, repo layout, secrets handling. Lands straight out of the 09:30 talk — branching, PRs and review are team agreements before they're commands. |
| 10:30 | Provisioning infra as code — Azure SQL (Terraform) pt 1 | Concept + demo | Module walkthrough → `terraform plan` → **kick off `apply` just before the break** so it provisions while everyone's away. Bicep shown as reference. |
| 11:00 | ☕ Break | — | 15 min (the `apply` runs through it) |
| 11:15 | Provisioning infra as code — Azure SQL pt 2 | Demo + follow-along | What got created, outputs, drift. Catch-up point for anyone following along. |
| 11:30 | Provisioning infra as code — Fabric SQL | Demo + follow-along | Side-by-side with Azure SQL; call out differences. |
| 12:15 | Database as code — SQL projects (`.sqlproj`/DACPAC) | Demo + follow-along | Build a DACPAC from the canonical sample schema. |
| 12:45 | 🍽 Lunch | — | 60 min |
| 13:45 | CI/CD part 1 — build & validate (GitHub Actions) | Demo + follow-along | Pipeline builds infra plan + DACPAC on PR. |
| 14:30 | CI/CD part 2 — deploy infra automatically | Demo + follow-along | Apply Terraform from the pipeline; environments/approvals. |
| 15:15 | ☕ Break | — | 15 min |
| 15:30 | CI/CD part 3 — ship database changes automatically | Demo + follow-along | Deploy DACPAC to Azure SQL & Fabric SQL from the pipeline. |
| 16:15 | Putting it together / migrations, drift & teardown | Demo + discussion | Migration-based options (Flyway, dbatools/dbops) as bonus; drift detection; clean teardown. |
| 16:45 | Wrap-up, resources, Q&A | Talk | Point to the site + downloads. Collect feedback → learnings. |
| 17:00 | End | — | |

## 09:30 — The hardest part of IT

> First up, let's talk about the hardest part of IT.
>
> We can show you the tech part — hell, most of you will probably Copilot it anyway. But
> here's the bits Copilot doesn't know: it's the blood balloons with egos… and feelings.
> This is what we have learnt.

**Why it's here and not buried:** the tooling is the easy half. It goes **before** the first
line of Terraform deliberately — everything after it (branching, PR review, approval gates,
who's allowed to drop a column) is a people problem wearing a YAML costume, and the room
should hear that framing first.

**To build (task #24):** the actual war stories, and the handoff line into the 10:00 source
control module.

## Backup / stretch material (if ahead of schedule)
- Bicep equivalents of each Terraform demo.
- Azure DevOps pipeline equivalents of the GitHub Actions demos.
- Flyway and dbatools/dbops migration demos against the same schema.

## Timing discipline
- Each follow-along segment has a hard "we move on" time; publish the checkpoint state so
  anyone following along on their own kit can catch up (and anyone just watching stays in sync).
- Note actual vs planned durations during dry runs and log them.

### Where the 30 minutes came from (2026-08-17)

The 09:30 module is new, so the morning was rebalanced to hold the **11:00 break, 12:45 lunch
and 17:00 end** anchors — **the afternoon is untouched**:

- **Environment check 25 → 10 min.** It's bring-your-own (D6); helping individuals is break work.
- **Azure SQL Terraform split across the break** (30 + 15 = the same 45 min) so the `apply`
  wait costs nothing.
- **SQL projects 45 → 30 min.** The only real squeeze. If the dry run (#13) says 30 isn't
  enough, take the 15 back from the 16:15 "putting it together" block and push migrations
  into the stretch list above.
