# Fabric SQL — Bicep (reference / bonus)

Bicep/ARM path for Fabric SQL. Reference material, kept in step with
[`../terraform/`](../terraform/) (the taught path).

## What Bicep/ARM can — and can't — express here

This is the honest limitation to teach, not hide:

| Piece | ARM/Bicep? | Why |
|-------|:---------:|-----|
| **Fabric capacity** | ✅ **Yes** | `Microsoft.Fabric/capacities` is a real Azure (ARM) resource. |
| **Fabric workspace** | ❌ No | A Fabric control-plane item — no ARM resource type exists. |
| **SQL database in Fabric** | ❌ No | Same — a Fabric item, created via the Fabric REST API, not ARM. |

So this Bicep provisions **only the capacity** (the `azurerm_fabric_capacity` slice of the
Terraform module). For the **full** `capacity → workspace → database` stack, use:

- [`../terraform/`](../terraform/) — the Terraform module uses the `microsoft/fabric`
  provider (Fabric REST APIs) for the workspace + database, **or**
- the **Fabric REST API / CLI** to create the workspace + database after this deploys the
  capacity.

## Files

- **`main.bicep`** — subscription-scoped; creates the resource group + Fabric capacity.
- **`capacity.bicep`** — resource-group-scoped module: the `Microsoft.Fabric/capacities` resource.
- **`main.bicepparam`** — starting-point parameters (capacity admins are required).

## Cost warning

An **F-SKU capacity bills the whole time it exists** — there is no serverless auto-pause
(unlike the Azure SQL serverless database). **Pause it** (az CLI / portal) or **tear it down**
when idle. There is no nightly-destroy workflow for Fabric yet.

## Run it

```powershell
Copy-Item main.bicepparam my.bicepparam   # then fill in capacityAdminMembers

az deployment sub create `
  --name fabric-capacity-dev `
  --location uksouth `
  --template-file main.bicep `
  --parameters my.bicepparam
```

> **Status:** `az bicep build` clean (zero warnings) for `main.bicep` + `capacity.bicep`.
> Capacity only, by design (see the table above). No live deploy (an F-SKU bills — tracked
> with the runtime work in [`planning/tasks.md`](../../../planning/tasks.md) #14).

Keep in step with the Terraform module in [`../terraform/`](../terraform/) and the Azure SQL
Bicep in [`../../azure-sql/bicep/`](../../azure-sql/bicep/).
