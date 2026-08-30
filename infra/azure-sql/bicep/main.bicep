// Azure SQL — Bicep (reference / bonus)
//
// Subscription-scoped entry point: creates the resource group, then deploys the SQL server
// + database + firewall via the resource-group-scoped module in sql.bicep. This is a
// functional mirror of the Terraform module in ../terraform (the taught path) — keep the two
// in step. Deploy with:
//
//   az deployment sub create --location uksouth `
//     --template-file main.bicep --parameters main.bicepparam
//
// Passwordless throughout: no SQL admin login/password — Microsoft Entra is the only way in.

targetScope = 'subscription'

@description('Azure region for all resources. Defaults to UK South — West Europe has no capacity for this subscription (see LEARNINGS 2026-08-29).')
param location string = 'uksouth'

@description('Short region token used in resource names (CAF style), e.g. uks for uksouth.')
@minLength(2)
@maxLength(6)
param locationAbbreviation string = 'uks'

@description('Workload / application token used in every resource name. Kept as the teardown prefix.')
@minLength(2)
@maxLength(16)
param workload string = 'fabcon26'

@description('Deployment environment token (e.g. dev, test, prod).')
@minLength(2)
@maxLength(8)
param environment string = 'dev'

@description('Workload token for the database name (becomes sqldb-<databaseName>-<environment>).')
@minLength(2)
@maxLength(16)
param databaseName string = 'football'

@description('Display name of the Microsoft Entra principal set as SQL server admin (a group is recommended).')
param entraAdminLogin string

@description('Object (principal) ID of the Microsoft Entra admin. A group is recommended over an individual.')
param entraAdminObjectId string

@description('Principal type of the Entra admin (a group is recommended and the module default).')
@allowed([ 'Group', 'User', 'Application' ])
param entraAdminPrincipalType string = 'Group'

@description('Allow public network access to the server (still gated by firewall rules).')
param publicNetworkAccessEnabled bool = true

@description('Add the "allow Azure services" firewall exception (0.0.0.0) so hosted pipeline runners can reach the server.')
param allowAzureServices bool = true

@description('Named client IPs to allow through the server firewall, as { ruleName: ipAddress }.')
param allowedClientIps object = {}

@description('Database SKU name. Default is 1-vCore General Purpose serverless (auto-pauses when idle).')
param databaseSkuName string = 'GP_S_Gen5_1'

@description('Maximum database size in GB.')
param databaseMaxSizeGb int = 2

@description('Minimum vCores for a serverless database. A string because Bicep has no decimal type (json() converts it).')
param databaseMinCapacity string = '0.5'

@description('Minutes of inactivity before a serverless database auto-pauses; -1 disables auto-pause.')
param databaseAutoPauseDelay int = 60

@description('Additional resource tags, merged over the module defaults.')
param tags object = {}

// CAF naming: <type>-<workload>-<environment>-<region>. The workload token stays "fabcon26"
// so a *fabcon26* filter still finds and tears down everything (CLAUDE.md §4).
var namingSuffix = '${workload}-${environment}-${locationAbbreviation}'
var resourceGroupName = 'rg-${namingSuffix}'

var defaultTags = {
  workload: workload
  environment: environment
  'managed-by': 'bicep'
  project: 'fabcon-europe-2026-workshop'
}

resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: resourceGroupName
  location: location
  tags: union(defaultTags, tags)
}

module sql 'sql.bicep' = {
  name: 'sql-${environment}'
  scope: rg
  params: {
    location: location
    namingSuffix: namingSuffix
    databaseName: databaseName
    environment: environment
    entraAdminLogin: entraAdminLogin
    entraAdminObjectId: entraAdminObjectId
    entraAdminPrincipalType: entraAdminPrincipalType
    tenantId: subscription().tenantId
    publicNetworkAccessEnabled: publicNetworkAccessEnabled
    allowAzureServices: allowAzureServices
    allowedClientIps: allowedClientIps
    databaseSkuName: databaseSkuName
    databaseMaxSizeGb: databaseMaxSizeGb
    databaseMinCapacity: databaseMinCapacity
    databaseAutoPauseDelay: databaseAutoPauseDelay
    tags: union(defaultTags, tags)
  }
}

output resourceGroupName string = rg.name
output sqlServerName string = sql.outputs.sqlServerName
output sqlServerFqdn string = sql.outputs.sqlServerFqdn
output sqlDatabaseName string = sql.outputs.sqlDatabaseName
