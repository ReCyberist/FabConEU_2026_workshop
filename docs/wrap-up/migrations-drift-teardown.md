# Migrations, drift & teardown

Close the day by running one final end-to-end change: edit Azure SQL infrastructure as code,
raise a pull request, show the plan summary, merge, and apply from `main`.

## The concept

- **Pull request first.** Terraform plan on the PR shows what will change before you merge.
- **Apply on intent.** Real deployment is a manual dispatch from `main`.
- **Drift awareness.** You trust code + state, then confirm the runtime result.
- **Teardown always.** Sandbox resources are disposable.

## Final demo — PR to deployment

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
     code .\infra\azure-sql\terraform\variables.tf
     ```

     In `database_auto_pause_delay`, change:
     - `default = 60`
     - to `default = 75`

     Save the file.

3. Commit the change.

     ```powershell
     git add .\infra\azure-sql\terraform\variables.tf
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
     git --no-pager show -- .\infra\azure-sql\terraform\variables.tf
     ```

     In the workflow run log, point to the same change being applied to the database.

8. Reset the demo default back to 60 for the next run.

     Repeat steps 1-7 with:
     - `default = 75` changed back to `default = 60`.

     This keeps the repository baseline consistent for future sessions.

## Reference — migration-based options

- [Flyway](https://github.com/JessAndRob/FabConEU_2026_workshop/tree/main/database/flyway)
- [dbatools / dbops](https://github.com/JessAndRob/FabConEU_2026_workshop/tree/main/database/dbatools-dbops)

## Teardown

If you deployed resources in your own subscription, run teardown before you finish.

```powershell
gh workflow run azure-sql-destroy.yml --ref main -f target=both
gh run list --workflow azure-sql-destroy.yml --limit 1
gh run watch
```

Nightly destroy still runs as the backstop, but do not rely on it during workshops.

## What's next

Next: [Resources & next steps](resources.md).
