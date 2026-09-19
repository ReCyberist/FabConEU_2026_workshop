<#
    DEMO 01 - Source control
    ATTENDEE PAGE: docs/foundations/demo.md
    SLOT:          Morning 1 - 09:00-10:30 (the source-control half)
    RUNTIME:       ~8 minutes at a comfortable pace

    THE POINT
    Before any infrastructure shows up, the room sees the shape of every change we will
    make all day: branch -> commit -> push -> pull request. Nothing is clicked. The file
    we change today is a note; by this afternoon it is Terraform and T-SQL, and the flow
    has not moved an inch.

    BEFORE YOU START
      - A terminal in the repository root, on a clean tree (`git status` says nothing).
      - `gh auth status` is signed in.
      - Zoom the terminal up. Git output is small and the back row is real.
      - Optional but good: have github.com open on the repo in a second tab, so you can
        show the pull request in the browser after step 08.

    See demo/README.md for how to run one of these (short version: F8, never F5).
#>

#region 00 · Guard rail -- do not remove, do not question
# ---------------------------------------------------------------------------------------
# You pressed F5, didn't you.
#
# This is a DEMO script, not a deployment. Top to bottom, in front of 300 people, it
# would open a pull request against your fork before you had finished saying "so, source
# control", and you would spend the next ten minutes explaining a branch you did not mean
# to create.
#
# `break` stops F5. It does NOT stop F8.
#
# Cursor in a region below -> F8 -> read the SAY line -> then talk.
# ---------------------------------------------------------------------------------------
break
#endregion


#region 01 · Where are we, and is it ours?                                          [~30s]
git remote -v
git status
#endregion


#region 02 · A branch                                                               [~15s]
git switch -c demo/source-control
git branch --show-current
#endregion


#region 03 · Write something down                                                   [~60s]
#
# TYPE THIS IN, DO NOT PASTE IT. The room enjoys watching someone type, and it buys you
# fifteen seconds of narration. Keep it short and keep it kind:
#
#   # Fabcon 2026 - Best Workshop so far!
#
#   So far I have learnt:
#   - Jess loves breakfast
#   - Rob has a beard
#
New-Item -Path notes/fabcon.md -ItemType File
code notes/fabcon.md
#endregion


#region 04 · What git noticed                                                       [~45s]
git status --short
git add notes/fabcon.md
git diff --cached -- notes/fabcon.md
#endregion


#region 05 · Only the thing we meant                                                [~20s]
git status
#endregion


#region 06 · The commit                                                             [~20s]
git commit -m "docs: add FabCon source control demo note"
#endregion


#region 07 · Push                                                                   [~25s]
git push --set-upstream origin demo/source-control
#endregion


#region 08 · The pull request                                                       [~40s]
gh pr create --fill --base main
#endregion


#region 09 · Read it back                                                           [~45s]
gh pr view
gh pr view --web
#endregion


#region 99 · RESET -- run this before you walk away                                 [~20s]
gh pr close --delete-branch demo/source-control
git status
#endregion
