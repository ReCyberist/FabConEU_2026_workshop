locals {
  # CAF naming: <type>-<workload>-<env>-<region>. workload stays "fabcon26" so a *fabcon26*
  # filter finds/tears down everything (CLAUDE.md §4).
  naming_suffix = "${var.workload}-${var.environment}-${var.location_abbreviation}"

  resource_group_name = "rg-${local.naming_suffix}"
  elastic_pool_name   = "ep-${local.naming_suffix}"

  # The logical SQL server name is globally unique, 1-63 chars, lowercase. A short random
  # token keeps it unique across re-deploys.
  sql_server_name = "sql-${local.naming_suffix}-${random_string.suffix.result}"

  # One id per attendee: attendee01 .. attendeeNN. Drives the databases, logins and users.
  # Both the database name (sqldb-attendee01) and the login/user name (attendee01) key off it.
  attendee_ids = toset([for i in range(1, var.attendee_count + 1) : format("attendee%02d", i)])

  add_entra_admin = var.entra_admin_login != "" && var.entra_admin_object_id != ""

  tags = merge({
    workload    = var.workload
    environment = var.environment
    managed-by  = "terraform"
    project     = "fabcon-europe-2026-workshop"
    purpose     = "shared-unsupported-attendee-endpoint"
  }, var.tags)
}

resource "random_string" "suffix" {
  length  = 6
  lower   = true
  upper   = false
  numeric = true
  special = false
}

# Server admin password — generated, never handed out (presenters/this module only). The
# override_special set excludes characters that commonly break connection strings.
resource "random_password" "admin" {
  length           = 24
  special          = true
  override_special = "!#$%*-_=+"
}

resource "azurerm_resource_group" "this" {
  name     = local.resource_group_name
  location = var.location
  tags     = local.tags
}

resource "azurerm_mssql_server" "this" {
  name                          = local.sql_server_name
  resource_group_name           = azurerm_resource_group.this.name
  location                      = azurerm_resource_group.this.location
  version                       = "12.0"
  minimum_tls_version           = "1.2"
  public_network_access_enabled = true

  # SQL authentication ON — the whole point of this endpoint. Attendees log in with their
  # per-attendee SQL login + the shared password (no Entra identity needed for a room of
  # strangers). Contrast the taught module, which is azuread_authentication_only = true.
  administrator_login          = var.admin_login
  administrator_login_password = random_password.admin.result

  # Optional Entra admin *in addition* — off by default. When set, SQL auth stays enabled
  # (azuread_authentication_only = false) so both paths work.
  dynamic "azuread_administrator" {
    for_each = local.add_entra_admin ? [1] : []
    content {
      login_username              = var.entra_admin_login
      object_id                   = var.entra_admin_object_id
      azuread_authentication_only = false
    }
  }

  tags = local.tags
}

# One elastic pool shared by every attendee database — a single, predictable cost for the
# day instead of N independent databases each carrying a floor.
resource "azurerm_mssql_elasticpool" "this" {
  name                = local.elastic_pool_name
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  server_name         = azurerm_mssql_server.this.name
  max_size_gb         = var.pool_max_size_gb

  sku {
    name     = var.pool_sku_name
    tier     = var.pool_sku_tier
    family   = var.pool_sku_family
    capacity = var.pool_capacity
  }

  per_database_settings {
    min_capacity = var.pool_per_db_min_capacity
    max_capacity = var.pool_per_db_max_capacity
  }

  tags = local.tags
}

# One empty database per attendee, all in the pool. Each attendee owns their own DB, so the
# DACPAC publishes into an isolated target — no cross-attendee name collisions (D6).
resource "azurerm_mssql_database" "attendee" {
  for_each = local.attendee_ids

  name            = "sqldb-${each.key}"
  server_id       = azurerm_mssql_server.this.id
  elastic_pool_id = azurerm_mssql_elasticpool.this.id
  sku_name        = "ElasticPool" # required for a pooled database
  collation       = "SQL_Latin1_General_CP1_CI_AS"
  max_size_gb     = var.database_max_size_gb
  zone_redundant  = false

  tags = local.tags
}

# --- Firewall -------------------------------------------------------------------------

# Open to the internet for the workshop day (unsupported, short-lived, destroyed same day).
resource "azurerm_mssql_firewall_rule" "allow_all" {
  count            = var.allow_all_ips ? 1 : 0
  name             = "AllowAllForWorkshopDay"
  server_id        = azurerm_mssql_server.this.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "255.255.255.255"
}

# Allow Azure services (the 0.0.0.0 sentinel) so hosted pipeline runners can reach the server.
resource "azurerm_mssql_firewall_rule" "allow_azure_services" {
  count            = var.allow_azure_services ? 1 : 0
  name             = "AllowAzureServices"
  server_id        = azurerm_mssql_server.this.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# Named client IPs (e.g. the presenter's machine, needed for the mssql provider below when
# allow_all_ips is false).
resource "azurerm_mssql_firewall_rule" "client" {
  for_each         = var.allowed_client_ips
  name             = each.key
  server_id        = azurerm_mssql_server.this.id
  start_ip_address = each.value
  end_ip_address   = each.value
}

# --- SQL logins + database users (mssql provider) -------------------------------------
#
# These run T-SQL against the live server, so they depend on the server being reachable
# (firewall) and on the admin credentials above. The provider connects per-resource with
# the SQL admin login this module generated.

# Server-level login per attendee, in master, all sharing the throwaway password.
resource "mssql_login" "attendee" {
  for_each = local.attendee_ids

  server {
    host = azurerm_mssql_server.this.fully_qualified_domain_name
    login {
      username = azurerm_mssql_server.this.administrator_login
      password = random_password.admin.result
    }
  }

  login_name = each.key
  password   = var.attendee_password

  # The login lives in master; it can't be created until the server firewall lets us in.
  depends_on = [
    azurerm_mssql_firewall_rule.allow_all,
    azurerm_mssql_firewall_rule.client,
  ]
}

# A user in each attendee's own database, mapped to that login, with db_owner so they can
# publish a DACPAC (create schema objects) into their sandbox — and only their sandbox.
resource "mssql_user" "attendee" {
  for_each = local.attendee_ids

  server {
    host = azurerm_mssql_server.this.fully_qualified_domain_name
    login {
      username = azurerm_mssql_server.this.administrator_login
      password = random_password.admin.result
    }
  }

  database   = azurerm_mssql_database.attendee[each.key].name
  username   = each.key
  login_name = mssql_login.attendee[each.key].login_name
  roles      = ["db_owner"]
}
