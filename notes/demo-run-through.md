# Demo run-through notes

Working notes from actually running the demos, in order, with a clock. Planning register —
terse and honest. Real durations graduate to [`../agenda/speaker-guide.md`](../agenda/speaker-guide.md)
once they have been measured twice; this is where the mess goes first.

**How to use it.** One section per demo, in run order. Record what *happened*, not what should
have. A step that worked needs one line. A step that did not needs the error text, because that is
the thing we will have forgotten by the dry run.

> Feeds task **#13** (the dry run). Anything here that changes a decision goes to
> [`decisions.md`](decisions.md); anything reusable goes to [`LEARNINGS.md`](LEARNINGS.md).

---

## Status

| Demo | Script | Attendee page | Last run through | Verdict |
|---|---|---|---|---|
| 01 · Source control | [`demo/01-source-control.ps1`](../demo/01-source-control.ps1) | [`foundations/demo.md`](../docs/foundations/demo.md) | — | not run |
| 01b · Merge conflict | [`demo/01b-merge-conflict.ps1`](../demo/01b-merge-conflict.ps1) | **none** — presenter-only | — | **written 2026-09-06, never rehearsed** |
| 02 · Infrastructure (Azure SQL) | [`demo/02-infrastructure.ps1`](../demo/02-infrastructure.ps1) | [`infra/demo.md`](../docs/infra/demo.md) | 2026-07-29 (apply only) | apply verified, walkthrough not |
| 02 · Infrastructure (Fabric SQL) | same | same | — | **never run live end to end** |
| 03 · Database, Part 1 | [`demo/03-database.ps1`](../demo/03-database.ps1) | [`database/demo.md`](../docs/database/demo.md) | build verified | not run as a demo |

---

## Morning

### 01 · Source control — regions 01–09, ~8 min

Slot is **10:00–10:25 (25 min)**. The script runs about eight minutes, so there is roughly
**fifteen minutes of slack** in this block. That is the room for the merge scenario Rob wants.

Watch for:

- [ ] Region 03 types `notes/fabcon.md` live. Time the typing — it is the only unscripted keystroke
      in the morning and it always takes longer in front of a room.
- [ ] Region 08 `gh pr create --fill --base main` — does it pick up a sensible title from the
      single commit, or does it prompt? Prompting on stage is the failure mode.
- [ ] Region 09 `gh pr view --web` — browser focus and zoom. Rehearse the window switch.
- [ ] Region 99 RESET actually leaves `git status` clean. Run it and check, every time.

### 01b · Merge conflict — presenter-only, ~9 min, two laptops

Runs straight after demo 01, in the same slot. **Written 2026-09-06 and never rehearsed** — this is
the one to put through a dry run first, because it is the only demo on the day that needs two people
to stay in step.

Watch for:

- [ ] Agree who is ROB and who is JESS *before* walking on. The script does not care which of you is
      which, only that one pushes first and the other hits the conflict.
- [ ] Region 01 — both on a clean `main`, both pulled. If the two clones are at different commits the
      conflict may not happen at all, which is a much worse demo than a conflict.
- [ ] Region 03 push succeeds before Jess runs region 05. This is the one hand-off with a real
      dependency; say "pushed" out loud.
- [ ] Region 06 — the moment. Let it land, count to two, say nothing.
- [ ] Region 08 `git merge --abort` runs **before** the resolution, not after.
- [ ] Region 99 RESET on **both** machines. It deletes the remote branch too.
- [ ] Time the two file edits (regions 02 and 04). They are typed live and always run long.

Open:

- **Say "nothing to type" out loud before you start.** There is no attendee page by design, and the
  demo slide in front of it says *sit back* — but half the room will still try unless a human says it.

### 02 · Infrastructure — Azure SQL, regions 01–10, ~12 min incl. 4m31s apply

Slot is **11:00–11:30**, entirely after the break. There is nowhere to hide the apply now.

Watch for:

- [ ] Kick the apply (region 09) off **early** and narrate the module over it. Two slides are
      written to be talked over: *Terraform in ninety seconds* and *State: the bit that bites in CI*.
- [ ] Does 4m31s hold on venue wifi? That number is from Jess's machine on a home connection.
- [ ] Region 06 `backend_local_override.tf` — confirm it is in place **before** `init`, or `init`
      prompts for a container name in front of the room. This is the failure the deck used to teach.
- [ ] Region 10 opens the portal. Clean browser profile, no other tabs, zoom up.

### 02 · Infrastructure — Fabric SQL, regions 12–19, ~10 min

Slot is **11:30–11:55**. First thing to compress if Azure SQL ran long.

Watch for:

- [ ] `$env:TF_VAR_fabric_subscription_id` set before `plan`, or it prompts.
- [ ] Cross-tenant: `az login` to **Tenant B**. The classic miss.
- [ ] Capacity resumed, not paused, before you start.

Open:

- **This path has never been run live end to end.** The attendee page carries a danger admonition
  and the script has a NOT-LIVE-VERIFIED region. Until that changes, say what is true: the module
  is built, the Azure SQL half is verified, and this is the shape the Fabric one takes.

### 03 · Database, Part 1 — regions 01–04, ~10 min

Slot is **12:15–12:45**, the only thing between the room and lunch. Do not overrun.

Watch for:

- [ ] `--configuration Release` is present. Without it the build lands in `bin/Debug` and region 03
      fails on the path.
- [ ] Build was 32s on Jess's machine. Time it on the presenting laptop, cold.
- [ ] Stop at region 04. No publish before lunch.

---

## Afternoon

Not yet reviewed against the slides — the morning pass (task #33) stopped at lunch. Sections to add
here when it is: `03-database.ps1` Part 2 (increments 0–2), `04-cicd.ps1`, `05-wrap-up.ps1`.

---

## Open across the morning

| # | Thing | Where it bites |
|---|---|---|
| — | **12 image placeholders have no artwork yet.** Each carries its generation prompt; feed them to Napkin / Eraser / Claude, then paste the picture over the dashed box. | Five of them are the whole 09:30 module |
| #35 | Merge-conflict demo written but **never rehearsed**, and it needs both of you in step. | Morning 1, 10:12 |
| #34 | The `attendee_count` bump has 15 minutes at 11:55 and no slide, no script region, no page. | Morning 2 |
| #29 | No drift demo. The slide no longer promises one — keep it that way until it exists. | Morning 2 |
| #19 | Shared endpoint has never had a live apply. | Blocks #34, and it is the fallback target |
| #25 | Afternoon slide straplines still on the dead timetable. | Afternoon |

---

## Timings log

Fill in on each run. Planned is from [`speaker-guide.md`](../agenda/speaker-guide.md).

| Date | Demo | Planned | Actual | Notes |
|---|---|---|---|---|
| | | | | |
