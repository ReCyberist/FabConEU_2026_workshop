<#
    DEMO 05 - The whole loop, once, end to end
    ATTENDEE PAGE: docs/wrap-up/demo.md
    SLOT:          Afternoon 2 - 16:00-16:30 (the last demo, before the close and Q&A at 16:30)
    RUNTIME:       ~15 min

    THE POINT
    Everything from the day, in one pull request: change a number in Terraform AND add a
    database change, open the PR, and watch the two guard rails do their jobs on it -- the
    Terraform plan shows what infra WOULD change, and the SQL build refuses a smell. The
    database change is broken on purpose (SELECT * and, for the humans, an emoji in the
    object name). CI catches the SELECT *; a reviewer catches the name. Fix it, go green,
    merge, apply from main, confirm the result in BOTH git and the running database, then
    tear it down. Nothing new is taught here -- the payoff is that the room recognises
    every step.

    THE TWO CHANGES IN THE PR
      infra     database_auto_pause_delay 60 -> 75 in
                infra/azure-sql/terraform/demo/variables.tf
      database  a new view football.vw_Standings, copied in from database/demo/wrap-up/.
                The BAD copy has SELECT * (SR0001, fails the build) and an emoji name.
                The FIXED copy has an explicit column list and a plain name.

    !! CHECK THE NUMBER IS 60 BEFORE YOU START !!
    Region 01 checks for you. If it is already 75, a previous run was committed and never
    reset -- the plan will say "0 to change" and the demo falls over in front of the room.
    This has happened once already (commit 33cf375), which is why region 01 and the RESET
    at the bottom both exist. The RESET also removes the merged view; if a previous run
    left it on main, the SQL build will already be green and there is nothing to catch.

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
# merge it to main without anybody reading it, and let a real apply publish a new view to
# a live database -- which, given that the entire point of the next twenty minutes is "a
# human, and a machine, read the change before it happens", would be a bold way to open.
#
# `break` stops F5. It does NOT stop F8.
#
# Cursor in a region below -> F8 -> read the SAY line -> then talk.
# ---------------------------------------------------------------------------------------
break
#endregion


#region 01 · Preflight -- is the number still 60?                                   [~10s]
Select-String -Path ./infra/azure-sql/terraform/demo/variables.tf `
              -Pattern 'default     = \d+' -Context 4, 0 |
    Where-Object { $_.Context.PreContext -match 'database_auto_pause_delay' }
#endregion


#region 02 · A branch, from a current main                                          [~20s]
git checkout main
git pull
git checkout -b demo/wrapup-change
#endregion


#region 03 · Change one number -- the infra change                                  [~60s]
# SAY: same move as this morning. 60 to 75, save. That is the whole infra change.
code ./infra/azure-sql/terraform/demo/variables.tf
#endregion


#region 04 · Add the database change -- a new view                                  [~60s]
# SAY: and a colleague has sent us a new standings view to ship in the same PR.
# Copy it in, and read it out loud. Let the room find what is wrong with it.
Copy-Item ./database/demo/wrap-up/vw_Standings.bad.sql `
          ./database/sql-projects/Views/vw_Standings.sql
code ./database/sql-projects/Views/vw_Standings.sql
# WHAT THEY SHOULD SPOT: `SELECT *` (a machine can catch that), and an emoji in the
# object name (a machine cannot -- that one is on us). Do not say which CI catches yet.
#endregion


#region 05 · Commit both changes, and push                                          [~30s]
git add ./infra/azure-sql/terraform/demo/variables.tf `
        ./database/sql-projects/Views/vw_Standings.sql
git commit -m "demo: bump auto-pause to 75 and add standings view"
git push -u origin demo/wrapup-change
#endregion


#region 06 · Open the pull request                                                  [~20s]
gh pr create --fill --base main
#endregion


#region 07 · Read the PR -- one guard rail passes, one fails                        [~2m]
# SAY: two checks matter here. The Terraform plan comment says what infra WOULD change --
# `Plan: 0 to add, 1 to change, 0 to destroy`, exactly as this morning. And the CI check
# "Build SQL project + code analysis" is RED: the SELECT * trips SR0001 and -warnaserror
# fails the build. Open the failed check and let them read the SR0001 line.
#
# THEN say the quiet part: the emoji name is also wrong, and NO analyser flagged it. That
# is what the human review is for. The machine and the person catch different things.
gh pr view --web
gh pr checks
#endregion


#region 08 · Fix the view, and push the fix                                         [~90s]
# Explicit column list, plain name. Show the diff -- both problems, gone in one change.
Copy-Item ./database/demo/wrap-up/vw_Standings.fixed.sql `
          ./database/sql-projects/Views/vw_Standings.sql
git --no-pager diff -- ./database/sql-projects/Views/vw_Standings.sql
git add ./database/sql-projects/Views/vw_Standings.sql
git commit -m "demo: list columns and drop the emoji from the standings view"
git push
#endregion


#region 09 · The checks go green                                                    [~2m]
# EXPECT: the SQL build re-runs on the new commit and passes. Green tick, mergeable.
gh pr checks --watch
#endregion


#region 10 · Merge                                                                  [~20s]
gh pr merge --squash --delete-branch
#endregion


#region 11 · Apply happens on commit to main                                        [~6m]
# No dispatch. The push to main from the merge triggers azure-sql-apply.yml, which routes
# to the demo flow (both the infra change and database/sql-projects changed), runs the
# Terraform apply, then publishes the DACPAC -- so the new view lands in the database too.
gh run list --workflow azure-sql-apply.yml --limit 1
gh run watch
gh run view --web
#endregion


#region 12 · Close the loop -- code AND runtime                                     [~90s]
# The number, on main. And the view file, on main. Both arrived by pull request.
git switch main
git pull
git --no-pager show -- ./infra/azure-sql/terraform/demo/variables.tf
Get-Content ./database/sql-projects/Views/vw_Standings.sql
# In the workflow run log, point to the publish job applying the same view to the database.
#endregion


#region 13 · Teardown -- do it, do not just recommend it                            [~4m]
gh workflow run azure-sql-destroy.yml --ref main -f target=both
gh run list --workflow azure-sql-destroy.yml --limit 1
gh run watch
#endregion


#region 99 · RESET -- put the number back AND remove the view. PEOPLE FORGET THIS.  [~60s]
# Assumes the demo reached the merge. If you aborted before merging, the view is not on
# main -- use `Remove-Item ./database/sql-projects/Views/vw_Standings.sql` and
# `git restore ./infra/azure-sql/terraform/demo/variables.tf` instead of the below.
git switch main
git pull
code ./infra/azure-sql/terraform/demo/variables.tf   # change 75 back to 60, and save
git rm ./database/sql-projects/Views/vw_Standings.sql
git add ./infra/azure-sql/terraform/demo/variables.tf
git commit -m "demo: reset wrap-up -- auto-pause 60, remove standings view"
git push
git status --short
#endregion
