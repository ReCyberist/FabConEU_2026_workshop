# Wrap-up demo — from pull request to deployment

--8<-- "includes/clock-afternoon-2.md"

This is the final end-to-end run of the day. One pull request carries two changes: an Azure SQL
infrastructure change and a database change. You raise the pull request, watch both guard rails
check it — the Terraform plan and the SQL build — fix what the build refuses, merge, apply from
`main`, then tear it down. Everything from this morning, in one loop.

!!! note "Follow along — or just watch"
    You need a fork of the repository, GitHub CLI signed in, and Azure access configured for the
    workflows. See [Prerequisites](../setup/prerequisites.md) and
    [Migrations, drift & teardown](migrations-drift-teardown.md).

!!! note "Run these commands in PowerShell"
    Every command on this page is PowerShell. If your prompt is bash or zsh, start PowerShell
    first:

    ```powershell
    pwsh
    ```

    The prompt changes to `PS>`. PowerShell 7 runs on Windows, macOS and Linux, and every
    command on this page works the same on all three.

## Run it

1. Create a branch for the wrap-up demo.

     ```powershell
     git checkout main
     git pull
     git checkout -b demo/wrapup-change
     ```

2. Change the Azure SQL serverless auto-pause value in Terraform.

     Open the variables file:

     ```powershell
     code ./infra/azure-sql/terraform/demo/variables.tf
     ```

     In `database_auto_pause_delay`, change:
     - `default     = 60`
     - to `default     = 75`

     Save the file. The repository baseline is `60`. If the file already says something else, a
     previous run of this demo was committed and not reset; put it back to `60` before you start,
     or the plan in step 6 reports `0 to change`.

3. Add the database change: copy in a new view.

     ```powershell
     Copy-Item ./database/demo/wrap-up/vw_Standings.bad.sql `
               ./database/sql-projects/Views/vw_Standings.sql
     code ./database/sql-projects/Views/vw_Standings.sql
     ```

     The view has two problems, on purpose. It uses `SELECT *`, and its object name contains an
     emoji. You fix both in step 7.

4. Commit both changes together.

     ```powershell
     git add ./infra/azure-sql/terraform/demo/variables.tf `
             ./database/sql-projects/Views/vw_Standings.sql
     git commit -m "demo: bump auto-pause to 75 and add standings view"
     ```

5. Push and open a pull request.

     ```powershell
     git push -u origin demo/wrapup-change
     gh pr create --fill --base main
     ```

6. Read the checks on the pull request.

     ```powershell
     gh pr view --web
     gh pr checks
     ```

     Two results matter:

     - **Azure SQL - Terraform plan (PR)** passes and posts the plan.
       Expected shape: `Plan: 0 to add, 1 to change, 0 to destroy`.
     - **Build SQL project + code analysis** fails. Open it. The error is
       `SR0001`: the shape of the result set produced by a `SELECT *` statement will change if the
       underlying table or view structure changes. The build runs with `-warnaserror`, so this one
       finding fails the check.

     The emoji in the object name does not fail the build. The analyzer does not check for it. A
     person catches that in review.

7. Fix the view and push the fix.

     ```powershell
     Copy-Item ./database/demo/wrap-up/vw_Standings.fixed.sql `
               ./database/sql-projects/Views/vw_Standings.sql
     git --no-pager diff -- ./database/sql-projects/Views/vw_Standings.sql
     git add ./database/sql-projects/Views/vw_Standings.sql
     git commit -m "demo: list columns and drop the emoji from the standings view"
     git push
     ```

     The fixed view lists its columns and uses a plain object name, `football.vw_Standings`.

8. Watch the checks go green.

     ```powershell
     gh pr checks --watch
     ```

     The SQL build re-runs on the new commit and passes. The pull request is now mergeable.

9. Merge the pull request.

     ```powershell
     gh pr merge --squash --delete-branch
     ```

     The change is now on `main`.

10. Watch the apply, which starts on merge.

     The merge pushes to `main`, which triggers the Azure SQL apply workflow. No dispatch is
     needed. The workflow applies the Terraform change, then publishes the database, so the new
     view lands in the database as well.

     ```powershell
     gh run list --workflow azure-sql-apply.yml --limit 1
     gh run watch
     gh run view --web
     ```

     Show the apply summary and the Terraform result line.
     Expected shape: `Apply complete! Resources: 0 added, 1 changed, 0 destroyed`.

11. Show the change on `main`.

     ```powershell
     git switch main
     git pull
     git --no-pager show -- ./infra/azure-sql/terraform/demo/variables.tf
     Get-Content ./database/sql-projects/Views/vw_Standings.sql
     ```

     The variables file shows `default     = 75`, and the view file is present on `main`. Both
     arrived through the pull request. In the workflow run log, the publish job applied this same
     view to the database.

12. Query the live view to prove it returns rows.

    Sign in to Azure, get a token, and set the server and database you deployed to.

    ```powershell
    az login
    $token  = az account get-access-token --resource https://database.windows.net/ --query accessToken -o tsv
    $server = "<your-server-name>"
    $db     = "<your-database-name>"
    ```

    On the shared attendee endpoint, use SQL login instead of a token. Set `$server`, `$db`, and
    `$sqlCredential` as shown on the [database demo page](../database/demo.md), then use the
    **Attendee path** tab below.

    === "Presenter path (Entra token)"

        ```powershell
        $ConnectionParams = @{
            SqlInstance = $server
            Database    = $db
            AccessToken = $token
        }
        $serverSMO = Connect-DbaInstance @ConnectionParams

        $queryParams = @{
            SqlInstance = $serverSMO
            Database    = $db
            Query       = "SELECT Competition, Position, Team, Played, Points FROM football.vw_Standings WHERE Position <= 5 ORDER BY Competition, Position"
        }

        Invoke-DbaQuery @queryParams
        ```

    === "Attendee path (SQL login)"

        ```powershell
        $queryParams = @{
            SqlInstance   = $server
            Database      = $db
            SqlCredential = $sqlCredential
            Query         = "SELECT Competition, Position, Team, Played, Points FROM football.vw_Standings WHERE Position <= 5 ORDER BY Competition, Position"
        }

        Invoke-DbaQuery @queryParams
        ```

    The query returns the top five of each competition, ranked by position. The Premier League and
    the WSL are separate tables, not mixed together. The view you read as a file is now answering
    from the live database.

## Teardown

If you deployed resources in your own subscription, run teardown before you finish.

```powershell
gh workflow run azure-sql-destroy.yml --ref main -f target=both
gh run list --workflow azure-sql-destroy.yml --limit 1
gh run watch
```

Nightly destroy still runs as the backstop, but do not rely on it during workshops.

## Reset for the next run

Return the repository to its baseline: auto-pause `60`, and no standings view.

1. Switch to `main` and pull the merged change.

     ```powershell
     git switch main
     git pull
     ```

2. Open the variables file and change `default     = 75` back to `default     = 60`. Save it.

     ```powershell
     code ./infra/azure-sql/terraform/demo/variables.tf
     ```

3. Remove the view, commit both, and push.

     ```powershell
     git rm ./database/sql-projects/Views/vw_Standings.sql
     git add ./infra/azure-sql/terraform/demo/variables.tf
     git commit -m "demo: reset wrap-up -- auto-pause 60, remove standings view"
     git push
     ```

## Checkpoint

You have taken two changes from a branch to a running database and back out again in one pull
request: a Terraform change carrying a `terraform plan`, a database change that the SQL build
refused until you fixed it, a merge, an apply from `main` that landed both the infra change and
the view, the same results confirmed in git and the database, and a teardown that leaves nothing
billing. That is the whole day in one loop.

## What's next

Next: [Resources & next steps](resources.md).
