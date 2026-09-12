# Speaker guide — how we deliver the day

**Workshop:** Azure SQL or Fabric SQL: Deploying Infrastructure and Databases as Code
**Presenters:** Jess Pomfret & Rob Sewell · **FabCon Europe 2026, Barcelona**

The agenda ([`agenda.md`](agenda.md)) says *what* happens and when. The deck's speaker notes
(`slides/content.py`) say what to say on a given slide. **This file is the layer in between:
who leads, how long each beat gets, what to do when a demo dies, and how to present to this
particular room.** Don't duplicate the slide notes here — if a line belongs to one slide, it
belongs in `content.py`.

> Status: **DRAFT — budgets untested.** Every minute figure below is a proposal until the dry
> run (#13) replaces it with a real one. Presenter split is **proposed from task ownership —
> Jess to confirm.**

---

## Part A — How we present this room

### A1. The room is not native-English

This is the single fact that shapes delivery. Most of the room reads English far better than
they parse a fast Yorkshire aside.

- **Slow down at every instruction.** Normal pace for the story, deliberate pace for the steps.
- **Say where before what.** "In the `infra/azure-sql/terraform/demo` folder, run this."
  Never "now just run terraform apply" with no anchor.
- **Say what success looks like, out loud.** "You should see `Apply complete! Resources: 4
  added`." People who fell behind use that line to work out whether they're lost.
- **Idioms live in the story, never in a step.** "Faff", "kit", "sorted" are fine while you're
  talking *about* the work. In an instruction, use plain words: "use", not "leverage"; "set
  up", not "spin up"; "delete", not "nuke".
- **The same word for the same thing all day.** Pick "folder", not "directory", and hold it.
- **Humour never carries meaning.** If the joke lands flat, the sentence must still be
  complete and correct. Assume some of the room is translating in their head.
- **Repeat the question before answering it.** Always. Half the room won't have heard it, and
  the recording certainly didn't.

### A2. Two presenters, one keyboard

- **One drives, one narrates.** The person typing does not explain — the other one does. It
  halves the dead air and it's much easier to follow than one person doing both.
- **Hand off out loud, by name.** "Jess is going to show you what that looks like in Fabric."
  A silent swap confuses the room and the recording.
- **The narrator watches the room, not the screen.** Blank faces, phones down, people typing —
  that's the signal to slow down or to call the "we move on" line early.
- **Never both on the keyboard.** If a demo goes wrong, the driver keeps driving and the
  narrator keeps talking. Two people debugging in silence is the worst two minutes of any
  workshop.

### A3. Machine setup (both laptops, before doors)

- Terminal and editor font sizes up — readable from the back row, not from your seat.
- Notifications off. Both of you. Slack, Teams, mail, calendar pop-ups, the lot.
- Browser zoom up; GitHub in a clean window with no other tabs; a second window pre-loaded
  with the fallback runs (see A5).
- Long commands are **pasted from the module READMEs**, not typed live. Typing them is a
  needless failure mode and the audience can't read your typos anyway.
- `az login` to **both tenants** — Tenant A (state + Azure SQL), Tenant B (Fabric).
- Full pre-doors procedure: [`../planning/morning-of-checklist.md`](../planning/morning-of-checklist.md).

### A4. Timing discipline

- **The anchors don't move**: break 10:30–11:00, lunch 12:45–14:00, break 15:15–15:45. The
  teaching flexes around them. Coming back late from a break steals from your own content.
- **Every follow-along has a hard "we move on" time.** Say it before you start it: "Five
  minutes, then we move on whether or not it's finished — the state you need will be
  published." Then keep to it.
- **Park questions that aren't shared problems.** "Good question — grab me at the break."
  One deep-dive with one attendee costs the other seventy people the same minutes.
- **The narrator owns the clock.** Not the driver — the driver is busy.

### A5. When a demo dies (the fallback ladder)

Work down it, out loud, without apologising more than once:

1. **Live run.** What we planned.
2. **A completed run, already open in the second window.** Have one staged for every apply
   before the day starts — this is the fallback the agenda already asks for.
3. **The code, walked.** The module is on screen anyway; talk through what it *would* have
   done. Most of the teaching value survives.
4. **Move on and come back at the next natural gap.** Never debug live for more than two
   minutes. Say "I'll pick that up at the break" and go.

Be honest about rough edges — especially on the Fabric path. The room will respect it, and
they'll hit the same edges next week.

### A6. What gets cut first, if we're behind

In order. Decide *before* the day so neither of you has to improvise:

1. Bicep equivalents (already stretch material).
2. Azure DevOps pipeline equivalents (ditto).
3. The Fabric "a word about the bill" slide — say the sentence, drop the slide.
4. The attendee-count bump demo becomes a **pre-made PR already open** rather than a live edit.
5. Increment 3's approval-gate detail shrinks to "here's the pattern, it's on the site".

**Never cut:** the Increment 2 trap, the silence after it, and the Q&A buffer.

---

## Part B — Run sheet

Budgets are proposals for the dry run to correct. Owner is who **leads**; the other presenter
narrates or drives.

### Morning 1 · 09:00–10:30 · 90 min · *Rob leads, Jess drives git*

| Time | Beat | Notes |
|---|---|---|
| 09:00 | Welcome, who we are, what today is and isn't | 10 min. Set the promise: no clicking required. |
| 09:10 | Why "as code" for data · run of the day · bring-your-own housekeeping | 10 min. Be explicit that watching is a respectable choice. |
| 09:20 | Environment check | 10 min. Attendees run the toolchain check while you work the room. Hard stop — stragglers get sorted at the break. |
| 09:30 | **The hardest part of IT** — the five lessons | 30 min. **No demo to hide behind: this is the easiest module in the day to overrun.** Rob's stories, Jess's counterpoints. |
| 10:00 | Source control foundations + the live PR | 12 min. Branch → add `notes/fabcon.md` → PR → checks run, in the shape of [`demo/01-source-control.ps1`](../demo/01-source-control.ps1). One tiny new file; stay on the happy path. |
| 10:12 | **The merge conflict** — [`demo/01b-merge-conflict.ps1`](../demo/01b-merge-conflict.ps1) | 13 min, **two laptops, presenter-only**. Rob pushes first, Jess hits the conflict. Say "nothing to type" before you start. Show `git merge --abort` *before* resolving. Closes the loop back to Lesson 3: two people were both reasonable, and someone has to choose in public. |
| 10:25 | Plant plan-on-PR, send them to coffee | 5 min. "Back at 11:00." Say the time twice. |

**Landing point:** every gate we build today is a people agreement wearing a YAML costume.
**Handoff into Morning 2:** "Jess is going to make Azure build something for us, from a file."

### Morning 2 · 11:00–12:15 · 75 min · *Jess leads, Rob narrates*

**The highest-risk block in the day.** Two platforms, two live applies, and the bump demo.

| Time | Beat | Notes |
|---|---|---|
| 11:00 | What we're about to provision | 5 min. |
| 11:05 | Walk the Azure SQL module, then **dispatch `azure-sql-apply` (target: demo)** | 7 min. **Start the apply early and narrate over it** — ~4–5 min in UK South. |
| 11:12 | Terraform in ninety seconds · state in CI (D5) | 13 min, over the top of the running apply. |
| 11:25 | What we just built: `terraform output` → the portal once → `plan` again = no changes | 5 min. This is where the drift beat goes **if #29 gets built**; if it doesn't, cut the promise from the slide. |
| 11:30 | Fabric SQL side by side — walk the module, dispatch `fabric-sql-apply` | 15 min. Capacity is pre-provisioned (`use_existing_capacity`), so only workspace + DB apply. Contrast the shapes out loud: *server → DB* vs *capacity → workspace → DB*. |
| 11:45 | What's genuinely different, and the bill | 10 min. Honest about rough edges. First thing to compress. |
| 11:55 | **The bump**: `attendee_count` 10 → 15 on a branch → PR → plan comment says *+5 databases, +5 logins, +5 users* → apply with `target: attendee` | 15 min. The most visceral IaC moment of the day. Endpoint must be pre-deployed at 10 so the plan reads "+5", not a from-scratch build. |
| 12:10 | Recap, hard stop | 5 min. |

**If behind at 11:45:** drop the bill slide. **If behind at 11:55:** switch to the pre-made PR.

### Morning 3 · 12:15–12:45 · 30 min · *Jess leads*

Short, tight, and the only thing between the room and lunch. Do not overrun — you will not win.

| Time | Beat | Notes |
|---|---|---|
| 12:15 | Two ways to put a schema in source control | 5 min. |
| 12:20 | The football sample database + the ER diagram | 7 min. |
| 12:27 | `dotnet build` → a DACPAC | 8 min. The schema is just code in git. |
| 12:35 | CI's `database` job + T-SQL static analysis, zero findings | 7 min. Name the quality bar. |
| 12:42 | Lunch. **"Back at 14:00."** | 3 min. |

**No live deploy in this block.** This section makes the artefact; the afternoon ships it.

### Afternoon 1 · 14:00–15:15 · 75 min · *Jess leads the pipeline, Rob leads the trap*

The post-lunch restart is the hardest slot of the day — open with something moving on screen,
not with a slide. **This is now the whole database part 2 in one block: increments 0 through 3.**
It is the demo-heaviest slot of the day and most of it is spent waiting on `sqlpackage`, so there
is almost no slack — see the cut lever below before you start.

| Time | Beat | Notes |
|---|---|---|
| 14:00 | Where we got to, what the afternoon does | 3 min. Straight into the terminal. |
| 14:03 | **Increment 0** — publish the baseline, prove `ShirtNumber` holds real data | 7 min. The trap needs something to destroy. |
| 14:10 | **Increment 1** — additive `vw_SquadAges` → DeployReport says *1 view to create, 0 data-loss operations* → publish | 12 min. Invite the follow-along here; this is the safe one. |
| 14:22 | **Increment 2 — the trap** | 28 min. See below — the recovery is part of it now. |
| 14:50 | **Increment 3** — retire the column safely: pre-deploy migration (Option A) or rename (Option B), then the approval gate | 22 min. Be straight that the gate is **documented, not wired** — a repo-plan limitation, not a design one. |
| 15:12 | Land it, then break | 3 min. "Back at 15:45." |

**The trap, in order — do not rush it:**
1. Show the data existing. Query the shirt numbers. Let them see rows.
2. Show the PR: a useful view, and a column removed. Two files. Tidy. Nobody typed "DROP".
3. The YOLO publish (`BlockOnPossibleDataLoss=false`) — the column and the data go. Green tick.
4. **Stop talking.** The silence of the green tick is the whole lesson. Count to three.
5. The recovery: "just redeploy the last good version." The **column** comes back; the **data**
   does not. Name point-in-time restore as the real answer — describe it, do not wait for one.
6. Then the guardrail we ship by default, failing loudly now the column exists again — and the
   DeployReport that flagged it *before* merge. "This is `terraform plan`, for your database."
   Say that sentence explicitly.

Presenter-led throughout: it's easier to watch the trap than to hit it.

**The cut lever, if you are behind at 14:50:** Increment 3 has two options that reach the same end
state. Show **Option B (the rename)** only — it is the clean one and needs no override — and
describe Option A rather than running it. If you are behind at 14:22, skip Increment 1's
follow-along invitation and keep it presenter-paced. **Never cut** the Increment 2 trap or the
silence after it.

### Afternoon 2 · 15:45–17:00 · 75 min · *both, Rob closes*

Three beats: CI/CD, then the whole loop once, then the day's argument and Q&A.

| Time | Beat | Notes |
|---|---|---|
| 15:45 | **CI/CD** — validate on every change, plan on a PR, apply on purpose, destroy on a schedule. Read the YAML first, watch a green tick second | 15 min. [`demo/04-cicd.ps1`](../demo/04-cicd.ps1). No secrets, not one. |
| 16:00 | **The whole loop, end to end** — one number in Terraform → PR → plan → merge → apply from `main` → confirm in git **and** the database → **destroy it, really** | 30 min. [`demo/05-wrap-up.ps1`](../demo/05-wrap-up.ps1). Nothing new is taught; the payoff is that the room recognises every step. Migrations/drift covered honestly in the same beat. |
| 16:30 | **Who is allowed to drop a column?** · where everything lives, what to take home | 12 min. The callback to 09:30 — the day's argument closes here, not on a pipeline. Point at the [resources & contacts page](../docs/wrap-up/resources.md). |
| 16:42 | **Q&A** | 18 min — this is the flex and it absorbs the day's slippage. Finish at 17:00, not after. |

**The last thing they hear** should be the same thing as the first: the tooling was the easy
half.

---

## Part C — Before you walk in

- [ ] Morning-of checklist run and green: [`../planning/morning-of-checklist.md`](../planning/morning-of-checklist.md).
- [ ] Both `*-apply` runs green **with smoke tests returning rows** — not just "workflow succeeded".
- [ ] Shared attendee endpoint standing at 10 databases (so the bump reads "+5"), and the
      handout of connection strings to hand.
- [ ] Fallback runs staged and open in a second window — one per live apply.
- [ ] Deck rebuilt (it's gitignored) and eyeballed against the FabCon template.
- [ ] Site in its intended state; reveal PR merged **early**, never live.
- [ ] Cut list (A6) agreed between the two of you, out loud, before 09:00.
- [ ] Notifications off. Both laptops. Yes, really.

## Part D — After

Straight into [`../notes/LEARNINGS.md`](../notes/LEARNINGS.md) while it still stings: what ran
long, what confused the room, which fallback you actually needed. Then update the budgets in
this file — they're only a draft until a real room has tested them.
