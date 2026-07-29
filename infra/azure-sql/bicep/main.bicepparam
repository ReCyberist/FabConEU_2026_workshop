using './main.bicep'

// Fill in the Microsoft Entra admin identity. A group is strongly recommended (a logical SQL
// server allows exactly one Entra admin, so a group is the only way to admin-grant more than
// one identity — e.g. the presenters plus the CI service principal).
param entraAdminLogin = 'fabcon26-sql-admins'
param entraAdminObjectId = '00000000-0000-0000-0000-000000000000'

// Everything else has a cost-aware default. Override here as needed, e.g. for a region your
// subscription is allowed to provision in:
// param location = 'uksouth'
// param locationAbbreviation = 'uks'
