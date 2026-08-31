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
# WHAT    Two orientation commands. `git remote -v` proves we are on a fork, not the
#         original; `git status` proves we are not about to commit somebody's lunch.
# SAY     "Everything today starts here. One repository, and it is the truth. Not the
#          server, not the portal, not the spreadsheet someone keeps in Teams."
# EXPECT  origin points at a github.com account. `git status` reports a clean tree.
# IF DEAD If the tree is not clean, do NOT start the demo on top of it. `git stash` and
#         carry on; unstash after the RESET region at the bottom.
# PAGE    docs/foundations/demo.md - step 1
git remote -v
git status
#endregion


#region 02 · A branch                                                               [~15s]
# WHAT    Creates and switches to the demo branch in one command.
# SAY     "A branch is just a place to be wrong in private."
# EXPECT  "Switched to a new branch 'demo/source-control'", then the name on its own line.
# IF DEAD "a branch named ... already exists" means a previous run left it behind. Either
#         `git branch -D demo/source-control` first, or add a suffix and keep going. Do
#         not stop to tidy up while the room watches.
# PAGE    docs/foundations/demo.md - step 2
git switch -c demo/source-control
git branch --show-current
#endregion


#region 03 · Write something down                                                   [~60s]
# WHAT    Creates notes/fabcon.md and opens it. The content genuinely does not matter --
#         no pipeline reads this file. That is the point: nothing here can break anything.
# SAY     "I need a change. Any change. The workflow does not care what is in the file,
#          and neither, right now, do we."
# EXPECT  VS Code opens an empty notes/fabcon.md.
# IF DEAD `code` not recognised -> open it from the Explorer instead, or use `notepad`.
#         Not worth a detour; the file is the point, not the editor.
# PAGE    docs/foundations/demo.md - step 3
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
# WHAT    Untracked -> staged, and the staged diff. This is the beat where "a change is a
#         reviewable diff" stops being a slogan and becomes a thing on screen.
# SAY     "This is what a reviewer reads. Not the file -- the difference. A change nobody
#          can read is a change nobody can review."
# EXPECT  `?? notes/fabcon.md` first. After the add, the diff shows a new file with your
#         lines, each prefixed with a green +.
# IF DEAD Empty diff means the file was not saved. Ctrl+S in the editor, run again.
#         Happens to everyone; say so and move on.
# PAGE    docs/foundations/demo.md - step 4
git status --short
git add notes/fabcon.md
git diff --cached -- notes/fabcon.md
#endregion


#region 05 · Only the thing we meant                                                [~20s]
# WHAT    Confirms exactly one file is queued. Small step, worth keeping: it is the habit
#         that stops a stray .tfvars going up with a real change.
# SAY     "One file. Check this every time -- it is how secrets get committed."
# EXPECT  "Changes to be committed:" listing new file: notes/fabcon.md, and nothing else.
# IF DEAD Anything unexpected listed -> `git restore --staged <file>` and re-run.
# PAGE    docs/foundations/demo.md - step 5
git status
#endregion


#region 06 · The commit                                                             [~20s]
# WHAT    Commits with a message that says what changed rather than "stuff" or "wip".
# SAY     "The message is for the person reading this in eighteen months. Very often that
#          person is you, and you will not remember."
# EXPECT  A short commit hash, "1 file changed, N insertions(+)", and "create mode ...".
# IF DEAD "Please tell me who you are" -> git has no identity on this machine. That is a
#         setup problem, not a demo problem: set user.email / user.name and re-run.
# PAGE    docs/foundations/demo.md - step 6
git commit -m "docs: add FabCon source control demo note"
#endregion


#region 07 · Push                                                                   [~25s]
# WHAT    Pushes the branch and sets it to track origin. --set-upstream is why later
#         `git push` and `git pull` need no arguments.
# SAY     "Now it exists somewhere other than my laptop. Which is the first point at
#          which anybody else can do anything with it."
# EXPECT  "branch 'demo/source-control' set up to track 'origin/demo/source-control'".
# IF DEAD Auth failure -> `gh auth login` in a second terminal. If that is going to take
#         more than a moment, skip to the fallback: show an existing PR in the browser
#         and narrate it. The idea survives; the live push does not matter.
# PAGE    docs/foundations/demo.md - step 7
git push --set-upstream origin demo/source-control
#endregion


#region 08 · The pull request                                                       [~40s]
# WHAT    Opens the PR from the command line. --fill reuses the commit message as the
#         title and body, so there is nothing to type and nothing to fumble.
# SAY     "This is the whole idea of the day, and it is worth being clear about it: a
#          change is a proposal. It is not applied. Somebody gets to read it first, and
#          the pipeline gets to check it, and only then does it become real."
# EXPECT  A pull request URL printed to the terminal.
# IF DEAD "no commits between main and demo/source-control" -> the commit in 06 did not
#         happen. `git log --oneline -1` to confirm, commit, push, retry.
# PAGE    docs/foundations/demo.md - step 8
gh pr create --fill --base main
#endregion


#region 09 · Read it back                                                           [~45s]
# WHAT    The PR from the terminal, then in the browser. The browser is worth the click
#         here -- the checks running live are the thing you want on screen.
# SAY     "Four checks. On a one-line change to a Markdown file. That looks like overkill
#          until you remember they are the same four checks standing between a broken
#          Terraform module and main, this afternoon."
# EXPECT  Title, branches, state, URL. In the browser: checks queued or running.
# IF DEAD If checks are slow, do not wait for green. Say what they do, move on, and come
#         back to the tab later in the session when they have finished on their own.
# PAGE    docs/foundations/demo.md - step 9
gh pr view
gh pr view --web
#endregion


#region 99 · RESET -- run this before you walk away                                 [~20s]
# WHAT    Closes the demo PR, returns to main, and removes the branch locally and on the
#         fork. Leaves notes/fabcon.md gone, because it was never meant to survive.
# SAY     Nothing. The room is at coffee.
# EXPECT  Back on main, `git status` clean, branch gone from both places.
# IF DEAD `gh pr close` fails if the PR was already merged or closed -- that is fine,
#         the -ErrorAction below swallows it. If the branch delete complains it is not
#         fully merged, that is expected: -D forces it, and we want it gone.
# PAGE    (presenter only -- deliberately not on the attendee page)
gh pr close --delete-branch 2>$null
git switch main
git branch -D demo/source-control 2>$null
git push origin --delete demo/source-control 2>$null
Remove-Item notes/fabcon.md -ErrorAction SilentlyContinue
git status
#endregion
