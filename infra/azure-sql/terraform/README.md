# Azure SQL — Terraform (content focus)

Provision Azure SQL (logical server + database + firewall + Entra auth) with Terraform.
This is the **taught path** for the Azure SQL infra module. It produces the server and
database that the SQL project's DACPAC publishes into (see
[`../../../database/sql-projects/PublishProfiles/`](../../../database/sql-projects/PublishProfiles/)).

## What it creates

| Resource | Name (defaults) | Notes |
|----------|-----------------|-------|
| Resource group | `rg-fabcon26-dev-weu` | |
| Logical SQL server | `sql-fabcon26-dev-weu-<rnd>` | Globally unique (random suffix); TLS 1.2 min; **Entra-only auth**. |
| SQL database | `sqldb-football-dev` | GP serverless, auto-pause 60 min, 2 GB — cost-aware lab default. |
| Firewall rule(s) | `AllowAzureServices` (+ any client IPs) | Lets the pipeline runner reach the server. |

## Naming — Azure Cloud Adoption Framework (CAF)

Names follow the CAF convention
`<resource-type-abbreviation>-<workload>-<environment>-<region>[-<unique>]`:

- **`rg-`** resource group, **`sql-`** logical server, **`sqldb-`** database — the official
  [CAF abbreviations](https://learn.microsoft.com/azure/cloud-adoption-framework/ready/azure-best-practices/resource-abbreviations).
- The **workload token stays `fabcon26`**, so a `*fabcon26*` filter still finds and tears
  down every workshop resource (CLAUDE.md §4) while the type-abbreviation leads, as CAF
  wants.
- The logical server name must be **globally unique**, so a short random token is appended.
- Region is abbreviated (`weu`) per CAF; override `location` + `location_abbreviation`
  together for other regions.

## Passwordless by design

Auth is **Microsoft Entra-only** (`azuread_authentication_only = true`) — there is no SQL
admin login or password, so nothing secret is committed or needs rotating. Supply the Entra
admin identity (a **group** is recommended) via `entra_admin_login` +
`entra_admin_object_id`. The deploy pipeline authenticates with its own Entra identity.

## Run it

```powershell
Copy-Item terraform.tfvars.example terraform.tfvars   # fill in the Entra admin identity
$env:ARM_SUBSCRIPTION_ID = "<your-subscription-id>"

terraform init
terraform plan
terraform apply
```

**State.** The decided direction is a **remote `azurerm` backend (Azure Storage)** for both
the CI pipeline and attendees — local state can't survive GitHub Actions' ephemeral runners
(see [`notes/decisions.md`](../../../notes/decisions.md) **D5**). This initial module still
uses **local state** until the state-backend work lands (task #17), which is gated on the
attendee sandbox decision (#1). HashiCorp also recommends **committing `.terraform.lock.hcl`**
once the backend is in place, so CI and teammates resolve identical provider versions.

> **Status:** `fmt`, `init`, `validate`, and `plan` all run clean (plan: 5 to add). Not yet
> `apply`-ed against a live subscription — tracked with the runtime deploy in
> [`planning/tasks.md`](../../../planning/tasks.md) #14.

## Inputs

Only `entra_admin_login` and `entra_admin_object_id` are required; everything else has a
cost-aware default. See [`variables.tf`](variables.tf) for the full list and validation
rules, and [`terraform.tfvars.example`](terraform.tfvars.example) for a starting point.

Keep in step with the Bicep reference in [`../bicep/`](../bicep/) and the Fabric SQL
equivalent in [`../../fabric-sql/terraform/`](../../fabric-sql/terraform/).
