# CI/CD — Azure DevOps (reference / bonus)

Azure DevOps YAML pipeline equivalents of the GitHub Actions workflows, for attendees on that
stack. **Reference material — not the taught path** (that's
[`../github-actions/`](../github-actions/)); keep these in step with it.

## The pipelines (each mirrors a GitHub Actions workflow)

| File | Mirrors | Trigger | What it does |
|------|---------|---------|--------------|
| [`ci.yml`](ci.yml) | `ci.yml` | push to `main` + PR | Build the SQL project + T-SQL static analysis (`-warnaserror`); publish the DACPAC as a pipeline artifact. No Azure auth. |
| [`azure-sql-plan.yml`](azure-sql-plan.yml) | `azure-sql-plan.yml` | PR touching `infra/azure-sql/terraform/demo/**` | Read-only `fmt`/`validate`/`plan` (`-lock=false`). Never applies. |
| [`azure-sql-apply.yml`](azure-sql-apply.yml) | `azure-sql-apply.yml` | manual | `terraform apply`, then publish the DACPAC into the new DB + smoke-test it. Two stages (Apply → Publish). |
| [`azure-sql-destroy.yml`](azure-sql-destroy.yml) | `azure-sql-destroy.yml` | schedule 21:00 UTC + manual | `terraform destroy` so nothing bills overnight. |

## Auth — workload identity federation (the OIDC equivalent, passwordless)

Where GitHub Actions uses **OIDC**, Azure DevOps uses an **Azure Resource Manager service
connection** configured for **workload identity federation** — same idea, no secrets stored.
The `AzureCLI@2` task logs in with it; `addSpnToEnvironment: true` exposes the service
principal id, the OIDC id-token, and the tenant id to the script, which passes them to
Terraform as the `ARM_*` environment variables:

```bash
export ARM_CLIENT_ID="$servicePrincipalId"
export ARM_OIDC_TOKEN="$idToken"
export ARM_TENANT_ID="$tenantId"
export ARM_SUBSCRIPTION_ID="$(AZURE_SUBSCRIPTION_ID)"
export ARM_USE_OIDC=true
```

The DACPAC publish + smoke test mint a Microsoft Entra token for Azure SQL
(`az account get-access-token --resource https://database.windows.net/`) and hand it to
SqlPackage / `Invoke-Sqlcmd -AccessToken` — no connection string, nothing secret.

## Prerequisites

1. **A WIF Azure Resource Manager service connection** in the Azure DevOps project. Its
   principal needs the same access as the GitHub Actions app: `Contributor` on the
   subscription, `Storage Blob Data Contributor` on the Terraform state account, and
   membership of the SQL server's Entra **admin group** (so the publish stage can log into the
   database — parity with task #18).
2. **A variable group `fabcon26-azure-sql`** (Pipelines → Library) providing — all non-secret
   with WIF, exactly like the GitHub Actions repo variables:

   | Variable | Example |
   |----------|---------|
   | `azureServiceConnection` | `fabcon26-arm` (the service connection name) |
   | `AZURE_SUBSCRIPTION_ID` | `bbd5…` |
   | `TF_STATE_RESOURCE_GROUP` | `rg-fabcon26-state-weu` |
   | `TF_STATE_STORAGE_ACCOUNT` | `stfabcon26tf4766a4` |
   | `TF_STATE_CONTAINER` | `tfstate` |
   | `SQL_ENTRA_ADMIN_LOGIN` | `fabcon26-sql-admins` |
   | `SQL_ENTRA_ADMIN_OBJECT_ID` | `b0d9…` |
   | `AZURE_LOCATION` | `uksouth` |
   | `AZURE_LOCATION_ABBREVIATION` | `uks` |

3. **Terraform** is preinstalled on the Microsoft-hosted `ubuntu-latest` image. To pin the
   version, add a `TerraformInstaller@1` step (Microsoft DevLabs **Terraform** extension).

## Register a pipeline (PowerShell, Azure CLI `azure-devops` extension)

```powershell
az extension add --name azure-devops
az pipelines create `
  --name "Azure SQL - apply" `
  --repository FabConEU_2026_workshop `
  --branch main `
  --yml-path infra/pipelines/azure-devops/azure-sql-apply.yml
```

Gate the real deploys behind an **Environment** with a required-approval check on the apply /
publish stages — the ADO equivalent of GitHub Environments + required reviewers.

> **Status:** all four YAML files parse and follow the ADO schema. Not executed here (no Azure
> DevOps org in this repo) — the taught, live-verified path runs on GitHub Actions. Keep these
> in step with [`../github-actions/`](../github-actions/) and the workflows under
> [`../../../.github/workflows/`](../../../.github/workflows/).
