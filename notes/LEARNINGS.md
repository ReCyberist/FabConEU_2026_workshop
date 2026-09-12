# Learnings Log 🔁

**Keep this updated.** Newest entries at the top. One entry per learning — a gotcha, a
better command, a broken assumption, a demo-timing note, a tester's confusion. See the
learnings loop in [`../CLAUDE.md`](../CLAUDE.md) §7.

Format:

```
## YYYY-MM-DD — short title
**Context:** what we were doing.
**Learning:** what we found out.
**Action:** what changed as a result (file updated, decision changed, task added). Link it.
```

---

## 2026-09-12 — A page with two session clocks needs the running one to be opaque
**Context:** The database demo page carries two session clocks — Morning 3 (Part 1) and
Afternoon 1 (Part 2) — because the demo spans lunch. In the afternoon slot the red "urgent"
Afternoon banner appeared to sit *over* the morning banner, with the grey morning bar bleeding
through the red.
**Learning:** Both clocks are `position: sticky` at the same `top`, so during Part 2 the
afternoon clock sticks at the exact spot the morning clock is still stuck. Later in the DOM, it
paints on top — that part is correct and is what "replaces" the morning banner. The bug was that
the `data-warn` background was a bare `rgba()` tint, which *replaces* the opaque base bg, so the
morning banner showed through the transparency. Fix: layer the tint over the opaque base with
`background: linear-gradient(tint, tint), var(--md-code-bg-color)` so the running banner is fully
opaque and cleanly covers the finished one. This is general — it applies to any page carrying two
stacked clocks, not just the database demo.
**Action:** Fixed the `soon`/`urgent` rules in
[`session-clock.css`](../docs/stylesheets/session-clock.css).

## 2026-09-12 — Azure SQL apply writes the provisioned server/db back into the presenter script
**Context:** The logical SQL server name carries a random 6-char suffix (main.tf), so it changes
on every destroy/recreate. Region 06 of `demo/03-database.ps1` held `<your-server-name>` /
`<your-database-name>` placeholders the presenters had to hand-edit after every apply.
**Learning:** The apply job already exposes `server_fqdn` / `database_name` outputs (added for the
publish job). A new `update-presenter-script` job (`needs: apply`) rewrites just the two region-06
assignment lines with a `(?m)^\$server\s*=\s*".*"$` anchor (matches the bare assignment, never
`$serverSMO` or `/TargetServerName:$server`) and commits back to `main`. Two gotchas worth keeping:
(1) in a PowerShell `-replace` the replacement string must escape a literal `$` as `$$`, or
`$server` is parsed as a capture-group reference; (2) the attendee page keeps its placeholders on
purpose — each attendee targets their own database, so pinning the presenters' ephemeral server
into `docs/database/demo.md` would be wrong. This is the one config value where the two halves of a
demo legitimately differ, and CLAUDE.md 7a's "touch both halves" is about *step* drift, not targets.
**Action:** Added the job to [`azure-sql-apply.yml`](../.github/workflows/azure-sql-apply.yml).
`demo/**` is not a trigger path and the commit carries `[skip ci]`, so it never loops. **Live-verify
open:** the built-in `GITHUB_TOKEN` push to `main` only works if branch protection allows it — if a
PR/review is required the push is rejected and this must become a PR or use a deploy key/PAT (noted
on task #9).

## 2026-09-12 — Azure SQL apply now runs on merge to main (reversing "apply on intent")
**Context:** Jess & Rob want the workshop demo to show the whole CI/CD loop, not stop at a
manual apply. `azure-sql-apply.yml` was `workflow_dispatch`-only by the 2026-07-29 decision.
**Learning:** With a multi-flow apply workflow you can't just add `on: push` — the demo and
attendee jobs were gated on the `workflow_dispatch` `target` input, which is empty on a push,
so every job would have skipped. The fix is a `detect-changes` job (`dorny/paths-filter`,
`fetch-depth: 0` so it can diff the push) whose outputs each job's `if` reads: run when
`workflow_dispatch` selects the flow **or** when `push` changed that flow's files. Path routing
matters — a demo-only merge must not deploy the attendee endpoint's N databases. No new OIDC
federated credential: a push to `main` already matches the existing `…:ref:refs/heads/main`
subject (unlike the PR plan, which needed `…:pull_request`).
**Action:** Added `push`+`detect-changes` to [`azure-sql-apply.yml`](../.github/workflows/azure-sql-apply.yml),
corrected the stale "apply is dispatch-only" note in [`azure-sql-plan.yml`](../.github/workflows/azure-sql-plan.yml),
and logged the reversal under D5 in [`decisions.md`](decisions.md).

## 2026-09-12 — `az ... --output table` silently hides any column literally named `id`
**Context:** The infra demo prints the signed-in subscription with
`az account show --query "{subscription:name, id:id}" --output table`, and only the subscription
name showed — the id column was missing.
**Learning:** The query was correct (`-o json` returned both fields). Azure CLI's **table
formatter deliberately drops any column named `id`** — a legacy quirk from when `id` was almost
always a long ARM resource id that made tables unreadable. It only affects the table/tsv-with-headers
formatters; json/jsonc show it. Fix: name the key anything else (`subscriptionId:id`), or use
`-o tsv` / `-o json` when you need the raw id.
**Action:** Renamed the key to `subscriptionId:id` in both halves of the infra demo —
[`demo/02-infrastructure.ps1`](../demo/02-infrastructure.ps1) (Azure SQL + Fabric sign-in regions)
and [`docs/infra/demo.md`](../docs/infra/demo.md).

## 2026-09-12 — Note the `plan -out` / `apply <plan>` artefact pattern near the infra plan step
**Context:** The infra demo runs plain `terraform plan` then `terraform apply` on both halves. That
is right for a live demo, but it hides the pipeline pattern where the reviewed plan is the plan that
ships.
**Learning:** Worth calling out (not doing) that `terraform plan -out=tfplan` saves the plan to a
file and `terraform apply tfplan` applies exactly it — no re-plan, no approval prompt — which is how
a plan job hands a build artefact to an apply job so no drift creeps in between review and apply.
**Action:** Added a `!!! tip` under the Azure SQL plan step in [`docs/infra/demo.md`](../docs/infra/demo.md)
and a matching `SAY:` comment at region 08 of [`demo/02-infrastructure.ps1`](../demo/02-infrastructure.ps1).
Kept it to the focus (Azure SQL) path to avoid the two-copy drift CLAUDE.md §7a warns about.

## 2026-09-12 — The session-clock "90 min" badge now counts down and warns in colour
**Context:** The teaching-slot clocks showed a static slot length ("90 min") on the right while
the fill bar moved. Only the break clock (`.session-clock__remaining`) counted down; the room had
no at-a-glance "how long is left" on a normal slot.
**Learning:** The countdown maths was already in `session-clock.js` for the break clock, so making
the `.session-clock__duration` badge live was a small addition, not a rewrite — one shared
`minutesLeft` drives both. The badge is `display:none` on narrow screens, so a warning band has to
re-show it or a phone loses exactly the readout that matters.
**Action:** `docs/javascripts/session-clock.js` now writes "N min left" to `.session-clock__duration`
while the slot runs (static length before it starts, "done" after) and sets `data-warn` =
`soon` (≤10 min) / `urgent` (≤5 min) **on the whole `.session-clock` container**, so the box
background and border colour, not just the badge text. `docs/stylesheets/session-clock.css` tints
the box blue (`rgba(37,99,235,.14)` + `#2563eb` border) then a strong red (`rgba(220,20,20,.18)` +
`#dc1414` border), colours the badge to match, and keeps the badge visible on narrow screens once
warning.
rgba tints are used so the box reads on both light and dark schemes. Break clocks are untouched
(they use `__remaining`, not `__duration`). Verified in Chrome against a harness forcing 30/9/4 min
left. Done in worktree `worktree-session-clock-countdown`.
Also fixed a pre-existing Impeccable `layout-transition` finding on `.session-clock__fill` in the
same pass: the fill now animates `transform: scaleX()` (origin left, `width:100%`) instead of
`width`, keeping the every-30s tick off the layout path. The JS sets `fill.style.transform =
"scaleX(fraction)"` instead of a width percentage; the track's `overflow:hidden` still rounds the
visible corners, so the fill dropped its own `border-radius`.

## 2026-09-12 — The database demo spans three slots, so it carries three clocks
**Context:** The database demo (`docs/database/demo.md`) is one page but is taught across two
timeslots either side of lunch — Part 1 before, Part 2 after — and Part 2 itself straddles the
15:15 break. It had a single `clock-morning-3` include at the very top, which was only true for
Part 1.
**Learning:** The earlier "one clock per section" mapping (database = Morning 3) assumed each
teaching section sits in exactly one slot. This one does not: Part 1 = Morning 3, Part 2 (increments
0–2b) = Afternoon 1, Increment 3 = Afternoon 2. A page can legitimately need more than one clock.
**Action:** Removed the top-of-page clock and placed the correct clock at the top of each part —
`clock-morning-3` under Part 1, `clock-afternoon-1` under Part 2, `clock-afternoon-2` at Increment 3
— with stable `{ #part-1 }` / `{ #part-2 }` anchors and jump links between the two parts. Also added
an "open the view" step to Increment 1 (mirrored in `demo/03-database.ps1` and the Increment 1 slide
in `slides/content.py`), and filled the attendee `$password` placeholder with the real throwaway
credential (`Taylor==Metallica`, the intentional public-secret from the shared-endpoint
`variables.tf`). Verified with a `mkdocs build -f mkdocs.local.yml --strict` and the demo-path check.

## 2026-09-12 — A whole-repo demo reset + Pester readiness check (git-clean is not demo-clean)
**Context:** Re-running the demos to rehearse, `git switch -c demo/source-control` failed with
*"a branch named 'demo/source-control' already exists"* — a previous run's throwaway branch was
still there. The per-script `RESET` regions each tidy only their own demo, and only if run; nothing
put the *whole* environment back at once or told you it was ready.
**Learning:** Several things a plain `git status` will not show you:
1. **Gitignored scratch survives a "clean" status.** `terraform.tfvars` and `*_override.tf` (demo
   02) are gitignored, so a checkout reads clean while the Fabric module still had a stale `tfvars`
   and `backend_local_override.tf` on disk from an abandoned run. A readiness check has to test the
   filesystem, not just `git status`.
2. **A demo commit can leak onto a working branch.** While mid-testing, the repo's HEAD had drifted
   onto the demo commit `d7ca952` (the "add FabCon source control demo note" that demo 01 makes), so
   `notes/fabcon.md` was **tracked** — present on disk, absent from `git status`, and it rode into a
   new branch cut from what looked like `main`. The reset now detects a *tracked* scratch file and
   refuses to `Remove-Item` it (that only stages a deletion); it flags it for a git-level fix.
3. **The 60-vs-75 trap is invisible to status.** If demo 05's `database_auto_pause_delay` change is
   committed, the tree is clean but the wrap-up plan reads *"0 to change"*. The check asserts the
   committed value with a whitespace-tolerant regex, because `git status` cannot.
4. **Keep reset and verify off one list.** Both [`Reset-DemoEnvironment.ps1`](../demo/Reset-DemoEnvironment.ps1)
   and [`DemoEnvironment.Tests.ps1`](../tests/DemoEnvironment.Tests.ps1) read
   [`DemoEnvironment.psd1`](../demo/DemoEnvironment.psd1) so they cannot drift — the same "no third
   copy" rule as the demo pairs (§7a). `check-demo-paths.py` keeps its own Python `EXPECTED_ABSENT`
   (different job, cannot read a psd1) — cross-referenced by comment.
**Action:** Added [`demo/DemoEnvironment.psd1`](../demo/DemoEnvironment.psd1) (the inventory),
[`demo/Reset-DemoEnvironment.ps1`](../demo/Reset-DemoEnvironment.ps1) (`-WhatIf`/`ShouldProcess`,
`-SkipRemote`; deletes only the four demo-run branches, restores only the four overwritten tracked
files, never `git clean`), and [`tests/DemoEnvironment.Tests.ps1`](../tests/DemoEnvironment.Tests.ps1)
(Pester 5, tags `Repo`/`Tooling`/`Auth`). Documented both in [`demo/README.md`](../demo/README.md).
Verified: reset cleared two real leftover branches + two gitignored scratch files; tests run 35
checks, 33 green on a dev branch (the two reds are the "on main"/"clean tree" checks correctly
failing mid-development). Deliberately **not** wired into CI — the tooling/auth checks need a real
presenter machine. Feeds task #13 (the dry run) and #28 (morning-of checklist).

## 2026-09-12 — The session-clock timing bar now covers every teaching-section page
**Context:** The timing strip (`session-clock`) was only on the two foundations content pages and
`lunch.md` — the demo pages, and the infra/database/cicd/wrap-up content pages, had no bar. Asked to
put it on the demo pages "to match the content page", we did a full rollout to every teaching-section
page (content **and** demo).
**Learning:** Only two clock includes existed (`clock-morning-1`, `clock-lunch`). The other four
agenda slots had none, so "match the content page" wasn't literally possible for most sections — the
content pages had no bar either. Section→slot mapping comes straight from
[`agenda/agenda.md`](../agenda/agenda.md): foundations = Morning 1, infra = Morning 2, database =
Morning 3, cicd = Afternoon 1, wrap-up = Afternoon 2.
**Action:** Added `includes/clock-morning-2.md` (11:00–12:15, 75 min), `clock-morning-3.md`
(12:15–12:45, 30 min), `clock-afternoon-1.md` (14:00–15:15, 75 min), `clock-afternoon-2.md`
(15:45–17:00, 75 min), each following the `clock-morning-1.md` template. Added the matching
`--8<--` include as line 3 on all 14 previously-bare teaching pages. `mkdocs build -f
mkdocs.local.yml --strict` passes; labels render (Morning 2 / Afternoon 1 / Afternoon 2 confirmed).
Times were taken from `agenda/agenda.md` per the existing includes' "change them THERE first" rule.

## 2026-09-05 — Demo path check distinguishes documented branch examples
**Context:** The CI demo-sync job treated the documented `demo/wrapup-azure-sql-reset`
branch example as a repository path.
**Learning:** A slash in a Markdown code span is not sufficient evidence that it is a
repository path. Branch-name examples must be excluded from path validation.
**Action:** Updated [`check-demo-paths.py`](../.github/scripts/check-demo-paths.py) to
recognise branch-name examples alongside Git branch commands.

## 2026-08-30 — Increment 3 built: the pre-deploy migration gotcha, and how to prove DACPAC behaviour offline
**Context:** Building Increment 3 of the ship-changes demo (safe retire of `Player.ShirtNumber`)
as runnable code (task #21). The design in `increment-3_safe-retire.md` had drafted a pre-deploy
migration: `UPDATE Player SET SquadNumber = ShirtNumber ...`. Verified everything with a real
`dotnet build` (installed .NET 8 SDK + `Microsoft.Build.Sql` locally) and `sqlpackage`.
**Learning:** Five things, most of which contradicted an assumption in the repo:
1. **The drafted pre-deploy migration was broken.** A DacFx publish runs *pre-deploy → schema
   change → post-deploy*, and the plan is computed once up front. So at pre-deploy time the new
   `SquadNumber` column does **not** exist. `UPDATE ... SET [SquadNumber] = ...` against a
   database that already has `Player` fails with **Msg 207 (Invalid column name)** at *bind*
   time — deferred name resolution never covers a missing *column* of an existing table, and the
   whole batch is bound before the `IF` guard runs. Confirmed by MS Learn + research.
2. **Canonical single-deployment fixes:** (a) genuine transform → **pre-deploy stash to a staging
   table + post-deploy restore** (each script binds only against columns that exist at its own
   phase); (b) pure rename → **refactorlog** (`sp_rename`, zero movement). A pre-deploy
   `sp_rename` is *not* reliable — it collides with the already-computed ADD/DROP plan.
3. **A `<PreDeploy Include="…">` pointing at a missing file FAILS the build** (`SQL72006`,
   exit 1). So the pre-deploy wiring can't be pre-committed — it stays a demo step (the presenter
   copies in a wired `.sqlproj`). Same for the refactorlog, which in SDK-style projects is **not**
   auto-globbed and needs an explicit `<RefactorLog Include="…">` item.
4. **Post-deploy scripts are NOT validated against the schema model at build time.** A seed that
   still references a dropped column *builds clean* — the mismatch fails only at publish. The old
   "the build should fail" note in `docs/database/demo.md` (and `increment-2_drop-shirtnumber.md`)
   was wrong; fixed the demo.md gotcha, flagged increment-2's copy as a follow-up.
5. **Option A still trips the data-loss guard.** Its DeployReport *keeps* the `DataIssue` alert
   (the column really is dropped; the data is preserved *around* it), so Option A must publish
   with `/p:BlockOnPossibleDataLoss=false` — the same flag as the Increment 2 YOLO, used
   deliberately. Only **Option B (refactorlog)** produces an empty `<Alerts />` and publishes
   under the shipped safe profile unchanged.
**Reusable technique — verify DACPAC deploy behaviour with no live DB:** build the "before" and
"after" DACPACs, then `sqlpackage /Action:Script` (or `/Action:DeployReport`)
`/SourceFile:new.dacpac /TargetFile:old.dacpac /TargetDatabaseName:<anyname>`. This diffs two
packages offline. It proved Option B: with the refactorlog the script is
`EXECUTE sp_rename @objname=N'[football].[Player].[ShirtNumber]', @newname=N'SquadNumber', @objtype=N'COLUMN'`
and the report is `<Alerts />`; without it, a column drop + `DataIssue` alert.
**Action:** Shipped the Increment 3 artifacts in
[`../database/demo/ship-changes/`](../database/demo/ship-changes/) (Player, pre-deploy migration,
seed, refactorlog, and two wired `.sqlproj` variants), rewrote
[`increment-3_safe-retire.md`](../database/demo/ship-changes/increment-3_safe-retire.md) and the
[`README`](../database/demo/ship-changes/README.md), rewrote `docs/database/demo.md` steps 16–26
to the step register, and fixed the false build-fail gotcha. All builds green (`-warnaserror`,
0 analysis findings); both mkdocs configs `--strict` green. Live publish is the remaining check
(task #21). **Toolchain note:** this box had no .NET/sqlpackage/mkdocs; installed .NET 8 via
`dotnet-install.sh` to `~/.dotnet`, `microsoft.sqlpackage` as a global tool, and mkdocs in a venv.

## 2026-08-30 — Lunch page + a reusable countdown banner; build-validate gets its PR demo
**Context:** Attendee docs for the lunch break and for the first session after lunch (build & validate).
**Learning:** The `session-clock` component now supports an **optional live countdown**. Add a
`<span class="session-clock__remaining">` to any clock include and `session-clock.js` fills it —
`"N min left"` while the slot runs, `"starts HH:MM"` before, `"done"` after. It is backward-compatible
(clocks without that span are untouched), so it doubles as a break countdown without a second widget.
Also a demo gotcha worth remembering: **`gh pr create` from a fork defaults its base to the UPSTREAM
repo**, so a follow-along attendee must open the PR *inside their own fork* or they raise it against
the workshop repo — the build-validate demo calls this out.
**Action:** Added [`docs/lunch.md`](../docs/lunch.md) (countdown banner via
[`includes/clock-lunch.md`](../includes/clock-lunch.md) + a light "Jess eats lunch" aside), enhanced
[`session-clock.js`](../docs/javascripts/session-clock.js) / [`session-clock.css`](../docs/stylesheets/session-clock.css),
wired lunch into both navs (teaser `exclude_docs` + `mkdocs.local.yml`), and added a step-register
**"watch CI validate a pull request"** demo to [`docs/cicd/build-validate.md`](../docs/cicd/build-validate.md)
(reuses the increment-1 additive view + `ci.yml`). Both mkdocs configs `--strict` green. Scoped to the
sessions either side of lunch — Afternoon 2 / increment 3 deliberately untouched. Feeds task #22.

## 2026-08-29 — Terraform plan output posted as a sticky PR comment (and the secret-leak trap)
**Context:** Wanted the PR plan workflows to surface the diff on the PR itself, not just in the
checks log — this makes the "bump attendee_count" demo land, since the +N databases/logins/users
show up right in the conversation.
**Learning:** Two things worth remembering. (1) The `hashicorp/setup-terraform` wrapper exposes
the plan text as `steps.<id>.outputs.stdout`, so capturing it is free — but only if the plan step
keeps its `id`. Give the step `continue-on-error: true` so the comment still posts on a failed
plan, then a `if: steps.plan.outcome == 'failure'` → `exit 1` gate re-fails the job. (2) **GitHub
masks registered secrets in the log, but NOT in a comment body posted via the API.** The azure-sql
`plan` job feeds `secrets.ROB_CLIENT_IP` / `secrets.JESS_CLIENT_IP` into the firewall-rule diff, so
a naive comment would leak the presenters' IPs into a public PR. The shared local action
`.github/actions/tf-plan-comment` takes a `mask` input (newline-separated secret values) and
redacts them before writing. Any plan that uses secret `-vars` MUST set `mask`.
**Action:** Added [`../.github/actions/tf-plan-comment/action.yml`](../.github/actions/tf-plan-comment/action.yml)
(sticky comment, one per header, masking + truncation) and wired it into all three plan jobs in
[`../.github/workflows/azure-sql-plan.yml`](../.github/workflows/azure-sql-plan.yml) and
[`../.github/workflows/fabric-sql-plan.yml`](../.github/workflows/fabric-sql-plan.yml), adding
`pull-requests: write` to each. YAML + embedded JS validated locally.

## 2026-08-30 — Rebase-style PR conflict checks still need a current-base merge
**Context:** Resolving the Morning 1 docs PR after GitHub still reported merge conflicts even though
the branch already contained an older merge from `main`.
**Learning:** A conflict can be genuinely resolved for one base SHA and then become dirty again when
`main` advances. In this case the only new conflict was the append-only learning log: keep both
entries, remove the markers, and verify the PR diff still contains only the intended feature files.
**Action:** Merged current `origin/main` into the PR branch, preserved both
`notes/LEARNINGS.md` entries, and confirmed the PR changed-files list stayed scoped to the Morning 1
work.

## 2026-08-29 — Presenter firewall IPs are GitHub secrets that go stale
**Context:** Reviewing the morning-of checklist (PR #43) before the workshop — specifically
what has to be true before dispatching `azure-sql-apply`.
**Learning:** The rules that let our laptops reach the Azure SQL server aren't hand-added on
the day — Terraform builds them as code from the `ROB_CLIENT_IP` / `JESS_CLIENT_IP` GitHub
**secrets** (`presenter_client_ips` in
[`azure-sql-apply.yml`](../.github/workflows/azure-sql-apply.yml)). They were set from home,
so in Barcelona they're stale, and apply won't re-open the firewall if you fix them *after*
running it. Secret **values can't be read back** — you can only `gh secret list` (names +
timestamps) — so "check they're current" really means "re-set them to today's egress IP."
**Action:** Added a "refresh the presenter IP secrets first" step to
[`../planning/morning-of-checklist.md`](../planning/morning-of-checklist.md) §1 and cross-linked
it from the §3 manual-firewall fallback (that manual `az` rule is now only for a skipped step
or a one-off third machine).
## 2026-08-29 — Database demo page should split at lunch, then pause again before increment 3
**Context:** Writing `docs/database/demo.md` as an attendee-facing step-by-step walkthrough from the existing SQL-project and ship-changes notes.
**Learning:** The clearest demo structure follows the agenda rather than the code folders: **Part 1** ends before lunch with the DACPAC built, and **Part 2** resumes after lunch for increments 1 and 2, with a second explicit pause at the 15:15 break before increment 3. That keeps the page aligned with how the room actually experiences the day.
**Action:** Added [`../docs/database/demo.md`](../docs/database/demo.md) as a two-part, step-by-step database demo page aligned to the agenda breaks.

## 2026-08-29 — Azure SQL local demo deploy to `test` in `uksouth` took 4m31s
**Context:** Running the Azure SQL Terraform module locally with the demo overrides (`environment=test`, `location=uksouth`) and local backend.
**Learning:** Jess's measured `terraform apply` completed in **4m31s** and created 4 resources: the resource group, logical SQL server, serverless database, and firewall rule. Example outputs were `rg-fabcon26-test-uks`, `sqldb-football-test`, and `sql-fabcon26-test-uks-myw0ki.database.windows.net`. This is a useful attendee expectation-setting datapoint for the infra demo page.
**Action:** Added the runtime note and sample output to [`../docs/infra/demo.md`](../docs/infra/demo.md).

## 2026-08-29 — Suppress the Material MkDocs 2.0 banner in local preview
**Context:** Running local attendee-site preview with `mkdocs serve -f mkdocs.local.yml` printed the new Material warning banner every run.
**Learning:** Material documents an opt-out env var for local runs. Setting `NO_MKDOCS_2_WARNING=1` in the PowerShell session suppresses the banner without changing the published site build.
**Action:** Updated [`../CLAUDE.md`](../CLAUDE.md) §6 with the local preview instruction: `$env:NO_MKDOCS_2_WARNING = '1'` before serving/building.

## 2026-08-29 — Infra demo page works best as one shared Terraform flow split by platform
**Context:** Writing `docs/infra/demo.md` to mirror the source-control demo while covering both Azure SQL and Fabric SQL.
**Learning:** The cleanest attendee demo format is one shared top-level structure (`What you'll do` → `The concept` → `Checkpoint` → `Gotchas`) with separate Azure and Fabric run sections underneath. The two paths are similar enough to teach side by side, but the provider split and cost warnings belong inside the Fabric subsection rather than in a generic flow.
**Action:** Added [`../docs/infra/demo.md`](../docs/infra/demo.md) as a step-by-step attendee walkthrough with Azure SQL and Fabric SQL subheadings.

## 2026-08-29 — The source-control demo should stay on the happy path
**Context:** Simplifying `docs/foundations/demo.md` after the PR step picked up fork and closed-PR edge cases.
**Learning:** This page works best as a first-run attendee exercise, not as a full GitHub CLI troubleshooting guide. Keep the flow on the happy path: branch, new file, staged diff, commit, push, `gh pr create --fill --base main`. Handle edge cases separately if they matter later.
**Action:** Restored [`../docs/foundations/demo.md`](../docs/foundations/demo.md) to the simpler working PR flow and removed the extra PR edge-case guidance.

## 2026-08-29 — Closed PR on the same branch needs reopen or a new commit
**Context:** Retesting the source-control demo after opening, closing and trying to recreate the same pull request.
**Learning:** `gh pr create` works for the first PR on a branch, but if that PR is later closed and the branch has no new commits, GitHub will not create a second PR for the same head/base comparison. The practical rule for the workshop is: reopen the closed PR with `gh pr reopen <number>`, or add another commit before creating a new PR.
**Action:** Updated [`../docs/foundations/demo.md`](../docs/foundations/demo.md) to explain the retry behaviour in the PR step and gotchas.

## 2026-08-29 — `gh pr create` needs the fork repo named explicitly in this demo
**Context:** Testing the source-control demo after switching it to create a new file and open a PR from a cloned fork.
**Learning:** In a clone created from `gh repo fork --clone`, `gh pr create` can target the upstream repo by default even though the working branch only exists in the attendee's fork. That produces `No commits between main and demo/source-control` and `Head ref must be a branch`. For this workshop flow, the reliable command is to name the fork explicitly with `--repo <your-account>/FabConEU_2026_workshop` and set `--head demo/source-control`.
**Action:** Updated [`../docs/foundations/demo.md`](../docs/foundations/demo.md) to target the attendee's fork explicitly and documented the gotcha on the page.

## 2026-08-29 — Source-control demo works best as one tiny PR from a harmless existing file
**Context:** Writing the attendee-facing demo page that sits after the source-control concepts page.
**Learning:** The clearest first source-control exercise is one complete PR loop against the attendee's own fork: clean status, branch, tiny edit, review the diff, commit, push, open PR. Using an existing harmless text file (`notes/Ideas.md`) keeps the exercise concrete without touching infra or database code too early.
**Action:** Added the step-by-step flow to [`../docs/foundations/demo.md`](../docs/foundations/demo.md).

## 2026-08-29 — Terraform directory renames merge cleanly with subsequent module edits
**Context:** The Azure SQL Terraform modules moved under `terraform/demo` and
`terraform/shared-endpoint`; the current `main` branch then changed the demo module's
auto-pause default.
**Learning:** Git's rename detection mapped the subsequent edit to the relocated demo module,
so merging the current base produced no conflict and retained the updated default.
**Action:** Merged current `main` into the restructuring branch and checked the resulting
`infra/azure-sql/terraform/demo/variables.tf` change.

## 2026-08-29 — Azure SQL Terraform split into `terraform/{demo,shared-endpoint}`
**Context:** The taught module lived at `infra/azure-sql/terraform` and the shared attendee
endpoint at a sibling `infra/azure-sql/shared-endpoint`. Post-merge feedback: put both under
one `terraform/` parent with `demo` and `shared-endpoint` children.
**Learning:** Two gotchas when relocating Terraform modules. (1) A blanket path rewrite is
unsafe once one new path is a prefix of another — rewrite the more specific path
(`shared-endpoint`) **first**, then rewrite `terraform` with a negative lookahead
(`terraform(?!/demo|/shared-endpoint)`) so you don't double-apply. (2) The remote-state
**blob key** (`azure-sql/shared-endpoint.terraform.tfstate`) is *not* a filesystem path —
it must stay put or you orphan state; anchoring the rewrite to the `infra/` prefix leaves it
alone. Also: a moved README's relative links all shift by one `../` level, and cross-module
links change target (`../terraform` → `../demo`).
**Action:** `git mv` into `terraform/demo` and `terraform/shared-endpoint`; updated all 20
referencing files (workflows, CI validate loop, ADO pipelines, docs, slides, agenda, tasks).
`terraform validate`/`fmt` clean on both; gitignore globs (`*_override.tf`, `**/.terraform/*`)
still catch the new depths. State keys and concurrency groups unchanged.

## 2026-08-29 — Default region flipped to UK South everywhere (West Europe has no capacity)
**Context:** West Europe has no capacity for our subscription, so a deploy that lands in the
old default region fails. Earlier the same day we had deliberately kept `westeurope` as the
*taught* default and only overrode to UK South in CI/the shared-endpoint module (see the
shared-endpoint entry below, and 2026-07-22).
**Learning:** That split is no longer worth keeping — a taught default nobody can actually
provision into is a footgun, not a teaching aid. So **UK South (`uksouth`/`uks`) is now the
single default across every module**: the taught Azure SQL + Fabric Terraform modules, both
Bicep templates, the Fabric automation module, and the shared-endpoint module (already there).
CI is unaffected — it still passes `AZURE_LOCATION`/`AZURE_LOCATION_ABBREVIATION` (=uksouth/uks)
explicitly, which is now belt-and-braces rather than a required override. **This supersedes the
"the taught module's WEU default stands" line in the shared-endpoint entry below.** Two things
deliberately **not** touched: the state resource group `rg-fabcon26-state-weu` (a real RG
physically in West Europe — renaming it in code would try to recreate the state backend), and
past dated entries in this log (history, not rewritten).
**Action:** `location`→`uksouth`, `location_abbreviation`→`uks` in
[`infra/azure-sql/terraform/demo/variables.tf`](../infra/azure-sql/terraform/demo/variables.tf),
[`infra/fabric-sql/terraform/variables.tf`](../infra/fabric-sql/terraform/variables.tf),
[`infra/fabric-sql/automation/variables.tf`](../infra/fabric-sql/automation/variables.tf), and
both `main.bicep` files; updated every `terraform.tfvars.example`, the Bicep deploy READMEs, the
CAF naming examples in the infra READMEs, and the attendee pages
[`docs/infra/azure-sql.md`](../docs/infra/azure-sql.md) /
[`docs/infra/fabric-sql.md`](../docs/infra/fabric-sql.md) (resource-name examples now `…-uks`).
Reworded the shared-endpoint `location` description (the "unlike the taught module" contrast is
gone). (Jess & Rob, 2026-08-29.)
## 2026-08-29 — The scary "MkDocs 2.0" banner is theme advocacy, not an error — and requirements.txt was unpinned
**Context:** Running `mkdocs serve -f mkdocs.local.yml` printed a red-bordered "Warning from
the Material for MkDocs team" about a coming **MkDocs 2.0** (plugins removed, theming
rewritten, "unlicensed", "unsuitable for production"). Looked like a build error.
**Learning:** It's a **banner the Material theme prints itself** on every `serve`/`build`
(seen here on `mkdocs-material==9.7.7`) — pure advocacy about a *forecasted* fork/rewrite the
squidfunk team disagrees with. It is **not** an error, is unrelated to our config, and the
build completes normally right after it (`mkdocs build --strict` → *"Documentation built in
1.52 seconds"*, exit 0). MkDocs 2.0 is not something installed here. The only real finding:
`requirements.txt` pinned nothing (`mkdocs-material` bare) despite its own "Pin versions before
the event" comment — a reproducibility risk for a 200-attendee follow-along.
**Action:** Pinned the toolchain to the tested combo — `mkdocs-material==9.7.7` + `mkdocs==1.6.1`
— in [`../requirements.txt`](../requirements.txt), verified with `mkdocs build --strict`.
(Earlier entries — 2026-07-18, 2026-07-04 — already noted the banner is informational; this
consolidates it and closes the pinning gap.)

## 2026-08-29 — Running Terraform locally against the *remote* state (no spurious diffs)
**Context:** For the "bump attendee_count" demo the presenter wants: apply workflow deploys the
10, then `terraform plan` **on the laptop** shows *no changes* — bump the count, plan shows only
the delta. That needs local Terraform to read the **same remote state** CI writes, not local state.
**Learning:** Two distinct local modes, easy to conflate: (a) the `backend_local_override.tf`
(local state) is for standing the module up *standalone*; (b) to interact with what the workflow
deployed you must init the **remote** backend locally. The committed backend block has
`use_oidc = true`, which has no token on a laptop — so init with the real `-backend-config` values
**plus `-backend-config="use_oidc=false"`**, and `az login`; `use_azuread_auth = true` (already in
the block) then authenticates the state blob via the Azure CLI identity (needs *Storage Blob Data
Contributor* on the state account). Second gotcha (general, though now defused for THIS module):
a local plan shows a **spurious full destroy/recreate** if it runs in a different **region** than
the deploy — the module names include the region token, so a region mismatch rewrites every
resource. The taught module keeps a West Europe default and overrides to UK South via the
`AZURE_LOCATION` repo var, so a laptop run there must set `location`/`location_abbreviation` to
match. For the shared-endpoint module we instead **changed the default to UK South** (it only ever
runs in this sandbox — see the follow-up entry), so a bare local run already matches and needs no
tfvars. With state + region matched, `terraform plan` reports *"No changes"*; bumping the count
then shows a clean **"5 to add"** (against the recorded 10) rather than "15 to add" (a fresh build).
**Action:** Documented the recipe in the module README ("Run locally against the shared state").
Companion to the apply/destroy workflows below.

## 2026-08-29 — Shared-endpoint module defaults to UK South (it only runs in the sandbox)
**Context:** The shared endpoint always deploys to the personal sandbox subscription, which is
region-restricted to UK South. The `location`/`location_abbreviation` defaults were West Europe
(copied from the taught module), so every local run needed a region override to avoid spurious
region-rewrite diffs.
**Learning:** The taught module deliberately keeps `westeurope` as its *documented/taught* default
and treats UK South as a sandbox-specific override (LEARNINGS 2026-07-22). The shared endpoint is
**ops tooling, not taught content**, and it only ever runs in that one sandbox — so the honest
default there is **`uksouth`/`uks`**, not a value nothing uses. Flipping it removes the local-run
footgun (no tfvars region override) and doesn't change CI, which still passes `AZURE_LOCATION`
(`=uksouth`) explicitly. Only the shared-endpoint module changed; the taught module's WEU default
stands. (Rob, 2026-08-29.)
**Action:** `location`→`uksouth`, `location_abbreviation`→`uks` in the module's `variables.tf`;
README examples now show `…-shared-uks-…` (the state RG stays `rg-fabcon26-state-weu` — really in
WEU) and the local-run steps drop the region override; `terraform.tfvars.example` region note
inverted.

## 2026-08-29 — Shared-endpoint apply + nightly destroy (auto-provision, small + torn down daily)
**Context:** Closing the demo loop: after plan-on-PR, a way to actually build the endpoint and to
guarantee it doesn't bill overnight. Auto-provisioning was OK'd because the pool is small and the
thing is destroyed daily.
**Learning:** Mirrored the taught module's apply/destroy shape but simpler — the shared endpoint has
**no DACPAC publish/smoke job** (attendees publish their own schemas into their own DBs), so apply is
just init → plan → apply against its own state key (`azure-sql/shared-endpoint.terraform.tfstate`).
Two deliberate choices: (1) apply **does not** pass `attendee_count` as a `-var` — it takes the
committed `variables.tf` default, so *committing a count change and running the workflow* is what
deploys the new count (the second half of the demo). (2) A **dedicated concurrency group**
(`azure-sql-shared-endpoint-terraform`, separate from the taught module's `azure-sql-terraform`) so
the two modules never block each other, while this module's own apply/destroy still serialise (never
run over the same state). The apply writes the **attendee handout** (server, shared password,
per-attendee connection strings — all giveaways; admin password stays a sensitive output, unprinted)
to `$GITHUB_STEP_SUMMARY` via `terraform output -json … | jq`. Destroy is nightly 21:00 UTC (house
style) and a no-op against empty state on days the endpoint wasn't stood up.

**Consolidated into `azure-sql-apply.yml` (Rob's steer, same day):** rather than a separate
`shared-endpoint-apply.yml`, the standup became the **`attendee-endpoint` job** inside the existing
apply workflow — one workflow, two Terraform flows (mirroring the two-job plan workflow). A
**`workflow_dispatch` choice input `target` (demo/attendee/both, default both)** gates the jobs via
`if:`; the `publish` (DACPAC) job `needs: apply`, so it's auto-skipped when `target=attendee`. Key
mechanic that makes independent flows safe in one workflow: **move concurrency from workflow-level to
JOB-level** — the demo `apply` job keeps `group: azure-sql-terraform`, the `attendee-endpoint` job
takes `group: azure-sql-shared-endpoint-terraform` (matching each flow's own destroy), so a run isn't
globally serialised and each flow only blocks against its own destroy. (GitHub Actions supports
`concurrency` at both workflow and job scope; job-level is what you want when one workflow drives
multiple independent state files.) The nightly destroy stays a separate file (only apply was
consolidated).
**Action:** Folded the standup into [`../.github/workflows/azure-sql-apply.yml`](../.github/workflows/azure-sql-apply.yml)
(deleted the standalone apply); kept [`shared-endpoint-destroy.yml`](../.github/workflows/shared-endpoint-destroy.yml); README Status +
demo sections updated; task #19 advanced. **Not yet run live** — first apply is the verification.

## 2026-08-29 — "Bump the count" IaC demo: a second plan flow in one workflow, refresh off
**Context:** Turning the shared endpoint into a teaching prop — change `attendee_count`, push,
and let a GitHub Actions plan show the exact "+N databases". Rob wanted it as a **second job in
the existing azure-sql workflow**, not a new workflow file.
**Learning:** Two independent Terraform flows live happily as **two jobs in one workflow** —
added `plan-shared-endpoint` alongside `plan` in [`azure-sql-plan.yml`](../.github/workflows/azure-sql-plan.yml)
(each with its own `working-directory` + state key), and widened the `paths:` filter so a change
to either module triggers the PR. Two gotchas that shaped it: (1) **a CI plan needs remote state
to show the *incremental* change** — with local state CI has no record that 10 DBs exist, so it'd
plan "everything to add". So the module moved from local to the **remote azurerm backend** (own
key `azure-sql/shared-endpoint.terraform.tfstate`), keeping a `backend_local_override.tf.example`
so presenters still run it locally. (2) **`terraform plan` refreshes state by default, and the
`betr-io/mssql` provider connects to the server to refresh existing logins/users** — which fails
whenever the endpoint is torn down between sessions. Fix: run the PR plan with **`-refresh=false`**
(plus `-lock=false`), so the diff is computed from state+config only, never touching SQL — the
plan still works when the DB is down and still shows the bumped-count delta. Caveat: the crisp
"+5" needs the initial 10 already seeded in the remote state (one prior apply).
**Action:** Second job added; module → remote state + local override; added to `ci.yml` validate
loop; demo beat written into [`../agenda/agenda.md`](../agenda/agenda.md) Morning 2 and the module
README. `init`/`validate`/`fmt` clean offline. Apply/destroy workflow for this module still to come
(task #19).

## 2026-08-29 — Shared attendee endpoint: Azure SQL elastic pool beats a VM
**Context:** Rob asked how we actually build the shared "run against this" endpoint (D6),
sketching an Azure SQL server with a database per attendee. D6 had said "SQL Server on a VM."
**Learning:** The VM was justified by "a database per attendee so DACPACs don't collide" — but
that's not a VM feature: an **Azure SQL logical server hosts many databases on one endpoint too**,
so per-attendee isolation needs no VM. Azure SQL wins on all the axes that matter here — it's the
platform we teach, it reuses the module we already have, and there's no VM to patch/back up/NSG on
a target we've said we won't support. An **elastic pool** caps the day's cost across N databases.
The real design forks are (1) **auth** — you can't hand a room of strangers Entra identities, so
this endpoint runs **SQL authentication** (per-attendee login, shared throwaway password), a
deliberate departure from the taught module's Entra-only design; and (2) **logins/users aren't ARM
resources** — azurerm makes the server/pool/DBs, but `CREATE LOGIN`/`CREATE USER`/role membership
run *inside* SQL, so they need the **`betr-io/mssql`** provider (connects per-resource with the
generated SQL admin) — which in turn needs the firewall open before it runs.
**Action:** Drafted a **separate** module [`../infra/azure-sql/terraform/shared-endpoint/`](../infra/azure-sql/terraform/shared-endpoint/)
(server + elastic pool + DB/login/user per attendee, local state, `Taylor==Metallica` shared password,
open firewall for the day) so the taught module stays pristine. Recorded the reversal as a
[decisions.md](decisions.md) **D6 update**; ordering + task #19 updated. **Untested** — no live
apply in the authoring env; first-run checks listed in the module README.

## 2026-08-29 — Fabric SQL module needed the same local-backend override as Azure SQL; infra diagrams added
**Context:** Bringing the Fabric SQL Terraform "Run it" steps in line with Azure SQL, and
adding infrastructure diagrams to the docs.
**Learning:** The Fabric SQL module declares the **same committed remote `azurerm` backend**
as Azure SQL (`providers.tf`), so a bare `terraform init` on a laptop prompts for a container
name — but it had **no `backend_local_override.tf.example`** and its README/docs jumped
straight into `init`. The gitignore already covers `*_override.tf` + `!*_override.tf.example`
repo-wide, so the override pattern drops into any module folder with no gitignore change.
Also: **Mermaid is already enabled** in `mkdocs.yml` (Material bundles Mermaid.js via
`pymdownx.superfences`), so ` ```mermaid ` fenced blocks render on the site and on GitHub with
no extra plugin — the right way to ship infra diagrams as version-controlled code. Note
`mkdocs build` does **not** validate Mermaid syntax (it renders client-side); verify diagrams
by rendering (e.g. an Artifact renders `<pre class="mermaid">` natively).
**Action:** Added `infra/fabric-sql/terraform/backend_local_override.tf.example`, the
`cd`/copy-override/open-tfvars steps to the Fabric README + `docs/infra/fabric-sql.md`, and
Mermaid diagrams to both infra docs pages. Reminder: `docs/infra/fabric-sql.md` is still held
from the published site by `exclude_docs`, so its diagram shows only in the local full
preview (`mkdocs serve -f mkdocs.local.yml`) until the page is un-excluded.

## 2026-08-29 — `terraform plan` "AccountUnusable" on Windows = WAM broker, fix with device-code login
**Context:** Running `terraform plan` for the Azure SQL module, every plan failed at the
`azurerm` provider block with *"Account has previously been signed out of this application…
Status: Response_Status.Status_AccountUnusable, Error code: 0, Tag: 540940121"*.
**Learning:** The `azurerm` provider fetches a **Microsoft Graph** token to parse identity
claims. ARM auth was fine (`az account get-access-token` with the default scope returned a
token), but the **Graph** scope (`--scope https://graph.microsoft.com/.default`) threw
`AccountUnusable`. A plain `az login` did **not** fix it — even `az login` failed at
"Retrieving tenants and subscriptions". Root cause on Windows: the **WAM broker** holds a
poisoned account outside `~/.azure`, so deleting `msal_token_cache.*` alone isn't enough.
**Action:** Fixed by disabling the broker + clearing + **device-code** login:
```powershell
az config set core.enable_broker_on_windows=false
az account clear
Remove-Item "$env:USERPROFILE\.azure\msal_token_cache.*" -Force -ErrorAction SilentlyContinue
az login --use-device-code
az account set --subscription $env:ARM_SUBSCRIPTION_ID
# verify GRAPH scope specifically:
az account get-access-token --scope https://graph.microsoft.com/.default --query expiresOn -o tsv
```
Diagnostic tell: ARM token works but the Graph-scoped `get-access-token` errors ⇒ it's the
CLI/broker, not Terraform. Attendees on managed Windows laptops will likely hit this.
Documented as a gotcha in
[`../docs/infra/azure-sql.md`](../docs/infra/azure-sql.md) and
[`../infra/azure-sql/terraform/demo/README.md`](../infra/azure-sql/terraform/demo/README.md).

## 2026-08-29 — Azure SQL Terraform run steps now name the folder + open tfvars
**Context:** Reviewing the Azure SQL Terraform "Run it" steps — the README and the
`docs/infra/azure-sql.md` demo block jumped into `Copy-Item`/`terraform init` without
saying which directory to be in.
**Learning:** Both left the working directory implicit. The docs demo block also never
copied `terraform.tfvars` at all, so attendees had no prompt to review the variables.
**Action:** Added `cd infra/azure-sql/terraform/demo` (from repo root) to both, added a
`Copy-Item terraform.tfvars.example …` + `code terraform.tfvars` step so the variables get
opened for review, and kept README and docs in step. Files:
[`../infra/azure-sql/terraform/demo/README.md`](../infra/azure-sql/terraform/demo/README.md),
[`../docs/infra/azure-sql.md`](../docs/infra/azure-sql.md).

## 2026-07-01 — Repo scaffolded and decisions locked
**Context:** First pass setting up the repo as the source of truth for the workshop.
**Learning:** Agreed the "all as code, focus in content" rule — the repo carries every
tooling variant (Terraform + Bicep, GitHub Actions + Azure DevOps, SQL projects + Flyway +
dbatools/dbops) but the taught content leads with **Terraform + GitHub Actions + SQL
projects**, covering **both Azure SQL and Fabric SQL** side by side. Site is **MkDocs
Material** → GitHub Pages.
**Action:** Recorded in [`decisions.md`](decisions.md) and [`../CLAUDE.md`](../CLAUDE.md).
Scaffold created; content still to be written (see [`../planning/tasks.md`](../planning/tasks.md)).

## 2026-07-04 — Canonical football schema built (men's + women's) as a SQL project
**Context:** First real code — building the canonical sample database (task #3) as the
content-focus SQL project.
**Learning:** Modelling **both the men's and women's game** cleanly falls out of a shared
`Club` that fields multiple `Team`s tagged by `Category` (Men/Women), with `Competition`
also carrying a category. One schema, both games, no duplication. Landed 9 tables, 3 views,
3 stored procedures + an idempotent, set-based post-deploy seed (PL + WSL played fixtures
with goals; El Clásico fixtures upcoming). Builds clean to a DACPAC with
`Microsoft.Build.Sql` (SDK-style) on `dotnet build`.
**Action:** Schema in [`../database/sql-projects/`](../database/sql-projects/); README
updated. Task #3 → DONE, #7 advanced. Runtime deploy not yet tested (no local SQL engine) —
see task #14.

## 2026-07-04 — Fabric SQL database ≠ Fabric Warehouse for T-SQL surface area
**Context:** Making sure the canonical schema deploys to both Azure SQL and Fabric SQL.
**Learning:** Our target is **SQL database in Fabric** (transactional, Azure SQL-compatible)
— IDENTITY, enforced constraints, indexes, views, procs all work. This is *not* the Fabric
**Data Warehouse**, whose T-SQL surface is far smaller (no enforced constraints, no
triggers, no indexes, IDENTITY behaves differently). Real watch-items for our target: no
TDE/Always Encrypted/ledger/in-memory, no spaces in column names, PKs can't be
`hierarchyid`/`sql_variant`/`timestamp`, no CDC.
**Action:** Documented in [`fabric-sql-notes.md`](fabric-sql-notes.md); referenced from the
`.sqlproj`. Grounded against Microsoft Learn.

## 2026-07-04 — Sample DB documented with a Mermaid ER diagram; CI builds docs on change
**Context:** Wanted an attendee page describing the sample database, with an entity diagram.
**Learning:** Material for MkDocs renders ```mermaid fences once you add the `custom_fences`
mapping (class `mermaid`) under `pymdownx.superfences` — no extra JS needed. `erDiagram`
gives a clean crow's-foot ER diagram from the schema. Verified with `mkdocs build --strict`
(catches broken nav/links) and confirmed the rendered HTML carries a `class="mermaid"`
block. Extended `ci.yml` with a **docs** job that runs `mkdocs build --strict`, gated by
`dorny/paths-filter` so it only runs when `docs/**`, `mkdocs.yml` or `requirements.txt`
change — the SQL-only PRs don't pay for it, and vice-versa.
**Action:** New page [`../docs/database/sample-database.md`](../docs/database/sample-database.md);
`mkdocs.yml` nav + mermaid config; docs job in [`../.github/workflows/ci.yml`](../.github/workflows/ci.yml).

## 2026-07-04 — Pin the .NET SDK, or CI grabs the wrong one
**Context:** First CI run on the PR failed even though the SQL project built fine locally.
**Learning:** The `ubuntu-latest` runner had a **preinstalled .NET 10 SDK**, and
`dotnet build` used it despite `setup-dotnet` installing 8.0.x — `setup-dotnet` installs a
version but doesn't *force* selection. The `Microsoft.Build.Sql/0.2.0-preview` SDK can't
build under .NET 10 (missing NuGet.Build.Tasks.Pack import). Fix: a repo-root
`global.json` pinning `sdk.version` to 8.0 (`rollForward: latestMinor`), so local and CI
resolve the same SDK. Separately, the CI actions were bumped off the deprecated Node 20
runtime to current majors — `actions/checkout@v7`, `actions/setup-dotnet@v5`,
`actions/upload-artifact@v7` (all Node 24). Keep the workflow on these majors, not the old
`@v4`.
**Action:** Added [`../global.json`](../global.json); CI green. Any `dotnet`-based job we
add later inherits the same pin.

## 2026-07-04 — CI to validate our own code; SQL static analysis keeps it clean
**Context:** Rob asked for a GitHub Action that checks all our code, growing as we go.
Jess flagged that moderator **Cláudio Silva** (perf expert) will notice smells.
**Learning:** SDK-style SQL projects run **T-SQL static code analysis** in-build via
`-p:RunSqlCodeAnalysis=true` (baked into the `.sqlproj` so it's always on). Combined with
`dotnet build -warnaserror`, any smell or model warning fails CI. Current schema: **0
findings**. Gotcha: from Git Bash the MSBuild `/p:` switch gets path-translated — use
`-p:` (or run under PowerShell).
**Action:** Added [`../.github/workflows/ci.yml`](../.github/workflows/ci.yml) (database
build + analysis job today; terraform/bicep/docs jobs to follow). Code-quality bar added to
[`../CLAUDE.md`](../CLAUDE.md) §4. Task #8 advanced.

## 2026-07-08 — Publish profiles carry options, not secrets; SqlPackage validates them offline
**Context:** Finishing task #7 — publish profiles for the SQL project's two targets
(Azure SQL Database + SQL database in Fabric), with no live engine to deploy against.
**Learning:** A `.publish.xml` profile can hold the DACPAC deploy *options* while keeping
**no connection string**, so nothing secret is committed — the target server/DB and the
Microsoft Entra token are passed on the SqlPackage command line at publish time. Safe
defaults we bake in for both: `BlockOnPossibleDataLoss=True`, `DropObjectsNotInSource=False`
(don't wipe attendee-created objects), `CreateNewDatabase=False` (infra provisions the DB),
and — required for Fabric, harmless for Azure SQL — `ScriptDatabaseOptions=False` (the
platform owns DB-level options and rejects most `ALTER DATABASE`). You can validate a profile
**without a live DB**: `sqlpackage /Action:Script /SourceFile:<dacpac> /Profile:<xml>
/OutputPath:... /TargetConnectionString:"...Connect Timeout=2"` — SqlPackage loads and
validates every option name *before* it connects, so an unrecognised option fails at load
while a good profile fails only at the connection stage. Gotcha: don't point the probe at
`(localdb)\...` — it hangs trying to start an instance; use a fast-failing TCP host with a
short `Connect Timeout`.
**Action:** Added [`../database/sql-projects/PublishProfiles/`](../database/sql-projects/PublishProfiles/)
(`AzureSql.publish.xml`, `FabricSql.publish.xml`); README publish section rewritten with
per-target commands. Task #7 → DONE; live-target verify still tracked by #14.

## 2026-07-08 — Azure SQL Terraform module: CAF naming + passwordless, validates & plans clean
**Context:** Task #4 — the Azure SQL infra module (content-focus IaC), the thing that
provisions the server + database the DACPAC publishes into.
**Learning:** Reconciled two naming rules that pull in different directions: **CAF** wants
the resource-type abbreviation first (`rg-`, `sql-`, `sqldb-`), while CLAUDE.md wants a
`fabcon26-*` teardown prefix. Solution — keep the CAF type-abbreviation leading and use
`fabcon26` as the *workload token* inside the name (`rg-fabcon26-dev-weu`,
`sql-fabcon26-dev-weu-<rnd>`, `sqldb-football-dev`), so `*fabcon26*` still filters
everything. The **logical SQL server name is globally unique**, so a `random_string` suffix
is appended. Went **passwordless**: `azuread_authentication_only = true` lets you omit the
SQL admin login/password entirely (azurerm accepts no `administrator_login` when Entra-only)
— no secret to commit. `min_capacity`/`auto_pause_delay_in_minutes` only apply to serverless
SKUs, so they're set conditionally via `can(regex("_S_", sku))` — flipping to a provisioned
SKU won't error. Verified offline: `terraform fmt/validate` clean and `plan` produces a
coherent **5-to-add** plan (picked up cached az-CLI auth; no live apply — that's #14).
Best-practice flag: this repo **gitignores `.terraform.lock.hcl`**; HashiCorp recommends
**committing** it so CI/teammates resolve identical provider versions — worth revisiting.
**Action:** New module [`../infra/azure-sql/terraform/demo/`](../infra/azure-sql/terraform/demo/)
(`providers/variables/main/outputs.tf` + `terraform.tfvars.example`); README rewritten with
the naming + passwordless rationale. Task #4 → DONE; unblocks the deploy pipeline (#9). The
Fabric mirror (#5) and Bicep reference (#6) should follow the same naming.

## 2026-07-09 — Command examples are PowerShell, not bash
**Context:** Jess asked that every shell example in the repo use PowerShell.
**Learning:** The presenters run Windows and demo in PowerShell, so bash-fenced examples
(`cp`, `export`, `\` line-continuations) don't match what they'll type on stage. Standardised
on **PowerShell for all command examples** in docs, READMEs, and planning — cmdlets +
`$env:VAR` syntax, fenced ` ```powershell `. Cross-platform tools (dotnet, terraform,
sqlpackage, mkdocs, pip) run the same; only the shell glue changes.
**Action:** Added the rule to [`../CLAUDE.md`](../CLAUDE.md) §4; converted the bash fence in
`CONTRIBUTING.md`. The SQL-project and Terraform module READMEs are converted on their own
open PRs (they own those files).

## 2026-07-18 — GitHub Pages deploy: artifact deployment, not the gh-pages branch
**Context:** Task #11 — the workflow that publishes the MkDocs Material site so attendees
can read it. `ci.yml` already builds the docs `--strict`; this adds the actual deploy.
**Learning:** Used the **modern GitHub Pages artifact deployment** (`actions/configure-pages`
+ `actions/upload-pages-artifact` + `actions/deploy-pages`) rather than the older
`mkdocs gh-deploy` that force-pushes a `gh-pages` branch. The artifact path gives a proper
`github-pages` deployment environment with the live URL surfaced on the run, needs no branch
juggling, and keeps history clean. It requires `permissions: pages:write` **and**
`id-token: write` (OIDC) — miss the id-token and the deploy step fails. Kept it a **separate
workflow** from `ci.yml` (validation vs. deploy are different concerns) and gated it to
`main` pushes touching `docs/**`, `mkdocs.yml`, `requirements.txt`, or the workflow itself.
Gotcha, still "nothing is clicked": the Pages **source** must be set to *GitHub Actions*
once — but that's doable in code via `gh api -X POST repos/<owner>/<repo>/pages -f
build_type=workflow`, documented in the workflow header. Verified `mkdocs build --strict`
exits 0 locally (the scary "MkDocs 2.0" banner from the Material team is informational, not a
build failure).
**Action:** Added [`../.github/workflows/pages.yml`](../.github/workflows/pages.yml).
Task #11 → DONE. Next docs step: fill in `site_url` in `mkdocs.yml` once the Pages URL is
live, and expand the `nav`.

## 2026-07-18 — Pages sites are public even from a private repo; teaser via exclude_docs
**Context:** Wanted a public **teaser** page live now but to hold the real workshop content
until a reveal date. Repo is private.
**Learning:** A **GitHub Pages site is public even when the repo is private** — on standard
plans, enabling Pages publishes to a public URL anyone can reach (only GitHub Enterprise
Cloud can access-control a Pages site). So you can't password-hide it; the best is an
*unlisted* URL. You **can** control *what content* ships, in code: MkDocs 1.6's top-level
`exclude_docs:` (gitignore-style globs) omits pages from the built site while leaving them in
the repo on `main` — and, crucially, `mkdocs build --strict` stays green because excluded
pages don't trip the "exists but not in nav" check (they must also be removed/commented from
`nav`, or nav errors on the missing file). Verified: with `database/sample-database.md`
excluded, `mkdocs build --strict` publishes only `index.html` (+ auto `404.html`).
**Reveal = a one-PR diff:** delete the `exclude_docs` block and un-comment the nav entries.
**Action:** "Teaser mode" wired in [`../mkdocs.yml`](../mkdocs.yml) (documented block) with
[`../docs/index.md`](../docs/index.md) reworked into a teaser. Content pages stay on `main`,
held back until reveal.

## 2026-07-18 — Fabric SQL Terraform module: two providers, capacity→workspace→database
**Context:** Task #5 — the Fabric SQL infra module, the "side by side" partner to the Azure
SQL module (#4).
**Learning:** Fabric SQL needs **two providers**, not one. The **capacity** is an *Azure*
resource — `azurerm_fabric_capacity` (`Microsoft.Fabric/capacities`, added to azurerm in
**v4.14**, so pin `~> 4.14` not `~> 4.0`) — while the **workspace** and **SQL database** are
Fabric items managed by the **`microsoft/fabric`** provider (~> 1.12, needs Terraform
>= 1.8) over the Fabric REST APIs. So the shape is **capacity → workspace → database**, where
Azure SQL is **server → database**. Gotchas that cost a validate cycle: (1) a Fabric capacity
name is **lowercase-alphanumeric only** (`^[a-z][a-z0-9]*$`, no hyphens), so it can't take the
hyphenated CAF form — build it from the tokens minus separators. (2) On `fabric_sql_database`
the connection details are **nested under a computed `properties` object**
(`properties.database_name` / `.server_fqdn` / `.connection_string`), *not* top-level
attributes — the registry docs page implied top-level and `validate` caught it; confirm
against `terraform providers schema -json`. Both providers are **passwordless** (reuse
`az login`; OIDC/SP in CI). `fmt`/`init`/`validate` are clean against the real schemas; no
live `plan`/`apply` (needs a real capacity — #14). The `fabric_sql_database` resource can also
deploy a `.sqlproj`/DACPAC directly via `definition`/`format` — noted as a future alternative,
but we keep the SqlPackage path for symmetry with Azure SQL.
**Action:** New module [`../infra/fabric-sql/terraform/`](../infra/fabric-sql/terraform/)
(`providers/variables/main/outputs.tf` + `terraform.tfvars.example`, README rewritten). Task
#5 → DONE. Reinforces the earlier flag to **commit `.terraform.lock.hcl`** — doubly true for
the fast-moving preview Fabric provider (still gitignored today; revisit with #17). Next: a
terraform `fmt`/`validate` CI job (#8) now covers both #4 and #5.

## 2026-07-18 — Attendee sandbox decided: bring-your-own (unblocks the prerequisites)
**Context:** Task #1 — the sandbox strategy that gates the prerequisites page (#2) and the tf
state backend owner (#17). Settled in a Jess + Rob chat.
**Learning:** We go **bring-your-own** — no per-attendee sandboxes. The hands-on is **two
independent parts**: IaC (needs the attendee's own Azure sub) and DB-deploy (needs a target
SQL), each optional depending on what they bring, plus **one shared SQL endpoint on the day
that we explicitly won't support**. The driver was support cost: "we can't spend a lot of time
troubleshooting labs, and if we provide something they'll expect that." Knock-on effects: it
**unblocks #2**, and it **defuses most of #17** — there's no shared attendee state account to
own (attendees use local state); only *our* CI/demo state backend still needs an owner.
**Shared endpoint resolved:** it's a **SQL Server on a VM** attendees push to via pipeline —
a database per attendee on one instance, so no DACPAC name collisions (task #19). **Deferred
("decide later"):** the Fabric IaC path's capacity cost (an F-SKU bills; a trial capacity
can't be TF-created), and *our* CI/demo state owner (#17) — both open caveats, neither blocks
the prereqs page.
**Action:** Recorded as [`decisions.md`](decisions.md) **D6**; prereq checklist + shared-endpoint
TODO in [`../planning/ordering.md`](../planning/ordering.md); tasks #1 → DONE, #2 unblocked,
#17 note updated, new #19 (shared VM target). CLAUDE.md §2 unchanged (D6 is an operational
decision, not a scope change).

## 2026-07-22 — Azure SQL apply/destroy workflows: personal-sandbox state backend + Git Bash gotcha
**Context:** Task #9/#17 — wanted GitHub Actions workflows to `terraform apply` the Azure
SQL module into Jess's personal sub, plus a nightly `terraform destroy` (21:00 UK, "we like
to go to bed then") so nothing bills overnight. Needed remote state so apply and destroy —
separate ephemeral runners — see the same state.
**Learning 1 — keep the state storage account out of the workload RG.** The state backend
(`stfabcon26tf4766a4`) lives in its own persistent `rg-fabcon26-state-weu`, never in the
`rg-fabcon26-dev-weu` that `terraform destroy` tears down nightly. Obvious in hindsight, but
worth stating: if the destroy target and the state store shared a resource group, the first
nightly run would delete its own backend.
**Learning 2 — two cron entries means two runs a day, not one.** First tried covering DST
by registering **two** cron triggers (20:00 and 21:00 UTC, one per UK offset) with a gate
step that skipped whichever one didn't land at 21:00 `Europe/London`. That does work, but
it means the workflow **fires twice every day** — one run always a no-op — which is more
confusing in the Actions history than it's worth for a personal sandbox. Settled on a
single fixed **21:00 UTC** cron instead: one run a day, genuinely 9pm in winter (GMT) and
10pm in summer (BST). Worth remembering for anything less forgiving of the drift.
**Learning 3 — Git Bash mangles leading-slash args.** `az role assignment create --scope
"/subscriptions/<id>"` failed with a cryptic `MissingSubscription` error — MSYS/Git Bash's
path conversion was rewriting the `/subscriptions/...` argument as if it were a Windows path
before `az` ever saw it. Fix: prefix the command with `MSYS_NO_PATHCONV=1`. Applies to any
`az`/`gh`/CLI argument that starts with `/` when run from this repo's Bash tool.
**Learning 4 — OIDC federated credential subject matching.** The federated credential
subject `repo:<owner>/<repo>:ref:refs/heads/main` covers both `schedule` events and
`workflow_dispatch` runs launched from `main` (both evaluate to that ref) — no separate
`environment:` subject needed for this simple case.
**Action:** Added [`../.github/workflows/azure-sql-apply.yml`](../.github/workflows/azure-sql-apply.yml)
and [`../.github/workflows/azure-sql-destroy.yml`](../.github/workflows/azure-sql-destroy.yml).
Backend + OIDC wired into `infra/azure-sql/terraform/demo/providers.tf`; `.terraform.lock.hcl`
un-ignored and committed. Repo variables set (`AZURE_CLIENT_ID`, `AZURE_TENANT_ID`,
`AZURE_SUBSCRIPTION_ID`, `TF_STATE_*`, `SQL_ENTRA_ADMIN_*`) — all non-secret with OIDC, so
`vars` not `secrets`. Recorded in `notes/decisions.md` D5 (update) and `planning/tasks.md`
#9/#17. First live `apply` still to be run — task #14.

## 2026-07-22 — Azure Sponsorship subs can be region-restricted below what the RP advertises
**Context:** First real `azure-sql-apply.yml` run (task #14). Resource group created fine
in West Europe, then `azurerm_mssql_server` failed: `ProvisioningDisabled — Subscriptions
are restricted from provisioning in this region`.
**Learning:** `az provider show --namespace Microsoft.Sql` lists West Europe as a perfectly
valid region for `Microsoft.Sql/servers` — that list is the **resource provider's**
supported regions, not a promise that *your subscription* can provision there. This
particular subscription is `quotaId: Sponsored_2016-01-01` (Azure Sponsorship), and new/
sponsorship subscriptions are commonly region-restricted (often exactly the popular EU
regions) independent of RP or quota. There's no clean CLI query for "which regions can
*this* subscription actually provision in" — the practical check is just: try, read the
error. No resources were actually created in Azure before the error (confirmed via `az
resource list` on the resource group — empty), so nothing needed cleaning up beyond the
now-pointless empty resource group.
**Action:** Added `AZURE_LOCATION`/`AZURE_LOCATION_ABBREVIATION` repo variables (`uksouth`/
`uks`) and wired them as `-var` overrides into both `azure-sql-apply.yml` and
`azure-sql-destroy.yml`, rather than changing the module's own default (`westeurope` stays
the documented/taught default — this restriction is specific to this one sandbox
subscription, not the module). Ran `azure-sql-destroy.yml` once to clear the empty
West Europe resource group before switching regions.

## 2026-07-29 — First live Azure SQL apply succeeded in UK South; DACPAC publish job added
**Context:** Re-ran `azure-sql-apply.yml` after merging the region override (PR #11), then
wired the DB-as-code publish step onto the same workflow (tasks #9/#14).
**Learning 1 — the region override worked, single-region as designed.** Run
[`30436925832`](https://github.com/JessAndRob/FabConEU_2026_workshop/actions/runs/30436925832)
went green: **5 resources added** in **UK South** — `rg-fabcon26-dev-uks`,
`sql-fabcon26-dev-uks-lmf5m4` (+ DB `sqldb-football-dev`, allow-Azure-services firewall
rule, random suffix). RG ~24s, server ~1m24s, DB ~2m6s, whole run 4m36s. Confirms the
module is single-region: the DB inherits the server's location which inherits the RG's
`var.location`, so one `location`/`location_abbreviation` pair moves everything together —
there was never a cross-region split, just a half-finished apply on the earlier WEU failure.
**Learning 2 — Entra-only server + human admin blocks CI publish (the real gotcha).** The
server is `azuread_authentication_only = true` with the Entra admin set to a **user**
(`jpomfret7`). A logical SQL server allows exactly **one** Entra admin (user *or* group),
so the GitHub Actions OIDC service principal (`AZURE_CLIENT_ID`) has **no way to log into
the database** — it isn't the admin and, with SQL auth disabled, can't be a SQL login
either. The DACPAC publish job authenticates fine (OIDC → `az account get-access-token
--resource https://database.windows.net/` → SqlPackage `/AccessToken`) but will fail at the
**database login** until the CI principal is granted access. Recommended fix (matches the
module's own advice): make the server's Entra admin an **Entra group** containing both the
presenter and the CI SP, and point `SQL_ENTRA_ADMIN_OBJECT_ID` at the group. Tracked as
task #18.
**Learning 3 — publish wired as a second job on the apply workflow.** The apply job now
exposes `sql_server_fqdn`/`sql_database_name` as job outputs (`terraform output -raw` →
`$GITHUB_OUTPUT`); the `publish` job `needs: apply` and targets them, so one dispatch does
infra + DB. SqlPackage on the Linux runner installs via `dotnet tool install -g
microsoft.sqlpackage` (add `$HOME/.dotnet/tools` to `$GITHUB_PATH`). The token is masked
(`::add-mask::`) — nothing secret persists.
**Action:** Extended [`../.github/workflows/azure-sql-apply.yml`](../.github/workflows/azure-sql-apply.yml)
with the `publish` job. Tasks #9/#14 advanced, #18 added for the CI-SP DB-access
prerequisite. **The publish job is unverified end-to-end** until #18 is done.

## 2026-07-29 — End-to-end "infra + DB as code" verified: Entra group admin unblocks CI publish
**Context:** Closing the #18 auth gap so the DACPAC publish job (#9) could run for real.
**Learning — an Entra *group* as the SQL server admin is what makes passwordless CI
publish work.** Created group `fabcon26-sql-admins`, added the presenters **and** the CI
service principal, then pointed the server's Entra admin at the group (via the
`SQL_ENTRA_ADMIN_LOGIN`/`SQL_ENTRA_ADMIN_OBJECT_ID` repo vars → `terraform apply`, a clean
`1 changed` in-place update of the `azuread_administrator` block). Because the CI SP is now
a *member* of the admin group, its OIDC token authenticates against the DB with no SQL
login and no secret. Two gotchas worth repeating: (1) group membership needs the CI
principal's **service-principal object id** (`az ad sp show --id <appId> --query id`), which
is **not** the app/client id in `AZURE_CLIENT_ID`; (2) a logical SQL server allows exactly
one Entra admin, so a *group* is the only way to admin-grant more than one identity — this
is the reusable pattern for attendees too (one workshop group, everyone in it).
**Result:** Re-ran `azure-sql-apply.yml` (run
[`30441294528`](https://github.com/JessAndRob/FabConEU_2026_workshop/actions/runs/30441294528))
— both jobs green: `apply` 58s, `publish` 1m26s. SqlPackage reported **"Successfully
published database"**, creating all 9 tables + indexes/FKs/checks, 3 views, 3 procs, and
running the post-deploy seed — into `sqldb-football-dev` on `sql-fabcon26-dev-uks-lmf5m4`,
passwordless. First full infra→schema deploy of the workshop's content-focus path.
**Action:** Tasks #9 and #18 → DONE; #14 → Azure SQL side verified at deploy level (Fabric
SQL still open). No file changes — the publish job already shipped in PR #12.

## 2026-07-29 — Post-publish DB smoke test; and two auth/network gotchas testing it
**Context:** Optional polish after the end-to-end deploy — add a data-level smoke test to
the publish job and clear the Node 20 action-deprecation warnings.
**Learning 1 — action bumps to clear the Node 20 warnings.** `hashicorp/setup-terraform@v3`
and `azure/login@v2` both emitted "Node.js 20 is deprecated … forced to run on Node.js 24".
The fix is just newer majors: **`setup-terraform@v4`** (v4.0.1, Feb 2026) and
**`azure/login@v3`** (v3.0.0, Mar 2026), both Node-24 native. Bumped in the apply + destroy
workflows.
**Learning 2 — the OIDC federated credential only trusts `main`, so deploy workflows can't
be test-run from a branch.** Dispatching `azure-sql-apply.yml` on a feature branch fails at
`terraform init` with `AADSTS700213: No matching federated identity record found for
presented assertion subject 'repo:…:ref:refs/heads/<branch>'`. The credential subject is
`repo:JessAndRob/FabConEU_2026_workshop:ref:refs/heads/main` (see the 2026-07-22 entry), and
the OIDC subject for a branch run is that branch's ref — no match, no token. Practical
consequence: **these workflows can only be verified after merging to `main`** (or by adding
a branch/environment federated credential, which we deliberately don't for a sandbox).
**Learning 3 — GitHub-hosted runners pass `AllowAzureServices`, external clients don't.**
The server's only firewall opening is the `0.0.0.0` "allow Azure services" rule. That's why
the publish job connects fine — **GitHub-hosted runners run on Azure**, so they count as an
Azure service. A developer machine (or this agent's sandbox IP) is *not* Azure-internal and
gets `Client with IP address '…' is not allowed to access the server`, even with a valid
Entra token (the login is accepted; the network ACL is what blocks). To smoke-test from
outside, add a temporary `az sql server firewall-rule create` for your IP and remove it
after.
**Learning 4 — the smoke test itself.** A `pwsh` step installs the `SqlServer` module and
uses `Invoke-Sqlcmd -AccessToken` (reusing the publish job's Entra token — no new secret) to
assert the deployed schema *serves data*: rows from `Club`, `Fixture`, `vw_LeagueTable`,
`vw_TopScorers`, and `usp_GetLeagueTable` (called with a competition/season pulled from the
league-table view). `vw_UpcomingFixtures` is executed but not row-asserted — it's
date-relative (`GETDATE()`), so it can legitimately be empty as seeded fixtures age.
**Verified against the live UK South DB** (via a temporary firewall rule): all checks OK,
proc returned a 2-row table. The in-pipeline run is pending a merge to `main` (Learning 2).
**Action:** Bumps + smoke-test step in
[`../.github/workflows/azure-sql-apply.yml`](../.github/workflows/azure-sql-apply.yml) and
the setup-terraform bump in
[`../.github/workflows/azure-sql-destroy.yml`](../.github/workflows/azure-sql-destroy.yml).
Confirms task #14's Azure SQL side at the data level.

## 2026-07-29 — Plan on PR (read-only), apply stays manual — needs a `pull_request` FIC
**Context:** The only Azure SQL infra workflow was `azure-sql-apply.yml` — a manual apply
whose very name reads as dangerous — and there was no way to see an infra change's effect
before merging. Added a read-only check (chosen over a tag-based apply credential).
**Learning — the idiomatic split is *plan on PR, apply on intent*, and each ref-context
needs its own OIDC federated credential.** New `azure-sql-plan.yml` runs
`fmt`/`validate`/`plan` — **never apply** — on `pull_request` events touching
`infra/azure-sql/**`, so reviewers see the plan in the PR checks; provisioning stays a
deliberate `workflow_dispatch` apply from `main`. The catch that makes this non-obvious: a
`pull_request` run's OIDC subject is `repo:<owner>/<repo>:pull_request`, which the existing
`…:ref:refs/heads/main` credential does **not** cover — so plan needs a *second* federated
credential (`fabcon26-github-pr`, subject `…:pull_request`) on the same app registration.
Read-only details: plan uses **`-lock=false`** (a plan never mutates state, so it must not
contend for the state lock with a running apply/destroy) and reads the same remote state
key, so it reports true drift. Verified green on its own PR (#15) — *"No changes. Your
infrastructure matches the configuration."* (the DB was still up from the earlier apply).
Security note: the `pull_request` credential lets any same-repo PR mint a token with the
app's `Contributor` rights — fine for a private repo with trusted collaborators; a scoped
read-only identity is the hardening step if the repo ever opens up. A **tag**-based
credential was considered and rejected: it would only add another way to run *apply* from
outside `main`, which doesn't address the safety concern — plan-on-PR does.
**Action:** Added [`../.github/workflows/azure-sql-plan.yml`](../.github/workflows/azure-sql-plan.yml)
and the `fabcon26-github-pr` federated credential; recorded in `decisions.md` D5 (update).
Resolves the "scary apply" concern and, for the read path, the branch-can't-authenticate
limitation noted in the smoke-test entry above.

## 2026-07-29 — Bicep reference modules: Azure SQL mirrors fully, Fabric can only do the capacity
**Context:** Task #6 — the Bicep reference variant of the infra ("all as code": every tooling
variant exists even though the taught content leads with Terraform).
**Learning 1 — Azure SQL maps cleanly to Bicep, with a few ARM-vs-Terraform seams.** A
subscription-scoped `main.bicep` creates the RG and calls an RG-scoped `sql.bicep`
(server + serverless DB + firewall) — the idiomatic Bicep shape for "make the RG too".
Passwordless is `Microsoft.Sql/servers` `properties.administrators` with
`azureADOnlyAuthentication: true` and **no** SQL admin login. Seams worth noting: (a) Bicep
has **no decimal type**, so `minCapacity` (0.5) is passed as a string and converted with
`json()`; (b) the globally-unique server suffix is `take(uniqueString(resourceGroup().id), 6)`
(the deterministic stand-in for Terraform's `random_string`); (c) the DB `sku` is verbose
(`name`/`tier`/`family`/`capacity`) where Terraform takes a single `sku_name`, so a
provisioned SKU needs matching tier/family/capacity; (d) firewall loop uses
`items(allowedClientIps)` over the map.
**Learning 2 — Fabric SQL can NOT be fully done in Bicep, and that's the teaching point.**
Only the **capacity** is an ARM resource (`Microsoft.Fabric/capacities`). The **workspace**
and the **SQL database in Fabric** are Fabric control-plane items with **no ARM resource
type at all** — Bicep/ARM simply can't create them. So the Fabric Bicep provisions the
capacity only and documents the gap; the full `capacity → workspace → database` stack needs
the Terraform `microsoft/fabric` provider (#5) or the Fabric REST API/CLI. This is exactly
why the taught IaC path is Terraform, not Bicep, for Fabric.
**Learning 3 — validate Bicep offline with `az bicep build`.** `az bicep build --file x.bicep`
compiles to ARM JSON with no Azure connection (install once via `az bicep install`);
`az bicep build-params` validates a `.bicepparam`. All four templates + both param files
compile clean with **zero linter warnings**. `az deployment sub what-if` is the next step up
(needs Azure) for a real preview.
**Action:** Added [`../infra/azure-sql/bicep/`](../infra/azure-sql/bicep/) (`main.bicep`,
`sql.bicep`, `main.bicepparam`) and [`../infra/fabric-sql/bicep/`](../infra/fabric-sql/bicep/)
(`main.bicep`, `capacity.bicep`, `main.bicepparam`); both READMEs rewritten. Task #6 → DONE.
Live deploy still tracked by #14.

## 2026-07-29 — Azure DevOps reference pipelines: WIF is the OIDC equivalent
**Context:** Task #10 — the Azure DevOps reference variant of the CI/CD pipelines ("all as
code"; taught path stays GitHub Actions).
**Learning — the passwordless story ports cleanly, the mechanics differ.** Where GitHub
Actions uses **OIDC federated credentials**, Azure DevOps uses an **ARM service connection
configured for workload identity federation (WIF)** — same "no secrets" outcome. The bridge
to Terraform: `AzureCLI@2` with **`addSpnToEnvironment: true`** exposes `$servicePrincipalId`,
`$idToken`, `$tenantId` to the inline script, which exports them as `ARM_CLIENT_ID` /
`ARM_OIDC_TOKEN` / `ARM_TENANT_ID` + `ARM_USE_OIDC=true` — Terraform then auths exactly like
in CI on GitHub. Other mappings worth noting: GH repo **variables** → an ADO **variable
group** (`fabcon26-azure-sql`); `workflow_dispatch` → `trigger: none` + manual run; GH `cron`
→ ADO `schedules:` (also UTC) with **`always: true`** (ADO skips scheduled runs with no new
commits otherwise); job-to-job `outputs` → `##vso[task.setvariable ...;isOutput=true]` read
downstream via `stageDependencies.<Stage>.<job>.outputs['<step>.<var>']`; adding a dir to
`$PATH` → `##vso[task.prependpath]`. Terraform is preinstalled on the hosted `ubuntu-latest`
image (or pin via the `TerraformInstaller@1` extension task). The DACPAC publish + smoke test
reuse the same Entra-token approach as GHA. **Not executed** — no ADO org in this repo — but
all four YAML files parse and follow the schema; GitHub Actions remains the live-verified path.
**Action:** Added [`../infra/pipelines/azure-devops/`](../infra/pipelines/azure-devops/)
(`ci.yml`, `azure-sql-plan.yml`, `azure-sql-apply.yml`, `azure-sql-destroy.yml`) + README.
Task #10 → DONE.

## 2026-07-29 — Fabric SQL CI/CD: verified the Fabric-specific bits against MS Learn, then built the pipeline
**Context:** Task #20 — the Fabric mirror of the Azure SQL pipeline (#9). Before writing it,
verified the three things that differ from Azure SQL against Microsoft Learn.
**Learning 1 — dual-provider OIDC.** The job needs *two* passwordless auths: `azurerm`
(`ARM_*`, for the `Microsoft.Fabric/capacities` resource + the state backend) **and** the
`microsoft/fabric` provider (`FABRIC_USE_OIDC=true` + `FABRIC_CLIENT_ID` + `FABRIC_TENANT_ID`).
In GitHub Actions the fabric provider **auto-detects** `ACTIONS_ID_TOKEN_REQUEST_URL/TOKEN`
(so `id-token: write` is all the extra wiring). Same OIDC app as Azure SQL — reuse
`AZURE_CLIENT_ID`/`AZURE_TENANT_ID`.
**Learning 2 — SqlPackage → Fabric needs two extra publish properties.** A DACPAC built for a
non-Fabric platform is refused unless you set **`AllowIncompatiblePlatform=True`**, and
**`ExcludeObjectTypes=Logins;Users`** avoids compat problems (Fabric has no logins). Added
both to `FabricSql.publish.xml` (belt-and-braces for us — our schema has neither). The DB must
already exist (the module provisions it); endpoint is `…database.fabric.microsoft.com,1433`;
token audience is the same `https://database.windows.net/` as Azure SQL. Source:
[Fabric SqlPackage](https://learn.microsoft.com/en-us/fabric/database/sql/sqlpackage).
**Learning 3 — the #18 analog is simpler in Fabric, but there's a hard tenant gate.** Fabric
SQL is Entra-only (no SQL auth/logins). The CI principal needs **Read item permission** via a
**Fabric workspace role** — with Fabric access controls you *don't* need manual
`CREATE USER` (unlike a raw contained user). BUT a **tenant admin must enable "Service
principals can use Fabric APIs"** or SPs can't connect at all — this is the real blocker, and
no pipeline/Terraform can flip it. Source:
[Fabric SQL authentication](https://learn.microsoft.com/en-us/fabric/database/sql/authentication).
**Learning 4 — cost shape.** An F-SKU capacity **bills continuously** (no serverless
auto-pause), so the nightly `fabric-sql-destroy.yml` matters more than the Azure SQL one; a
future `use_existing_capacity` toggle would let trial-capacity users avoid the F2 charge
(trial capacities can't be Terraform-created).
**Action:** Wired the remote backend into `infra/fabric-sql/terraform/providers.tf`
(state key `fabric-sql/dev.terraform.tfstate`); added the two publish properties; added
[`../.github/workflows/fabric-sql-plan.yml`](../.github/workflows/fabric-sql-plan.yml),
[`fabric-sql-apply.yml`](../.github/workflows/fabric-sql-apply.yml), and
[`fabric-sql-destroy.yml`](../.github/workflows/fabric-sql-destroy.yml). YAML + `fmt` clean.
**Untested end-to-end** — blocked on the tenant setting + workspace role + a capacity (task
#20; live verify is the Fabric side of #14).

## 2026-08-04 — "Ship changes as code" designed around a DB `plan` and the guard we already ship
**Context:** Task #15 — designing the PR-driven schema-change increments for the 15:30 module.
**Learning:** The clean framing is *"a database change is a PR, and the pipeline shows you what
it will do to your data before it does it"* — the DB analog of `terraform plan`, driven by
**`sqlpackage /Action:DeployReport`** (emits the would-be operations incl. `DataIssue`
data-loss alerts, applies nothing). The punchline demo (drop the populated
`Player.ShirtNumber`) needs almost no new safety code because **our publish profiles already
set `BlockOnPossibleDataLoss=True`** — so the "good path" is: the report flags the drop on the
PR, and the guard makes a blind publish fail loudly instead of silently losing data. "Manual
apply" = a **GitHub Environment required-reviewer gate**, not an out-of-band step (still
as-code). Nice reuse: the seed already populates `ShirtNumber`, so the data loss is real with
zero extra setup. Same flow on Azure SQL and Fabric SQL (per-target profile only).
**Action:** Designed in [`../planning/ship-changes-increments.md`](../planning/ship-changes-increments.md);
task #15 → DONE, implementation split out as #21. Answered the open questions in
[`Ideas.md`](Ideas.md).

## 2026-08-04 — "Ship changes" demo built as runnable artifacts; DeployReport is the DB's `plan`
**Context:** Task #21 — turning the #15 design into the actual demo. Built the demo-as-code
first (the reusable teaching content), before the CI wiring.
**Learning:** The three increments live in [`../database/demo/ship-changes/`](../database/demo/ship-changes/)
as real, copy-into-the-project SQL + a follow-along `README` with the exact commands — not just
prose. Two things worth recording: (1) **`sqlpackage /Action:DeployReport` is the "database
plan"** — it emits an XML report of what a publish *would* do, including `<Alert
Name="DataIssue">` for a column drop, and (per MS Learn) it flags the data-loss *operation*
from the schema diff, so it surfaces the risk **before** any deploy. (2) The "good path" needed
almost no new safety code — our publish profiles already ship `BlockOnPossibleDataLoss=True`,
so a blind publish **fails loudly** instead of silently dropping the populated `ShirtNumber`;
the demo just contrasts that with a throwaway `/p:BlockOnPossibleDataLoss=false`. Schema-fidelity
gotcha while writing the views: `Team` has **no `Name`** — a team's display name is
`Club.Name` + `Category` (the men's/women's split), so `vw_TeamRosterSizes` joins `Club`.
Can't build/verify locally — `global.json` pins .NET **8** (`rollForward: latestMinor`) and this
box only has .NET 9 + no SqlPackage; validation happens in CI / against a live DB.
**Action:** Added the demo folder; task #21 → DOING (content done; the `deploy-report` CI job,
Dev→Test approval gate, and naive-publish workflow remain, best done against a live DB).

## 2026-08-04 — DeployReport in CI: it's `/OutputPath`, not `/DeployReportPath` — validated live
**Context:** Wiring the "database plan" (`sqlpackage /Action:DeployReport`) into
`azure-sql-apply.yml` before the publish step (task #21).
**Learning:** The SqlPackage **DeployReport** CLI action writes its XML with **`/OutputPath:`**.
`/DeployReportPath` is an **MSBuild property**, not a CLI arg — passing it fails the action with
*"'DeployReportPath' is not a valid argument for the 'DeployReport' action."* A live
`azure-sql-apply` run caught this (the step failed before publish); the branch-only checks
couldn't, because the OIDC federated credential only trusts `main`, so the deploy workflow can
only be exercised after merge (recurring theme). Fixed → re-ran → green. The report's shape is
useful to know for the demo: `<DeploymentReport><Alerts/><Operations>…</Operations>` — against
a **fresh/empty** DB `Alerts` is empty and every object is a `Create`; a **column drop against a
populated** DB is where an `<Alert Name="DataIssue">` (possible data loss) shows up. So the
pipeline now emits a real "DB plan" artifact before every publish, and the same grep that shows
"None reported" here will surface the data-loss alert in the #15/#21 demo.
**Action:** `/OutputPath` fix in [`../.github/workflows/azure-sql-apply.yml`](../.github/workflows/azure-sql-apply.yml)
and the demo README; deploy-report step live-verified (run `30902247159`, whole apply→report→
publish→smoke pipeline green). Task #21 advanced.

## 2026-08-04 — GitHub Environment approval gates need a paid plan on private repos
**Context:** Wiring the #15/#21 "manual approval" gate as a **GitHub Environment required
reviewer** on the deploy job.
**Learning:** On a **private** repo, environment **protection rules** (required reviewers *and*
wait timer) require **GitHub Team or Enterprise** — they're only free on public repos. The API
`PUT …/environments/{name}` creates the bare environment on any plan, but adding a
protection rule returns **`422 — Please ensure the billing plan supports the … protection
rule`** (hit this even though `orgs/…/plan.name` reported "team" — worth checking billing/seats
in the UI). Second gotcha for when it *is* enabled: referencing `environment: <name>` on a job
changes that job's **OIDC `sub` claim** to `repo:<org>/<repo>:environment:<name>`, so the deploy
principal needs a **third federated credential** for that subject (like the `pull_request` one we
added) or `azure/login` fails with AADSTS700213. So the gate is a *coordinated* change (env rule
+ FIC + YAML), not a one-liner.
**Decision:** Left the gate **documented** (the production-grade pattern is in
[`../database/demo/ship-changes/increment-3_safe-retire.md`](../database/demo/ship-changes/increment-3_safe-retire.md))
rather than wired, since it can't be enforced on this repo's plan; deleted the bare `production`
environment to keep things clean. Task #21 note updated.

## 2026-08-06 — Cross-tenant Terraform: state in one tenant, infra in another (Fabric SQL)
**Context:** Task #20 — the Fabric SQL infra + DB deploy had to run in a *different* tenant /
subscription / client (**Tenant B**) than the Azure SQL work and the Terraform state backend
(**Tenant A**), without touching any Azure SQL wiring.
**Learning:** The reusable *separation-of-duties* pattern — **state in one subscription, the infra
it describes in another** — comes down to splitting the azurerm **backend** from the azurerm
**provider**, which both default to reading `ARM_*`. The clean split: leave the **backend** on the
`ARM_*` env (Tenant A) and **pin the provider explicitly in `providers.tf`** (`subscription_id` /
`client_id` / `tenant_id` / `use_oidc` from vars = Tenant B). Explicit provider args beat the
`ARM_*` env, so backend and provider authenticate to different tenants **in one `terraform` run**.
The `microsoft/fabric` provider uses its own `FABRIC_*` env (no clash), and the DACPAC publish's
`azure/login` moves to Tenant B. One GitHub OIDC token is exchanged at *both* tenants — so Tenant B
needs its own app registration with `main` + `pull_request` federated credentials (mirroring
Tenant A). Two gotchas worth keeping: (1) `azurerm_fabric_capacity.administration_members` takes
**users by UPN** and **service principals by object id** — and the module now *always* includes the
deploying caller as a capacity admin (an explicit list previously *replaced* it, which would break
the workspace→capacity assignment); (2) the Tenant B CI app needs **User Access Administrator** on
top of Contributor so Terraform can create the automation identity's custom role + assignment as
code.
**Also landed (task #23):** a **persistent Azure Automation** (its own state key) that pauses the
Fabric capacity **every 2h** and resumes **on demand** via PowerShell runbooks under a
system-assigned managed identity with a sub-scoped least-privilege custom role. The runbooks
**discover the capacity by its (stable) resource group** because the capacity name is random and
nightly-recreated. Since pausing preserves the workspace + DB + data (unlike destroy), the nightly
Fabric destroy is now a candidate to relax.
**Action:** Module + workflows rewired; `infra/fabric-sql/automation/` added; Tenant B setup
documented in [`../infra/fabric-sql/CROSS-TENANT-SETUP.md`](../infra/fabric-sql/CROSS-TENANT-SETUP.md).
Design [`../planning/2026-08-05-fabric-cross-tenant-automation-design.md`](../planning/2026-08-05-fabric-cross-tenant-automation-design.md),
plan [`../planning/2026-08-06-fabric-cross-tenant-automation-plan.md`](../planning/2026-08-06-fabric-cross-tenant-automation-plan.md).
Branch `feat/fabric-cross-tenant-automation`; tasks #20 advanced, #23 added. Live plan→apply is the
next step (the long-blocked Fabric side of #14).

## 2026-08-04 — Attendee site skeleton: 12 templated stubs, held in teaser mode
**Context:** Task #22 — turning the attendee site from a lone teaser into the full workshop
shape. Designed the content system first (a [spec](../planning/2026-08-04-attendee-content-design.md)
+ [plan](../planning/2026-08-04-attendee-content-skeleton-plan.md) via the brainstorming/
writing-plans flow), then built **Phase 1**: the page skeleton.
**Learning:** Held the whole skeleton out of the published site with **`exclude_docs`** while
keeping `mkdocs build --strict` green. The key property: an excluded page is dropped from the
build entirely, so it neither publishes nor trips the strict *"page exists but not in nav"* check
— **and its own internal links aren't validated either**. So a stub can link `[Prerequisites]` /
`[What's next]` to other held pages and strict stays happy; the only rule is that the one *built*
page (`index.md`) must not link to a held page (verified with a grep). Confirmed the teaser build
emits exactly `index.html` + `404.html` with all 12 stubs present in the repo. Toolchain note for
a Debian box: system pip is PEP 668 *externally-managed*, so mkdocs went in a throwaway **venv in
the scratchpad** (never in the repo — nothing to gitignore or accidentally commit) and the build
wrote to a scratch `site/` dir, keeping the working tree clean. **Reveal stays a one-PR diff** —
drop the `exclude_docs` entries and uncomment the nav, both already staged in `mkdocs.yml`.
**Action:** 12 stub pages under `docs/` (setup / foundations / infra / database / cicd / wrap-up /
reference) on a shared 9-section template, plus the full commented nav. Branch
`docs/attendee-content-skeleton`. Task #22 → DOING (Phase 1 done; Phase 2 = flesh the prerequisites
page #2, Phase 3 = polish the Azure SQL core, each its own branch).

## 2026-08-06 — PowerShell `$var:` scope syntax silently corrupts OIDC federated-credential subjects
**Context:** The first cross-tenant `fabric-sql-plan` failed at the azurerm-provider token
exchange with `AADSTS700213 — No matching federated identity record found for subject
repo:JessAndRob/FabConEU_2026_workshop:pull_request`, even though a `fabcon26-fabric-pr` federated
credential existed on the Tenant B app.
**Learning:** The credential existed but its **subject was missing the repo** — stored as `repo:`
and `repo:/heads/main` instead of the full `repo:<org>/<repo>:pull_request` /
`…:ref:refs/heads/main`. Cause: the setup built the subject in a **double-quoted** here-string as
`"repo:$repo:pull_request"`, and PowerShell parses `$repo:pull_request` as a **namespaced
variable** (`$scope:name`, exactly like `$env:PATH`) — so `$repo` is dropped and the `:pull_request`
tail is swallowed. Fix: delimit with **`${repo}`** (`"repo:${repo}:pull_request"`), or use a
single-quoted here-string with the repo hard-coded. Diagnostic that pinpoints it:
`az ad app federated-credential list --id <appId> --query "[].{name:name,subject:subject}" -o table`
— **AADSTS700213 means the app was found but no subject matched** (credential present ≠ correct).
**Action:** Recreated both subjects (`main` + `pr`); patched
[`../infra/fabric-sql/CROSS-TENANT-SETUP.md`](../infra/fabric-sql/CROSS-TENANT-SETUP.md) to use
`${repo}` + a warning. Unblocks the first live Fabric plan (tasks #20).

## 2026-08-17 — The people module goes to the front of the day, and the morning pays for it
**Context:** Rob wanted the "hardest part of IT" hook — the egos-and-feelings bit, written up
in `README.md` under "👉 Start here" — promoted from a repo-front line into an actual agenda
module, at 09:30, ahead of any tech.
**Learning:** A full-day agenda that already runs 09:00–17:00 has **no slack** — the 30 minutes
had to come out of the same morning, because the 11:00 break, 12:45 lunch and 17:00 end are
fixed. Three sources, in order of how painless they were: the environment check (25 → 10 min;
it's bring-your-own per D6, so individual help belongs in the breaks, not the room's time);
splitting the Azure SQL Terraform module **across** the 11:00 break so `terraform apply` runs
while everyone's at coffee (same 45 min of teaching, 15 minutes of waiting deleted); and
SQL projects 45 → 30, which is the one genuine squeeze on a focus module. The afternoon was
left completely untouched — worth preserving as a property, it makes the change reviewable.
**Action:** [`../agenda/agenda.md`](../agenda/agenda.md) rebuilt (new 09:30 row, hook text in
Rob's voice under the table, plus a "where the 30 minutes came from" note so the trade is
auditable at the dry run). Task **#24** added to build the module content; the SQL-projects
squeeze is explicitly flagged for **#13** (dry run) — if 30 min doesn't hold, take it back from
the 16:15 block. **Doc nit spotted, not fixed:** this file's header says "Newest entries at the
top" but every entry is appended at the bottom above the `<!-- Add new entries -->` marker —
one of the two is wrong and should be settled.

## 2026-08-17 — The repo had no `.gitattributes`, and it made every file look modified
**Context:** Committing the agenda change (above), `git status` reported **all 102 files
modified** — 7,600 insertions against 7,549 deletions — despite only three files being touched.
**Learning:** Every file on disk was **CRLF** while the index held **LF**, with no
`.gitattributes` and `core.autocrlf` unset, so git saw each file as a whole-file rewrite. Real
diffs become unreviewable — a three-line agenda edit is indistinguishable from a rewrite of the
Terraform modules, which is exactly the failure mode PR review is supposed to prevent. Note
that `git add --renormalize .` does **nothing** until `.gitattributes` exists — the renormalise
uses whatever attributes are in force at the time, so the order is: add the file, *then*
renormalise.
**Action:** Added [`../.gitattributes`](../.gitattributes) — `* text=auto` plus explicit
`eol=lf` for `*.sh` (Linux runners), `eol=crlf` for `*.bat`/`*.cmd`, and `binary` for images and
`.dacpac`/`.bacpac`. Renormalise + commit run by hand on Windows (see below).
**Second learning — git can't be driven from a Cowork cloud session over the device bridge.**
The bridge mount is deletion-restricted, so git cannot unlink `.git/index.lock` after an index
operation: the lock survives, and the *next* git command dies with "Another git process seems to
be running." It also strands `tmp_obj_*` files under `.git/objects`. Reads and file edits over
the bridge are fine; **anything that writes the git index must be run on the Windows box** (or
in a Cowork session running *on the computer* rather than in the cloud). Leftovers from this
session were quarantined in `.git/_cowork_to_delete/` — safe to delete.

## 2026-08-20 — `use_existing_capacity` toggle: bind to a capacity we pause, never destroy
**Context:** We now have a **persistent paid F-SKU** (`cappymccapface` in `fabcon-demo-rg`,
Tenant B) to run the first live Fabric apply against, rather than creating/nightly-destroying an
F2. The module always created the capacity; needed a way to *use ours* and guarantee Terraform
can never tear it down. Also pruned all merged branches and tracked the slides deck (#25).
**Learning 1 — the fabric provider gives you the correct binding id; azurerm's `.id` may not.**
`terraform providers schema -json` (microsoft/fabric v1.13) shows `fabric_workspace.capacity_id`
wants **"the ID of the Fabric Capacity"** — the Fabric **GUID** — and there's a
**`data "fabric_capacity"`** that resolves a capacity **by `display_name` tenant-wide** to exactly
that GUID (no resource group needed for the lookup). That flagged a **latent risk in the untested
create path**: it binds `capacity_id = azurerm_fabric_capacity.this.id`, which is the **ARM resource
id**, not the GUID. Left the create path as-is (can't live-test it today) with a `# KNOWN RISK`
comment; the existing path uses `data.fabric_capacity.existing[0].id` (unambiguously the GUID). If
the first *create-mode* apply rejects the ARM id, resolve the created capacity via
`data.fabric_capacity` too. Reinforces the repo's standing rule: **confirm provider shapes against
`providers schema -json`, not the registry docs.**
**Learning 2 — `count = 0` is the teardown guarantee.** With `use_existing_capacity = true` the
capacity is a **read-only data source** and the `azurerm_fabric_capacity` / `azurerm_resource_group`
resources drop to `count = 0`, so they're **never in state** — `terraform destroy` provably cannot
touch the capacity (or its RG); it removes only the workspace + SQL DB. Cost control becomes
**pause, not destroy** (pausing preserves workspace/DB/data), so the **nightly 21:00 destroy cron
was disabled** (commented out; manual `workflow_dispatch` kept) — leaving it on would wipe the DB we
just deployed onto a persistent capacity every night. Re-enable the cron only if we revert to the
module creating its own F-SKU.
**Learning 3 — drive the mode from a repo variable with a safe default.** Workflows pass
`TF_VAR_use_existing_capacity: ${{ vars.FABRIC_USE_EXISTING_CAPACITY || 'false' }}` — unset ⇒ the
taught create-as-code path still works; set to `true` ⇒ existing-capacity mode. Needs three Tenant B
repo vars: `FABRIC_USE_EXISTING_CAPACITY=true`, `FABRIC_EXISTING_CAPACITY_NAME=cappymccapface`,
`FABRIC_EXISTING_CAPACITY_RG=fabcon-demo-rg`.
**Action:** Toggle in [`../infra/fabric-sql/terraform/`](../infra/fabric-sql/terraform/) (main /
variables / outputs / tfvars.example / README) + the three `fabric-sql-*` workflows;
`.terraform.lock.hcl` generated & kept (repo convention). `fmt`/`validate` clean offline; **live
plan→apply is the next step** (still after a merge — OIDC only trusts `main`). Tasks #20/#14
advanced, #25 added (slides). **Still needs: set the 3 repo vars, then run `fabric-sql-plan` on the
PR and `fabric-sql-apply` after merge.**

## 2026-08-20 — First live Fabric deploy end-to-end; two access gotchas on the way
**Context:** Straight after the `use_existing_capacity` toggle merged (PR #33), took the Fabric
path live for the first time against our persistent paid F-SKU **`cappymccapface`** (`fabcon-demo-rg`,
Tenant B) — the long-blocked Fabric side of #14/#20.
**The milestone:** `fabric-sql-apply` went **green end-to-end** (run `32393958396`): `terraform apply`
= *2 added* (workspace + SQL DB), capacity untouched; DACPAC publish = **"Successfully published
database"**; smoke test passed (every seeded view + `usp_GetLeagueTable` returning rows on the real
Fabric SQL DB). First working "infra + DB as code" deploy to Fabric, side by side with Azure SQL.
**Gotcha 1 — `data.fabric_capacity` only sees capacities the CI SP is a capacity ADMIN of.** The
first `fabric-sql-plan` failed: *"Unable to find Capacity with 'display_name': cappymccapface"* —
even though auth succeeded (no `AADSTS700213`; the fabric provider queried the API fine). The
`fabric_capacity` **data source lists capacities the principal can see**, and a capacity we created
out-of-band doesn''t include the CI SP. In *create* mode the module auto-adds the deploying SP as a
capacity admin, so this never surfaced; for an *existing* capacity it''s the Fabric analog of #18 —
a one-time out-of-band grant. **Also ruled out** as red herrings first: a *paused* capacity (resumed,
still failed) and a display-name typo. **Least-privilege note (parked, issue-worthy):** capacity
**admin** is more than needed — Fabric **"Capacity contributor"** lets a principal assign workspaces
without admin; but the list-capacities API may not return contributor-only capacities, so the truly
minimal setup is to **pass the capacity GUID directly** (drop the data source) + grant contributor.
We took admin for now to get moving.
**Gotcha 2 — a workspace created by an SP is invisible to humans.** After the apply, Jess/Rob
couldn''t see the workspace: its creator (the CI SP) is the **only member**. Fix = grant them the
**Admin** role **as code** via `fabric_workspace_role_assignment` (PR #34, `workspace_admin_object_ids`
→ repo var `FABRIC_WORKSPACE_ADMIN_OBJECT_IDS`, a JSON array of **Entra USER object ids** — GUIDs,
**not** UPNs; principal `type = "User"`). Must be as-code because the workspace is recreated on every
apply — a portal grant wouldn''t survive. Plan confirmed *2 role assignments to add, 0 change, 0
destroy* (workspace/DB/capacity untouched).
**Gotcha 3 (design, not bug) — pause ≠ destroy, so the nightly-destroy question reopened.** With the
every-2h capacity pause already zeroing overnight cost, a nightly *destroy* is now only about a
**clean slate each morning**, not money — and destroying Fabric items needs the capacity **resumed**
first (resume → destroy → re-pause). Captured as a decision for Rob in **issue #35** rather than
silently wiring it.
**Process note — the fabric provider schema is the source of truth.** Used
`terraform providers schema -json` (via a temp `backend "local"` override, since `providers schema`
needs backend init) to confirm both `data.fabric_capacity` (look up by `display_name`) and
`fabric_workspace_role_assignment` (`principal = { id, type }` object, not a block) *before* writing —
no validate cycles wasted, per the standing rule.
**Action:** Toggle + workspace-admin grant shipped (PRs #33/#34, merged); repo vars set
(`FABRIC_USE_EXISTING_CAPACITY`, `FABRIC_EXISTING_CAPACITY_NAME/RG`, `FABRIC_WORKSPACE_ADMIN_OBJECT_IDS`).
Tasks #14 (**Fabric side now verified end-to-end**) and #20 updated. Open follow-ups: nightly-teardown
decision (issue #35), least-privilege contributor+GUID refactor, and a possible PR-time plan comment.

## 2026-08-23 — Demos mapped onto the five-section agenda; CI now validates infra too
**Context:** Status pass — "where are we, what's left, what demos go where, is the base
complete?" The base (both Terraform modules, both pipelines, the SQL project) is built and
**live-verified end to end on Azure SQL and Fabric SQL**; the review surfaced three genuine
"base" gaps and one drift problem.
**Learning 1 — the agenda restructure orphaned the demo docs.** `agenda.md` was rebuilt into
**five teaching sections**, but the ship-changes design doc, its demo README, and the
`Ideas.md` seed still pointed at the old **"15:30 module."** That per-30-min module map no
longer exists. Fixed the *living* docs to point at the afternoon sections (increments 1–2 →
Afternoon 1, increment 3 → Afternoon 2); deliberately **left the append-only log and the
dated `2026-08-04-*` planning snapshots alone** (rewriting a timestamped record falsifies
history — same reason this file's old entries keep their original times).
**Learning 2 — the coffee-break apply trick died with the restructure.** The 2026-08-17 plan
hid the Azure SQL `terraform apply` behind the 10:30 break by splitting the module across it.
In the five-section agenda **IaC (Morning 2) sits entirely *after* the break**, so there's
nowhere to hide ~4–5 min of provisioning — the apply now runs live inside the block (kick off
early, narrate the module while it runs; Fabric is faster because the capacity is
pre-provisioned). Flagged Morning 2 as the section most at risk of overrun for the dry run (#13).
**Learning 3 — CI validated our SQL + docs but not the infra it ships.** `ci.yml` had only
`database` + `docs` jobs, so a broken Terraform/Bicep change passed CI. Added **`terraform`**
(`fmt -check -recursive` + per-module `validate` with **`init -backend=false`** so it needs no
Azure creds — the committed `.terraform.lock.hcl` pins providers) and **`bicep`**
(`az bicep install` → `az bicep build` templates + `build-params`), both **path-gated** with
`dorny/paths-filter` like the docs job so unrelated PRs don't pay for them. YAML validated;
live-verify on the next PR touching each area (the deploy workflows' OIDC-only-trusts-`main`
limit doesn't apply here — these jobs are credential-free).
**Action:** `agenda.md` gained a per-section demo map (M1 source-control → A2 pulling-together,
each naming the driving workflow/module); stale "15:30" refs fixed in
[`ship-changes-increments.md`](../planning/ship-changes-increments.md),
[`ship-changes/README.md`](../database/demo/ship-changes/README.md), and [`Ideas.md`](Ideas.md);
`terraform`+`bicep` jobs added to [`../.github/workflows/ci.yml`](../.github/workflows/ci.yml).
Task **#8 → DONE**. Open base gaps still tracked: **#12** (code-bundle packaging — attendee
downloads), and Flyway + dbatools/dbops are still **README-only stubs** vs CLAUDE.md's
"all as code" (fine as pointers if we decide that consciously — worth a decision).

## 2026-08-28 — Morning-of readiness checklist captured from the operational gotchas
**Context:** Planning the run-of-day. Realised the demo environment is **not** standing when we
walk in — nightly destroy (21:00 UTC) wipes the infra and the Fabric capacity auto-pauses every
2h — so "be demo-ready" is an actual procedure, not a given.
**Learning:** The morning setup is fully derivable from gotchas already logged, and they cluster:
(1) both `*-apply` workflows must be re-dispatched **from `main`** (OIDC only trusts main) to
rebuild infra + republish the DACPAC; (2) the Fabric capacity must be **resumed to `Active`**
before anything Fabric resolves; (3) `az login` to **both tenants** (the Fabric path is
cross-tenant); (4) the Fabric **workspace-admin grant re-applies** on every apply because the
workspace is recreated; (5) any laptop-to-DB demo needs a **temporary firewall rule** (external
clients are blocked). Site reveal (drop `exclude_docs` + uncomment nav) should happen **early, not
live**.
**Action:** Wrote [`../planning/morning-of-checklist.md`](../planning/morning-of-checklist.md);
added task **#28**. Standalone eval flagged the real gap as **content + a timed dry run** (#13,
#22, #24, #25), not code — the core "infra + DB as code" path is proven live on both platforms.

## 2026-08-28 — Docs-accuracy sweep: pages drift behind the code that ships underneath them
**Context:** Asked to check the whole attendee site was up to date. Read every page and diffed
its factual claims against `tasks.md`, `LEARNINGS.md`, and the actual code.
**Learning:** Three real drifts, all "the code moved, the prose didn't": (1) the Fabric SQL page
**and** the CI/CD-part-3 Fabric tab still said the Fabric apply was *pending*, though it went live
end-to-end on 2026-08-20 (#20); (2) the **build & validate** page described `ci.yml` as two jobs
(database + docs) when #8 grew it to **four** (added terraform `fmt`/`validate` + bicep `az bicep
build`) on 2026-08-23; (3) the sample-database **ER diagram had drifted from the schema** — missing
`Stadium.Opened`, `Club.ShortName`/`Founded`, `Competition.Tier`, `Player.ShirtNumber`/`DateOfBirth`,
`Referee.Country`. `ShirtNumber` is the one that stings: it's the column the whole part-3 "drop a
populated column" demo revolves around, and it wasn't on the diagram. **Method gotcha worth keeping:**
a quick `grep '^\s*\['` column extract that also filters `CONSTRAINT` lines gives **false negatives** —
it hid `Fixture.Status` and `Goal.IsPenalty`/`IsOwnGoal` (inline `DEFAULT` constraints on the column
line), which I nearly reported as missing. Read the table file to confirm a column is *absent*; a
filtered grep only proves it's *present*. Verified the fixes with a `--strict` build of the full
(un-excluded) site via a scratch `INHERIT` overlay.
**Action:** Fixed [`docs/infra/fabric-sql.md`](../docs/infra/fabric-sql.md) (earlier this session),
[`docs/cicd/ship-database-changes.md`](../docs/cicd/ship-database-changes.md),
[`docs/cicd/build-validate.md`](../docs/cicd/build-validate.md), and the ER diagram in
[`docs/database/sample-database.md`](../docs/database/sample-database.md). **Still open (content, not
accuracy — task #22):** `fabric-sql.md` is a bare skeleton while its Azure SQL sibling is fully
fleshed, and `welcome.md` / both `wrap-up/` pages / `reference/other-tooling.md` are still stubs.

## 2026-08-28 — Content Phase 3: fleshed the skeleton pages, and where "as code" honesty forced a hold
**Context:** Fleshing the remaining stub pages (#22): `infra/fabric-sql.md`, `setup/welcome.md`,
`wrap-up/resources.md`, `wrap-up/migrations-drift-teardown.md`.
**Learning:** Three wrote cleanly from material already in the repo — the Fabric page from the
Terraform module + `fabric-sql-notes.md` + the live-deploy learnings (it had been the one bare
skeleton while its Azure SQL sibling was fully fleshed); welcome from D6 + the agenda (kept
**format-focused**, not pinned to timings still being finalised); resources with a "coming soon"
Downloads placeholder (bundles = #12) and a generic FabCon-survey feedback line. The **wrap-up
migrations/drift/teardown** page is the honest exception: its migrations-reference (Flyway,
dbatools/dbops are README-only, links per decision B) and teardown parts are writable, but **there
is no drift demo anywhere in the repo** (grep confirms "drift" only appears in prose). Rather than
write a drift section describing a demo that doesn't exist — against the repo's "everything is real,
runnable code" rule — we **hold the page and build the demo first** (new task #29). Also captured a
standing hygiene task: **sweep for `coming soon`/`TODO`/skeleton placeholders before any reveal**
(#30).
**Action:** Fleshed the three pages (PR on branch `docs/fabric-page-verified-status`); `--strict`
full-site build green. Tasks: #22 Phase-3 progress noted, **#29** (drift demo) and **#30**
(placeholder sweep) added.

## 2026-08-28 — Preview the full site locally while the pushed site stays teaser: an INHERIT overlay
**Context:** Wanted to author/preview the held content pages on a laptop while keeping the
**published** site in teaser mode (`exclude_docs` in `mkdocs.yml`). The published config can't
just un-hide the pages, and MkDocs has a single config per build.
**Learning:** MkDocs' **`INHERIT:`** key lets a second config layer on top of the first, and
**scalars/lists in the child replace the parent's** (dicts deep-merge). So `mkdocs.local.yml`
does `INHERIT: mkdocs.yml`, sets `exclude_docs: ""` (clears the teaser exclusions) and supplies
the **full `nav`** (replacing the teaser nav wholesale — necessary because a page that's in nav
*and* excluded errors under `--strict`, so the parent's nav can't just list everything). Preview
with **`mkdocs serve -f mkdocs.local.yml`**; the overlay is only ever used when you pass `-f`, so
CI (`ci.yml`) and Pages (`pages.yml`) — both plain `mkdocs build` on the default `mkdocs.yml` —
still publish teaser-only. Verified both `--strict` builds: default emits **2** pages
(`index` + `prerequisites`), the overlay emits all **14**. Bonus: the overlay's nav is the exact
tree to paste into `mkdocs.yml` at the real reveal.
**Action:** Added [`../mkdocs.local.yml`](../mkdocs.local.yml); pointers in
[`../mkdocs.yml`](../mkdocs.yml) teaser header, [`../CONTRIBUTING.md`](../CONTRIBUTING.md), and
[`../CLAUDE.md`](../CLAUDE.md) §5. Doesn't change the reveal (#22) — just makes held pages
previewable while writing them.

## 2026-08-28 — Local Terraform demo needs a local-backend override, not `-backend=false`
**Context:** Attendee/presenter runs `terraform init` in `infra/azure-sql/terraform/demo` on a laptop
and gets prompted for a **container name**. `providers.tf` declares a remote **`azurerm`** backend
(D5) with only `use_oidc`/`use_azuread_auth` inline — the storage account/container/key come from
`-backend-config` in CI, so a bare local `init` tries to initialize the real remote backend
interactively.
**Learning:** `terraform init -backend=false` (what the README used to say) is **not** a working
local demo path — it only unblocks `fmt`/`validate`. A subsequent `plan`/`apply` errors with
*"Backend initialization required, please run terraform init"* because the `backend "azurerm"`
block is present but uninitialized (verified on TF v1.12.0). The clean fix: Terraform
**auto-merges any `*_override.tf` file**, and a `backend` block in an override **replaces** the
primary. A one-line `backend_local_override.tf` (`terraform { backend "local" {} }`) makes local
`init` → `plan` → `apply` run with **local state, no Azure Storage account, no prompts**, while the
committed `azurerm` backend stays intact for CI. Shipped as `.example` (mirrors
`terraform.tfvars.example`); `.gitignore` adds `*_override.tf` + `!*_override.tf.example` so the
activated copy never gets committed and can't clobber the remote backend.
**Action:** Added
[`../infra/azure-sql/terraform/demo/backend_local_override.tf.example`](../infra/azure-sql/terraform/demo/backend_local_override.tf.example);
fixed the local snippets in
[`../infra/azure-sql/terraform/demo/README.md`](../infra/azure-sql/terraform/demo/README.md) and the
Terraform tab in [`../docs/infra/azure-sql.md`](../docs/infra/azure-sql.md); gitignore rule added.
The *attendee-facing* backend/sandbox strategy (#1) is still the broader open question — this just
makes the module runnable on a laptop today.

## 2026-08-29 — Attendee voice: two registers, with hover translations for the idioms
**Context:** Doing a voice pass on the attendee site, starting with the home page. The room at
FabCon Europe is international, and a lot of attendees will not have English as a first language —
so the dry British humour we want in the prose is a genuine comprehension risk in the steps.
**Learning:** One blanket "voice" rule does not work. The useful line is between **talking about
a thing** and **doing the thing**, so `docs/` now has two registers: **discussion** (relaxed, dry
humour, idioms permitted) and **step** (numbered, one action per step, no idioms, no hedging, say
what success looks like). The idioms are then made safe by MkDocs Material's abbreviation
tooltips: `abbr` + `pymdownx.snippets.auto_append` pointed at a single `includes/glossary.md`
gives a hover translation for a term **on every page with zero per-page markup** — verified on the
existing home page, which picked up `CI/CD`, `DACPAC`, `teardown` and `kit` without being edited.
Two constraints worth knowing: the glossary file must live **outside `docs/`** (inside it, the
teaser-mode `exclude_docs` and the `mkdocs.local.yml` overlay that clears it fight each other and
`--strict` fails on a page missing from the nav), and matching is **exact and case-sensitive and
site-wide** — a word added for the prose will also underline itself inside a step. Tooltips also
do not appear on touch devices, which is why the standing rule is that humour and idiom must never
carry meaning: the sentence has to survive the tooltip never showing.
**Action:** Rewrote [`../CLAUDE.md`](../CLAUDE.md) §5 into 5a/5b/5c (sections 5–8 renumbered to
6–9); added [`../includes/glossary.md`](../includes/glossary.md); enabled `abbr`,
`pymdownx.snippets` and the `content.tooltips` feature in [`../mkdocs.yml`](../mkdocs.yml);
voice-passed [`../docs/index.md`](../docs/index.md) only. Both `mkdocs build --strict` (teaser)
and `-f mkdocs.local.yml` (full) pass. The remaining 13 pages are **deliberately untouched** —
we are working through them one at a time.

## 2026-08-29 — A session clock on every teaching page, and Morning 1 written
**Context:** Building out the first agenda slot (Morning 1, 09:00–10:30 — "the hardest part of IT"
then source control), plus Rob's ask for the section timing to run along the top of every page as
`09:00 ————— 10:30` with a progress bar.
**Learning:** Four things.
(1) **One include per agenda slot beats a per-page HTML block.** `includes/clock-*.md` holds the
markup once per slot and a page adds its timing with a single
`--8<-- "includes/clock-morning-1.md"`. `pymdownx.snippets` was already enabled for the glossary
auto-append, and explicit `--8<--` includes resolve from the project root, so no config change was
needed beyond `extra_css`/`extra_javascript`. **The times live in one place per slot** — change
`agenda/agenda.md` first, then the include.
(2) **The live fill must be progressive enhancement.** The bar is plain HTML + CSS; the JS only
paints a fill when the reader's local clock is inside the window. With JS off, or at any other hour,
it degrades to exactly the static bar the sketch asked for. Boundary bug worth remembering: the
first version snapped the bar from ~100% back to **empty** at the moment a session ended — a
finished slot now holds at 100% but muted (`data-state="done"`), so "finished" and "running" read
differently. Verified with a DOM shim in node across before/start/half/end/after.
(3) **`abbr` will not match a phrase that straddles a source line break.** "carries the can" was
wrapped mid-phrase and silently got no tooltip; reflowing the line fixed it. Since we hard-wrap at
~100 chars, **any multi-word glossary phrase needs its line checked after wrapping** — the build
gives no warning, the tooltip is just quietly absent. Same failure mode as the `keyring` entry
last time (that one matched nothing because it only ever appeared inside code).
(4) **`ci.yml` has no path filter and needs no cloud credentials** (`terraform validate` runs
`-backend=false`), so an attendee's first PR **in their own fork** genuinely goes green on all four
checks. That makes a real "change → PR → green → merge" moment possible in Morning 1 with no Azure
subscription. The OIDC-based `azure-sql-plan.yml` is the opposite — it *will* fail in a fork until
the Deploy-infrastructure setup is done, so the page says so plainly rather than letting attendees
think they broke something.
**Action:** Added [`../docs/foundations/hardest-part-of-it.md`](../docs/foundations/hardest-part-of-it.md)
(discussion register, no steps) and rewrote
[`../docs/foundations/source-control.md`](../docs/foundations/source-control.md) with a nine-step
first-PR walkthrough; added `ATTENDEES.md` as the safe thing to change (dropped 2026-09-05); added
the clock component (`includes/clock-morning-1.md`, `docs/stylesheets/session-clock.css`,
`docs/javascripts/session-clock.js`); `carries the can` added to the glossary.
**Deliberately scoped to Morning 1 only.** The clock was briefly rolled out to all eleven teaching
pages and then pulled back: the later sections still have code being written (Jess's PR #56 touches
`docs/database/sample-database.md`, `docs/infra/fabric-sql.md` and
`docs/wrap-up/migrations-drift-teardown.md`; #60 rewires the plan workflows), and there is no point
writing prose against demos that have not settled. **Standing rule: write an attendee page only
once the code it describes is merged.** Adding the clock to a later page is one `--8<--` line plus
a five-line include, so nothing is lost by waiting.
Related: the source-control page describes `azure-sql-plan.yml` as *surfacing the plan on the pull
request* rather than naming checks-vs-comment, because #60 is actively moving it to a sticky PR
comment. Pitch a page above a mechanism that is still in flight.

## 2026-08-29 — Fabric demo: `ARM_SUBSCRIPTION_ID` doesn't feed the required module variable
**Context:** Running the Fabric `terraform plan` from the demo steps dropped into an interactive
prompt for `var.fabric_subscription_id` — the exact thing the "no clicking / no surprises" rule
forbids happening live in the room.
**Learning:** The Fabric module's `azurerm` provider reads its subscription from the
`fabric_subscription_id` **variable** (no default — it exists for the cross-tenant CI design where
the state backend is Tenant A and the provider is Tenant B), **not** from `ARM_SUBSCRIPTION_ID`.
`ARM_SUBSCRIPTION_ID` only feeds the state backend and the CLI, so setting it (as both demo pages
did) leaves the variable unset and `terraform plan` prompts. For a local single-tenant demo the
cleanest fix is one env line — `$env:TF_VAR_fabric_subscription_id = $env:ARM_SUBSCRIPTION_ID` —
reusing the same GUID; no tfvars edit needed. The Azure SQL module has no equivalent required var,
which is why only the Fabric path trips on this.
**Action:** Added the `TF_VAR_fabric_subscription_id` line to the Fabric steps in
[`../docs/infra/demo.md`](../docs/infra/demo.md) and the "The code" snippet in
[`../docs/infra/fabric-sql.md`](../docs/infra/fabric-sql.md), plus a gotcha on demo.md so it does
not regress. Also surfaced `fabric_subscription_id` in
`infra/fabric-sql/terraform/terraform.tfvars.example` (previously it never mentioned the one
required variable, and its header wrongly claimed the module "runs with no tfvars at all").

## 2026-08-29 — Non-Windows attendees: OS install tabs, and a repo-setup step that keeps them short
**Context:** Issue #52 — the prerequisites page only ever showed `winget`, which leaves every
attendee not on Windows to work it out themselves. The room is international; a lot of them will
be on a Mac.
**Learning:** Three things worth keeping.
(1) **`content.tabs.link` syncs tab sets by their *label list***, not by page position. A
`Windows`/`macOS`/`Debian & Ubuntu` set therefore syncs with every other copy of itself while
leaving the existing `Azure SQL`/`Fabric SQL` and `Terraform`/`Bicep` sets completely alone — so
the attendee picks their OS once and the page follows them. Verified: 8 OS sets and 1 platform set
on the page, and the OS sets **nest cleanly inside** the Azure SQL tab (confirmed at nesting depth
1 by parsing the built HTML, not by eye — indentation is 4 spaces per level, so a tab inside a
numbered step inside a tab puts the fence at 12 spaces).
(2) **The apt keyring dance belongs in one collapsed block at the top, not in every step.** Four of
the six tools come from vendor repositories (GitHub CLI, HashiCorp, Microsoft ×2). Repeating the
keyring commands per tool would have added ~60 lines to an already long page; hoisting them into a
run-once `??? note` makes every later Linux tab a single `sudo apt install x` that sits level with
the winget and brew one-liners. Using `$(lsb_release -cs)` and `$(dpkg --print-architecture)` makes
that block identical on Debian and Ubuntu — the **only** genuine split is .NET, where Ubuntu 22.04+
ships `dotnet-sdk-8.0` in its own archive and adding Microsoft's repo there causes a package
conflict.
(3) **A glossary entry only fires in prose.** `winget` and `Homebrew` picked up tooltips; `keyring`
did not, because the word appeared solely inside code blocks — `abbr` never matches inside `<code>`.
Worth checking the built HTML after adding an entry rather than assuming it took.
**Testing:** The Debian path is genuinely tested — this is a Debian 12 box. All five packages
resolve under `apt-get install --simulate`, all 14 bash blocks pass `bash -n`, and all three
keyring commands were checked against the keys actually installed here (GitHub and Microsoft match
byte-for-byte; HashiCorp matches on both fingerprints). **macOS is not tested by either of us**, so
the page says so plainly in a short note and points at the vendor link as the authority — per
CLAUDE.md §4.
**Action:** Rewrote [`../docs/setup/prerequisites.md`](../docs/setup/prerequisites.md) with OS tabs
throughout (including the summary table); added `winget` and `Homebrew` to
[`../includes/glossary.md`](../includes/glossary.md) — deliberately **not** `apt`, since matching is
exact and site-wide and "apt" is an ordinary English word that would underline itself in prose. No
`mkdocs.yml` change needed; `pymdownx.tabbed` and `content.tabs.link` were already on.

## 2026-08-31 — "Nothing is provisioned" vs. the shared SQL endpoint: name the exception up front

**Learning:** Three attendee pages opened with an absolute — "Nothing is provisioned for you, and
there is no lab environment handed out" — and then, further down the same page, offered a shared
SQL endpoint. Read end to end it looks like a contradiction, and an attendee deciding what to bring
cannot tell which sentence to believe.

The fix is not to soften the promise but to **state the exception where the promise is made**. The
"bring your own" claim is really two claims: (a) we hand out no subscriptions, capacities or
credentials — always true; (b) we provide nothing at all — never was true. The intro now makes
claim (a) and immediately names the single exception, with a link down to
[The shared endpoint](../docs/setup/prerequisites.md). The shared-endpoint section, in turn, opens
by saying it *is* the one thing we provide, and bounds it: a Part 2 target, not a lab environment —
Part 1 still needs your own subscription.

Also worth remembering: "follow along **or** watch" is not in tension with "we provide nothing".
Those are separate axes — how hands-on you are, versus whose cloud you use — and the original prose
blurred them into one paragraph. Keeping them in separate sentences makes both readable.

**Action:** Reworded the openers of [`../docs/index.md`](../docs/index.md),
[`../docs/setup/welcome.md`](../docs/setup/welcome.md) and
[`../docs/setup/prerequisites.md`](../docs/setup/prerequisites.md), and expanded the shared-endpoint
section on the prerequisites page.

## 2026-08-31 — One job per page: overview pages explain, demo pages instruct

**Learning:** Every teaching section had grown **two** step-by-step walkthroughs — one on the
concept page and one on Jess's `demo.md` — and they were near-duplicates that had already started
to drift apart. `foundations/source-control.md` walked a nine-step pull request against
`ATTENDEES.md`; `foundations/demo.md` walked a nine-step pull request against `notes/fabcon.md`.
`cicd/build-validate.md` carried a six-step "watch CI validate a PR" demo alongside `cicd/demo.md`.
`infra/azure-sql.md` printed a full `init`/`plan`/`apply` block pointing at
`infra/azure-sql/terraform/demo`, while `infra/demo.md` pointed at `infra/azure-sql/terraform`.
An attendee reading top to bottom cannot tell which page to follow, and a presenter cannot tell
which one is current.

The rule that resolves it, and the one to keep: **a page either explains a thing or instructs you
to do it, never both.** Overview pages get the concept, what gets built, the gotchas, and a
signposted link to the demo. The demo page is the only place with numbered commands. Applied
consistently, the two registers in CLAUDE.md §5 stop competing for the same page.

Two knock-on effects worth noting. Troubleshooting is *step* register but does not belong on a demo
page mid-flow — the Windows WAM/Graph-token fix now sits on `infra/azure-sql.md` as a collapsed
`??? warning` under Gotchas, out of the way until needed. And the wrap-up had no `demo.md` at all;
its "final boss" demo lived inside `migrations-drift-teardown.md`, so it was split out to
`wrap-up/demo.md` (content moved byte-for-byte) to match every other section.

**Follow-up:** those stale demo paths were fixed in the demo-code pass (task #32): `infra/demo.md`
now uses `infra/azure-sql/terraform/demo`, and `wrap-up/demo.md` now points at
`infra/azure-sql/terraform/demo/variables.tf`.

**Action:** Rewrote the eight overview pages, added the "Two kinds of page" section to
[`../docs/setup/welcome.md`](../docs/setup/welcome.md), created
[`../docs/wrap-up/demo.md`](../docs/wrap-up/demo.md), and added it to the nav in `mkdocs.yml`
(commented, plus `exclude_docs`) and `mkdocs.local.yml`. Both configs build clean under
`mkdocs build --strict`. Jess's four `demo.md` pages were not touched.

## 2026-08-31 — Presenter demos, and the drift that had already been committed

**Learning:** Building the presenter scripts turned up the thing they were meant to prevent, sitting
on `main`. `database_auto_pause_delay` in the Azure SQL module was `75`, not `60` — commit `33cf375`
committed a demo run's value. Step 8 of the wrap-up demo says to reset it and nobody had. The whole
beat of that demo is "change 60 to 75, look at the plan", so as it stood `terraform plan` would have
reported `0 to change` in front of the room. The demo would have died on stage and nobody would have
known why.

That is the actual argument for a **RESET region**, and it is why every presenter script now ends
with one. `03-database.ps1` is the worst offender: the ship-changes demo overwrites three *tracked*
files (`Tables/Player.sql`, `Scripts/PostDeployment/Seed.sql`, `FabConFootball.sqlproj`) and creates
four more. The attendee page has no reset step and should not grow one — it is presenter
housekeeping, not an attendee step.

**The `break` guard rail works, and is worth knowing.** `break` at the top level of a PowerShell
script terminates it, so F5 does nothing; F8 (Run Selection) never sends that line, so running a
block at a time is unaffected. Verified both ways rather than assumed. It is two characters and it
removes the entire "I pressed F5 in front of 300 people" class of disaster.

**"The path exists" is a useless check.** The first version of `check-demo-paths.py` passed happily
on the exact bug it was written to catch: `cd infra/azure-sql/terraform` resolves to a real
directory — it is just the *container* for `demo/` and `shared-endpoint/`, with no `.tf` files in
it. The check that works is **"a `cd` that is followed by a `terraform` command must land somewhere
holding tracked `.tf` files"**, and it has to ask *git*, not the filesystem: a leftover gitignored
`backend_local_override.tf` from someone's demo run (there is one in that very folder) makes the
wrong directory look right. Worth remembering generally — a checker that passes on the known bug is
worse than no checker, because now you trust it.

**Also:** resolving demo paths the way the demo does — walking the file, tracking `cd`, resolving
`..\` against it — is what makes the check meaningful, and it means one wrong `cd` lights up every
command after it.

**Action:** Added [`demo/`](../demo/) — five presenter scripts plus a README. Added CLAUDE.md §7a
(the two halves of a demo, and that Jess's comments may be added to but not rewritten), the `demos`
job in `ci.yml`, and [`check-demo-paths.py`](../.github/scripts/check-demo-paths.py). Fixed six
bugs, listed in [the design doc](../planning/2026-08-31-presenter-demo-scripts-design.md).

## 2026-09-05 — Nothing pairs a slide with the demo it describes, so the deck drifted for weeks

**Context:** First reconciliation pass over the **morning** of the deck against the demos and the
attendee pages it describes, plus a walk-in slide for the doors opening. `CLAUDE.md` §7a pairs a
presenter script with its attendee page, and the `demos` job in CI enforces the mechanical half of
that. **Nothing pairs either of them with the slide** — and it showed. All four morning `CMD`
slides were wrong.

**Learning — the commands.** Each was wrong in a way the room would have noticed:

- `terraform init -backend=false` — the exact command the **2026-08-28** entry above records as
  *not a working local path*. It only unblocks `fmt`/`validate`; `plan` then fails with *"Backend
  initialization required"*. That was fixed the same day in the module README and in
  [`../docs/infra/azure-sql.md`](../docs/infra/azure-sql.md). The slide kept it — and its speaker
  note instructed the presenter to **call it out specially**. A fix that lands in the docs does not
  land in the deck.
- `dotnet build … -warnaserror` with **no `--configuration Release`**, on a slide whose very next
  line claims the artifact is `bin/Release/FabConFootball.dacpac`. Without it the build lands in
  `bin/Debug` and every path on the slide is wrong.
- `git add .` on the source-control slide — two slides after *"What never goes in the repo"*, and
  against a demo whose entire beat is staging one **named** file.
- The Fabric slide omitted `TF_VAR_fabric_subscription_id` — which is not optional, because the
  module's `azurerm` provider has no default for it and `plan` stops and prompts without it — and
  offered `FABRIC_TENANT_ID` instead, which nothing in the module reads.

**Learning — the timetable.** The deck ran the **old** schedule throughout: break at 11:00 for
fifteen minutes, lunch 12:45–13:45. Worse than the numbers, it still split the IaC block across the
break with an *"Off it goes — see you after coffee"* slide, long after
[`../agenda/agenda.md`](../agenda/agenda.md) explicitly reversed that decision. **The slide was
teaching the opposite of the plan**, and it would have sent the room to coffee half an hour late.

**Learning — why this drift is invisible.** The docs and the demo scripts get edited *while* the
code is edited, so they stay close to true. The deck is edited only when someone opens
`content.py`, and its output is gitignored and rarely rebuilt — so **nothing ever shows you the
drift**. Reading the prose does not catch a missing `--configuration Release`. The deck is the one
artefact in this repo with no reader between writing it and standing in front of 300 people.

**Learning — a third description of a demo is always a liability.** The source-control demo edited
a different file in three places: `ATTENDEES.md` said the first pull request edits `ATTENDEES.md`,
the speaker guide agreed, and the demo script and the attendee page both used `notes/fabcon.md`.
Task #31 had already dropped the `ATTENDEES.md` exercise on 2026-08-31 but left the file behind,
still describing it. **Rob's rule, 2026-09-05: the attendee demo page and the demo script are the
only source of truth for a demo, and they must match.** `ATTENDEES.md` removed.

**Action:** Re-cut the morning of [`../slides/content.py`](../slides/content.py) to the venue
anchors; moved the break slide **before** the Azure SQL block and dropped the coffee slide; pulled
*"So what did we just build?"* back inside Morning 2 and cut its drift promise (#29 is still not
built, so the slide no longer offers a demo we cannot run). Mirrored all four morning `CMD` slides
to their scripts and pages, each speaker note now naming the script and the regions it mirrors.
Added the **walk-in slide** (`WALK_IN_*` in `content.py`, rendered ahead of the conference splash)
carrying the site address, so the first thing the room sees is where the written steps live.
Removed `ATTENDEES.md` and pointed [`../agenda/speaker-guide.md`](../agenda/speaker-guide.md) at
`notes/fabcon.md`. Added the third-copy rule to `CLAUDE.md` §7a. Logged the `attendee_count` bump
gap as **#34** and the afternoon re-cut under **#25**.

**Verified, same day.** Rob supplied the template and the deck was built (70 slides) and rendered.
The walk-in slide sits comfortably on the section-break layout; every re-cut morning slide fits with
room to spare, including the 72-character `dotnet build` line and both 13-line command slides. Two
things only the render could show: the walk-in's body text **inherited the layout's gold**, so it
competed with the URL and gave the smallest text on the slide the weakest contrast (now explicitly
white, leaving the URL as the only accent); and three run-of-day entries wrapped, since a `DUAL`
column breaks at about **47 characters** at 16pt.

**A fourth pass added the demo slides and the merge demo.** Every demo now gets a `DEMO` slide in
front of it — big title, one quip, then two plain lines whose only job is to say *follow along* or
*sit back*. That last distinction turned out to need a mechanism, not just wording: the merge-conflict
demo needs **two laptops and two people**, so there is nothing an attendee can follow, and
[`check-demo-paths.py`](../.github/scripts/check-demo-paths.py) would have failed it for not naming an
attendee page. Rather than inventing a page nobody would use, presenter-only demos now declare
`ATTENDEE PAGE: none` and CI skips the pairing half while still checking every path they mention.
Use it sparingly — it is an admission that a demo is not reproducible by the reader, which is why the
rule now says the slide in front of it *has* to tell the room to sit back.

**The two-presenter demo is one script, not two.** [`01b-merge-conflict.ps1`](../demo/01b-merge-conflict.ps1)
interleaves `ROB` and `JESS` regions in run order with a choreography table in the header, rather than
shipping a file each. Two files would have duplicated the dance in two places, and this repository's
entire failure history is duplicated things drifting apart. Both presenters fold the same file and run
only the regions with their own name on them.

**A third pass turned the morning into overview-plus-demo.** Rob's call: the slides are the quick
overview that *leads into* a demo, not a parallel teaching track. So every `CMD` slide in a module
that has a `demo/` script behind it came out (`Getting started`, `Run it on your own kit`, `The
Fabric module`, `Build the DACPAC`) — they were the third copy of a demo, which `CLAUDE.md` §7a had
just finished warning about. `Check your toolchain` stayed, because the room types that one itself.
Also out: `How this repo is laid out` (its own speaker note said *"show the actual repo rather than
reading the slide"*), `What you'll leave with`, and `So what did we just build?`. Morning went **45
slides to 39** while gaining two — the merge-conflict pair the source-control slot has room for,
since that slot is 25 minutes and the branch-and-PR demo runs eight.

**The 09:30 module is the exception that proves the rule.** Thirty minutes with no demo at all, so
"lead into the demo" does not apply — instead each of the five lessons became an `IMAGE` slide:
three short bullets and a dashed box carrying a **written prompt** for Napkin/Eraser/Claude. Twelve
placeholders across the morning. Worth recording *why* the prompt lives in `content.py` rather than
in someone's chat history: the picture is the argument, and six months from now the only way to
regenerate or correct it is to still have the sentence that asked for it.

**A python-pptx trap, found by rendering.** A placeholder inherits its position from the layout, and
writing **one** dimension (`width`) drops the other three to zero — the bullets jumped to the top-left
corner and printed straight through the slide title. Set all four (`left`, `top`, `width`, `height`)
or none. Measured off the template: the light content layout's body box is L=0.81 T=1.86 W=11.75
H=4.63 inches, now a constant in `build.py`.

**Then it immediately paid for itself.** A second pass the same day (rainbow walk-in with image
placeholders, one intro slide each, a "being good to each other" housekeeping slide, the site
address repeated mid-deck) produced three layout bugs that **reading the code could not have
found**: an autoshape **centres its first paragraph by default**, so the walk-in title was centred
while every line under it was left; `add_textbox` applies a default left inset, so the URL strip sat
indented from the title it was meant to line up with; and two bullets wrapped a single word onto a
line of its own. All three were invisible in the source and obvious in a PNG. Budget a render for
every deck change, not just the risky ones.

**And the reason nobody had ever looked.** `slides/README.md` documented the sanity check as
`python /mnt/skills/public/pptx/scripts/office/validate.py …` — a **Linux sandbox path**, which
cannot run on either presenter's Windows machine. The one documented step for checking the deck was
unrunnable, so it was never run, which is exactly how a deck drifts for eight days without anyone
noticing. Replaced with a PowerShell snippet that drives the installed PowerPoint to export the
changed slides to PNG. **A verification step nobody can execute is not a verification step.**

**Syncing a demo's two halves is not a copy — presenter-only lines don't cross.** When
`02-infrastructure.ps1` gained `# if Rob doing demo` lines (`Get-Secret` for the subscription id,
`$groupName = "SQLAdmins"`), mirroring them onto `docs/infra/demo.md` would have been wrong:
attendees have no `beard-mvp-subscription`/`sewells-subscription-id` secret and no `SQLAdmins`
group. Presenter context stays in the script (§7a). The only change that legitimately synced was
the *shape* of an attendee-facing command — region 04 refactored the object-id lookup to a
`$groupName` variable — because that changed a command the page mirrors, and it fits the page's
existing "update for your group name" wording. Rule of thumb: sync a change only if it alters a
command the attendee actually runs; skip anything gated on "if Rob/Jess doing demo".

**A fix made live on stage is only half a fix.** On 6 September, `Invoke-DbaQuery` with a server
*name* plus `AccessToken` did not work, so `03-database.ps1` was changed to build the connection
once with `Connect-DbaInstance` and pass the resulting `$serverSMO` as `SqlInstance` (commits
`18d84b1`, `00a3a19`). Two things went unfinished. The attendee page still showed the old form in
all five of its presenter-path tabs — attendees would have hit the exact failure we had already
fixed. And the script itself only fixed the *first* query: `$verifyParams` in increment 3 still used
the broken pattern, so the demo would have failed again at the payoff. `check-demo-paths.py` cannot
see either, because both are variables, not paths. When a demo is fixed under pressure, the whole
fix is: **every occurrence in the script, then the page.**

**A page that contradicts itself is worse than one that contradicts the script.** `docs/wrap-up/demo.md`
told attendees to change `database_auto_pause_delay` from `75` to `90`, then committed it with the
message "…to 75 minutes", then reset "`75` back to `60`". Three different starting values on one
page. The repo baseline is `60` and the presenter script does `60 → 75`; the page is now the same,
and says out loud what to do if the file is not `60` (a previous run committed and never reset —
the failure `05-wrap-up.ps1` region 01 already preflights for).

**Action:** Synced all five pairs. Page changes: the `Connect-DbaInstance` pattern and a note on
reviving it after the 15:15 break, two wrong expected-output values, the wrap-up numbers, and the
tab/space indentation in `docs/foundations/demo.md` that was leaking 4-space padding into rendered
code blocks. Script changes: `$verifyParams` → `$serverSMO`, and the `Select-String "ShirtNumber"`
check that the page had and region 13 did not.

**Increment 2b never worked, and the reason is worth teaching.** The demo forced a
column-dropping publish through with `/p:BlockOnPossibleDataLoss=false` (2a), then published the
same DACPAC under the shipped profile to show the guard refusing it (2b). It never refused
anything: 2a had already dropped the column, so the second publish had nothing left to drop and
succeeded quietly. **`BlockOnPossibleDataLoss` only fires when there is something to lose.** The
guard needs a populated column in front of it, and after 2a there wasn't one.

**The fix turned a bug into the best five minutes of the section.** Between 2a and 2b there is now
a recovery attempt — `git restore` the two files, rebuild, republish — which is the thing every room
will suggest anyway. It puts the **column** back and not the **data**: the post-deploy seed only
inserts players that are missing, and none are. "Source control has your schema. It has never had
your data." That republish is also what re-arms 2b, so one sequence does both jobs. Point-in-time
restore is named as the real recovery and described rather than run (several minutes of nothing,
and the 15:45–17:00 slot has not got them).

**`git` pathspecs with backslashes fail silently on Linux.** `git diff -- .\Tables\Player.sql`
matches nothing and prints nothing — exit code 0, no error, and it looks exactly like a clean diff.
Verified both forms in `pwsh` here. **Forward slashes work in PowerShell *and* git on Windows,
macOS and Linux**, so every demo path in both halves is now `./Tables/Player.sql`. That is one line
that works everywhere rather than a Windows line plus a commented-out alternative to maintain —
fewer places for the two halves to drift. The one backslash left in the demos is the `\d+` in
`05-wrap-up.ps1`'s preflight regex, which is not a path.

**`pwsh` is the first command of the day.** Attendees on a Mac or Linux land in bash, and the
symptom is not "command not found" but subtly wrong behaviour a few steps later. Every demo page
now opens with a note to run `pwsh` first.

**Action:** All five pairs re-synced. Increment 2 rebuilt as force → damage → failed recovery →
guard blocks (page steps 13–23, script regions 14–24, both renumbered). Split the `git diff` from
the `Select-String` so each result gets explained rather than scrolling past. Added an after-lunch
`Test-Path ./FabConFootball.sqlproj` and a fresh `az login` to both halves, because the terminal
and the token rarely survive lunch. Showed Terraform's actual `Only 'yes' will be accepted` prompt
instead of "prompts for confirmation". Removed the Fabric not-tested banner from the attendee page;
`02-infrastructure.ps1` region 11 now states plainly that it is verified to `plan` and no further.

**SQL project analysis emits a build artifact alongside the DACPAC.** Demo 03's `dotnet build` writes `bin/Release/FabConFootball.StaticCodeAnalysis.Results.xml`. It is intentionally absent from a clean checkout, so it belongs in both `.gitignore` and `check-demo-paths.py`'s documented `EXPECTED_ABSENT` list.

## 2026-09-12 — Afternoon re-slotted: all of database part 2 into Afternoon 1

**The whole database demo part 2 now fits one slot.** Increments 0 → 3 (baseline, additive view,
the trap + recovery + guard, and the safe retire) all run in **Afternoon 1, 14:00–15:15**, before
the break — Increment 3 no longer waits until Afternoon 2. Afternoon 2 (15:45–17:00) is now three
beats: **CI/CD 15:45–16:00**, the **whole-loop wrap-up demo 16:00–16:30**, then **close + Q&A
16:30–17:00**.

**The session clocks are slot-level, so most of the change was re-pointing includes, not editing
times.** `includes/clock-*.md` are keyed to the fixed venue slots (Morning 1/2/3, Afternoon 1/2,
Lunch), so re-slotting content = swapping which `--8<--` a page pulls in. The CI/CD pages moved
`clock-afternoon-1` → `clock-afternoon-2`; `database/demo.md` dropped its second
(`clock-afternoon-2`) clock before Increment 3 because part 2 is now entirely Afternoon 1. Change
slot *times* in `agenda/agenda.md` first, then the clock include; change slot *content* by
re-pointing the include.

**Part 2 now has almost no slack.** ~62 min of runtime (mostly waiting on `sqlpackage`) in a 75-min
slot. The cut lever is documented in `03-database.ps1` and the speaker guide: run only Increment 3
**Option B** (the rename — clean, no override) and *describe* Option A. Never cut the Increment 2
trap or the silence after it.

**Files touched (kept both halves of every demo in sync):** `agenda/agenda.md`,
`agenda/speaker-guide.md`, demo headers `03-database.ps1` / `04-cicd.ps1` / `05-wrap-up.ps1`,
`docs/database/demo.md`, the four `docs/cicd/*.md` clocks, `docs/lunch.md` (return pointer now goes
to database part 2, not build-validate), `docs/setup/welcome.md` schedule table, and
`docs/wrap-up/resources.md` (now "Resources, contacts & next steps" — a Find-us section awaits Jess
& Rob's handles). `check-demo-paths.py` clean; `mkdocs build -f mkdocs.local.yml --strict` green.

<!-- Add new entries above this line -->
