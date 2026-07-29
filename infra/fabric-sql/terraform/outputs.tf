output "resource_group_name" {
  description = "Name of the resource group holding the Fabric capacity."
  value       = azurerm_resource_group.this.name
}

output "capacity_name" {
  description = "Name of the Fabric capacity (globally unique)."
  value       = azurerm_fabric_capacity.this.name
}

output "workspace_id" {
  description = "ID of the Fabric workspace the SQL database lives in."
  value       = fabric_workspace.this.id
}

output "sql_database_name" {
  description = "Actual name of the SQL database in Fabric that the DACPAC publishes into."
  value       = fabric_sql_database.this.properties.database_name
}

output "sql_server_fqdn" {
  description = "Fully-qualified server name for the Fabric SQL database — the target for SqlPackage publish (mirrors the Azure SQL module's sql_server_fqdn)."
  value       = fabric_sql_database.this.properties.server_fqdn
}

output "sql_connection_string" {
  description = "Connection string for the Fabric SQL database (Microsoft Entra auth; no secret embedded)."
  value       = fabric_sql_database.this.properties.connection_string
}
