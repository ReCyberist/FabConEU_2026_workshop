<#
    DEMO 02 - Infrastructure as code (Azure SQL, then Fabric SQL)
    ATTENDEE PAGE: docs/infra/demo.md
    SLOT:          Morning 2 - 11:00-12:15
    RUNTIME:       Azure SQL ~12 min incl. a 4m31s apply. Fabric ~10 min.

    THE POINT
    Two platforms, one flow: read the module, plan, apply. Azure SQL is server -> database.
    Fabric is capacity -> workspace -> database, and it takes two providers to build. The
    shapes differ; the discipline does not.

    TIMING - READ THIS
    The agenda flags this as the section most likely to overrun (#13). The apply is ~4.5
    minutes of nothing happening on screen. Kick it off EARLY and narrate the module while
    it runs -- do not start the apply and then go quiet. If you are behind by the Fabric
    section, show the plan and skip the apply; the contrast is the teaching point, not the
    second set of resources.

    BEFORE YOU START
      - `az login` done, and the right subscription selected.
      - A completed apply run open in a browser tab as the fallback if this one stalls.
      - Know your subscription id. Do not go hunting for it on stage.

    See demo/README.md for how to run one of these (short version: F8, never F5).
#>

#region 00 · Guard rail -- do not remove, do not question
# ---------------------------------------------------------------------------------------
# You pressed F5, didn't you.
#
# This is a DEMO script, not a deployment. Top to bottom it would apply Terraform against
# a real subscription and then, several regions later, destroy it -- all without pausing
# for the small matter of your approval. Twice. On two platforms.
#
# `break` stops F5. It does NOT stop F8.
#
# Cursor in a region below -> F8 -> read the SAY line -> then talk.
# ---------------------------------------------------------------------------------------
break
#endregion


# =======================================================================================
#  AZURE SQL
# =======================================================================================

#region 01 · Into the module                                                        [~15s]
# WHAT    Moves into the taught Azure SQL module. NOTE the /demo on the end -- the parent
#         folder is only a container for demo/ and shared-endpoint/. Getting this wrong
#         gives you a very confusing "no configuration files" a minute from now.
# SAY     "Four files. That is an Azure SQL server, a database and a firewall rule."
# EXPECT  The path ends with infra\azure-sql\terraform\demo.
# IF DEAD Wrong directory -> you are probably in the repo root's parent. `cd` to the repo
#         root first, then run this again.
# PAGE    docs/infra/demo.md - Azure SQL, step 1
cd infra/azure-sql/terraform/demo
Get-Location
#endregion


#region 02 · Sign in, and be very sure which subscription                           [~40s]
# WHAT    Logs in and pins the subscription. The `az account show` line is not optional
#         padding -- it is the step that stops you deploying into production by accident.
# SAY     "Check this every single time. The number of people who have deployed a demo
#          into a live subscription is higher than anyone admits."
# EXPECT  A table showing the subscription name and id you expect.
# IF DEAD If the wrong subscription is shown: `az account set --subscription "<name>"`.
#         If login opens a browser and hangs, use `az login --use-device-code`.
# PAGE    docs/infra/demo.md - Azure SQL, step 2
az login
$env:ARM_SUBSCRIPTION_ID = "<your-subscription-id>"
az account show --query "{subscription:name, id:id}" --output table
#endregion


#region 03 · The variables                                                          [~90s]
# WHAT    Copies the example tfvars and opens it. Set entra_admin_login and
#         entra_admin_object_id. Everything else already has a cost-aware default.
# SAY     "Two values. There is no admin password here, because there is no admin
#          password at all -- the server is Entra-only. Nothing to commit, nothing to
#          rotate, nothing to leak."
# EXPECT  terraform.tfvars opens in VS Code.
# IF DEAD Do not hunt for the object id live. Have it in your notes. If you must look it
#         up, the command is in the next region.
# PAGE    docs/infra/demo.md - Azure SQL, step 3
Copy-Item terraform.tfvars.example terraform.tfvars
code terraform.tfvars
#endregion


#region 04 · Finding the object id, if you must                                     [~20s]
# WHAT    Looks up the Entra group's object id. A group beats a user here -- a logical
#         server allows exactly one Entra admin, so a group is the only way both
#         presenters and CI get in.
# SAY     "One admin per server. So make the one admin a group, and put everybody in it."
# EXPECT  A GUID.
# IF DEAD Group not found -> check the name. This is a lookup, not a demo beat; if it
#         fights you, paste the id from your notes and move on.
# PAGE    docs/infra/demo.md - Azure SQL, step 3
az ad group show --group "fabcon26-sql-admins" --query id -o tsv
#endregion


#region 05 · Make it visibly ours                                                   [~60s]
# WHAT    Overrides for the live demo. Deploy `test` in uksouth and rename the database,
#         so the room can see the names in the code turn into names in the portal.
# SAY     "Watch what the names do. This is the Cloud Adoption Framework naming -- and it
#          means a *fabcon26* filter finds every single thing we made today, which is how
#          we delete it again tonight."
# EXPECT  You type these four lines into terraform.tfvars and save.
# IF DEAD Keep location and location_abbreviation in step or the names drift.
#         database_name must be lowercase alphanumeric -- `soccer` or `futbol` are fine,
#         `futbol` with the accent is not. (Yes, we tried.)
# PAGE    docs/infra/demo.md - Azure SQL, step 4
#
#   environment           = "test"
#   location              = "uksouth"
#   location_abbreviation = "uks"
#   database_name         = "soccer"
#
code terraform.tfvars
#endregion


#region 06 · Local state for a laptop                                               [~15s]
# WHAT    Swaps the remote azurerm backend for a local one. The module ships pointing at
#         shared Azure Storage for CI; on a laptop that backend has no storage account to
#         talk to and a bare `terraform init` sits there asking for a container name.
# SAY     "One file. CI keeps its shared state; my laptop gets its own. The override is
#          gitignored, so I cannot accidentally inflict it on anybody."
# EXPECT  The folder now contains backend_local_override.tf.
# IF DEAD If `terraform init` later prompts for a container name, this region did not run.
# PAGE    docs/infra/demo.md - Azure SQL, step 5
Copy-Item backend_local_override.tf.example backend_local_override.tf
#endregion


#region 07 · init                                                                   [~45s]
# WHAT    Downloads the providers. Dull, necessary, and a good moment to talk about what
#         a provider actually is.
# SAY     "Terraform on its own knows nothing about Azure. The provider is the bit that
#          does, and it is versioned, and it is pinned in the lock file. Which is why
#          this will still work in March."
# EXPECT  "Terraform has been successfully initialized!"
# IF DEAD Behind a corporate proxy this is where it fails. Nothing you can fix on stage --
#         switch to the fallback tab and narrate a completed run.
# PAGE    docs/infra/demo.md - Azure SQL, step 6
terraform init
#endregion


#region 08 · plan -- the proposal                                                   [~40s]
# WHAT    Compares the code to real Azure. Changes nothing.
# SAY     "Nothing has happened. This is a proposal, and you read it like a diff. This is
#          the single most useful thing in this room today, and it is the same idea we
#          point at your database after lunch."
# EXPECT  Plan: 4 to add, 0 to change, 0 to destroy.
# IF DEAD On Windows, "Account has previously been signed out of this application" is the
#         WAM broker holding a poisoned Graph token. The fix is on the attendee page --
#         docs/infra/azure-sql.md, under Gotchas, the collapsed warning. It is four
#         commands and it does work. If you are short of time, use the fallback tab.
# PAGE    docs/infra/demo.md - Azure SQL, step 7
terraform plan
#endregion


#region 09 · apply -- START THIS, THEN TALK                                       [~4m31s]
# WHAT    Actually builds it. Terraform asks for confirmation; type yes.
# SAY     Start it, then go back to the module and narrate while it works. Good material:
#          - why the server name has a random suffix (globally unique);
#          - why the database is serverless with auto-pause (it costs nothing overnight);
#          - what azuread_authentication_only = true bought us (no password exists);
#          - the tags, and why the nightly destroy can find everything by them.
#         Do NOT stand and watch the spinner. Four and a half minutes of silence is a
#         very long time.
# EXPECT  "Apply complete! Resources: 4 added, 0 changed, 0 destroyed." then outputs:
#           resource_group_name = "rg-fabcon26-test-uks"
#           sql_database_name   = "sqldb-football-test"   (or -soccer, if you renamed it)
#           sql_server_fqdn     = "sql-fabcon26-test-uks-XXXXXX.database.windows.net"
# IF DEAD "Subscriptions are restricted from provisioning in this region" happens on
#         Sponsorship and MSDN subscriptions. Change location AND location_abbreviation
#         together, then re-run. If it fails twice, stop and use the fallback tab -- do
#         not troubleshoot a subscription live.
# PAGE    docs/infra/demo.md - Azure SQL, step 8
terraform apply
#endregion


#region 10 · Show it exists                                                         [~60s]
# WHAT    The portal, purely to prove the code produced real things.
# SAY     "This is the only time today we open the portal, and we are only doing it to
#          look. Nothing here was clicked into existence."
# EXPECT  The resource group holds the logical server and the database.
# IF DEAD Portal slow to show new resources -> refresh once, then move on. `az resource
#         list --resource-group rg-fabcon26-test-uks -o table` makes the same point faster.
# PAGE    docs/infra/demo.md - Azure SQL, step 9
Start-Process "https://portal.azure.com"
#endregion


# =======================================================================================
#  FABRIC SQL
# =======================================================================================

#region 11 · !! NOT LIVE-VERIFIED !! -- read before presenting                      [~0s]
# ---------------------------------------------------------------------------------------
# The attendee page carries a danger admonition on this section, and it is there for a
# reason: this Fabric path has not been run live end to end.
#
# So do not say "and this works exactly the same". Say what is true: the module is built,
# the Azure SQL half is verified, and this is the shape the Fabric one takes. If the room
# asks whether we have run it, the answer is honest.
#
# If you have five minutes rather than ten, show regions 12 and 17 (the plan) and skip
# the apply. The teaching point is capacity -> workspace -> database and the two
# providers. It does not need the resources to exist.
# ---------------------------------------------------------------------------------------
#endregion


#region 12 · Across to the Fabric module                                            [~20s]
# WHAT    Moves from the Azure SQL module to the Fabric one. Note the three levels of ..
#         -- we are coming out of terraform/demo, not terraform.
# SAY     "Same repository, same tooling, different platform."
# EXPECT  The path ends with infra\fabric-sql\terraform.
# IF DEAD If you get infra\azure-sql\fabric-sql\terraform you used two dots too few.
#         `cd` to the repo root and use the absolute path below instead.
# PAGE    docs/infra/demo.md - Fabric SQL, step 1
cd ../../../fabric-sql/terraform
Get-Location
#endregion


#region 13 · Two subscriptions' worth of environment                                [~45s]
# WHAT    ARM_SUBSCRIPTION_ID for the state backend and the CLI; TF_VAR_fabric_subscription_id
#         for the module's own azurerm provider, which builds the capacity. The module
#         variable has NO default, on purpose.
# SAY     "Two providers. azurerm builds the capacity, because a capacity is an Azure
#          resource. The Fabric provider builds the workspace and the database, because
#          those are Fabric items. One apply, two authentications."
# EXPECT  The subscription table, as before.
# IF DEAD If `terraform plan` later stops and prompts you for a value, it is this: the
#         TF_VAR_ line did not run, or you set it in a different terminal.
# PAGE    docs/infra/demo.md - Fabric SQL, step 2
az login
$env:ARM_SUBSCRIPTION_ID = "<your-subscription-id>"
$env:TF_VAR_fabric_subscription_id = $env:ARM_SUBSCRIPTION_ID
az account show --query "{subscription:name, id:id}" --output table
#endregion


#region 14 · Variables                                                              [~45s]
# WHAT    Same pattern as Azure SQL. Every value has a default here, so this is review
#         rather than required editing -- unless you are binding to a capacity you
#         already run, in which case set that now.
# SAY     "If you already pay for a capacity, bind to it and Terraform will never destroy
#          it -- it is a read-only data source, not managed state. Worth knowing before
#          you point this at your employer's."
# EXPECT  terraform.tfvars opens.
# IF DEAD Nothing to break here; it is a file copy.
# PAGE    docs/infra/demo.md - Fabric SQL, step 3
Copy-Item terraform.tfvars.example terraform.tfvars
code terraform.tfvars
#endregion


#region 15 · Same overrides as Azure SQL                                            [~45s]
# WHAT    Keeps both platforms on matching names, so the side-by-side actually looks
#         side by side.
# SAY     "Same four lines, so the two platforms line up on screen."
# EXPECT  You type these into terraform.tfvars and save.
# IF DEAD Capacity names are lowercase-alphanumeric only, no hyphens -- the module builds
#         that name itself, so you do not need to. Leave it alone.
# PAGE    docs/infra/demo.md - Fabric SQL, step 4
#
#   environment           = "test"
#   location              = "uksouth"
#   location_abbreviation = "uks"
#   database_name         = "soccer"
#
code terraform.tfvars
#endregion


#region 16 · Local state, then init                                                 [~60s]
# WHAT    Same backend override as Azure SQL, then init -- which this time fetches TWO
#         providers. Worth pointing at the output.
# SAY     "Look at what it just downloaded. azurerm and microsoft/fabric. That is the
#          whole difference between the two platforms, in one line of output."
# EXPECT  Both providers listed, then "Terraform has been successfully initialized!"
# IF DEAD Same as Azure SQL -- if init cannot reach the registry, use the fallback tab.
# PAGE    docs/infra/demo.md - Fabric SQL, steps 5 and 6
Copy-Item backend_local_override.tf.example backend_local_override.tf
terraform init
#endregion


#region 17 · plan -- the shape of Fabric                                            [~45s]
# WHAT    The plan. This is the region to show even if you skip the apply.
# SAY     "Three things where Azure SQL had two. The capacity is the extra one, and it is
#          the one with the cost implications -- an F-SKU bills continuously. There is no
#          serverless auto-pause to save you here."
# EXPECT  The capacity (or the binding to an existing one), the workspace, the database.
# IF DEAD "Service principals cannot use Fabric APIs" -> a tenant admin has to enable
#         that setting. No Terraform can flip it. Explain it as the one genuine
#         human-in-the-loop prerequisite of the day and move on.
# PAGE    docs/infra/demo.md - Fabric SQL, step 7
terraform plan
#endregion


#region 18 · apply                                                                  [~3m]
# WHAT    Builds the Fabric stack. Faster than Azure SQL if the capacity already exists,
#         because then only the workspace and database are created.
# SAY     Narrate while it runs: the workspace is invisible to humans if a service
#         principal made it, which is why the module grants the presenters Admin as code.
#         A portal grant would not survive the next apply.
# EXPECT  "Apply complete!" and the database reachable at
#         ...database.fabric.microsoft.com,1433
# IF DEAD Not live-verified -- see region 11. If it fails, say so plainly, show the plan
#         output instead, and move on. It is a better look than fifteen minutes of
#         debugging.
# PAGE    docs/infra/demo.md - Fabric SQL, step 8
terraform apply
#endregion


#region 19 · Show it exists                                                         [~60s]
# WHAT    Both portals. Azure holds the capacity; Fabric holds the workspace and database.
# SAY     "The capacity is in Azure. The workspace and the database are in Fabric. Two
#          planes, one apply."
# EXPECT  Capacity in the resource group; workspace and SQL database in Fabric.
# IF DEAD Fabric's UI can lag behind a fresh create. Refresh once, then move on.
# PAGE    docs/infra/demo.md - Fabric SQL, step 9
Start-Process "https://portal.azure.com"
Start-Process "https://app.fabric.microsoft.com"
#endregion


#region 98 · TEAR IT DOWN -- do this before lunch                             [~2m12s+2m]
# WHAT    Destroys both stacks. Run it. Workshop resources that survive the workshop
#         become a bill, and the Fabric capacity bills continuously.
# SAY     Nothing -- this runs while the room is at lunch. But do say, before you leave
#         the stage, that you are about to do it. "Tear down what you built" lands better
#         as something you actually did than as advice.
# EXPECT  "Destroy complete! Resources: 5 destroyed." (Azure SQL), then the same for
#         Fabric.
# IF DEAD With use_existing_capacity = true, destroy removes ONLY the workspace and
#         database -- the capacity is a data source, not managed state. That is correct
#         and intended. Pause the capacity yourself afterwards, or it keeps billing.
# PAGE    docs/infra/demo.md - Tear it down
cd ../../azure-sql/terraform/demo
terraform destroy
cd ../../../fabric-sql/terraform
terraform destroy
#endregion


#region 99 · RESET -- leave the repository as you found it                          [~15s]
# WHAT    Removes the local-only files the demo created. All four are gitignored, so this
#         is housekeeping rather than a correctness fix -- but a clean `git status` at
#         the start of the next demo is worth fifteen seconds.
# SAY     Nothing. The room is elsewhere.
# EXPECT  `git status` reports a clean tree.
# IF DEAD Nothing to break. These are file deletes on gitignored files.
# PAGE    (presenter only -- deliberately not on the attendee page)
cd $PSScriptRoot/..
Remove-Item infra/azure-sql/terraform/demo/terraform.tfvars              -ErrorAction SilentlyContinue
Remove-Item infra/azure-sql/terraform/demo/backend_local_override.tf    -ErrorAction SilentlyContinue
Remove-Item infra/fabric-sql/terraform/terraform.tfvars                 -ErrorAction SilentlyContinue
Remove-Item infra/fabric-sql/terraform/backend_local_override.tf        -ErrorAction SilentlyContinue
git status
#endregion
