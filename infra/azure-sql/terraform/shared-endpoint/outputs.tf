output "resource_group_name" {
  description = "Name of the resource group holding the shared endpoint. Tear down with: az group delete -n <this>."
  value       = azurerm_resource_group.this.name
}

output "sql_server_name" {
  description = "Name of the logical SQL server (globally unique)."
  value       = azurerm_mssql_server.this.name
}

output "sql_server_fqdn" {
  description = "Server FQDN — the host attendees connect to and the DACPAC publishes into."
  value       = azurerm_mssql_server.this.fully_qualified_domain_name
}

output "attendee_databases" {
  description = "The per-attendee database names (attendee logs into the one matching their number)."
  value       = sort([for db in azurerm_mssql_database.attendee : db.name])
}

output "attendee_count" {
  description = "Number of attendee databases/logins provisioned."
  value       = var.attendee_count
}

output "attendee_password" {
  description = "The shared attendee password (public by design — print it on the slide)."
  value       = var.attendee_password
}

# Handout: a ready-to-paste connection string per attendee. login attendeeNN / their DB /
# the shared password. Non-sensitive on purpose — this is the giveaway.
output "attendee_connection_strings" {
  description = "sqlcmd/ADO.NET-style connection string per attendee, ready to hand out."
  value = {
    for id in local.attendee_ids : id =>
    "Server=tcp:${azurerm_mssql_server.this.fully_qualified_domain_name},1433;Database=sqldb-${id};User ID=${id};Password=${var.attendee_password};Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
  }
}

output "admin_login" {
  description = "SQL admin login (presenters only)."
  value       = azurerm_mssql_server.this.administrator_login
}

output "admin_password" {
  description = "Generated SQL admin password (presenters only — NOT for attendees)."
  value       = random_password.admin.result
  sensitive   = true
}
