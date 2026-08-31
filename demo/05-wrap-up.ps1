<#
    DEMO 05 - The whole loop, once, end to end
    ATTENDEE PAGE: docs/wrap-up/demo.md
    SLOT:          Afternoon 2 - 15:45-17:00 (the last thing before Q&A)
    RUNTIME:       ~15 min

    THE POINT
    Everything from the day, in one pass: change a number in Terraform, open a pull
    request, read the plan on it, merge, apply from main, confirm the result in BOTH git
    and the running database, then tear it down. Nothing new is taught here. That is
    deliberate -- the payoff is that the room recognises every step.

    THE NUMBER
    The demo changes database_auto_pause_delay from 60 to 75 in
    infra/azure-sql/terraform/demo/variables.tf.

    !! CHECK IT IS 60 BEFORE YOU START !!
    Region 01 checks for you. If it is already 75, a previous run was committed and never
    reset -- the plan will say "0 to change" and the demo dies on the spot. This has
    happened once already (commit 33cf375), which is why region 01 and the RESET at the
    bottom both exist.

    BEFORE YOU START
      - Clean tree, on main, up to date.
      - `gh auth status` signed in.
      - The Azure OIDC repo variables set, or the apply cannot log in.

    See demo/README.md for how to run one of these (short version: F8, never F5).
#>

#region 00 · Guard rail -- do not remove, do not question
# ---------------------------------------------------------------------------------------
# You pressed F5, didn't you.
#
# This is a DEMO script, not a deployment. Top to bottom it would open a pull request,
# merge it to main without anybody reading it, and dispatch a real apply -- which, given
# that the entire point of the next fifteen minutes is "a human reads the change before it
# happens", would be a bold way to open.
#
# `break` stops F5. It does NOT stop F8.
#
# Cursor in a region below -> F8 -> read the SAY line -> then talk.
# ---------------------------------------------------------------------------------------
break
#endregion


#region 01 · Preflight -- is the number still 60?                                   [~10s]
# WHAT    Checks the starting value before you commit to the bit. Ten seconds now beats
#         discovering "0 to change" in front of the room.
# SAY     Nothing -- run this before you start talking.
# EXPECT  "default     = 60"
# IF DEAD If it prints 75, someone committed a demo run. Fix it before you begin:
#           git checkout main; git pull
#         and if it is still 75, the committed baseline is wrong -- change it back to 60,
#         commit that as a fix, and then start the demo.
# PAGE    (presenter only -- deliberately not on the attendee page)
Select-String -Path .\infra\azure-sql\terraform\demo\variables.tf `
              -Pattern 'default     = \d+' -Context 4, 0 |
    Where-Object { $_.Context.PreContext -match 'database_auto_pause_delay' }
#endregion


#region 02 · A branch, from a current main                                          [~20s]
# WHAT    Fresh branch off an up-to-date main. Same first move as this morning.
# SAY     "Last one of the day, and you have seen every step of it before. That is rather
#          the point."
# EXPECT  Switched to a new branch 'demo/wrapup-azure-sql-change'.
# IF DEAD Branch already exists from a previous run -> `git branch -D
#         demo/wrapup-azure-sql-change` first.
# PAGE    docs/wrap-up/demo.md - step 1
git checkout main
git pull
git checkout -b demo/wrapup-azure-sql-change
#endregion


#region 03 · Change one number                                                      [~60s]
# WHAT    Opens variables.tf. Find database_auto_pause_delay and change 60 to 75. Save.
# SAY     "One number. Seventy-five minutes instead of sixty before the database pauses
#          itself. It is a deliberately boring change -- I want the machinery visible, not
#          the change."
# EXPECT  You edit and save the file.
# IF DEAD Do not go hunting through the file live. Ctrl+F for auto_pause.
# PAGE    docs/wrap-up/demo.md - step 2
code .\infra\azure-sql\terraform\demo\variables.tf
#endregion


#region 04 · Commit and push                                                        [~30s]
# WHAT    Commits the one-line change and pushes the branch.
# SAY     "Message says what changed and why. In eighteen months this is the only record
#          of why the number is seventy-five."
# EXPECT  1 file changed, 1 insertion(+), 1 deletion(-); branch pushed.
# IF DEAD Empty commit -> the file was not saved. Ctrl+S, run again.
# PAGE    docs/wrap-up/demo.md - steps 3-4
git add .\infra\azure-sql\terraform\demo\variables.tf
git commit -m "demo: change Azure SQL auto-pause delay to 75 minutes"
git push -u origin demo/wrapup-azure-sql-change
#endregion


#region 05 · The pull request, and the plan on it                                   [~3m]
# WHAT    Opens the PR and the browser. Then WAIT for the "Azure SQL - Terraform plan (PR)"
#         check and open it -- the plan summary line is the whole demo.
# SAY     "There it is. Zero to add, one to change, zero to destroy. Before I merge
#          anything, before anything is applied, the pipeline has read my change and told
#          me exactly what it will do. This is the same idea as the deploy report we
#          pointed at the database, and it is the same idea as the pull request we opened
#          at half past nine this morning."
# EXPECT  In the plan job's log: Plan: 0 to add, 1 to change, 0 to destroy.
# IF DEAD If the plan check does not appear, the PR did not touch a watched path -- check
#         you edited the file under terraform/demo. If it fails on auth, the fork lacks
#         the Azure repo variables; narrate a previous run instead. Do not wait more than
#         two minutes on stage.
# PAGE    docs/wrap-up/demo.md - step 4
gh pr create --fill --base main
gh pr view --web
#endregion


#region 06 · Merge                                                                  [~20s]
# WHAT    Squash-merges and deletes the branch.
# SAY     "Reviewed, checked, merged. Now -- and only now -- it is on main. And notice it
#          still has not been deployed."
# EXPECT  Merged and branch deleted.
# IF DEAD Merge blocked by a failing required check -> if it is the plan check failing on
#         credentials, say so honestly and merge with --admin, or narrate the rest.
# PAGE    docs/wrap-up/demo.md - step 5
gh pr merge --squash --delete-branch
#endregion


#region 07 · Apply, on intent                                                       [~6m]
# WHAT    Dispatches the apply from main and watches it.
# SAY     "Merging did not deploy it. Somebody still has to decide. That gap between 'the
#          change is agreed' and 'the change is live' is where approval gates live, and it
#          is the last piece of the day."
# EXPECT  Apply complete! Resources: 0 added, 1 changed, 0 destroyed.
# IF DEAD Must be --ref main for the OIDC subject to match. If the apply fails, use the
#         fallback tab -- with fifteen minutes left, do not debug.
# PAGE    docs/wrap-up/demo.md - step 6
gh workflow run azure-sql-apply.yml --ref main -f target=demo
gh run list --workflow azure-sql-apply.yml --limit 1
gh run watch
gh run view --web
#endregion


#region 08 · Close the loop -- code AND runtime                                     [~90s]
# WHAT    Shows the committed change locally, then points at the same value being applied
#         in the run log. Both halves, on purpose.
# SAY     "The code says seventy-five. The database says seventy-five. When those two stop
#          agreeing, that is drift -- and the only reason they agree here is that the only
#          route to a change was a pull request. Trust the code alone and drift hides."
# EXPECT  The diff shows 60 -> 75; the run log shows the same value applied.
# IF DEAD n/a -- local git commands.
# PAGE    docs/wrap-up/demo.md - step 7
git switch main
git pull
git --no-pager show -- .\infra\azure-sql\terraform\demo\variables.tf
#endregion


#region 09 · Teardown -- do it, do not just recommend it                            [~4m]
# WHAT    Destroys everything the day created. Run it in front of them.
# SAY     "We have told you all day to tear it down. So here we are, tearing it down. The
#          nightly job is a backstop, not a plan -- if you are finished, finish properly."
# EXPECT  Destroy workflow queues and completes.
# IF DEAD If you are out of time, dispatch it and move to Q&A without watching. The
#         nightly cron catches it either way.
# PAGE    docs/wrap-up/demo.md - Teardown
gh workflow run azure-sql-destroy.yml --ref main -f target=both
gh run list --workflow azure-sql-destroy.yml --limit 1
gh run watch
#endregion


#region 99 · RESET -- put the number back. THIS IS THE ONE PEOPLE FORGET.           [~40s]
# WHAT    Returns database_auto_pause_delay to 60 on main, so the demo works next time.
#         Step 8 of the attendee page says to do this; the last person to run it did not,
#         and the value sat wrong on main until it was found writing these scripts.
# SAY     Nothing. Everyone has gone to find a drink.
# EXPECT  variables.tf shows 60 again, committed and pushed.
# IF DEAD If you would rather do it as a pull request for the sake of consistency, do --
#         but do it. A five-second `git commit` beats the next presenter finding out the
#         hard way.
# PAGE    docs/wrap-up/demo.md - step 8
git switch main
git pull
code .\infra\azure-sql\terraform\demo\variables.tf   # change 75 back to 60, and save
git add .\infra\azure-sql\terraform\demo\variables.tf
git commit -m "demo: reset Azure SQL auto-pause delay to 60 minutes"
git push
git status --short
#endregion
