# ---------------------------------------------------------------------------------------
# Naming inputs — kept identical to the Azure SQL module so the two read side by side.
#
# Azure resources (the Fabric capacity + its resource group) follow CAF:
#   <type>-<workload>-<environment>-<region>   e.g. rg-fabcon26-dev-weu
# The workload token stays "fabcon26" so a *fabcon26* filter tears everything down
# (CLAUDE.md §4). NOTE: a Fabric capacity name allows lowercase alphanumerics ONLY
# (no hyphens), so its name is assembled separately in main.tf.
# ---------------------------------------------------------------------------------------

variable "workload" {
  description = "Workload / application token used in every resource name. Kept as the teardown prefix."
  type        = string
  default     = "fabcon26"

  validation {
    condition     = can(regex("^[a-z0-9]{2,16}$", var.workload))
    error_message = "workload must be 2-16 lowercase alphanumeric characters (it becomes part of the Fabric capacity name)."
  }
}

variable "environment" {
  description = "Deployment environment token (e.g. dev, test, prod)."
  type        = string
  default     = "dev"

  validation {
    condition     = can(regex("^[a-z0-9]{2,8}$", var.environment))
    error_message = "environment must be 2-8 lowercase alphanumeric characters."
  }
}

variable "location" {
  description = "Azure region for the Fabric capacity (the workspace inherits this region)."
  type        = string
  default     = "westeurope"
}

variable "location_abbreviation" {
  description = "Short region token used in the resource group name (CAF style), e.g. weu for westeurope."
  type        = string
  default     = "weu"

  validation {
    condition     = can(regex("^[a-z0-9]{2,6}$", var.location_abbreviation))
    error_message = "location_abbreviation must be 2-6 lowercase alphanumeric characters (e.g. weu, neu, eus)."
  }
}

variable "database_name" {
  description = "Workload token for the SQL database name (becomes <database_name>-<environment> as the Fabric item display name)."
  type        = string
  default     = "football"

  validation {
    condition     = can(regex("^[a-z0-9]{2,16}$", var.database_name))
    error_message = "database_name must be 2-16 lowercase alphanumeric characters."
  }
}

# ---------------------------------------------------------------------------------------
# Identity — passwordless. The capacity admins are Microsoft Entra principals; the Fabric
# and azurerm providers both authenticate via your az CLI login (or CI OIDC/SP). No secret.
# ---------------------------------------------------------------------------------------

variable "capacity_admin_members" {
  description = "Microsoft Entra admins for the Fabric capacity (UPNs or service-principal object IDs). Leave empty to default to the caller's own principal."
  type        = list(string)
  default     = []
}

# ---------------------------------------------------------------------------------------
# Existing-capacity mode. By default the module PROVISIONS the Fabric capacity as code (the
# taught "infra as code" path). Set use_existing_capacity = true to bind the workspace to a
# capacity that ALREADY EXISTS and is managed out-of-band — e.g. a paid F-SKU you pause when
# idle. In that mode the module creates NEITHER the resource group NOR the capacity (only the
# workspace + SQL database), and it can NEVER destroy the capacity because the capacity is a
# read-only data source, not a managed resource. capacity_sku / capacity_admin_members are
# then ignored (the existing capacity owns its own SKU and admins).
# ---------------------------------------------------------------------------------------

variable "use_existing_capacity" {
  description = "Bind the workspace to an existing Fabric capacity instead of creating one. The existing capacity is never managed, modified, or destroyed by this module — pause it out-of-band to stop billing."
  type        = bool
  default     = false
}

variable "existing_capacity_name" {
  description = "Display name of the existing Fabric capacity to bind to (required when use_existing_capacity = true). Resolved tenant-wide by the fabric provider — the Azure resource group is not needed for the lookup."
  type        = string
  default     = ""

  validation {
    condition     = !var.use_existing_capacity || length(var.existing_capacity_name) > 0
    error_message = "existing_capacity_name is required when use_existing_capacity = true."
  }
}

variable "existing_capacity_resource_group" {
  description = "Azure resource group of the existing capacity. Informational (the workspace binds by display name, not RG); surfaced in outputs and the resource group the #23 pause/resume automation targets."
  type        = string
  default     = ""
}

# ---------------------------------------------------------------------------------------
# Fabric capacity sizing — defaults to the smallest SKU (cost-aware for a lab).
# Ignored when use_existing_capacity = true.
# ---------------------------------------------------------------------------------------

variable "capacity_sku" {
  description = "Fabric capacity SKU. F2 is the smallest/cheapest — fine for the workshop database. Scale up (F4, F8, ...) for heavier demos."
  type        = string
  default     = "F2"

  validation {
    condition     = can(regex("^F(2|4|8|16|32|64|128|256|512|1024|2048)$", var.capacity_sku))
    error_message = "capacity_sku must be a Fabric F-SKU: F2, F4, F8, F16, F32, F64, F128, F256, F512, F1024 or F2048."
  }
}

# ---------------------------------------------------------------------------------------
# Workspace access. The CI service principal that runs Terraform is the workspace's creator
# and sole admin, so humans can't see the workspace until they're granted a role. We grant it
# AS CODE (not in the portal) because the workspace is recreated on every apply — a manual
# grant would vanish on the next run. List the Entra USER object IDs to make workspace admins
# (get one with: az ad user show --id you@contoso.com --query id -o tsv).
# ---------------------------------------------------------------------------------------

variable "workspace_admin_object_ids" {
  description = "Entra USER object IDs (GUIDs, not UPNs) to grant the Admin role on the Fabric workspace, so presenters can see/use it. Empty = only the CI service principal has access."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for id in var.workspace_admin_object_ids : can(regex("^[0-9a-fA-F-]{36}$", id))])
    error_message = "workspace_admin_object_ids must be Entra object-id GUIDs (not UPNs). Look one up with: az ad user show --id you@contoso.com --query id -o tsv"
  }
}

# ---------------------------------------------------------------------------------------
# SQL database options.
# ---------------------------------------------------------------------------------------

variable "database_collation" {
  description = "Collation for the Fabric SQL database. Matches the Azure SQL module so the DACPAC deploys identically to both."
  type        = string
  default     = "SQL_Latin1_General_CP1_CI_AS"
}

variable "database_backup_retention_days" {
  description = "Point-in-time-restore backup retention, in days."
  type        = number
  default     = 7

  validation {
    condition     = var.database_backup_retention_days >= 1 && var.database_backup_retention_days <= 35
    error_message = "database_backup_retention_days must be between 1 and 35."
  }
}

variable "tags" {
  description = "Additional tags for the Azure resources (capacity + resource group), merged over the module's defaults."
  type        = map(string)
  default     = {}
}

# ---------------------------------------------------------------------------------------
# Cross-tenant identity for the azurerm provider (Fabric capacity + RG). The Terraform state
# backend authenticates separately (Tenant A, ARM_* env); these pin the *provider* to
# Tenant B. See planning/2026-08-05-fabric-cross-tenant-automation-design.md.
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
