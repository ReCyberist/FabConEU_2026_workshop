locals {
  # Two modes:
  #   create_capacity = true  (default, the TAUGHT path) — provision the Azure resource
  #                           group + Fabric capacity as code, then the workspace + DB.
  #   create_capacity = false (use_existing_capacity)   — bind the workspace to a capacity
  #                           that ALREADY exists and is managed out-of-band (e.g. a paid
  #                           F-SKU you pause when idle). The module then creates NEITHER the
  #                           resource group NOR the capacity — only the workspace + SQL DB —
  #                           and can NEVER destroy the capacity (it isn't in state).
  create_capacity = !var.use_existing_capacity

  # CAF naming for the Azure-side resources (resource group + capacity's RG scope).
  naming_suffix       = "${var.workload}-${var.environment}-${var.location_abbreviation}"
  resource_group_name = "rg-${local.naming_suffix}"

  # A Fabric capacity name allows LOWERCASE ALPHANUMERICS ONLY (^[a-z][a-z0-9]*$,
  # 3-63 chars) — no hyphens — so it can't use the CAF hyphenated form. We build it
  # from the same tokens minus separators, prefixed with "cap" to guarantee a leading
  # letter, plus a short random token (capacity names are globally unique). In
  # existing-capacity mode there's no random token — the name IS the existing capacity's.
  capacity_name = local.create_capacity ? "cap${var.workload}${var.environment}${random_string.suffix[0].result}" : var.existing_capacity_name

  # The Fabric-side capacity GUID the workspace binds to. Created path uses the azurerm
  # resource; existing path resolves it tenant-wide by display name via the fabric provider.
  # KNOWN RISK (create path, never live-applied — task #20): fabric_workspace.capacity_id
  # wants the Fabric capacity GUID, but azurerm_fabric_capacity.id is the ARM resource id.
  # The existing path (data.fabric_capacity.existing[0].id) is unambiguously the GUID; if the
  # first create-mode apply rejects the ARM id, resolve the created capacity via
  # data.fabric_capacity too. Left as-is here to not alter the untested create path.
  capacity_id = local.create_capacity ? azurerm_fabric_capacity.this[0].id : data.fabric_capacity.existing[0].id

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
  count   = local.create_capacity ? 1 : 0
  length  = 6
  lower   = true
  upper   = false
  numeric = true
  special = false
}

# --- Azure side: resource group + Fabric capacity (Microsoft.Fabric/capacities) ---------
# Both are created ONLY in the taught path (create_capacity). In existing-capacity mode the
# capacity already lives in its own resource group, managed out-of-band, so we create neither.

resource "azurerm_resource_group" "this" {
  count    = local.create_capacity ? 1 : 0
  name     = local.resource_group_name
  location = var.location
  tags     = local.tags
}

# The Fabric capacity is the compute/billing unit. F2 is the smallest SKU. A capacity can
# be paused when idle to stop billing — do that out-of-band (az CLI / portal / the #23
# automation); Terraform manages the capacity's existence, not its paused state.
resource "azurerm_fabric_capacity" "this" {
  count                  = local.create_capacity ? 1 : 0
  name                   = local.capacity_name
  resource_group_name    = azurerm_resource_group.this[0].name
  location               = azurerm_resource_group.this[0].location
  administration_members = local.capacity_admin_members

  sku {
    name = var.capacity_sku
    tier = "Fabric"
  }

  tags = local.tags
}

# Existing-capacity mode: resolve the capacity by display name (tenant-wide) so the workspace
# can bind to it. This is a READ ONLY data source — Terraform never manages or destroys the
# capacity, so `terraform destroy` leaves it untouched (pause it out-of-band to stop billing).
data "fabric_capacity" "existing" {
  count        = local.create_capacity ? 0 : 1
  display_name = var.existing_capacity_name
}

# --- Fabric side: workspace + SQL database ----------------------------------------------

# The workspace is the container for Fabric items; assigning it to our capacity is what
# gives the SQL database compute.
resource "fabric_workspace" "this" {
  display_name = local.workspace_name
  description  = "FabCon Europe 2026 workshop — Fabric SQL, side by side with Azure SQL."
  capacity_id  = local.capacity_id
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
