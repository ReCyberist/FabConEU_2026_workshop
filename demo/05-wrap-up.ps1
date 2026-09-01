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
    reset -- the plan will say "0 to change" and the demo falls over in front of the
    room. This has happened once already (commit 33cf375), which is why region 01 and the
    RESET at the bottom both exist.

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
Select-String -Path .\infra\azure-sql\terraform\demo\variables.tf `
              -Pattern 'default     = \d+' -Context 4, 0 |
    Where-Object { $_.Context.PreContext -match 'database_auto_pause_delay' }
#endregion


#region 02 · A branch, from a current main                                          [~20s]
git checkout main
git pull
git checkout -b demo/wrapup-azure-sql-change
#endregion


#region 03 · Change one number                                                      [~60s]
code .\infra\azure-sql\terraform\demo\variables.tf
#endregion


#region 04 · Commit and push                                                        [~30s]
git add .\infra\azure-sql\terraform\demo\variables.tf
git commit -m "demo: change Azure SQL auto-pause delay to 75 minutes"
git push -u origin demo/wrapup-azure-sql-change
#endregion


#region 05 · The pull request, and the plan on it                                   [~3m]
gh pr create --fill --base main
gh pr view --web
#endregion


#region 06 · Merge                                                                  [~20s]
gh pr merge --squash --delete-branch
#endregion


#region 07 · Apply, on intent                                                       [~6m]
gh workflow run azure-sql-apply.yml --ref main -f target=demo
gh run list --workflow azure-sql-apply.yml --limit 1
gh run watch
gh run view --web
#endregion


#region 08 · Close the loop -- code AND runtime                                     [~90s]
git switch main
git pull
git --no-pager show -- .\infra\azure-sql\terraform\demo\variables.tf
#endregion


#region 09 · Teardown -- do it, do not just recommend it                            [~4m]
gh workflow run azure-sql-destroy.yml --ref main -f target=both
gh run list --workflow azure-sql-destroy.yml --limit 1
gh run watch
#endregion


#region 99 · RESET -- put the number back. THIS IS THE ONE PEOPLE FORGET.           [~40s]
git switch main
git pull
code .\infra\azure-sql\terraform\demo\variables.tf   # change 75 back to 60, and save
git add .\infra\azure-sql\terraform\demo\variables.tf
git commit -m "demo: reset Azure SQL auto-pause delay to 60 minutes"
git push
git status --short
#endregion
