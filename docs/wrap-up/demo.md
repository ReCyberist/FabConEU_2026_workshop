# Wrap-up demo — from pull request to deployment

This is the final end-to-end run of the day: change Azure SQL infrastructure as code, raise a pull
request, read the plan, merge, apply from `main`, then tear it down. Everything from this morning,
in one loop.

!!! note "Follow along — or just watch"
    You need a fork of the repository, GitHub CLI signed in, and Azure access configured for the
    workflows. See [Prerequisites](../setup/prerequisites.md) and
    [Migrations, drift & teardown](migrations-drift-teardown.md).

## Run it

This demo changes one Azure SQL database setting by code, then shows the full CI/CD loop.

1. Create a branch for the wrap-up demo.

     ```powershell
     git checkout main
     git pull
     git checkout -b demo/wrapup-azure-sql-change
     ```

2. Change the Azure SQL serverless auto-pause value in Terraform.

     Open the variables file:

     ```powershell
     code .\infra\azure-sql\terraform\demo\variables.tf
     ```

     In `database_auto_pause_delay`, change:
     - `default = 75`
     - to `default = 90`

     Save the file.

3. Commit the change.

     ```powershell
     git add .\infra\azure-sql\terraform\demo\variables.tf
     git commit -m "demo: change Azure SQL auto-pause delay to 75 minutes"
     ```

4. Push and open a pull request.

     ```powershell
     git push -u origin demo/wrapup-azure-sql-change
     gh pr create --fill --base main
     gh pr view --web
     ```

     In the PR checks, open **Azure SQL - Terraform plan (PR)** and show the plan summary line.
     Expected shape: `Plan: 0 to add, 1 to change, 0 to destroy`.

5. Merge the pull request.

     ```powershell
     gh pr merge --squash --delete-branch
     ```

     The change is now on `main`, ready for deliberate apply.

6. Dispatch the Azure SQL apply workflow from `main`.

     ```powershell
     gh workflow run azure-sql-apply.yml --ref main -f target=demo
     gh run list --workflow azure-sql-apply.yml --limit 1
     gh run watch
     gh run view --web
     ```

     Show the apply summary and the Terraform result line.
     Expected shape: `Apply complete! Resources: 0 added, 1 changed, 0 destroyed`.

7. Show the change in code and runtime.

     ```powershell
     git switch main
     git pull
     git --no-pager show -- .\infra\azure-sql\terraform\demo\variables.tf
     ```

     In the workflow run log, point to the same change being applied to the database.

8. Reset the demo default back to 60 for the next run.

     Repeat steps 1-7, but use a new branch name (for example, `demo/wrapup-azure-sql-reset`), with:
     - `default = 75` changed back to `default = 60`.

     This keeps the repository baseline consistent for future sessions.

## Teardown

If you deployed resources in your own subscription, run teardown before you finish.

```powershell
gh workflow run azure-sql-destroy.yml --ref main -f target=both
gh run list --workflow azure-sql-destroy.yml --limit 1
gh run watch
```

Nightly destroy still runs as the backstop, but do not rely on it during workshops.

## Checkpoint

You have taken one change from a branch to a running database and back out again: a pull request
carrying a `terraform plan`, a merge, a deliberate apply from `main`, the same value confirmed in
both git and the database, and a teardown that leaves nothing billing. That is the whole day in
one loop.

## What's next

Next: [Resources & next steps](resources.md).
