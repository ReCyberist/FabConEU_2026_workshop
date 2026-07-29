using './main.bicep'

// Capacity admins: your Entra UPN(s) and/or service-principal object ID(s). At least one is
// required. Leave the Fabric workspace + SQL database to the Terraform module (../terraform)
// or the Fabric REST API / CLI — ARM/Bicep can't create them (see main.bicep).
param capacityAdminMembers = [
  'you@example.com'
]

// Override defaults as needed, e.g.:
// param capacitySku = 'F4'
// param location = 'uksouth'
// param locationAbbreviation = 'uks'
