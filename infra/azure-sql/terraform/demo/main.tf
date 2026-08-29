locals {
  # CAF naming: <type>-<workload>-<env>-<region>. The workload token stays "fabcon26"
  # so a *fabcon26* filter still finds/tears down everything (CLAUDE.md §4).
  naming_suffix = "${var.workload}-${var.environment}-${var.location_abbreviation}"

  resource_group_name = "rg-${local.naming_suffix}"

  # The logical SQL server name must be globally unique, 1-63 chars, lowercase. A short
  # random token keeps it unique across re-deploys and attendees.
  sql_server_name = "sql-${local.naming_suffix}-${random_string.suffix.result}"

  # Database names are scoped to the server (not global), so no random token needed.
  sql_database_name = "sqldb-${var.database_name}-${var.environment}"

  # Serverless SKUs (GP_S_*) accept min_capacity / auto_pause; provisioned SKUs reject them.
  is_serverless = can(regex("_S_", var.database_sku_name))

  tags = merge({
    workload    = var.workload
    environment = var.environment
    managed-by  = "terraform"
    project     = "fabcon-europe-2026-workshop"
  }, var.tags)
}

resource "random_string" "suffix" {
  length  = 6
  lower   = true
  upper   = false
  numeric = true
  special = false
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
  public_network_access_enabled = var.public_network_access_enabled

  # Passwordless: Microsoft Entra is the only way in — no SQL admin login/password, so
  # there is no secret to commit or rotate. A group principal is recommended for the admin.
  azuread_administrator {
    login_username              = var.entra_admin_login
    object_id                   = var.entra_admin_object_id
    azuread_authentication_only = true
  }

  tags = local.tags
}

resource "azurerm_mssql_database" "this" {
  name      = local.sql_database_name
  server_id = azurerm_mssql_server.this.id
  collation = "SQL_Latin1_General_CP1_CI_AS"
  sku_name  = var.database_sku_name

  max_size_gb                 = var.database_max_size_gb
  min_capacity                = local.is_serverless ? var.database_min_capacity : null
  auto_pause_delay_in_minutes = local.is_serverless ? var.database_auto_pause_delay : null

  # Cost-aware lab defaults: no zone redundancy, locally-redundant backup storage.
  zone_redundant       = false
  storage_account_type = "Local"

  tags = local.tags
}

# Allow other Azure services (e.g. the GitHub Actions hosted runner that publishes the
# DACPAC) to reach the server. The 0.0.0.0 sentinel is Azure's "allow Azure services" rule.
resource "azurerm_mssql_firewall_rule" "allow_azure_services" {
  count            = var.allow_azure_services ? 1 : 0
  name             = "AllowAzureServices"
  server_id        = azurerm_mssql_server.this.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# Named client IPs (e.g. an attendee's machine) allowed through the server firewall.
resource "azurerm_mssql_firewall_rule" "client" {
  for_each         = var.allowed_client_ips
  name             = each.key
  server_id        = azurerm_mssql_server.this.id
  start_ip_address = each.value
  end_ip_address   = each.value
}

# Presenter/static client IPs supplied from secrets (see var.presenter_client_ips). compact()
# drops empty entries (an unset secret expands to ""), so unset secrets create no rules.
#
# The IPs are sensitive, which means they can't drive for_each directly. Key the rules on a
# one-way hash of each IP instead: the hash is safe to expose (it reveals nothing about the
# address), so nonsensitive() lifts the sensitivity off the for_each keys / rule names, while
# the IP itself stays sensitive and is looked up by hash for the rule value. Result: neither
# the plan diff nor the resource address ever shows the IP — Terraform prints the rule value as
# "(sensitive value)" and the name as presenter-<hash>. GitHub Actions masking is a second layer.
locals {
  presenter_ip_by_hash = { for ip in compact(var.presenter_client_ips) : substr(sha1(ip), 0, 8) => ip }
}

resource "azurerm_mssql_firewall_rule" "presenter" {
  for_each         = nonsensitive(toset(keys(local.presenter_ip_by_hash)))
  name             = "presenter-${each.key}"
  server_id        = azurerm_mssql_server.this.id
  start_ip_address = local.presenter_ip_by_hash[each.key]
  end_ip_address   = local.presenter_ip_by_hash[each.key]
}
