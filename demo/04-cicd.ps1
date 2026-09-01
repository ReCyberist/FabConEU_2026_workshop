<#
    DEMO 04 - CI/CD: validate automatically, deploy deliberately, tear down on schedule
    ATTENDEE PAGE: docs/cicd/demo.md
    SLOT:          Afternoon 2 - 15:45-17:00
    RUNTIME:       ~15 min, most of it watching runs

    THE POINT
    Three behaviours, in this order, because they build on each other:
      validate  on every change, automatically, needing no credentials
      apply     only on intent -- a manual dispatch, from main
      destroy   on a schedule, so a forgotten sandbox does not bill all month

    READ THE YAML FIRST
    Regions 01-03 open the workflow files before anything runs. Do not skip them for time.
    Watching a green tick appear teaches nothing; reading the twelve lines that produced it
    teaches the whole idea. If you are short, cut a WATCH region, not a READ one.

    BEFORE YOU START
      - `gh auth status` signed in, and the fork's Actions enabled.
      - Azure OIDC variables set on the repo (AZURE_CLIENT_ID, AZURE_TENANT_ID,
        AZURE_SUBSCRIPTION_ID) or the apply in region 07 will fail at login.
      - A previously-successful apply run open in a tab, as the fallback.

    See demo/README.md for how to run one of these (short version: F8, never F5).
#>

#region 00 · Guard rail -- do not remove, do not question
# ---------------------------------------------------------------------------------------
# You pressed F5, didn't you.
#
# This is a DEMO script, not a deployment. Top to bottom it would dispatch a real apply
# against a real subscription, having first opened four YAML files you were going to talk
# about. The apply would probably succeed, which is the worrying part.
#
# `break` stops F5. It does NOT stop F8.
#
# Cursor in a region below -> F8 -> read the SAY line -> then talk.
# ---------------------------------------------------------------------------------------
break
#endregion


#region 01 · Read: what runs on every change                                        [~2m]
code .\.github\workflows\ci.yml
#endregion


#region 02 · Read: the read-only plan on a pull request                             [~2m]
code .\.github\workflows\azure-sql-plan.yml
#endregion


#region 03 · Read: the one that actually deploys                                    [~2m]
code .\.github\workflows\azure-sql-apply.yml
#endregion


#region 04 · The workflows, as GitHub sees them                                     [~20s]
gh workflow list
#endregion


#region 05 · Trigger validation                                                     [~15s]
gh workflow run ci.yml --ref main
#endregion


#region 06 · Watch it                                                              [~2-3m]
gh run list --workflow ci.yml --limit 1
gh run watch
#endregion


#region 07 · Deploy, on purpose                                                     [~15s]
gh workflow run azure-sql-apply.yml --ref main -f target=demo
#endregion


#region 08 · Watch the deploy                                                       [~5-6m]
gh run list --workflow azure-sql-apply.yml --limit 1
gh run watch
gh run view --web
#endregion


#region 09 · And the thing that cleans up after us                                  [~90s]
code .\.github\workflows\azure-sql-destroy.yml
#endregion


#region 99 · RESET                                                                  [~10s]
git status --short
#endregion
