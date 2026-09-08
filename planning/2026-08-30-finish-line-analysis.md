# Finish-line analysis — 2026-08-30

State of the repo four weeks out, and what still has to happen before the doors open.
Written from a full read of the repo on 2026-08-30 (`main`, clean, last commit `2905d26`).

**Event:** FabCon Europe 2026, Barcelona, **28 September – 1 October 2026**. Workshops run on
the first day, so assume **Monday 28 September** — **~4 weeks** from this write-up.

> Register: planning file, so this is terse and honest. Nothing here is attendee-facing.

---

## 1 · Where we actually are

The build is further along than the task table suggests. Both platforms are proven end to end:
Azure SQL apply → DACPAC publish → smoke test (2026-07-29) and the Fabric equivalent
cross-tenant (2026-08-20). Eleven workflows, CI validating four areas, a deck generated from
code, and 19 attendee pages that are mostly written rather than skeletons.

| Area | State |
|---|---|
| Infra as code | **Done.** Terraform (Azure SQL demo + shared endpoint, Fabric SQL) and Bicep mirrors, all live-verified except the shared endpoint. |
| Database as code | **Done.** `FabConFootball.sqlproj` builds, publishes to both platforms, T-SQL analysis at zero findings. |
| CI/CD | **Done.** `ci.yml` (4 path-gated jobs), plan-on-PR with sticky masked comments, apply/destroy per platform, nightly teardown, ADO mirrors. |
| Attendee site | **Mostly written.** 19 pages; only `reference/other-tooling.md` is still a skeleton. Held in teaser mode. |
| Deck | **Drafted as code.** 68 slides with real speaker notes — but on the **wrong timetable** (see §2.2). |
| The day itself | **Untested.** No dry run, no timing pass, and the deck, the agenda and the docs tell three slightly different stories about the afternoon. |

The gap is no longer "build the thing". It is **rehearsal, reconciliation, and the handful of
live-fire runs that have never happened.**

## 2 · Blockers — must land before the day (P0)

### 2.1 The dry run (#13) is the single biggest open item
Nothing else on this list will be believed until a full run-through has happened with a clock.
Morning 2 is 75 minutes and currently carries two live applies, a side-by-side comparison and
the attendee-count bump — the deck alone budgets 45 minutes for the Fabric half. Something is
going to overrun; better to find out in a rehearsal.

**Do:** one full dry run, timed per beat, feeding real durations into `agenda/agenda.md` and
the budgets in [`../agenda/speaker-guide.md`](../agenda/speaker-guide.md). Rehearse the
morning-of checklist the same day.

### 2.2 The deck runs on a timetable that no longer exists
Every `SECTION` strapline in `slides/content.py` uses the **old** schedule: break at 11:00 for
fifteen minutes, lunch 12:45–13:45, afternoon blocks at 13:45 / 14:30 / 15:30 / 16:15 / 16:45.
The venue anchors in `agenda/agenda.md` are break **10:30–11:00** (30 min), lunch
**12:45–14:00**, afternoon break **15:15–15:45**.

Worse than the numbers: the deck still splits the IaC block across the break — Azure SQL at
10:30, an "Off it goes — see you after coffee" slide, then Fabric at 11:30. The agenda
explicitly reversed that decision ("IaC now sits entirely *after* the break, so there's
nowhere to hide the apply"). The slide that tells the room to stand up while Terraform runs
is now teaching the opposite of the plan.

**Do:** re-cut the straplines and the section comments in `content.py` to the venue anchors;
rewrite or drop the "see you after coffee" slide; move the "So what did we just build?"
beat to sit inside Morning 2 rather than after a break.

### 2.3 Two follow-along commands are broken on the page
Both are steps an attendee (or a presenter) types in front of the room.

1. `docs/infra/demo.md:37` — `cd infra/azure-sql/terraform`. That folder holds no `.tf` files
   since the 2026-08-29 split into `terraform/{demo,shared-endpoint}`; `terraform init` fails
   there. The confirming line ("The path ends with `infra\azure-sql\terraform`") is wrong too.
2. `docs/wrap-up/migrations-drift-teardown.md` — the final demo of the day says change
   `database_auto_pause_delay` **from 60 to 75**. The default in
   `infra/azure-sql/terraform/demo/variables.tf` is **already 75**, so the plan comes back
   `0 to change` and the closing demo produces nothing. The same page also points at
   `infra\azure-sql\terraform\variables.tf` three times — stale path, same refactor.

**Do:** fix the paths, and pick a value the demo can actually move (change *to* 90, or reset
the committed default to 60 and leave the page alone). This is exactly what task #30's
placeholder sweep is for — widen it to a "does this command still work" sweep.

### 2.4 The shared attendee endpoint (#19) has never been applied
It is drafted, wired into plan/apply/destroy, and **untested** — no live apply has ever run.
It carries two loads on the day: it is the fallback for every attendee without a target SQL,
*and* it is the "bump `attendee_count` → +5 databases" beat, described in the agenda as the
most visceral IaC moment of the day. Unknowns still open in the module README: whether the
`betr-io/mssql` provider creates the logins/users cleanly, the pool SKU, and cold-apply
firewall ordering.

**Do:** first live `apply` + `destroy`, then seed the initial 10 into remote state so the
demo bump shows a clean `+5` rather than a from-scratch build.

### 2.5 Nightly Fabric teardown (#26) has open live-verify questions
Three, all logged: whether the CI SP really holds `Microsoft.Fabric/capacities/resume|suspend/action`,
whether `properties.state` is the right poll field, and whether destroy-while-resumed is clean.
If the first is wrong, the morning-of procedure fails at step one on the day.

**Do:** watch one real nightly run end to end and tick all three off.

## 3 · Materially affects the day (P1)

- **Code bundles (#12) don't exist.** "Prose = pages, code = downloads" is stated in
  `CLAUDE.md`, the README and the decisions log, and `docs/wrap-up/resources.md` carries a
  "coming soon" box. Either build the zip-per-module job or cut the promise and link the repo.
  Cutting it is a legitimate answer — but not on the morning.
- **No drift demo (#29).** The deck's "So what did we just build?" slide promises the room a
  deliberate drift moment ("change something in the portal and re-plan"), and the speaker note
  calls it "the moment 'as code' stops being abstract". No drift demo exists. It's ninety
  seconds of work to script and it's currently sitting in the deck as an unbacked promise.
- **The site reveal is a live PR nobody has rehearsed.** Dropping `exclude_docs` and
  un-commenting the nav in `mkdocs.yml` is one PR — do it early on the day at the latest, and
  test the whole thing locally with `mkdocs.local.yml` first. Also decide *when* the reveal
  happens: attendees need the prerequisites page well before the day, and that page is already
  public, so the reveal itself can wait until the morning.
- **Flyway and dbatools/dbops are five-line READMEs.** The decisions log says every variant
  ships "as working code so nothing is hand-wavy", `docs/reference/other-tooling.md` links to
  them as reference implementations, and they are listed as stretch material in the agenda. In
  front of a moderator like Cláudio Silva, a link to an empty folder is a worse look than not
  offering it. Either build a minimal working migration set against the same schema, or reword
  both the page and the decision to "pointers, not implementations".
- **`ordering.md` is stale, and it's the one with external lead time.** Nearly everything is
  unticked, including items that are plainly done (sample DB, slides) and items nobody can
  chase in the last week: **room A/V, WiFi bandwidth, confirmed timings with the organisers,
  attendee count/cap**. Four weeks out is exactly when those need chasing. Reconcile the file
  against reality, then chase the three organiser-dependent lines this week.
- **The session clock only exists for Morning 1.** `includes/clock-morning-1.md` is included by
  two pages; there are no includes for the other four slots. Finish the set or drop the
  feature — a timing strip that appears on two pages out of nineteen reads as unfinished.
- **`reference/other-tooling.md` is still a skeleton** (84 words, `<!-- DRAFT -->` banner) and
  is in the reveal nav. Finish it or leave it excluded.

## 4 · Fine to carry (P2)

- Least-privilege Fabric capacity refactor (#27) — parked deliberately, no impact on the day.
- ADO Fabric mirror — the ADO pipelines are reference material and Fabric is the newer half.
- Markdown link/lint CI job (#8's nice-to-have).
- The approval gate stays **documented, not wired** (blocked by the repo plan). That's a
  defensible teaching position: say out loud that it's a plan limitation, not a design one.

## 5 · Risk register for the day

| Risk | Likelihood | Mitigation that already exists |
|---|---|---|
| Morning 2 overruns | **High** | Not yet mitigated — needs the dry run and a rehearsed cut list. |
| Venue WiFi can't carry live provisioning | Medium | Pre-run workflow runs kept open as fallback; not yet staged. |
| Presenter IP secrets stale in Barcelona | Medium | Covered in the morning-of checklist §1 — must run *before* apply. |
| Fabric capacity still paused / cross-tenant login missed | Medium | Morning-of checklist §1; the classic trap is forgetting Tenant B. |
| Shared endpoint fails on first ever apply — in the room | Medium | **Unmitigated until #19 runs live once.** |
| A live apply stalls mid-demo | Medium | Agenda says have a completed run open as fallback — stage it explicitly. |

## 6 · Suggested four-week shape

- **Week of 31 Aug** — §2.3 command fixes; first live apply/destroy of the shared endpoint
  (#19); watch one nightly Fabric teardown (#26); chase the three organiser lines in
  `ordering.md`.
- **Week of 7 Sep** — deck re-cut to the venue anchors (#25); decide bundles-or-not (#12);
  drift demo (#29) or trim the slide; finish or drop the session-clock set.
- **Week of 14 Sep** — **full dry run with a clock** (#13), morning-of checklist rehearsed the
  same morning; feed real timings into the agenda and the speaker guide; placeholder + broken
  command sweep (#30).
- **Week of 21 Sep** — second, shorter run of anything the dry run moved; freeze the deck and
  the docs; prepare (don't merge) the reveal PR; travel.

## 7 · Where the run sheet lives

Delivery mechanics — who leads what, per-beat minute budgets, demo cues, and the fallback
ladder — are in [`../agenda/speaker-guide.md`](../agenda/speaker-guide.md). This file is the
build; that file is the performance.
