# Identity (cross-tenant) — mirrors the module. Backend = Tenant A via ARM_* env; these pin the
# azurerm provider to Tenant B. See ../CROSS-TENANT-SETUP.md.

variable "fabric_subscription_id" {
  description = "Tenant B subscription id (where the Fabric capacity + this automation live)."
  type        = string
}

variable "fabric_client_id" {
  description = "Tenant B app (client) id for the azurerm provider. Empty = use the az CLI login."
  type        = string
  default     = ""
}

variable "fabric_tenant_id" {
  description = "Tenant B tenant id. Empty = use the az CLI login's tenant."
  type        = string
  default     = ""
}

variable "fabric_use_oidc" {
  description = "azurerm provider uses GitHub OIDC (CI true) vs the az CLI login (local false)."
  type        = bool
  default     = false
}

# Naming — kept identical to the Fabric module so this config can derive the workload resource
# group name (where the capacity lives) without a cross-config dependency.

variable "workload" {
  description = "Workload token (must match the Fabric module)."
  type        = string
  default     = "fabcon26"
}

variable "environment" {
  description = "Environment token (must match the Fabric module)."
  type        = string
  default     = "dev"
}

variable "location" {
  description = "Azure region for the Automation account's resource group."
  type        = string
  default     = "uksouth"
}

variable "location_abbreviation" {
  description = "Short region token for CAF naming (e.g. uks). Must match the Fabric module."
  type        = string
  default     = "uks"
}
