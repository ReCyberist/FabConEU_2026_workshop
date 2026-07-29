// Fabric SQL — Bicep (reference / bonus)
//
// IMPORTANT — what Bicep/ARM can and cannot express here:
//   [YES] Fabric CAPACITY  — Microsoft.Fabric/capacities is a real Azure (ARM) resource, so
//         Bicep provisions it fully (this file).
//   [NO]  Fabric WORKSPACE and SQL DATABASE in Fabric — these are Fabric *control-plane*
//         items with NO ARM resource type, so they cannot be created by Bicep/ARM at all.
//
// For the full stack (capacity -> workspace -> database) use the Terraform module in
// ../terraform (it uses the microsoft/fabric provider over the Fabric REST APIs), or create
// the workspace + database via the Fabric REST API / CLI after this deploys the capacity.
// This mirrors the "capacity" slice of ../terraform/main.tf only.
//
// Deploy with:
//   az deployment sub create --location westeurope `
//     --template-file main.bicep --parameters main.bicepparam

targetScope = 'subscription'

@description('Azure region for the Fabric capacity (and its resource group).')
param location string = 'westeurope'

@description('Short region token used in the resource group name (CAF style), e.g. weu.')
@minLength(2)
@maxLength(6)
param locationAbbreviation string = 'weu'

@description('Workload / application token used in every resource name. Kept as the teardown prefix.')
@minLength(2)
@maxLength(16)
param workload string = 'fabcon26'

@description('Deployment environment token (e.g. dev, test, prod).')
@minLength(2)
@maxLength(8)
param environment string = 'dev'

@description('Fabric capacity SKU. F2 is the smallest/cheapest — fine for the workshop database.')
param capacitySku string = 'F2'

@description('Microsoft Entra admins for the Fabric capacity (UPNs or service-principal object IDs).')
param capacityAdminMembers array

@description('Additional resource tags, merged over the module defaults.')
param tags object = {}

var namingSuffix = '${workload}-${environment}-${locationAbbreviation}'
var resourceGroupName = 'rg-${namingSuffix}'

// A Fabric capacity name allows LOWERCASE ALPHANUMERICS ONLY (no hyphens) and is globally
// unique — build it from the tokens minus separators, prefixed to guarantee a leading letter.
var capacityName = 'cap${workload}${environment}${take(uniqueString(subscription().id, workload, environment), 6)}'

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

module capacity 'capacity.bicep' = {
  name: 'fabric-capacity-${environment}'
  scope: rg
  params: {
    location: location
    capacityName: capacityName
    capacitySku: capacitySku
    capacityAdminMembers: capacityAdminMembers
    tags: union(defaultTags, tags)
  }
}

output resourceGroupName string = rg.name
output capacityName string = capacity.outputs.capacityName
output capacityId string = capacity.outputs.capacityId
