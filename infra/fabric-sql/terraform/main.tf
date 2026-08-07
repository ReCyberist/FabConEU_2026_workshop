locals {
  # CAF naming for the Azure-side resources (resource group + capacity's RG scope).
  naming_suffix       = "${var.workload}-${var.environment}-${var.location_abbreviation}"
  resource_group_name = "rg-${local.naming_suffix}"

  # A Fabric capacity name allows LOWERCASE ALPHANUMERICS ONLY (^[a-z][a-z0-9]*$,
  # 3-63 chars) — no hyphens — so it can't use the CAF hyphenated form. We build it
  # from the same tokens minus separators, prefixed with "cap" to guarantee a leading
  # letter, plus a short random token (capacity names are globally unique).
  capacity_name = "cap${var.workload}${var.environment}${random_string.suffix.result}"

  # Fabric item display names are friendly strings (unique within their scope).
  workspace_name    = "ws-${local.naming_suffix}"
  sql_database_name = "${var.database_name}-${var.environment}"

  # Capacity admins are ALWAYS the deploying caller (the CI SP in Tenant B — required for the
  # workspace->capacity assignment) PLUS any extras supplied (presenter UPNs). distinct()
  # dedupes if the caller is also listed. Previously an explicit list *replaced* the caller,
  # which would break the assignment — see
  # planning/2026-08-05-fabric-cross-tenant-automation-design.md §4d.
  capacity_admin_members = distinct(concat([data.azurerm_client_config.current.object_id], var.capacity_admin_members))

  tags = merge({
    workload    = var.workload
    environment = var.environment
    managed-by  = "terraform"
    project     = "fabcon-europe-2026-workshop"
  }, var.tags)
}

data "azurerm_client_config" "current" {}

resource "random_string" "suffix" {
  length  = 6
  lower   = true
  upper   = false
  numeric = true
  special = false
}

# --- Azure side: resource group + Fabric capacity (Microsoft.Fabric/capacities) ---------

resource "azurerm_resource_group" "this" {
  name     = local.resource_group_name
  location = var.location
  tags     = local.tags
}

# The Fabric capacity is the compute/billing unit. F2 is the smallest SKU. A capacity can
# be paused when idle to stop billing — do that out-of-band (az CLI / portal); Terraform
# manages the capacity's existence, not its paused state.
resource "azurerm_fabric_capacity" "this" {
  name                   = local.capacity_name
  resource_group_name    = azurerm_resource_group.this.name
  location               = azurerm_resource_group.this.location
  administration_members = local.capacity_admin_members

  sku {
    name = var.capacity_sku
    tier = "Fabric"
  }

  tags = local.tags
}

# --- Fabric side: workspace + SQL database ----------------------------------------------

# The workspace is the container for Fabric items; assigning it to our capacity is what
# gives the SQL database compute.
resource "fabric_workspace" "this" {
  display_name = local.workspace_name
  description  = "FabCon Europe 2026 workshop — Fabric SQL, side by side with Azure SQL."
  capacity_id  = azurerm_fabric_capacity.this.id
}

# SQL database in Fabric (transactional, Azure SQL-compatible surface — see
# notes/fabric-sql-notes.md). The same DACPAC that targets Azure SQL publishes here; this
# module just provisions the empty database, the schema ships via SqlPackage (task #9),
# exactly as on the Azure SQL side.
resource "fabric_sql_database" "this" {
  display_name = local.sql_database_name
  workspace_id = fabric_workspace.this.id
  description  = "Football sample database (men's + women's)."

  configuration = {
    creation_mode         = "New"
    collation             = var.database_collation
    backup_retention_days = var.database_backup_retention_days
  }
}
