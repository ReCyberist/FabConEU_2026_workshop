// Resource-group-scoped module: the Fabric capacity (Microsoft.Fabric/capacities) — the
// compute/billing unit. Called by main.bicep. This is the only Fabric-related resource ARM
// can express; the workspace + SQL database are Fabric control-plane items (see main.bicep).

@description('Azure region.')
param location string = resourceGroup().location

@description('Fabric capacity name (lowercase alphanumerics only, globally unique).')
param capacityName string

@description('Fabric capacity SKU. F2 is the smallest/cheapest.')
param capacitySku string = 'F2'

@description('Microsoft Entra admins for the capacity (UPNs or service-principal object IDs).')
param capacityAdminMembers array

param tags object = {}

// NOTE: an F-SKU capacity BILLS the whole time it exists — there is no serverless auto-pause.
// Pause it out-of-band (az CLI / portal) or tear it down when idle to stop charges.
resource capacity 'Microsoft.Fabric/capacities@2023-11-01' = {
  name: capacityName
  location: location
  tags: tags
  sku: {
    name: capacitySku
    tier: 'Fabric'
  }
  properties: {
    administration: {
      members: capacityAdminMembers
    }
  }
}

output capacityName string = capacity.name
output capacityId string = capacity.id
