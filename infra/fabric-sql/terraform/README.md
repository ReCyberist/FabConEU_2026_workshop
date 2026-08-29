# Fabric SQL — Terraform (content focus)

Provision **SQL database in Microsoft Fabric** with Terraform, shown **side by side** with
[Azure SQL](../../azure-sql/terraform/). It provisions the empty database that the SQL
project's DACPAC publishes into — the *same* DACPAC that targets Azure SQL (see
[`../../../database/sql-projects/PublishProfiles/`](../../../database/sql-projects/PublishProfiles/)).

## What it creates

| Resource | Provider | Name (defaults) | Notes |
|----------|----------|-----------------|-------|
| Resource group | `azurerm` | `rg-fabcon26-dev-weu` | Holds the Azure-side capacity. |
| Fabric capacity | `azurerm` | `capfabcon26dev<rnd>` | `Microsoft.Fabric/capacities`, SKU **F2** (smallest). Lowercase-alphanumeric-only name. |
| Fabric workspace | `fabric` | `ws-fabcon26-dev-weu` | Assigned to the capacity above. |
| SQL database in Fabric | `fabric` | `football-dev` | `SQL_Latin1_General_CP1_CI_AS`, 7-day PITR. |

## Two providers, two planes

This is the key thing Fabric does differently from Azure SQL, and worth calling out in the
attendee content:

- **`azurerm`** provisions the **capacity** — a `Microsoft.Fabric/capacities` *Azure*
  resource (the compute/billing unit, added to azurerm in v4.14). There is no "logical
  server"; a Fabric **capacity + workspace** play that role.
- **`microsoft/fabric`** provisions items *inside* Fabric (the **workspace** and the **SQL
  database**) via the Fabric REST APIs, not ARM.

So where Azure SQL is `server → database`, Fabric is `capacity → workspace → database`.

## Naming

The Azure-side resources (resource group) follow the same CAF convention as the Azure SQL
module, with `fabcon26` as the workload token so a `*fabcon26*` filter tears everything down
(CLAUDE.md §4). **Exception:** a Fabric capacity name allows **lowercase alphanumerics only**
(`^[a-z][a-z0-9]*$`, no hyphens), so it can't use the hyphenated CAF form — it's assembled
from the same tokens minus separators (`cap` + workload + env + random). Capacity names are
globally unique, hence the random suffix.

## Passwordless by design

No secrets. Both providers authenticate via your **Azure CLI login** (`az login`) locally,
or **OIDC / a service principal via environment variables** in CI. The Fabric **capacity
admins** are Microsoft Entra principals (`capacity_admin_members`) — leave the list empty and
it defaults to your own signed-in principal, so the module runs with no required input. A
**group** is recommended for a shared workshop.

## Run it

Run from this module folder, `infra/fabric-sql/terraform`:

```powershell
cd infra/fabric-sql/terraform   # from the repo root

Copy-Item terraform.tfvars.example terraform.tfvars   # optional — all values have defaults
code terraform.tfvars                                 # open it to review/edit the variables
Copy-Item backend_local_override.tf.example backend_local_override.tf   # local state, no remote backend

az login
$env:ARM_SUBSCRIPTION_ID = "<your-subscription-id>"   # for the Fabric capacity
# optional: $env:FABRIC_TENANT_ID = "<your-tenant-id>"

terraform init
terraform plan
terraform apply
```

Like the Azure SQL module, `backend_local_override.tf` swaps the committed remote `azurerm`
backend (see **State** below) for **local** state — Terraform auto-merges `*_override.tf`
files and a `backend` block in an override replaces the primary one. Without it, a bare
`terraform init` tries to initialize the remote backend and prompts for a container name. The
override file and `terraform.tfstate*` are gitignored, so local iteration never touches the
shared remote backend.

> **Cost:** a Fabric capacity bills while it runs. F2 is the smallest SKU; **pause the
> capacity** (az CLI / portal) when idle to stop billing. Terraform manages the capacity's
> existence, not its paused state.

### Using an existing capacity (paid F-SKU you pause)

By default the module **creates** the capacity (the taught "infra as code" path). To bind the
workspace to a capacity that **already exists** — e.g. a paid F-SKU you manage out-of-band and
**pause** when idle — set:

```hcl
use_existing_capacity            = true
existing_capacity_name           = "cappymccapface"   # the capacity's display name
existing_capacity_resource_group = "fabcon-demo-rg"   # informational (binding is by display name)
```

In this mode the module creates **neither the resource group nor the capacity** — only the
**workspace + SQL database** — and it resolves the capacity read-only via `data.fabric_capacity`.
Because the capacity is a data source, not a managed resource, **`terraform destroy` can never
tear it down** (it removes only the workspace + DB). Cost control here is **pause, not destroy**:
pausing preserves the workspace, database and data; pause via the portal or the
[#23 pause/resume automation](../automation/). `capacity_sku` and `capacity_admin_members` are
ignored in this mode (the existing capacity owns its own SKU and admins).

**State.** Same direction as the Azure SQL module — a remote `azurerm` backend (Azure
Storage) for CI + attendees (see [`notes/decisions.md`](../../../notes/decisions.md) **D5**,
task #17, gated on #1). Local state until then. The `microsoft/fabric` provider is young and
its versions move fast, so **committing `.terraform.lock.hcl`** here matters even more than
usual once the backend lands.

> **Status:** `fmt`, `init`, and `validate` run clean against the real provider schemas
> (`microsoft/fabric` ~> 1.12, `azurerm` ~> 4.14). Not yet `plan`/`apply`-ed against a live
> tenant — that needs a real Fabric capacity and is tracked with the runtime deploy in
> [`planning/tasks.md`](../../../planning/tasks.md) #14 (and the sandbox decision #1).

### Who can see the workspace

Terraform runs as a **service principal**, which becomes the workspace's creator and sole
admin — so **humans see nothing** until granted a role, and because the workspace is recreated
on every apply, a portal grant would vanish next run. Grant access **as code** instead: list the
presenters' Entra **user object IDs** in `workspace_admin_object_ids` and the module assigns each
the workspace **Admin** role every apply.

```powershell
az ad user show --id you@contoso.com --query id -o tsv   # the object id (a GUID, not the UPN)
```

## Inputs

Every input has a sensible default — the module runs with **no tfvars at all**. See
[`variables.tf`](variables.tf) for the full list and validation rules, and
[`terraform.tfvars.example`](terraform.tfvars.example) for a starting point.

## Note on deploying the schema

This module only *provisions* the database. The schema ships the same way as Azure SQL — via
SqlPackage + the shared DACPAC (task #9). Fabric SQL is Azure SQL-compatible for our schema;
the watch-items (no TDE, no spaces in column names, PK type limits, etc.) are captured in
[`../../../notes/fabric-sql-notes.md`](../../../notes/fabric-sql-notes.md). The Fabric
provider *can* also deploy a `.sqlproj`/DACPAC directly via its `definition`/`format`
arguments — a nice alternative we may show, but we keep the SqlPackage path here for
symmetry with Azure SQL.

Keep in step with the Bicep reference in [`../bicep/`](../bicep/) and the Azure SQL
equivalent in [`../../azure-sql/terraform/`](../../azure-sql/terraform/).
