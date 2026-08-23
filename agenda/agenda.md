# Agenda — Full Day (DRAFT)

**Workshop:** Azure SQL or Fabric SQL: Deploying Infrastructure and Databases as Code
**Presenters:** Jess Pomfret & Rob Sewell · **Event:** FabCon Europe 2026, Barcelona

> Status: **DRAFT** — five teaching sections (~5.75 hours) around the venue's fixed
> break/lunch times, 09:00–17:00. Slides and demos for each section are **still to be mapped**.
> Every section: short concept → live demo (Terraform + GitHub Actions + SQL projects) →
> optional follow-along. Azure SQL and Fabric SQL are shown side by side throughout. Log timing
> surprises in [`../notes/LEARNINGS.md`](../notes/LEARNINGS.md).

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

**Next:** map the slides + demos into each section (then feed real durations into the full dry run — task #13 in [`../planning/tasks.md`](../planning/tasks.md)).

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
