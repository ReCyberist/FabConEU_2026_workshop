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
cd infra/azure-sql/terraform/demo
Get-Location
#endregion


#region 02 · Sign in, and be very sure which subscription                           [~40s]
az login
$env:ARM_SUBSCRIPTION_ID = "<your-subscription-id>"
# $env:ARM_SUBSCRIPTION_ID = (Get-Secret -Name "beard-mvp-subscription" -AsPlainText) # if Rob doing demo
az account show --query "{subscription:name, subscriptionId:id}" --output table
#endregion


#region 03 · The variables                                                          [~90s]
Copy-Item terraform.tfvars.example terraform.tfvars
code terraform.tfvars
#endregion


#region 04 · Finding the object id, if you must                                     [~20s]
$groupName = "fabcon26-sql-admins"
# $groupName = "SQLAdmins" # if Rob doing demo
az ad group show --group $groupName --query id -o tsv
#endregion


#region 05 · Make it visibly ours                                                   [~60s]
#
#   environment           = "test"
#   location              = "uksouth"
#   location_abbreviation = "uks"
#   database_name         = "soccer"
#
code terraform.tfvars
#endregion


#region 06 · Local state for a laptop                                               [~15s]
Copy-Item backend_local_override.tf.example backend_local_override.tf
#endregion


#region 07 · init                                                                   [~45s]
terraform init
#endregion


#region 08 · plan -- the proposal                                                   [~40s]
# SAY: in a pipeline we'd run `terraform plan -out=tfplan` to save this to a file, publish
# tfplan as a build artefact, then `terraform apply tfplan` in the apply job -- so what ships
# is exactly the plan a human reviewed, not a fresh re-plan that might have drifted. Live we
# just run plain `plan` then `apply` for speed. (Attendee page has this as a tip.)
terraform plan
#endregion


#region 09 · apply -- START THIS, THEN TALK                                       [~4m31s]
# It stops on "Only 'yes' will be accepted to approve." -- read that line out, type yes,
# THEN start narrating the module. Do not type yes and go quiet for four and a half minutes.
terraform apply
#endregion


#region 10 · Show it exists                                                         [~60s]
Start-Process "https://portal.azure.com"
#endregion


# =======================================================================================
#  FABRIC SQL
# =======================================================================================

#region 11 · How far this one has actually been run                                 [~0s]
# ---------------------------------------------------------------------------------------
# Verified to `terraform plan`. The apply in region 18 has not been run end to end, so do
# not say "and this works exactly the same". Say what is true: the module is built, the
# plan is clean, and this is the shape the Fabric one takes.
#
# If you have five minutes rather than ten, show regions 12 and 17 (the plan) and skip
# the apply. The teaching point is capacity -> workspace -> database and the two
# providers. It does not need the resources to exist.
# ---------------------------------------------------------------------------------------
#endregion


#region 12 · Across to the Fabric module                                            [~20s]
cd ../../../fabric-sql/terraform
Get-Location
#endregion


#region 13 · Two subscriptions' worth of environment                                [~45s]
az login
$env:ARM_SUBSCRIPTION_ID = "<your-subscription-id>"
# $env:ARM_SUBSCRIPTION_ID = (Get-Secret -Name sewells-subscription-id -AsPlainText) # if Rob doing demo
$env:TF_VAR_fabric_subscription_id = $env:ARM_SUBSCRIPTION_ID
az account show --query "{subscription:name, subscriptionId:id}" --output table
#endregion


#region 14 · Variables                                                              [~45s]
Copy-Item terraform.tfvars.example terraform.tfvars
code terraform.tfvars
#endregion


#region 15 · Same overrides as Azure SQL                                            [~45s]
#
#   environment           = "test"
#   location              = "uksouth"
#   location_abbreviation = "uks"
#   database_name         = "soccer"
#
code terraform.tfvars
#endregion


#region 16 · Local state, then init                                                 [~60s]
Copy-Item backend_local_override.tf.example backend_local_override.tf
terraform init
#endregion


#region 17 · plan -- the shape of Fabric                                            [~45s]
terraform plan
#endregion


#region 18 · apply                                                                  [~3m]
# Same prompt as region 09: only 'yes' approves.
terraform apply
#endregion


#region 19 · Show it exists                                                         [~60s]
Start-Process "https://portal.azure.com"
Start-Process "https://app.fabric.microsoft.com"
#endregion


#region 98 · TEAR IT DOWN -- do this before lunch                             [~2m12s+2m]
cd ../../azure-sql/terraform/demo
terraform destroy
cd ../../../fabric-sql/terraform
terraform destroy
#endregion


#region 99 · RESET -- leave the repository as you found it                          [~15s]
cd $PSScriptRoot/..
Remove-Item infra/azure-sql/terraform/demo/terraform.tfvars              -ErrorAction SilentlyContinue
Remove-Item infra/azure-sql/terraform/demo/backend_local_override.tf    -ErrorAction SilentlyContinue
Remove-Item infra/fabric-sql/terraform/terraform.tfvars                 -ErrorAction SilentlyContinue
Remove-Item infra/fabric-sql/terraform/backend_local_override.tf        -ErrorAction SilentlyContinue
git status
#endregion
