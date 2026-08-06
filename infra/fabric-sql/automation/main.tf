locals {
  naming_suffix           = "${var.workload}-${var.environment}-${var.location_abbreviation}"
  automation_rg_name      = "rg-${var.workload}-automation-${var.location_abbreviation}"
  automation_account_name = "aa-${local.naming_suffix}"

  # The workload RG the Fabric module creates its (random-named) capacity in — the runbooks
  # discover the capacity here, so there is no dependency on the ever-changing capacity name.
  workload_rg_name = "rg-${local.naming_suffix}"
  subscription_id  = var.fabric_subscription_id
}

# Persistent RG for the automation — separate from the nightly-destroyed workload RG.
resource "azurerm_resource_group" "automation" {
  name     = local.automation_rg_name
  location = var.location
}

resource "azurerm_automation_account" "this" {
  name                = local.automation_account_name
  resource_group_name = azurerm_resource_group.automation.name
  location            = azurerm_resource_group.automation.location
  sku_name            = "Basic"

  identity {
    type = "SystemAssigned"
  }
}

# Least-privilege custom role at SUBSCRIPTION scope (survives the workload RG being recreated
# nightly): read + suspend + resume on Fabric capacities, nothing else.
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

# The runbooks read where-to-look from these automation variables (set by Terraform).
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
  runbook_type            = "PowerShell76"
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
  runbook_type            = "PowerShell76"
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
