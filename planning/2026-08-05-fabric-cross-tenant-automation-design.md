# Fabric SQL cross-tenant + capacity cost-control automation — design spec

**Date:** 2026-08-05 · **Status:** Approved (Rob) · **Branch:** `feat/fabric-cross-tenant-automation`
· **Feeds:** task [#20](tasks.md) (Fabric SQL CI/CD, cross-tenant rewiring) + a new task **#23**
(capacity pause/resume automation).

> Lives in `planning/` (repo convention for design docs; `docs/` is the published site). Same
> rationale as [`2026-08-04-attendee-content-design.md`](2026-08-04-attendee-content-design.md).

---

## 1. Goal & context

The Fabric SQL infra + database deployment must run against a **different tenant, subscription,
and client** than the Azure SQL work — while the **Terraform state stays in the existing
Tenant A backend**. This is the real-world *separation-of-duties* pattern worth teaching:
**state in one subscription, the infra it describes in another.** Plus: a cost-control
**Azure Automation** that pauses the (continuously-billing) Fabric capacity every 2 hours and
resumes on demand.

Naming: **Tenant A** = the existing sandbox (Azure SQL + TF state, `stfabcon26tf4766a4`).
**Tenant B** = the new Fabric tenant/subscription.

## 2. Scope

**In:** the `fabric-sql-*` workflows, the `infra/fabric-sql/terraform` module's providers +
variables, new Tenant B repo variables, and a new persistent `infra/fabric-sql/automation`
Terraform config + its apply workflow.

**Hard constraint — do NOT touch any Azure SQL work:** no changes to `azure-sql-*.yml`,
`infra/azure-sql/**`, or the existing `AZURE_*` / `TF_STATE_*` / `SQL_*` repo variables.

**Out:** relaxing the nightly Fabric destroy (flagged §9); the ADO Fabric mirror; attendee docs
(a later content pass will use this as a real example).

## 3. Decisions (all approved 2026-08-05)

- **Two identities.** Tenant A app (`fabcon26-github-actions`, existing) authenticates the
  **state backend only**. A **new Tenant B app** authenticates the azurerm + fabric providers
  **and** the DACPAC publish.
- **Auth split by mechanism, not just values** (§4b) — because the azurerm *backend* and
  *provider* both key on `ARM_*`, we pin the provider explicitly in HCL.
- **Capacity stays module-owned** (create on apply, nightly destroy). No `use_existing_capacity`
  toggle. The hand-built Tenant B capacity gets paused/deleted.
- **Capacity admins** = the deploying caller (CI SP, auto) **+ `jess@sewells-consulting.co.uk`
  + `rob@sewells-consulting.co.uk`** (users by UPN; SPs by object ID — per the
  `azurerm_fabric_capacity` provider doc).
- **CI-app rights in Tenant B** = **Contributor + User Access Administrator** on the sub, so
  Terraform can create the Automation MI's custom role + assignment fully as-code (not full Owner).
- **Automation is a separate, persistent config** (not nightly-destroyed); it finds the capacity
  by its stable resource group.

## 4. Architecture

### 4a. Identity model
| Concern | Identity | Auth |
|---|---|---|
| TF **state backend** (`stfabcon26tf4766a4`, Tenant A) | Tenant A app `fabcon26-github-actions` (existing; already `Storage Blob Data Contributor`) | `ARM_*` env + OIDC |
| azurerm provider — Fabric **capacity** (Tenant B) | **new Tenant B app** | explicit HCL + OIDC |
| fabric provider — **workspace + SQL DB** (Tenant B) | new Tenant B app | `FABRIC_*` env + OIDC |
| DACPAC **publish** (Tenant B) | new Tenant B app | `azure/login` + Entra token |

### 4b. The auth split (the crux)
Both the azurerm **backend** and **provider** read `ARM_*`, so env vars alone can't separate
them. Resolution:
- **Backend → Tenant A:** workflow sets `ARM_CLIENT_ID/TENANT_ID/SUBSCRIPTION_ID` = the existing
  `AZURE_*` vars, `ARM_USE_OIDC=true`; `terraform init -backend-config=…` from `TF_STATE_*`
  (unchanged). `use_azuread_auth=true`.
- **azurerm provider → Tenant B:** pinned **explicitly in `providers.tf`** from new vars:
  ```hcl
  provider "azurerm" {
    features {}
    subscription_id = var.fabric_subscription_id
    client_id       = var.fabric_client_id != "" ? var.fabric_client_id : null
    tenant_id       = var.fabric_tenant_id  != "" ? var.fabric_tenant_id  : null
    use_oidc        = var.fabric_use_oidc
  }
  ```
  Explicit provider args beat the `ARM_*` env, so backend (Tenant A) and provider (Tenant B)
  diverge cleanly.
- **fabric provider → Tenant B:** unchanged block; workflow env `FABRIC_CLIENT_ID/TENANT_ID` =
  Tenant B vars, `FABRIC_USE_OIDC=true` (its own namespace — no conflict).
- **publish job → Tenant B:** `azure/login` with the Tenant B client/tenant/subscription, then
  `az account get-access-token --resource https://database.windows.net/` → SqlPackage.
- **Local runs preserved:** the identity vars default to empty and `fabric_use_oidc=false`, so a
  developer `az login` (Tenant B) still works; CI supplies the values.

*(Rejected alternative: pin the **backend** via explicit `-backend-config` and env the provider to
Tenant B — the backend-config-vs-env precedence at apply time is unreliable.)*

### 4c. Repo variables
**New (Tenant B; non-secret under OIDC):** `FABRIC_CLIENT_ID`, `FABRIC_TENANT_ID`,
`FABRIC_SUBSCRIPTION_ID` — each mapped in the workflow to **both** the fabric provider
(`FABRIC_*` env) **and** the azurerm provider (`TF_VAR_fabric_client_id/tenant_id/subscription_id`)
so one repo var drives both. Plus `FABRIC_CAPACITY_ADMIN_UPNS` (a **JSON array** string,
`["jess@sewells-consulting.co.uk","rob@sewells-consulting.co.uk"]`, passed as
`TF_VAR_capacity_admin_members`).
**Reused unchanged (Tenant A):** `AZURE_CLIENT_ID/TENANT_ID/SUBSCRIPTION_ID` (backend only),
`TF_STATE_*`, `AZURE_LOCATION*`.

### 4d. Capacity admins (module change)
`main.tf` local becomes:
```hcl
capacity_admin_members = distinct(concat([data.azurerm_client_config.current.object_id], var.capacity_admin_members))
```
Always includes the deploying caller (needed for the workspace→capacity assignment) + any extras.
`var.capacity_admin_members` (default `[]`) is set in CI to the two presenter UPNs. Fixes the
latent bug where an explicit list dropped the caller.

### 4e. Tenant B one-time identity setup (Rob's action — commands provided at build time)
App registration + SP → GitHub OIDC **federated credentials** (subjects
`repo:JessAndRob/FabConEU_2026_workshop:ref:refs/heads/main` for apply/destroy/automation and
`…:pull_request` for plan) → **Contributor + User Access Administrator** on the Tenant B
subscription → add the SP to **`data-deployment-sps`** (which carries the Fabric API tenant
setting + any workspace access).

### 4f. Automation subsystem — `infra/fabric-sql/automation/` (persistent)
Own state key `fabric-sql/automation.tfstate`; same cross-tenant provider/backend split (§4b).
Creates (all Tenant B):
- A persistent **resource group** (`rg-fabcon26-automation-<abbr>`), separate from the
  nightly-destroyed workload RG.
- An **Automation account** with a **system-assigned managed identity**.
- Two **PowerShell 7.2 runbooks**:
  - `Pause-FabricCapacity` → `Connect-AzAccount -Identity`, find the capacity in the workload RG
    (`rg-fabcon26-<env>-<abbr>`), `POST …/Microsoft.Fabric/capacities/{name}/suspend?api-version=2023-11-01`.
  - `Resume-FabricCapacity` → same discovery, `…/resume`.
  - Workload RG + subscription passed to the runbooks via `azurerm_automation_variable_string`.
- An **`azurerm_automation_schedule`** (frequency `Hour`, interval **2**) linked to **Pause** via
  `azurerm_automation_job_schedule`. **Resume has no schedule** (on-demand).
- A least-privilege **custom role** (`azurerm_role_definition`: `Microsoft.Fabric/capacities/read`
  + `…/suspend/action` + `…/resume/action`) assigned to the MI at **Tenant B subscription scope**
  (survives the workload RG being recreated nightly).

## 5. Files touched (Fabric only — zero Azure SQL)

**Modify:**
- `infra/fabric-sql/terraform/providers.tf` (azurerm provider pinned to Tenant B vars)
- `infra/fabric-sql/terraform/variables.tf` (`fabric_client_id/tenant_id/subscription_id`,
  `fabric_use_oidc`; `capacity_admin_members` already exists)
- `infra/fabric-sql/terraform/main.tf` (capacity-admins local §4d)
- `.github/workflows/fabric-sql-plan.yml`, `fabric-sql-apply.yml`, `fabric-sql-destroy.yml`
  (backend=Tenant A env, provider=Tenant B via `TF_VAR_*`/`FABRIC_*`, publish `azure/login`=Tenant B)

**Create:**
- `infra/fabric-sql/automation/` (`providers.tf`, `variables.tf`, `main.tf`, `terraform.tfvars.example`,
  `runbooks/Pause-FabricCapacity.ps1`, `runbooks/Resume-FabricCapacity.ps1`, `README.md`)
- `.github/workflows/fabric-sql-automation-apply.yml`

## 6. Delivery phases

- **Phase A — cross-tenant rewiring.** Module provider/variable/local changes + the three
  `fabric-sql-*` workflows + the Tenant B setup runbook (docs). Deliverable: `terraform fmt`/
  `validate` clean; the workflows lint; first live **plan on a PR → apply** is the real test.
- **Phase B — capacity automation.** The `automation/` config + `fabric-sql-automation-apply.yml`.
  Deliverable: `fmt`/`validate` clean; applied once; pause fires on schedule, resume on demand.

Each phase is its own set of commits on this branch (one PR, or split if it gets large).

## 7. Verification

OIDC only works inside Actions and the FICs only trust `main`/`pull_request`, so **locally** we
can only `terraform fmt -check` + `validate` and lint the YAML/PowerShell. The **real tests**:
Phase A → a PR plan then a dispatched apply + publish + smoke (the long-blocked Fabric side of
[#14](tasks.md)/[#20](tasks.md)); Phase B → apply the config, manually trigger Resume, confirm the
2-hourly Pause. Log outcomes in `LEARNINGS.md`.

## 8. The learning to capture

Write up the **separation-of-duties pattern** in `notes/LEARNINGS.md`: *state in Tenant A, infra in
Tenant B, split by pinning the azurerm provider in HCL while the backend uses `ARM_*` env* — the
reusable answer to "we keep TF state in one subscription and the infra in another." It becomes a
real-world example on the Fabric infra page in a later content pass.

## 9. Open items / follow-ups (not blockers)

- **Relax the nightly Fabric destroy?** Pausing preserves the workspace + DB + data; destroy tears
  it down and forces a morning republish. Once pause/resume is proven, consider dropping/relaxing
  `fabric-sql-destroy.yml` for Fabric. Decide after Phase B.
- **Pin the exact ARM API version** for `suspend`/`resume` against MS Learn during implementation
  (draft `2023-11-01`); decide `Invoke-AzRestMethod` vs `Az.Fabric` cmdlets.
- **`azurerm_automation_schedule.start_time`** must be a future time — use a fixed near-future value
  + `lifecycle { ignore_changes = [start_time] }` to avoid perpetual diffs.

## 10. References

[LEARNINGS 2026-07-29 "Fabric SQL CI/CD"](../notes/LEARNINGS.md) ·
[tasks #20](tasks.md) · [decisions D5](../notes/decisions.md) ·
`infra/fabric-sql/terraform/{main,variables,providers}.tf` ·
`.github/workflows/fabric-sql-*.yml` ·
[azurerm_fabric_capacity provider doc](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/fabric_capacity)
