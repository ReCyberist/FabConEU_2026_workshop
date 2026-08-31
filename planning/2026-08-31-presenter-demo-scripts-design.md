# Design — presenter demo scripts (`demo/`)

**Date:** 2026-08-31 · **Owner:** R · **Task:** [#32](tasks.md) · **Follows:** [#31](tasks.md)

## The problem

After [#31](tasks.md) the attendee site is clean: each section is an overview page plus one
`demo.md` holding the numbered steps. But `demo.md` is written **for attendees**. It cannot carry
the things a presenter needs and an attendee must not see:

- how long a step takes, so we know whether we are behind;
- what to *say* while a command runs;
- what the failure looks like and how to recover on stage;
- which parts of the repository the demo dirties, and how to put them back.

Presenting from the attendee page also means presenting from a browser, scrolling past
`!!! note` boxes aimed at someone else, and copy-pasting out of rendered HTML.

There is a second, sharper problem. Running a demo **changes tracked files**, and twice now a
demo's working state has been committed to `main`:

- `infra/azure-sql/terraform/demo/variables.tf` — `database_auto_pause_delay` was left at `75`
  in commit `33cf375`. The wrap-up demo's whole beat is "change 60 to 75", so as it stands
  `terraform plan` reports `0 to change` and the demo dies on stage.
- `database/sql-projects/` — the ship-changes demo overwrites `Tables/Player.sql`,
  `Scripts/PostDeployment/Seed.sql` and `FabConFootball.sqlproj`, and creates four more files.
  The attendee page has no reset step, so the tree is left dirty every single run.

## What we are building

One PowerShell script per section, at `demo/`, numbered in run order. Each is the **presenter
twin** of exactly one attendee demo page: same commands, same order, plus timings, narration,
failure recovery and a reset.

```
demo/
  README.md              run order, the guard rail, the sync rule
  01-source-control.ps1  <-> docs/foundations/demo.md   Morning 1   (09:00-10:30)
  02-infrastructure.ps1  <-> docs/infra/demo.md         Morning 2   (11:00-12:15)
  03-database.ps1        <-> docs/database/demo.md      Morning 3 + Afternoon 1
  04-cicd.ps1            <-> docs/cicd/demo.md          Afternoon 2 (15:45-17:00)
  05-wrap-up.ps1         <-> docs/wrap-up/demo.md       Afternoon 2 (15:45-17:00)
```

Scripts **reference code where it already lives** — `infra/**`, `database/sql-projects/`,
`database/demo/ship-changes/`. Nothing moves. This keeps CLAUDE.md §3's rule that code lives in
the folder that owns it, and it means Jess's increment files stay exactly where every existing
link expects them.

### Not in scope

- Assigning demos to a presenter. Who drives is fluid and may change mid-day.
- Moving or restructuring any existing code.
- Rewriting the attendee demo pages beyond the bug fixes listed below.

## The guard rail

A demo script that runs top to bottom is a liability. `break` at the top level of a PowerShell
script terminates it, so **F5 does nothing** — but F8 (Run Selection) sends only the highlighted
text, never the `break`, so running a block at a time works normally.

Every script opens with it, and says why in the register of the room:

```powershell
#region 00 · Guard rail -- do not remove, do not question
# You pressed F5, didn't you.
#
# This is a DEMO script, not a deployment...
break
#endregion
```

## Comment scheme

Every block is a foldable `#region` with a fixed header, so nothing has to be hunted for
mid-sentence:

| Field | Holds |
|---|---|
| `WHAT` | What the command actually does. The technical truth, for us. |
| `SAY` | The line that goes with it. A prompt, not a script — say it in your own words. |
| `EXPECT` | The output that means it worked. If you do not see this, stop. |
| `IF DEAD` | The known failure and the recovery, so nobody debugs live. |
| `PAGE` | The matching step on the attendee page. Also the anchor CI checks. |

Region titles carry a duration (`[~40s]`) so we can tell at a glance whether we are behind.

Humour is welcome in `WHAT` and `SAY` and in the guard rail. It is **not** welcome in `EXPECT` or
`IF DEAD` — those two are read under pressure, and a joke in a recovery instruction is a bug.
Attendees may well see these scripts; nothing in them should embarrass us or mislead them.

## Reset regions

Each script ends with a `RESET` region that returns the repository to its committed state. This is
the fix for the drift described above, and it is the one thing the attendee pages do not need and
must not grow.

`03-database.ps1` has the most to undo:

- restore tracked: `Tables/Player.sql`, `Scripts/PostDeployment/Seed.sql`, `FabConFootball.sqlproj`
- delete created: `Views/vw_SquadAges.sql`, `Views/vw_TeamRosterSizes.sql`,
  `Scripts/PreDeployment/Migrate-ShirtNumber.sql`, `FabConFootball.refactorlog`,
  `deploy-report*.xml`

Reset regions are explicit about what they touch. They never run `git clean` across the whole
repository — that is how somebody loses an afternoon of unrelated work.

## Jess's comments

Every comment Jess has written in `.tf`, `.sql`, `.sqlproj` and `.md` files stays. Presenter
scripts **add** context; they never edit hers. The single exception is a value that is technically
wrong (bug 5 below) — the value changes, the comment above it does not.

## Keeping the two halves in sync

**The rule** (recorded in CLAUDE.md §7a): a change to a demo touches the presenter script **and**
the attendee page, or it is not finished.

**The check** — a new `Demo scripts` job in `ci.yml`, path-gated on `demo/**`, `docs/**`,
`infra/**`, `database/**`:

1. **Parse** — every `demo/*.ps1` parses cleanly (`[Parser]::ParseFile`). Catches a broken script
   before 09:00 rather than at 09:01.
2. **Pairing** — every script names an existing `ATTENDEE PAGE`, and every `docs/**/demo.md` is
   claimed by exactly one script. Adding a demo page without its script fails the build.
3. **Paths** — every repository path referenced by either half exists on disk.

Check 3 is the one that matters: it is what would have caught all five bugs below. It lives in
`.github/scripts/check-demo-paths.py`, with an explicit ignore list where every entry carries a
reason (`notes/fabcon.md - created by demo 01, step 3`). Paths the demo *creates* are expected not
to exist; anything else is drift.

## Bugs fixed

Found while writing #31, deferred to here so that PR stayed scoped.

| # | Where | Wrong | Right |
|---|---|---|---|
| 1 | `docs/infra/demo.md` ×4 | `cd infra/azure-sql/terraform` | `.../terraform/demo` |
| 2 | `docs/infra/demo.md` | `cd ../../fabric-sql/terraform` | `../../../fabric-sql/terraform` — with bug 1 fixed, the old hop lands in `infra/azure-sql/fabric-sql/terraform` |
| 3 | `docs/wrap-up/demo.md` ×3 | `...\terraform\variables.tf` | `...\terraform\demo\variables.tf` |
| 4 | `docs/cicd/demo.md` | `infra/azure-sql/shared-endpoint` | `infra/azure-sql/terraform/shared-endpoint` |
| 5 | `infra/azure-sql/terraform/demo/variables.tf` | `database_auto_pause_delay` default `75` | `60` — committed demo drift |
| 6 | `.gitignore` | `deploy-report*.xml` not ignored | ignored — the demo writes it into a tracked folder |

Bugs 1–4 are in pages Jess wrote. They are corrected because they are factually wrong; no prose
or comment is otherwise touched.

## Verification

- `.github/scripts/check-demo-paths.py` passes locally and in CI.
- Every `demo/*.ps1` parses under `pwsh`.
- `mkdocs build --strict` stays green for both `mkdocs.yml` and `mkdocs.local.yml`.
- Bug 5 is checked against `terraform` — the demo's `60 -> 75` edit must produce
  `1 to change`.

Live runs of the demos themselves remain gated on the dry run (task #13).
