<#
    DEMO 02b - The attendee-count bump ("more of you than we planned for")
    ATTENDEE PAGE: none
    SLOT:          Morning 2 - ~11:55, after the Azure SQL + Fabric applies (demo 02)
    RUNTIME:       ~12 minutes. The plan is quick; the apply runs unattended (do not watch it).
    SLIDES:        "Demo - one number, more databases" (the demo slide says "sit back")
    PRESENTER:     Jess leads, Rob narrates (Morning 2)

    PRESENTER-ONLY. THE ROOM WATCHES.
    This bumps OUR shared attendee endpoint -- one shared thing, in our subscription and our
    state. Attendees cannot each run it, so there is deliberately no attendee page. Say
    "nothing to type for this one" before you start, or half the room will try and fall behind.
    (Anyone who wants it can replay the same change = plan idea on their own fork afterwards.)

    THE POINT
    One number in one file, changed on a branch, produces a precise and reviewable plan of
    EXACTLY the resources it will create -- before anything is built. This is the payoff of the
    plan-on-PR idea planted in Morning 1: change = plan. The most visceral IaC moment of the day.

    THE HEADCOUNT TWIST (why we run this live, now)
    By 11:55 the room is settled, so we know the real number. Bump straight to it -- "we planned
    for ten, there are thirty-eight of you, let's give everyone a database". A plan reading
    "+28 databases, +28 logins, +28 users" is far more visceral than an abstract +5. And the
    timing is generous: attendees do not touch their database until the Afternoon 1 follow-along
    (~14:10), so fire the apply and MOVE ON -- it has hours, plus lunch, to finish.

    DECOUPLE THE SHOW FROM THE PROVISIONING
    Morning 2 is the highest-risk block. If you are behind, the speaker guide cut lever turns
    this into a pre-made PR already open (region 05 still reads the plan on it). BUT the attendee
    databases must exist for the afternoon regardless -- so even if the live demo is cut, still
    run region 06's apply. "We ran out of time for the demo" must never become "nobody has a DB".

    BEFORE YOU START
      - The shared endpoint is already standing at the baseline 10. The morning-of checklist
        provisions it (azure-sql-apply.yml -f target=both) -- so the bump shows a clean "+N",
        not a from-scratch build. If it is NOT up, this demo shows all N as new; stop and apply
        the baseline first (planning/morning-of-checklist.md).
      - `gh auth status` signed in; clean tree, on main.
      - Know the room count before you branch. Do not count heads live on stage.

    See demo/README.md for how to run one of these (short version: F8, never F5).
#>

#region 00 · Guard rail -- do not remove, do not question
# ---------------------------------------------------------------------------------------
# You pressed F5, didn't you.
#
# Top to bottom this would open a pull request, merge it to main without anybody reading it,
# and dispatch a real apply that provisions a database, a login and a user for every attendee
# -- which, in a session whose whole point is "a human reads the plan before it runs", would
# be a bold way to make the point.
#
# `break` stops F5. It does NOT stop F8.
#
# Cursor in a region below -> F8 -> read the SAY line -> then talk.
# ---------------------------------------------------------------------------------------
break
#endregion


#region 01 · Preflight -- where are we, and what is standing?                        [~40s]
# SAY: this morning's apply built ten attendee databases. We are about to change one number
# and let the pipeline tell us, exactly, what more it would build.
git switch main
git pull
git status
# The committed count -- the source of truth the CI plan and apply both read. Should say 10.
Select-String -Path ./infra/azure-sql/terraform/shared-endpoint/variables.tf `
              -Pattern 'default' -Context 3, 0 |
    Where-Object { $_.Context.PreContext -match 'attendee_count' }
#endregion


#region 02 · A branch, and one number                                               [~90s]
# Change `default = 10` to the real room count (max 99). Save.
# SAY, as you type it: "we planned for ten. There are <N> of you. Let's give everyone a database."
git switch -c demo/more-attendees
code ./infra/azure-sql/terraform/shared-endpoint/variables.tf
#endregion


#region 03 · Commit the change, and push it                                         [~30s]
# Put the real number in the message -- it reads back beautifully in the PR.
git commit -am "more attendees: 10 -> <N> databases"
git push --set-upstream origin demo/more-attendees
#endregion


#region 04 · Open the pull request                                                  [~20s]
gh pr create --fill --base main
gh pr view --web
#endregion


#region 05 · Read the plan the robot wrote -- change = plan                         [~3m]
# Wait for the `terraform plan (shared endpoint)` check (the plan-shared-endpoint job in
# azure-sql-plan.yml). It is READ-ONLY (-lock=false -refresh=false) -- it provisions nothing.
# Open it and read the delta to the room, line by line:
#     + <N-10> azurerm_mssql_database
#     + <N-10> mssql_login
#     + <N-10> mssql_user
#     Plan: <N> to add, 0 to change, 0 to destroy.
# SAY: this is the plan-on-PR we planted this morning, paying off. One number in, a precise,
# reviewed list of exactly what it will create out. Nobody has touched Azure yet.
gh pr checks --watch
#endregion


#region 06 · Make it real -- merge, then apply, then MOVE ON                        [~30s]
# Merge puts the new count on main, where the apply reads it from. Then dispatch the apply
# against the shared endpoint and WALK AWAY -- do not watch it. The run summary prints the
# attendee handout (server, shared password, one connection string per attendee).
# The databases are not needed until ~14:10, so this has hours plus lunch to finish.
gh pr merge --squash --delete-branch
gh workflow run azure-sql-apply.yml --ref main -f target=attendee
gh run list --workflow azure-sql-apply.yml --limit 1
#
# IF BEHIND: the speaker guide turns the SHOW above into a pre-made PR already open -- but you
# must still run this apply, or the afternoon follow-along has no databases to deploy into.
#endregion


#region 99 · RESET -- END OF DAY ONLY. Not right after the demo.                     [~40s]
# UNLIKE every other demo, the change this one commits to main (attendee_count = <N>) is the
# state you WANT all afternoon -- it is how the apply knew the count. Do NOT reset it during
# the day. At the END of the day, put the default back to the baseline 10 so main does not
# carry one room's number, and let the nightly destroy remove the databases themselves.
git switch main
git pull
# Set `default = 10` back in variables.tf (edit + save), then:
code ./infra/azure-sql/terraform/shared-endpoint/variables.tf
git commit -am "reset: attendee_count back to baseline 10 after the workshop"
git push
git branch -D demo/more-attendees 2>$null
git status
#endregion
