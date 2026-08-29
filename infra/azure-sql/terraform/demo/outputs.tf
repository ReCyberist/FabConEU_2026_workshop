output "resource_group_name" {
  description = "Name of the resource group holding the Azure SQL resources."
  value       = azurerm_resource_group.this.name
}

output "sql_server_name" {
  description = "Name of the logical SQL server (globally unique)."
  value       = azurerm_mssql_server.this.name
}

output "sql_server_fqdn" {
  description = "Fully-qualified domain name of the SQL server — the target for SqlPackage publish."
  value       = azurerm_mssql_server.this.fully_qualified_domain_name
}

output "sql_database_name" {
  description = "Name of the SQL database the DACPAC publishes into."
  value       = azurerm_mssql_database.this.name
}
