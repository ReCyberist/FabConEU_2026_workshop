# ---------------------------------------------------------------------------------------
# Naming inputs
#
# Resource names follow the Azure Cloud Adoption Framework (CAF) convention:
#   <resource-type-abbreviation>-<workload>-<environment>-<region>[-<unique>]
# e.g. rg-fabcon26-dev-weu, sql-fabcon26-dev-weu-a1b2c3, sqldb-football-dev.
#
# The workload token stays "fabcon26" so a *fabcon26* filter still finds and tears down
# every workshop resource (CLAUDE.md §4).
# ---------------------------------------------------------------------------------------

variable "workload" {
  description = "Workload / application token used in every resource name. Kept as the teardown prefix."
  type        = string
  default     = "fabcon26"

  validation {
    condition     = can(regex("^[a-z0-9]{2,16}$", var.workload))
    error_message = "workload must be 2-16 lowercase alphanumeric characters (it becomes part of a globally-unique server name)."
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
  description = "Azure region for all resources."
  type        = string
  default     = "westeurope"
}

variable "location_abbreviation" {
  description = "Short region token used in resource names (CAF style), e.g. weu for westeurope."
  type        = string
  default     = "weu"

  validation {
    condition     = can(regex("^[a-z0-9]{2,6}$", var.location_abbreviation))
    error_message = "location_abbreviation must be 2-6 lowercase alphanumeric characters (e.g. weu, neu, eus)."
  }
}

variable "database_name" {
  description = "Workload token for the database name (becomes sqldb-<database_name>-<environment>)."
  type        = string
  default     = "football"

  validation {
    condition     = can(regex("^[a-z0-9]{2,16}$", var.database_name))
    error_message = "database_name must be 2-16 lowercase alphanumeric characters."
  }
}

# ---------------------------------------------------------------------------------------
# Identity / auth — passwordless (Microsoft Entra-only). No SQL admin, no secret in code.
# ---------------------------------------------------------------------------------------

variable "entra_admin_login" {
  description = "Display name of the Microsoft Entra principal set as SQL server admin (user, group, or SP)."
  type        = string
}

variable "entra_admin_object_id" {
  description = "Object (principal) ID of the Microsoft Entra admin. A group is recommended over an individual."
  type        = string

  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-([0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}$", var.entra_admin_object_id))
    error_message = "entra_admin_object_id must be a GUID."
  }
}

# ---------------------------------------------------------------------------------------
# Network access
# ---------------------------------------------------------------------------------------

variable "public_network_access_enabled" {
  description = "Allow public network access to the server (gated by firewall rules). Production should use a private endpoint instead."
  type        = bool
  default     = true
}

variable "allow_azure_services" {
  description = "Add the 'allow Azure services' firewall exception (0.0.0.0) so hosted pipeline runners can reach the server."
  type        = bool
  default     = true
}

variable "allowed_client_ips" {
  description = "Named client IPs to allow through the server firewall, as { rule_name = ip_address }."
  type        = map(string)
  default     = {}
}

# A single client IP sourced from a secret (e.g. a presenter's static IP) — kept SEPARATE
# from allowed_client_ips, which is for non-secret, named IPs committed in tfvars. This one
# is passed at apply time from a GitHub Actions secret (TF_VAR / -var), so the address is
# never committed to source. Empty string (the default, and what an unset secret expands to)
# creates no rule. Not marked `sensitive` on purpose: a sensitive value can't drive a
# resource `count`, and the real protection is that the value lives in a secret and GitHub
# Actions masks it in every log line — the firewall IP itself is an allow-list entry, not a
# credential.
variable "presenter_client_ip" {
  description = "Optional single client IPv4 to allow through the firewall, supplied from a secret (empty = no rule)."
  type        = string
  default     = ""

  validation {
    condition     = var.presenter_client_ip == "" || can(regex("^(\\d{1,3}\\.){3}\\d{1,3}$", var.presenter_client_ip))
    error_message = "presenter_client_ip must be a single IPv4 address (e.g. 203.0.113.5) or an empty string."
  }
}

# ---------------------------------------------------------------------------------------
# Database sizing — defaults to General Purpose serverless with auto-pause (cost-aware).
# ---------------------------------------------------------------------------------------

variable "database_sku_name" {
  description = "Database SKU. Default is 1-vCore GP serverless (auto-pauses when idle). Set a provisioned SKU (e.g. S0) to disable serverless."
  type        = string
  default     = "GP_S_Gen5_1"
}

variable "database_max_size_gb" {
  description = "Maximum database size in GB."
  type        = number
  default     = 2
}

variable "database_min_capacity" {
  description = "Minimum vCores for a serverless database (ignored for provisioned SKUs)."
  type        = number
  default     = 0.5
}

variable "database_auto_pause_delay" {
  description = "Minutes of inactivity before a serverless database auto-pauses; -1 disables auto-pause (ignored for provisioned SKUs)."
  type        = number
  default     = 60
}

variable "tags" {
  description = "Additional resource tags, merged over the module's defaults."
  type        = map(string)
  default     = {}
}
