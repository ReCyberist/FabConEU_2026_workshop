# =======================================================================================
# Shared, UNSUPPORTED workshop endpoint — inputs.
#
# This is NOT the taught Azure SQL module. It provisions ONE logical server carrying an
# elastic pool and a database-per-attendee, each with its own SQL login (all sharing one
# throwaway password), as a best-effort DB-deploy target on the day (decisions.md D6).
# SQL authentication is ON here (the taught module is Entra-only/passwordless) precisely
# because we can't hand a room full of strangers Entra identities.
# =======================================================================================

# ---------------------------------------------------------------------------------------
# Naming — same CAF scheme as the taught module (rg-/sql-/sqldb- + fabcon26 workload token
# so a *fabcon26* filter still tears everything down). Environment token is "shared" so the
# resource group never collides with the demo one (rg-fabcon26-dev-*).
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
  description = "Environment token in resource names. Defaults to 'shared' to distinguish this endpoint from the demo resources."
  type        = string
  default     = "shared"

  validation {
    condition     = can(regex("^[a-z0-9]{2,8}$", var.environment))
    error_message = "environment must be 2-8 lowercase alphanumeric characters."
  }
}

variable "location" {
  description = "Azure region for all resources. NB: the personal sandbox sub is region-restricted to UK South (uksouth/uks) — see LEARNINGS 2026-07-22."
  type        = string
  default     = "westeurope"
}

variable "location_abbreviation" {
  description = "Short region token used in resource names (CAF style), e.g. weu for westeurope, uks for uksouth."
  type        = string
  default     = "weu"

  validation {
    condition     = can(regex("^[a-z0-9]{2,6}$", var.location_abbreviation))
    error_message = "location_abbreviation must be 2-6 lowercase alphanumeric characters (e.g. weu, neu, uks)."
  }
}

# ---------------------------------------------------------------------------------------
# Attendees — one database + one login per attendee, generated as attendee01..attendeeNN.
# ---------------------------------------------------------------------------------------

variable "attendee_count" {
  description = "How many per-attendee databases + logins to create (attendee01 .. attendeeNN). Size the pool to match."
  type        = number
  default     = 10

  validation {
    condition     = var.attendee_count >= 1 && var.attendee_count <= 99
    error_message = "attendee_count must be between 1 and 99 (names are zero-padded to two digits: attendee01..attendee99)."
  }
}

# ---------------------------------------------------------------------------------------
# Credentials.
#
# SERVER ADMIN password is generated (random_password) and never handed out — it's for the
# presenters / this module's mssql provider only, surfaced as a sensitive output.
#
# ATTENDEE password is a DELIBERATELY PUBLIC, throwaway, shared credential printed on a
# slide for an explicitly-unsupported endpoint that is destroyed the same day. It is NOT a
# secret in the security sense, which is why it carries a default and isn't marked
# sensitive (the README prints it too). Change it per event if you like; never reuse it for
# anything real. This is the one intentional exception to CLAUDE.md's "never commit
# secrets" — and it's a giveaway, not a secret.
# ---------------------------------------------------------------------------------------

variable "admin_login" {
  description = "SQL administrator login name for the server. Cannot be a reserved name (admin, administrator, sa, root, dbmanager, guest, ...)."
  type        = string
  default     = "fabconadmin"
}

variable "attendee_password" {
  description = "Shared, throwaway password given to every attendee login. Public by design (printed on a slide); not a real secret."
  type        = string
  default     = "Taylor==Metallica"

  validation {
    # Azure SQL complexity: >= 8 chars and 3 of 4 categories. Keep the guard simple/honest.
    condition     = length(var.attendee_password) >= 8
    error_message = "attendee_password must be at least 8 characters (Azure SQL also requires 3 of upper/lower/digit/symbol)."
  }
}

# ---------------------------------------------------------------------------------------
# Elastic pool sizing — one pool shared across every attendee database (cost cap for the
# day). Defaults: General Purpose Gen5, 4 vCores, each DB may burst to 2. Tune for headcount.
# ---------------------------------------------------------------------------------------

variable "pool_sku_name" {
  description = "Elastic pool SKU name (vCore, e.g. GP_Gen5)."
  type        = string
  default     = "GP_Gen5"
}

variable "pool_sku_tier" {
  description = "Elastic pool tier."
  type        = string
  default     = "GeneralPurpose"
}

variable "pool_sku_family" {
  description = "Elastic pool hardware family."
  type        = string
  default     = "Gen5"
}

variable "pool_capacity" {
  description = "Total vCores for the pool, shared across all attendee databases."
  type        = number
  default     = 4
}

variable "pool_max_size_gb" {
  description = "Maximum total storage for the pool, in GB."
  type        = number
  default     = 50
}

variable "pool_per_db_min_capacity" {
  description = "Minimum vCores guaranteed to each database in the pool (0 = no floor)."
  type        = number
  default     = 0
}

variable "pool_per_db_max_capacity" {
  description = "Maximum vCores any single database may burst to within the pool."
  type        = number
  default     = 2
}

variable "database_max_size_gb" {
  description = "Maximum size of each attendee database, in GB (the sample schema is tiny)."
  type        = number
  default     = 1
}

# ---------------------------------------------------------------------------------------
# Network access. For the day this endpoint is intentionally open to the internet (it's
# unsupported and short-lived); attendees connect from wherever they are. Turn allow_all
# off and use allowed_client_ips for a tighter test.
# ---------------------------------------------------------------------------------------

variable "allow_all_ips" {
  description = "Open the firewall to the whole internet (0.0.0.0-255.255.255.255) for the workshop day. Unsupported endpoint, destroyed same day."
  type        = bool
  default     = true
}

variable "allow_azure_services" {
  description = "Add the 'allow Azure services' firewall exception (0.0.0.0) so hosted pipeline runners can reach the server."
  type        = bool
  default     = true
}

variable "allowed_client_ips" {
  description = "Named client IPs to allow through the firewall, as { rule_name = ip_address }. Include the machine running terraform if allow_all_ips is false (the mssql provider must reach the server)."
  type        = map(string)
  default     = {}
}

# ---------------------------------------------------------------------------------------
# Optional Entra admin. Off by default — this endpoint runs on SQL auth. Set both to also
# let a presenter/CI principal administer the server passwordlessly (SQL auth stays ON).
# ---------------------------------------------------------------------------------------

variable "entra_admin_login" {
  description = "Optional: display name of a Microsoft Entra principal to also set as server admin. Empty = no Entra admin."
  type        = string
  default     = ""
}

variable "entra_admin_object_id" {
  description = "Optional: object (principal) ID of the Entra admin. Required if entra_admin_login is set."
  type        = string
  default     = ""

  validation {
    condition     = var.entra_admin_object_id == "" || can(regex("^[0-9a-fA-F]{8}-([0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}$", var.entra_admin_object_id))
    error_message = "entra_admin_object_id must be a GUID or an empty string."
  }
}

variable "tags" {
  description = "Additional resource tags, merged over the module's defaults."
  type        = map(string)
  default     = {}
}
