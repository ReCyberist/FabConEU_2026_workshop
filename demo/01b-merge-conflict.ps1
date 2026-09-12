<#
    DEMO 01b - The merge conflict
    ATTENDEE PAGE: none
    SLOT:          Morning 1 - 10:00-10:25, straight after demo 01
    RUNTIME:       ~9 minutes at a comfortable pace
    SLIDES:        "Two people, one file" (the demo slide before it says "sit back")
    PRESENTER:     The presenter known as JESS shares the screen

    PRESENTER-ONLY. THE ROOM WATCHES.
    This one needs two laptops and two people, so there is deliberately no attendee page
    and nothing for anyone to follow along with. Say that out loud before you start --
    "nothing to type for this one" -- or half the room will try and fall behind.

    THE POINT
    Demo 01 showed one person's change becoming a pull request. This one shows what
    happens when two people change the same thing, which is the normal case and the one
    everybody quietly dreads. A conflict is not an error. It is git refusing to guess
    which of two reasonable humans is right, and handing the decision back to them.
    That is the 09:30 module, in a command.

    THE CHOREOGRAPHY
    Fold everything (Ctrl+K Ctrl+0) and run ONLY the regions with your own name on them.

        01  BOTH   start from a clean main
        02  ROB    branch, write a note, commit
        03  ROB    push it
        04  JESS   branch from the same commit, write a different note, commit
        05  JESS   fetch what Rob pushed
        06  JESS   merge  ->  CONFLICT                       <- the moment
        07  JESS   read what git is actually telling you
        08  JESS   the way back: merge --abort
        09  JESS   do it again, and this time resolve it
        10  JESS   keep both, delete the markers
        11  JESS   stage and commit the resolution
        12  BOTH   what just happened, as a graph
        99  BOTH   RESET

    Who drives is not fixed. If Jess is on the keyboard for demo 01, swap the names --
    the only thing that matters is that ROB pushes first and JESS hits the conflict.

    BEFORE YOU START
      - Both laptops on a clean tree, both signed in, both able to push to origin.
      - Both terminals zoomed up. This demo is entirely small text.
      - Agree who is ROB and who is JESS before you walk on.
      - Demo 01's RESET has run (it does not have to, but a tidy `git status` helps).

    See demo/README.md for how to run one of these (short version: F8, never F5).
#>

#region 00 · Guard rail -- do not remove, do not question
# ---------------------------------------------------------------------------------------
# You pressed F5, didn't you.
#
# Top to bottom this would create two branches, push one of them, start a merge, abort it,
# start it again and then delete the lot -- on whichever machine you happened to be sitting
# at, in about four seconds, while the room watched.
#
# `break` stops F5. It does NOT stop F8.
#
# Cursor in a region below -> F8 -> read the line -> then talk.
# ---------------------------------------------------------------------------------------
break
#endregion


#region 01 · BOTH · Start from the same commit                                      [~30s]
#
# Both of you, at the same time. Say it out loud: "we are both starting from exactly the
# same place, which is the only honest way to show this."
git switch main
git pull
git status
#endregion


#region 02 · ROB · A branch, and a note                                             [~60s]
#
# TYPE THE FILE IN, DO NOT PASTE IT. Keep it short:
#
#   # FabCon 2026 - team notes
#
#   Best bits so far:
#   - terraform apply is a spinner with ambition
#
git switch -c demo/merge-rob
New-Item -Path notes/team-notes.md -ItemType File
code notes/team-notes.md
#endregion


#region 03 · ROB · Commit and push                                                  [~40s]
git add notes/team-notes.md
git commit -m "docs: add team notes"
git push --set-upstream origin demo/merge-rob
#endregion


#region 04 · JESS · The same file, different words                                  [~75s]
#
# Branch from main -- NOT from Rob's branch. That is what makes this a conflict rather
# than a fast-forward, and it is worth saying while you type it.
#
# TYPE THIS IN. Same heading, different bullet:
#
#   # FabCon 2026 - team notes
#
#   Best bits so far:
#   - lunch is at 12:45 and it is non-negotiable
#
git switch main
git switch -c demo/merge-jess
New-Item -Path notes/team-notes.md -ItemType File
code notes/team-notes.md
git add notes/team-notes.md
git commit -m "docs: add team notes"
#endregion


#region 05 · JESS · Collect what Rob pushed                                         [~20s]
git fetch origin
git log --oneline --graph --all -6
#endregion


#region 06 · JESS · Merge -- and stop talking                                       [~30s]
#
# THIS IS THE MOMENT. Run it, let the red text land, and say nothing for two seconds.
# Then: "that is not an error. That is git refusing to guess."
git merge origin/demo/merge-rob
#endregion


#region 07 · JESS · What git is actually telling you                                [~60s]
#
# `git status` is the whole lesson: it names the file, it tells you what state you are in,
# and it tells you both ways out. Read it to the room rather than summarising it.
git status
code notes/team-notes.md
#endregion


#region 08 · JESS · The way back                                                    [~45s]
#
# Do this BEFORE resolving. A room that knows it can undo a merge will branch; a room that
# does not will avoid branches for the rest of their career.
git merge --abort
git status
code notes/team-notes.md
#endregion


#region 09 · JESS · Again, and this time we choose                                  [~20s]
git merge origin/demo/merge-rob
#endregion


#region 10 · JESS · Keep both, delete the markers                                   [~75s]
#
# On screen, in the editor. Click the 'Keep both' and then review.
# There are other options, Copilot fix it, manually fix it.
#
#   # FabCon 2026 - team notes
#
#   Best bits so far:
#   - terraform apply is a spinner with ambition
#   - lunch is at 12:45 and it is non-negotiable
#
# Say why: nobody was wrong. Both notes were true. Someone had to decide, in public, and
# the deciding is the job -- not the typing.
code notes/team-notes.md
#endregion


#region 11 · JESS · Stage the resolution and commit it                              [~40s]
git add notes/team-notes.md
git status
git commit --no-edit
#endregion


#region 12 · BOTH · The shape of what just happened                                 [~45s]
#
# Two lines of history that diverged and came back together, with a commit that exists
# only because a human made a decision. Point at the merge commit.
git log --oneline --graph -8
#endregion


#region 99 · RESET -- run this before you walk away                                 [~40s]
#
# JESS runs the first block, ROB runs the second. Or one of you runs both, on both
# machines. Nothing here touches main, and nothing here runs `git clean`.
git switch main
git branch -D demo/merge-jess 2>$null
git branch -D demo/merge-rob 2>$null
git push origin --delete demo/merge-rob 2>$null
Remove-Item notes/team-notes.md -ErrorAction SilentlyContinue
git status
#endregion
