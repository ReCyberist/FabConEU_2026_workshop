# Azure SQL — Bicep (reference / bonus)

Bicep equivalent of the Azure SQL Terraform module. Provided so attendees on an
Azure-native stack have a working path. **Not the primary taught content** — the taught
path is [`../terraform/`](../terraform/); keep this in step with it.

## What it creates

Same shape as the Terraform module (`fmt`/`validate`-clean, `az bicep build`-clean):

| Resource | Name (defaults) | Notes |
|----------|-----------------|-------|
| Resource group | `rg-fabcon26-dev-uks` | created by the subscription-scoped `main.bicep`. |
| Logical SQL server | `sql-fabcon26-dev-uks-<uniq>` | globally unique (`uniqueString` suffix); TLS 1.2 min; **Entra-only auth**. |
| SQL database | `sqldb-football-dev` | GP serverless, auto-pause 60 min, 2 GB — cost-aware lab default. |
| Firewall rule(s) | `AllowAzureServices` (+ any client IPs) | lets the pipeline runner reach the server. |

## Files

- **`main.bicep`** — subscription-scoped entry point; creates the resource group and calls the module.
- **`sql.bicep`** — resource-group-scoped module: server + database + firewall rules.
- **`main.bicepparam`** — starting-point parameters (fill in the Entra admin identity).

## Naming, passwordless, cost — same rules as Terraform

- **CAF naming** with the `fabcon26` workload token so a `*fabcon26*` filter tears everything
  down; the server name gets a short `uniqueString(resourceGroup().id)` suffix (the Bicep
  equivalent of the module's `random_string`).
- **Passwordless** — the server is created with `azureADOnlyAuthentication: true` and no SQL
  admin login/password. Supply the Entra admin via `entraAdminLogin` + `entraAdminObjectId`
  (a **group** is recommended — a server allows exactly one Entra admin, and only a group can
  admin-grant more than one identity, e.g. presenters + the CI service principal).
- **Cost-aware** — GP **serverless** with auto-pause. NOTE: `autoPauseDelay`/`minCapacity`
  apply to serverless SKUs only, and switching `databaseSkuName` to a provisioned SKU also
  needs a matching `tier`/`family`/`capacity` in `sql.bicep` (ARM is more verbose than
  Terraform's single `sku_name`).

## Run it

```powershell
# Uses your current az CLI login + subscription (az account set --subscription <id> to switch)
Copy-Item main.bicepparam my.bicepparam   # then fill in the Entra admin identity

az deployment sub create `
  --name azure-sql-dev `
  --location uksouth `
  --template-file main.bicep `
  --parameters my.bicepparam
```

Validate without deploying:

```powershell
az bicep build --file main.bicep          # compile to ARM JSON (offline)
az deployment sub what-if `
  --location uksouth `
  --template-file main.bicep `
  --parameters my.bicepparam              # preview changes against Azure
```

> **Status:** `az bicep build` clean (zero warnings) for `main.bicep` + `sql.bicep`; params
> validate with `az bicep build-params`. No live deploy yet — the taught path runs through
> Terraform + GitHub Actions (see [`../terraform/`](../terraform/) and the runtime deploy in
> [`planning/tasks.md`](../../../planning/tasks.md) #14).

Keep in step with the Terraform module in [`../terraform/`](../terraform/) and the Fabric SQL
Bicep in [`../../fabric-sql/bicep/`](../../fabric-sql/bicep/).
