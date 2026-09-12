# `demo/` — the presenter scripts

The scripts Jess and Rob actually drive on the day. One per section, numbered in run order.

Each script is the **presenter twin** of one attendee page. Same commands, same order — plus the
things attendees never need to see: how long a step takes, what to say while it runs, what the
failure looks like, and how to put the repository back afterwards.

| Script | Attendee page | Slot |
|---|---|---|
| [`01-source-control.ps1`](01-source-control.ps1) | [`docs/foundations/demo.md`](../docs/foundations/demo.md) | Morning 1 · 09:00–10:30 |
| [`01b-merge-conflict.ps1`](01b-merge-conflict.ps1) | **none** — presenter-only | Morning 1 · 10:00–10:25 |
| [`02-infrastructure.ps1`](02-infrastructure.ps1) | [`docs/infra/demo.md`](../docs/infra/demo.md) | Morning 2 · 11:00–12:15 |
| [`03-database.ps1`](03-database.ps1) | [`docs/database/demo.md`](../docs/database/demo.md) | Morning 3 (Part 1) + Afternoon 1 & 2 (Part 2) |
| [`04-cicd.ps1`](04-cicd.ps1) | [`docs/cicd/demo.md`](../docs/cicd/demo.md) | Afternoon 2 · 15:45–17:00 |
| [`05-wrap-up.ps1`](05-wrap-up.ps1) | [`docs/wrap-up/demo.md`](../docs/wrap-up/demo.md) | Afternoon 2 · 15:45–17:00 |

Who drives which demo is deliberately not written down. It is fluid, and it may well change
halfway through. The exception is [`01b-merge-conflict.ps1`](01b-merge-conflict.ps1), which needs
**two people on two laptops** and so names them: fold the file, and each of you runs only the
regions with your own name on them. Swap the names if you like — all that matters is that one of
you pushes first and the other one hits the conflict.

## Presenter-only demos

Most demos have two halves, a script and an attendee page. A few cannot: a demo that needs two
laptops and two people is one the room **watches**, and there is nothing useful for an attendee to
follow along with. Those declare `ATTENDEE PAGE: none` in the header, and the `demos` CI job skips
the pairing check for them — their paths are still checked like everything else.

If you write one, say *out loud on the day* that there is nothing to type. Otherwise half the room
will try, and fall behind.

## How to run one

**Never press F5.** Every script starts with a `break` that halts a full run, because running
one of these top to bottom in front of a room would provision an Azure SQL server, drop a
populated column and open three pull requests before you had finished your first sentence.

1. Open the script in VS Code.
2. Fold everything: <kbd>Ctrl</kbd>+<kbd>K</kbd> <kbd>Ctrl</kbd>+<kbd>0</kbd>. You now have the
   run order on one screen, which is also the best cheat sheet there is.
3. Put the cursor in a region, or select the lines you want.
4. <kbd>F8</kbd> — Run Selection. One region at a time.

## What is in a region

```powershell
#region 03 · The plan — a proposal, not a change          [~40s]
# WHAT     What the command actually does.
# SAY      The line that goes with it — a prompt, not a script.
# EXPECT   The output that means it worked. If you don't see this, stop.
# IF STUCK The known failure and the recovery, so nobody debugs live.
# PAGE     The matching step on the attendee page.
terraform plan
#endregion
```

`EXPECT` and `IF STUCK` are read under pressure, with a room watching. They stay plain. Jokes live
in `WHAT`, `SAY` and the guard rail, where they cost nothing if they land badly.

The `[~40s]` in a region title is how long the step took when we last ran it. If you are three
regions in and twenty minutes down, that is the number telling you to move.

## Reset

Every script ends with a `RESET` region. **Run it.** These demos overwrite tracked files —
`Tables/Player.sql`, `FabConFootball.sqlproj`, a Terraform default — and a demo's working state
committed to `main` breaks the demo for whoever runs it next. That has already happened twice.

Reset regions name every file they touch. None of them runs `git clean` across the whole
repository, because losing an afternoon of someone else's work to a demo tidy-up would be a poor
way to end the day.

### One command to reset them all

A per-script `RESET` only tidies its own demo, and only if you remember to run it. When a run was
abandoned half-way, or you just want to be sure before walking on, undo **every** demo at once:

```powershell
./demo/Reset-DemoEnvironment.ps1 -WhatIf   # show what it would do, change nothing
./demo/Reset-DemoEnvironment.ps1           # do it (prompts before deleting), add -SkipRemote to stay offline
```

It only ever touches the branches and files the demos own — listed in
[`DemoEnvironment.psd1`](DemoEnvironment.psd1), the single source both this script and the tests
read. It deletes the throwaway demo branches (the reason `git switch -c demo/source-control` fails
on a re-run), restores the tracked files the demos overwrite, and removes the scratch files they
create — including the gitignored ones (`terraform.tfvars`, `*_override.tf`) that a plain
`git status` never shows. It never runs `git clean`.

### Check the environment is ready

The read-only companion. Run it before a rehearsal to confirm nothing from a previous run is
lingering — it verifies the reset is done, the tooling is present, and `gh`/`az` are signed in:

```powershell
Invoke-Pester ./tests/DemoEnvironment.Tests.ps1              # everything
Invoke-Pester ./tests/DemoEnvironment.Tests.ps1 -Tag Repo    # just git + files, fast + offline
Invoke-Pester ./tests/DemoEnvironment.Tests.ps1 -ExcludeTag Auth   # skip sign-in checks
```

It is deliberately **not** in CI — the `Auth` and `Tooling` checks want a real signed-in presenter
machine (`az login`, `dbatools`, `sqlpackage`), which a CI runner does not have. It is a
before-you-present check, not a gate.

## Keeping these in sync with the site

**A change to a demo touches the presenter script and the attendee page, or it is not finished.**
See [`CLAUDE.md`](../CLAUDE.md) §7a.

CI enforces the mechanical half of that: the `Demo scripts` job in
[`ci.yml`](../.github/workflows/ci.yml) parses every script, checks each one names a real attendee
page, and — via [`check-demo-paths.py`](../.github/scripts/check-demo-paths.py) — checks that every
repository path mentioned in either half actually exists. It cannot tell you the prose has drifted.
It can tell you the `cd` is wrong, which is the bug we have actually shipped.

Run it yourself before pushing:

```powershell
python .github/scripts/check-demo-paths.py
```
