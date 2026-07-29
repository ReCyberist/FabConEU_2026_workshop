// Resource-group-scoped module: logical SQL server (Entra-only, passwordless) + serverless
// database + firewall rules. Called by main.bicep. Mirrors ../terraform/main.tf.

@description('Azure region.')
param location string = resourceGroup().location

@description('CAF naming suffix: <workload>-<environment>-<region>.')
param namingSuffix string

@description('Workload token for the database name.')
param databaseName string

@description('Environment token.')
param environment string

@description('Display name of the Microsoft Entra admin principal (group recommended).')
param entraAdminLogin string

@description('Object (principal) ID of the Microsoft Entra admin.')
param entraAdminObjectId string

@description('Principal type of the Entra admin.')
@allowed([ 'Group', 'User', 'Application' ])
param entraAdminPrincipalType string = 'Group'

@description('Entra tenant ID for the admin principal.')
param tenantId string

param publicNetworkAccessEnabled bool = true
param allowAzureServices bool = true
param allowedClientIps object = {}
param databaseSkuName string = 'GP_S_Gen5_1'
param databaseMaxSizeGb int = 2
param databaseMinCapacity string = '0.5'
param databaseAutoPauseDelay int = 60
param tags object = {}

// The logical SQL server name must be globally unique — append a short deterministic suffix
// (the Terraform module uses a random_string; uniqueString gives a stable per-RG equivalent).
var uniqueSuffix = take(uniqueString(resourceGroup().id), 6)
var sqlServerName = 'sql-${namingSuffix}-${uniqueSuffix}'
var sqlDatabaseName = 'sqldb-${databaseName}-${environment}'

resource sqlServer 'Microsoft.Sql/servers@2023-08-01-preview' = {
  name: sqlServerName
  location: location
  tags: tags
  properties: {
    version: '12.0'
    minimalTlsVersion: '1.2'
    publicNetworkAccess: publicNetworkAccessEnabled ? 'Enabled' : 'Disabled'
    // Passwordless: Microsoft Entra is the only way in — no SQL admin login/password, so
    // there is no secret to commit or rotate. A group principal is recommended for the admin.
    administrators: {
      administratorType: 'ActiveDirectory'
      principalType: entraAdminPrincipalType
      login: entraAdminLogin
      sid: entraAdminObjectId
      tenantId: tenantId
      azureADOnlyAuthentication: true
    }
  }
}

// Cost-aware lab default: General Purpose serverless, auto-pause when idle, locally-redundant
// backup, no zone redundancy. NOTE: autoPauseDelay/minCapacity apply to serverless SKUs only;
// switching databaseSkuName to a provisioned SKU also needs a matching tier/family/capacity.
resource sqlDatabase 'Microsoft.Sql/servers/databases@2023-08-01-preview' = {
  parent: sqlServer
  name: sqlDatabaseName
  location: location
  tags: tags
  sku: {
    name: databaseSkuName
    tier: 'GeneralPurpose'
    family: 'Gen5'
    capacity: 1
  }
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    maxSizeBytes: databaseMaxSizeGb * 1073741824
    autoPauseDelay: databaseAutoPauseDelay
    minCapacity: json(databaseMinCapacity)
    zoneRedundant: false
    requestedBackupStorageRedundancy: 'Local'
  }
}

// The 0.0.0.0 sentinel is Azure's "allow Azure services" rule — lets the hosted pipeline
// runner that publishes the DACPAC reach the server.
resource allowAzure 'Microsoft.Sql/servers/firewallRules@2023-08-01-preview' = if (allowAzureServices) {
  parent: sqlServer
  name: 'AllowAzureServices'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

// Named client IPs (e.g. an attendee's machine) allowed through the server firewall.
resource clientRules 'Microsoft.Sql/servers/firewallRules@2023-08-01-preview' = [for rule in items(allowedClientIps): {
  parent: sqlServer
  name: rule.key
  properties: {
    startIpAddress: rule.value
    endIpAddress: rule.value
  }
}]

output sqlServerName string = sqlServer.name
output sqlServerFqdn string = sqlServer.properties.fullyQualifiedDomainName
output sqlDatabaseName string = sqlDatabase.name
