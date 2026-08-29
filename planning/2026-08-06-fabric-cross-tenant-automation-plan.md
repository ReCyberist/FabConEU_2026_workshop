# Fabric cross-tenant + capacity automation — Implementation Plan

> **For agentic workers:** Follow the checklist below task-by-task (each step ends with a verify gate + commit). Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rewire the Fabric SQL module + workflows so the **state stays in Tenant A** while the **infra + DB deploy run in Tenant B**, and add a persistent **Azure Automation** that pauses the capacity every 2h / resumes on demand — without touching any Azure SQL work.

**Architecture:** The Terraform *backend* authenticates to Tenant A via `ARM_*` env; the azurerm *provider* is pinned to Tenant B via explicit HCL (from vars); the fabric provider uses `FABRIC_*` env (Tenant B); publish uses `azure/login` (Tenant B). A separate persistent `infra/fabric-sql/automation/` config runs the pause/resume runbooks under a managed identity with a sub-scoped least-priv custom role. Full design: [`2026-08-05-fabric-cross-tenant-automation-design.md`](2026-08-05-fabric-cross-tenant-automation-design.md).

**Tech Stack:** Terraform (azurerm ~>4.14, microsoft/fabric ~>1.12), GitHub Actions (OIDC), Azure Automation + PowerShell 7.2 runbooks.

**Scope:** Two phases on branch `feat/fabric-cross-tenant-automation`. Phase A = cross-tenant rewiring; Phase B = the automation subsystem. Feeds task [#20](tasks.md) + new **#23**.

## Global Constraints

- **Never touch Azure SQL:** no edits to `azure-sql-*.yml`, `infra/azure-sql/**`, or the `AZURE_*`/`TF_STATE_*`/`SQL_*` repo vars. (`AZURE_*` + `TF_STATE_*` are *read* by the Fabric workflows for the **backend** only — reading is fine, they stay Tenant A.)
- **The cross-tenant env block** (used verbatim in every Fabric workflow `env:`):
  ```yaml
  env:
    # --- Terraform state backend -> Tenant A (unchanged identity) ---
    ARM_CLIENT_ID: ${{ vars.AZURE_CLIENT_ID }}
    ARM_TENANT_ID: ${{ vars.AZURE_TENANT_ID }}
    ARM_SUBSCRIPTION_ID: ${{ vars.AZURE_SUBSCRIPTION_ID }}
    ARM_USE_OIDC: true
    # --- azurerm provider (Fabric capacity) -> Tenant B (pinned in providers.tf via TF_VAR_*) ---
    TF_VAR_fabric_client_id: ${{ vars.FABRIC_CLIENT_ID }}
    TF_VAR_fabric_tenant_id: ${{ vars.FABRIC_TENANT_ID }}
    TF_VAR_fabric_subscription_id: ${{ vars.FABRIC_SUBSCRIPTION_ID }}
    TF_VAR_fabric_use_oidc: true
    # --- fabric provider (workspace + SQL DB) -> Tenant B ---
    FABRIC_USE_OIDC: true
    FABRIC_CLIENT_ID: ${{ vars.FABRIC_CLIENT_ID }}
    FABRIC_TENANT_ID: ${{ vars.FABRIC_TENANT_ID }}
    # --- capacity admins: presenter UPNs (the CI SP is auto-added as the caller) ---
    TF_VAR_capacity_admin_members: ${{ vars.FABRIC_CAPACITY_ADMIN_UPNS }}
  ```
- **Verification gates** (no unit tests for infra): Terraform → `terraform fmt -check -recursive` + `terraform validate` (via `terraform init -backend=false`); workflows/YAML → parse-check with `python3 -c "import yaml,sys; yaml.safe_load(open(sys.argv[1]))"`. Real end-to-end test is CI (plan on PR → apply), which OIDC restricts to Actions.
- **Commit trailers** — every commit ends with:
  ```
  Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
  Claude-Session: https://claude.ai/code/session_01FomQZPCUXLqFQLnNnCn8nQ
  ```

---

## File Structure

**Phase A — modify:**
- `infra/fabric-sql/terraform/providers.tf` — pin azurerm provider to Tenant B vars
- `infra/fabric-sql/terraform/variables.tf` — add `fabric_client_id/tenant_id/subscription_id`, `fabric_use_oidc`
- `infra/fabric-sql/terraform/main.tf` — capacity-admins local (always include caller)
- `.github/workflows/fabric-sql-plan.yml`, `fabric-sql-apply.yml`, `fabric-sql-destroy.yml` — cross-tenant env block; apply's publish `azure/login` → Tenant B

**Phase A — create:**
- `infra/fabric-sql/CROSS-TENANT-SETUP.md` — the Tenant B identity setup runbook (as-code docs)

**Phase B — create:**
- `infra/fabric-sql/automation/{providers,variables,main}.tf`, `terraform.tfvars.example`, `README.md`
- `infra/fabric-sql/automation/runbooks/{Pause,Resume}-FabricCapacity.ps1`
- `.github/workflows/fabric-sql-automation-apply.yml`

---

## Phase A

### Task 1: Module Terraform — pin azurerm to Tenant B, keep backend on Tenant A

**Files:** Modify `infra/fabric-sql/terraform/{providers,variables,main}.tf`

- [ ] **Step 1: `providers.tf` — replace the `provider "azurerm"` block** with the pinned version:

```hcl
provider "azurerm" {
  features {}

  # Pinned to Tenant B (the Fabric infra). The Terraform STATE BACKEND authenticates
  # separately to Tenant A via the ARM_* env — explicit provider args here beat those env
  # vars, so backend (Tenant A) and provider (Tenant B) diverge cleanly in one run. See
  # planning/2026-08-05-fabric-cross-tenant-automation-design.md §4b. Vars default empty /
  # use_oidc=false so a local `az login` (into Tenant B) still works; CI supplies them.
  subscription_id = var.fabric_subscription_id
  client_id       = var.fabric_client_id != "" ? var.fabric_client_id : null
  tenant_id       = var.fabric_tenant_id != "" ? var.fabric_tenant_id : null
  use_oidc        = var.fabric_use_oidc
}
```
(Leave the `fabric` provider block as-is — it reads `FABRIC_*` env.)

- [ ] **Step 2: `variables.tf` — append** the identity vars:

```hcl
# ---------------------------------------------------------------------------------------
# Cross-tenant identity for the azurerm provider (Fabric capacity + RG). The Terraform
# state backend authenticates separately (Tenant A, ARM_* env); these pin the *provider*
# to Tenant B. See planning/2026-08-05-fabric-cross-tenant-automation-design.md.
# ---------------------------------------------------------------------------------------

variable "fabric_subscription_id" {
  description = "Tenant B subscription id for the Fabric capacity (azurerm provider)."
  type        = string
}

variable "fabric_client_id" {
  description = "Tenant B app (client) id for the azurerm provider. Empty = use the az CLI login."
  type        = string
  default     = ""
}

variable "fabric_tenant_id" {
  description = "Tenant B tenant id for the azurerm provider. Empty = use the az CLI login's tenant."
  type        = string
  default     = ""
}

variable "fabric_use_oidc" {
  description = "azurerm provider uses GitHub OIDC (CI true) vs the az CLI login (local false)."
  type        = bool
  default     = false
}
```

- [ ] **Step 3: `main.tf` — replace the `capacity_admin_members` local** (currently the `length(...) > 0 ? ... : [...]` ternary) with:

```hcl
  # Capacity admins are ALWAYS the deploying caller (the CI SP in Tenant B — required for the
  # workspace->capacity assignment) PLUS any extras supplied (presenter UPNs). distinct()
  # dedupes. Previously an explicit list *replaced* the caller, which would break the
  # assignment — see planning/2026-08-05-fabric-cross-tenant-automation-design.md §4d.
  capacity_admin_members = distinct(concat([data.azurerm_client_config.current.object_id], var.capacity_admin_members))
```

- [ ] **Step 4: Verify** — from `infra/fabric-sql/terraform`:

Run: `terraform fmt -check -recursive` → expect clean.
Run: `terraform init -backend=false && terraform validate` → expect `Success! The configuration is valid.`
(If `terraform` is not installed, install a ~1.12 build first; if the provider download is blocked, note it and rely on the CI plan job.)

- [ ] **Step 5: Commit**

```powershell
git add infra/fabric-sql/terraform/providers.tf infra/fabric-sql/terraform/variables.tf infra/fabric-sql/terraform/main.tf
git commit -m "Pin Fabric azurerm provider to Tenant B; state backend stays Tenant A" -m "<body>" -m "<trailers>"
```

### Task 2: Rewire the three Fabric workflows for the tenant split

**Files:** Modify `.github/workflows/fabric-sql-{plan,apply,destroy}.yml`

- [ ] **Step 1:** In **each** of the three workflows, replace the existing `env:` block (the 7 `ARM_*`/`FABRIC_*` lines) with the **cross-tenant env block** from Global Constraints.

- [ ] **Step 2:** In **`fabric-sql-apply.yml` only**, change the publish job's `Azure login (OIDC)` step to Tenant B:

```yaml
      - name: Azure login (OIDC)
        uses: azure/login@v3
        with:
          client-id: ${{ vars.FABRIC_CLIENT_ID }}
          tenant-id: ${{ vars.FABRIC_TENANT_ID }}
          subscription-id: ${{ vars.FABRIC_SUBSCRIPTION_ID }}
```

- [ ] **Step 3:** Update the header comment in each workflow's auth note to say *backend → Tenant A, providers + publish → Tenant B* (one-line accuracy fix; no logic).

- [ ] **Step 4: Verify** each file parses:

Run: `for f in .github/workflows/fabric-sql-plan.yml .github/workflows/fabric-sql-apply.yml .github/workflows/fabric-sql-destroy.yml; do python3 -c "import yaml,sys; yaml.safe_load(open('$f')); print('ok', '$f')"; done`
Expected: `ok` for all three.

- [ ] **Step 5: Commit**

```bash
git add .github/workflows/fabric-sql-plan.yml .github/workflows/fabric-sql-apply.yml .github/workflows/fabric-sql-destroy.yml
git commit -m "Split Fabric workflows: backend Tenant A, providers + publish Tenant B" -m "<body>" -m "<trailers>"
```

### Task 3: Commit the Tenant B setup as documented code

**Files:** Create `infra/fabric-sql/CROSS-TENANT-SETUP.md`

- [ ] **Step 1: Create the doc** with the exact PowerShell runbook already run (app + SP + 2 federated credentials + Contributor & User Access Administrator + `data-deployment-sps` membership + the `FABRIC_*` repo vars), plus a short "why" intro (state Tenant A / infra Tenant B) and the two required tenant prereqs (SP-can-use-Fabric-APIs setting; `data-deployment-sps` carrying it). Content = the PowerShell from the design conversation, fenced ```powershell, with `<TENANT_B_TENANT_ID>` / `<TENANT_B_SUBSCRIPTION_ID>` placeholders.

- [ ] **Step 2: Commit**

```bash
git add infra/fabric-sql/CROSS-TENANT-SETUP.md
git commit -m "Document Tenant B CI identity setup (nothing clicked)" -m "<body>" -m "<trailers>"
```

---

## Phase B

### Task 4: Automation config + runbooks

**Files:** Create `infra/fabric-sql/automation/{providers,variables,main}.tf`, `terraform.tfvars.example`, `README.md`, `runbooks/{Pause,Resume}-FabricCapacity.ps1`

- [ ] **Step 1: `providers.tf`** (backend Tenant A / provider Tenant B, own state key):

```hcl
terraform {
  required_version = ">= 1.8.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.14"
    }
  }
  # State in Tenant A (same backend as the module, different key). Auth via ARM_* env.
  backend "azurerm" {
    use_oidc         = true
    use_azuread_auth = true
  }
}

provider "azurerm" {
  features {}
  # Pinned to Tenant B (same pattern as the module). Backend uses ARM_* env (Tenant A).
  subscription_id = var.fabric_subscription_id
  client_id       = var.fabric_client_id != "" ? var.fabric_client_id : null
  tenant_id       = var.fabric_tenant_id != "" ? var.fabric_tenant_id : null
  use_oidc        = var.fabric_use_oidc
}
```

- [ ] **Step 2: `variables.tf`**:

```hcl
variable "fabric_subscription_id" {
  description = "Tenant B subscription id (where the Fabric capacity + this automation live)."
  type        = string
}
variable "fabric_client_id" {
  description = "Tenant B app (client) id for the azurerm provider. Empty = az CLI login."
  type        = string
  default     = ""
}
variable "fabric_tenant_id" {
  description = "Tenant B tenant id. Empty = az CLI login's tenant."
  type        = string
  default     = ""
}
variable "fabric_use_oidc" {
  description = "azurerm provider uses GitHub OIDC (CI) vs az CLI login (local)."
  type        = bool
  default     = false
}
variable "workload" {
  type    = string
  default = "fabcon26"
}
variable "environment" {
  type    = string
  default = "dev"
}
variable "location" {
  type    = string
  default = "uksouth"
}
variable "location_abbreviation" {
  type    = string
  default = "uks"
}
```

- [ ] **Step 3: `main.tf`** (account + MI + custom role + runbooks + schedule):

```hcl
locals {
  naming_suffix           = "${var.workload}-${var.environment}-${var.location_abbreviation}"
  automation_rg_name      = "rg-${var.workload}-automation-${var.location_abbreviation}"
  automation_account_name = "aa-${local.naming_suffix}"
  # The workload RG the module creates its (random-named) capacity in — the runbooks discover
  # the capacity here, so no dependency on the ever-changing capacity name.
  workload_rg_name = "rg-${local.naming_suffix}"
  subscription_id  = var.fabric_subscription_id
}

resource "azurerm_resource_group" "automation" {
  name     = local.automation_rg_name
  location = var.location
}

resource "azurerm_automation_account" "this" {
  name                = local.automation_account_name
  resource_group_name = azurerm_resource_group.automation.name
  location            = azurerm_resource_group.automation.location
  sku_name            = "Basic"
  identity { type = "SystemAssigned" }
}

# Least-privilege custom role at SUBSCRIPTION scope (survives the workload RG being recreated
# nightly): just read + suspend + resume on Fabric capacities.
resource "azurerm_role_definition" "fabric_capacity_operator" {
  name        = "Fabric Capacity Operator (fabcon26)"
  scope       = "/subscriptions/${local.subscription_id}"
  description = "Read and suspend/resume Microsoft.Fabric capacities."
  permissions {
    actions = [
      "Microsoft.Fabric/capacities/read",
      "Microsoft.Fabric/capacities/suspend/action",
      "Microsoft.Fabric/capacities/resume/action",
    ]
    not_actions = []
  }
  assignable_scopes = ["/subscriptions/${local.subscription_id}"]
}

resource "azurerm_role_assignment" "operator" {
  scope              = "/subscriptions/${local.subscription_id}"
  role_definition_id = azurerm_role_definition.fabric_capacity_operator.role_definition_resource_id
  principal_id       = azurerm_automation_account.this.identity[0].principal_id
}

# Runbooks read where-to-look from these automation variables.
resource "azurerm_automation_variable_string" "subscription_id" {
  name                    = "FabricSubscriptionId"
  resource_group_name     = azurerm_resource_group.automation.name
  automation_account_name = azurerm_automation_account.this.name
  value                   = local.subscription_id
}

resource "azurerm_automation_variable_string" "workload_rg" {
  name                    = "FabricWorkloadResourceGroup"
  resource_group_name     = azurerm_resource_group.automation.name
  automation_account_name = azurerm_automation_account.this.name
  value                   = local.workload_rg_name
}

resource "azurerm_automation_runbook" "pause" {
  name                    = "Pause-FabricCapacity"
  resource_group_name     = azurerm_resource_group.automation.name
  automation_account_name = azurerm_automation_account.this.name
  location                = azurerm_resource_group.automation.location
  runbook_type            = "PowerShell72"
  log_verbose             = false
  log_progress            = false
  description             = "Suspend the workshop Fabric capacity (cost control)."
  content                 = file("${path.module}/runbooks/Pause-FabricCapacity.ps1")
}

resource "azurerm_automation_runbook" "resume" {
  name                    = "Resume-FabricCapacity"
  resource_group_name     = azurerm_resource_group.automation.name
  automation_account_name = azurerm_automation_account.this.name
  location                = azurerm_resource_group.automation.location
  runbook_type            = "PowerShell72"
  log_verbose             = false
  log_progress            = false
  description             = "Resume the workshop Fabric capacity (on demand)."
  content                 = file("${path.module}/runbooks/Resume-FabricCapacity.ps1")
}

# Pause every 2 hours. Resume has NO schedule (on-demand only).
resource "azurerm_automation_schedule" "every_2h" {
  name                    = "pause-every-2h"
  resource_group_name     = azurerm_resource_group.automation.name
  automation_account_name = azurerm_automation_account.this.name
  frequency               = "Hour"
  interval                = 2
  timezone                = "Etc/UTC"
  start_time              = timeadd(timestamp(), "15m") # must be >5 min out; ignored after create
  description             = "Pause the Fabric capacity every 2 hours."
  lifecycle {
    ignore_changes = [start_time]
  }
}

resource "azurerm_automation_job_schedule" "pause_every_2h" {
  resource_group_name     = azurerm_resource_group.automation.name
  automation_account_name = azurerm_automation_account.this.name
  schedule_name           = azurerm_automation_schedule.every_2h.name
  runbook_name            = azurerm_automation_runbook.pause.name
}
```

> **Runbook `content` caveat:** `runbook_type = "PowerShell72"` is confirmed valid (provider doc). Modern azurerm (~>4.14) accepts `content` alone — try that first. If the CI *apply* rejects it (the doc notes the API historically wanted a `publish_content_link` too), add a minimal `publish_content_link { uri = "<any reachable https URI>" }` to each runbook resource; the real body still comes from `content`. `terraform validate` won't surface this — only apply will.

- [ ] **Step 4: `runbooks/Pause-FabricCapacity.ps1`**:

```powershell
# Azure Automation runbook (PowerShell 7.2). Runs as the account's system-assigned managed
# identity. Discovers the Fabric capacity in the workload RG (its name is random-suffixed) and
# suspends it via the ARM suspend action. Idempotent — no-op if there's no capacity.
$ErrorActionPreference = 'Stop'
Connect-AzAccount -Identity | Out-Null

$subscriptionId = Get-AutomationVariable -Name 'FabricSubscriptionId'
$resourceGroup  = Get-AutomationVariable -Name 'FabricWorkloadResourceGroup'
Set-AzContext -Subscription $subscriptionId | Out-Null

$capacities = Get-AzResource -ResourceGroupName $resourceGroup -ResourceType 'Microsoft.Fabric/capacities' -ErrorAction SilentlyContinue
if (-not $capacities) { Write-Output "No Fabric capacity in $resourceGroup - nothing to pause."; return }

foreach ($cap in $capacities) {
    $uri = "https://management.azure.com$($cap.ResourceId)/suspend?api-version=2023-11-01"
    Write-Output "Suspending $($cap.Name)..."
    Invoke-AzRestMethod -Method POST -Uri $uri | Out-Null
    Write-Output "Suspended $($cap.Name)."
}
```

- [ ] **Step 5: `runbooks/Resume-FabricCapacity.ps1`** — identical to Step 4 but with `resume` in the URI and "Resuming/Resumed" wording:

```powershell
$ErrorActionPreference = 'Stop'
Connect-AzAccount -Identity | Out-Null

$subscriptionId = Get-AutomationVariable -Name 'FabricSubscriptionId'
$resourceGroup  = Get-AutomationVariable -Name 'FabricWorkloadResourceGroup'
Set-AzContext -Subscription $subscriptionId | Out-Null

$capacities = Get-AzResource -ResourceGroupName $resourceGroup -ResourceType 'Microsoft.Fabric/capacities' -ErrorAction SilentlyContinue
if (-not $capacities) { Write-Output "No Fabric capacity in $resourceGroup - nothing to resume."; return }

foreach ($cap in $capacities) {
    $uri = "https://management.azure.com$($cap.ResourceId)/resume?api-version=2023-11-01"
    Write-Output "Resuming $($cap.Name)..."
    Invoke-AzRestMethod -Method POST -Uri $uri | Out-Null
    Write-Output "Resumed $($cap.Name)."
}
```

- [ ] **Step 6: `terraform.tfvars.example` + `README.md`** — example var values (Tenant B ids as placeholders) and a short README (what it does, apply once via `fabric-sql-automation-apply.yml`, that Resume is manual, and the sub-scoped custom role).

- [ ] **Step 7: Verify** — from `infra/fabric-sql/automation`:

Run: `terraform fmt -check -recursive`
Run: `terraform init -backend=false && terraform validate` → `Success!`

- [ ] **Step 8: Commit**

```bash
git add infra/fabric-sql/automation
git commit -m "Add Fabric capacity pause/resume Azure Automation (MI, sub-scoped role)" -m "<body>" -m "<trailers>"
```

### Task 5: Automation apply workflow

**Files:** Create `.github/workflows/fabric-sql-automation-apply.yml`

- [ ] **Step 1: Create the workflow** — `workflow_dispatch` only; the cross-tenant env block (from Global Constraints) minus the `FABRIC_*` and `TF_VAR_capacity_admin_members` lines (this config has no fabric provider and no capacity admins — keep only `ARM_*` for the backend + `TF_VAR_fabric_*` for the azurerm provider); `working-directory: infra/fabric-sql/automation`; steps = checkout → setup-terraform ~1.12 → `fmt -check` → `init` (`-backend-config` key `fabric-sql/automation.tfstate`) → `validate` → `apply -auto-approve` with `location`/`location_abbreviation` `-var`s.

- [ ] **Step 2: Verify**

Run: `python3 -c "import yaml; yaml.safe_load(open('.github/workflows/fabric-sql-automation-apply.yml')); print('ok')"`

- [ ] **Step 3: Commit**

```bash
git add .github/workflows/fabric-sql-automation-apply.yml
git commit -m "Add Fabric capacity automation apply workflow" -m "<body>" -m "<trailers>"
```

---

## Self-Review

**1. Spec coverage** (against [design](2026-08-05-fabric-cross-tenant-automation-design.md)):
- §4b auth split → Task 1 (provider pin) + Task 2 (env block). ✅
- §4c repo vars mapped to both providers → Task 2 env block (`TF_VAR_fabric_*` + `FABRIC_*`). ✅
- §4d capacity admins always-include-caller → Task 1 Step 3. ✅
- §4e Tenant B setup as code → Task 3. ✅
- §4f automation (MI, 2 runbooks, pause-2h/resume-none, sub-scoped custom role, discover-by-RG) → Task 4. ✅
- §5 files list → matches File Structure. ✅  §6 phases → A (1-3) / B (4-5). ✅

**2. Placeholder scan:** `<body>`/`<trailers>` are commit-message shorthand (body = one-line summary of the task; trailers = the two verbatim lines in Global Constraints) — not code placeholders. Runbook api-version `2023-11-01` is pinned (verify vs MS Learn at execution, per design §9). No TODO/TBD in steps. ✅

**3. Type/name consistency:** `fabric_subscription_id/client_id/tenant_id`, `fabric_use_oidc`, `capacity_admin_members` used identically across module + automation + workflow `TF_VAR_*`; `FabricSubscriptionId`/`FabricWorkloadResourceGroup` automation-variable names match between `main.tf` and both runbooks; `azurerm_automation_account.this.identity[0].principal_id` is the MI used in the role assignment. ✅

---

## Execution Handoff

Five tasks across two phases on `feat/fabric-cross-tenant-automation`, each ending in a verify gate + commit. Real end-to-end validation is the first CI run (plan on PR → apply), gated on the Tenant B identity (now set up).
