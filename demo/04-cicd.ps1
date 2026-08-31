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
# WHAT    Opens ci.yml. Four path-gated jobs, no cloud credentials anywhere in it.
# SAY     "Push, pull request, or a button. Four jobs, and every one of them can run on a
#          fork owned by somebody I have never met -- because not one of them needs a
#          credential. They build, they format, they validate. That is all."
# EXPECT  The file opens. Point at: the `on:` triggers, -warnaserror on the database job,
#         and the dorny/paths-filter gating so a SQL-only change does not build the docs.
# IF DEAD n/a -- it is a file open.
# PAGE    docs/cicd/demo.md - Before you run it, step 1
code .\.github\workflows\ci.yml
#endregion


#region 02 · Read: the read-only plan on a pull request                             [~2m]
# WHAT    Opens azure-sql-plan.yml. Pull-request only, plan only, OIDC only.
# SAY     "This one does touch Azure -- and it is still safe, because it can only ever
#          plan. There is no apply in this file. A reviewer sees precisely what the change
#          would do, and the change still has not happened."
# EXPECT  Point at: pull_request trigger, `id-token: write` (OIDC, no stored secret), and
#         the two separate plan jobs -- the taught module and the shared endpoint.
# IF DEAD n/a
# PAGE    docs/cicd/demo.md - Before you run it, step 2
code .\.github\workflows\azure-sql-plan.yml
#endregion


#region 03 · Read: the one that actually deploys                                    [~2m]
# WHAT    Opens azure-sql-apply.yml. workflow_dispatch only -- there is no push trigger,
#         and that absence is deliberate.
# SAY     "Look at what is NOT in this file. No push. No pull request. The only way this
#          runs is somebody choosing to run it. Deployment is a decision, so it looks
#          like one."
# EXPECT  Point at: workflow_dispatch, the `target` input (demo / attendee / both), and
#         that one run does DACPAC build, deploy report, publish AND smoke test.
# IF DEAD n/a
# PAGE    docs/cicd/demo.md - Before you run it, step 3
code .\.github\workflows\azure-sql-apply.yml
#endregion


#region 04 · The workflows, as GitHub sees them                                     [~20s]
# WHAT    Lists the workflows so the names on screen match the names you are about to type.
# SAY     "Same files, from the other side."
# EXPECT  The list includes CI, "Azure SQL - Terraform apply", "Azure SQL - Terraform
#         destroy".
# IF DEAD "could not determine base repo" -> you are outside the repository folder, or gh
#         is not authenticated. `gh auth status`.
# PAGE    docs/cicd/demo.md - Run it, step 1
gh workflow list
#endregion


#region 05 · Trigger validation                                                     [~15s]
# WHAT    Fires CI manually. Manual only because we need it to start on cue -- normally
#         nobody triggers this by hand, it just happens.
# SAY     "In real life I would never run this. It runs itself, on every push and every
#          pull request. I am only pressing the button so we can watch it."
# EXPECT  "workflow_dispatch" accepted; a run queues.
# IF DEAD If dispatch is rejected, the workflow needs `workflow_dispatch:` in its `on:`
#         block -- ci.yml has it. On a fresh fork, Actions may need enabling once in the
#         browser.
# PAGE    docs/cicd/demo.md - Run it, step 2
gh workflow run ci.yml --ref main
#endregion


#region 06 · Watch it                                                              [~2-3m]
# WHAT    Waits for the run and shows each job's result.
# SAY     Talk while it runs. Best material: which jobs are SKIPPED and why. A run that
#         skips three of its four jobs is not a broken run, it is a well-configured one.
# EXPECT  Green. Jobs not matching the changed paths show as skipped.
# IF DEAD `gh run watch` sometimes attaches to the wrong run. `gh run list --workflow
#         ci.yml --limit 3` and pick the id explicitly, or just open it in the browser.
# PAGE    docs/cicd/demo.md - Run it, step 3
gh run list --workflow ci.yml --limit 1
gh run watch
#endregion


#region 07 · Deploy, on purpose                                                     [~15s]
# WHAT    Dispatches the apply from main, targeting the demo flow.
# SAY     "Note what I had to do to make this happen. Name the workflow, name the branch,
#          name the target. Nobody does this by accident, and that is the entire design."
# EXPECT  A deployment run queues.
# IF DEAD Must be `--ref main`. A feature branch run has a different OIDC token subject
#         and the federated credential will refuse it. That failure looks like a login
#         error and is one of the easiest ways to lose ten minutes on stage.
# PAGE    docs/cicd/demo.md - Run it, step 4
gh workflow run azure-sql-apply.yml --ref main -f target=demo
#endregion


#region 08 · Watch the deploy                                                       [~5-6m]
# WHAT    Watches the apply, then opens the run summary in the browser -- the summary is
#         much better to present from than the log.
# SAY     Long one. Narrate the stages as they appear: terraform apply, then the DACPAC
#         build, then the deploy report (the plan for the database), then publish, then a
#         smoke test that queries actual rows. "Infrastructure and schema, one dispatch,
#         no passwords anywhere in it."
# EXPECT  Green, with apply / publish / smoke-test results in the summary.
# IF DEAD Failure at the publish step is almost always Entra access for the CI principal:
#         a logical server allows ONE Entra admin, so the service principal must be in
#         that group, added by OBJECT id, not client id. If it fails, switch to the
#         fallback tab -- do not debug Entra live.
# PAGE    docs/cicd/demo.md - Run it, step 5
gh run list --workflow azure-sql-apply.yml --limit 1
gh run watch
gh run view --web
#endregion


#region 09 · And the thing that cleans up after us                                  [~90s]
# WHAT    Opens the destroy workflow. Nightly cron plus manual dispatch.
# SAY     "Last one, and it is the one people forget to build. Everything we made today
#          disappears at nine tonight. If you take one workflow home, it is arguably this
#          one -- the demo environment that bills for eleven months is a genuine genre."
# EXPECT  A schedule block and a workflow_dispatch block.
# IF DEAD n/a
# PAGE    docs/cicd/demo.md - Run it, step 6
code .\.github\workflows\azure-sql-destroy.yml
#endregion


#region 99 · RESET                                                                  [~10s]
# WHAT    Nothing to undo locally -- this demo only reads files and triggers workflows.
#         The only state it created is in Azure, and the nightly destroy handles that.
# SAY     Nothing.
# EXPECT  Clean tree.
# IF DEAD If you dispatched an apply and are NOT coming back tomorrow, tear it down now
#         rather than trusting the cron:
#           gh workflow run azure-sql-destroy.yml --ref main -f target=both
# PAGE    (presenter only -- deliberately not on the attendee page)
git status --short
#endregion
