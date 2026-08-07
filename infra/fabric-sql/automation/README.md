# Fabric capacity pause/resume — Azure Automation

Persistent **cost-control** automation for the workshop's Fabric capacity. A Fabric F-SKU bills
continuously (no serverless auto-pause), so this **pauses it every 2 hours** and lets you **resume
on demand**.

- **`Pause-FabricCapacity`** runbook — suspends the capacity. Scheduled **every 2 hours**.
- **`Resume-FabricCapacity`** runbook — resumes it. **No schedule** — run on demand (portal or
  `Start-AzAutomationRunbook`) before a demo.

Both run as the Automation account's **system-assigned managed identity**, which holds a
least-privilege **custom role** (`Microsoft.Fabric/capacities` read + suspend + resume) at
**subscription scope**. The runbooks **discover the capacity by its resource group**
(`rg-<workload>-<env>-<abbr>`), so they keep working across the module's nightly destroy/recreate
(the capacity name is random each time).

Cross-tenant like the module: **state in Tenant A, resources in Tenant B** — see
[`../CROSS-TENANT-SETUP.md`](../CROSS-TENANT-SETUP.md) and the
[design](../../../planning/2026-08-05-fabric-cross-tenant-automation-design.md).

## Apply

This is **persistent** (not part of the nightly cycle), applied **once** via
[`fabric-sql-automation-apply.yml`](../../../.github/workflows/fabric-sql-automation-apply.yml)
(`workflow_dispatch`). Its own state key: `fabric-sql/automation.tfstate`.

> Pausing preserves the workspace + database + data (unlike the nightly `fabric-sql-destroy.yml`,
> which tears everything down). Once pause/resume is proven you may want to relax the nightly
> Fabric destroy — see the design's open items.
