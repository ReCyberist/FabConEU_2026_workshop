# Cross-tenant setup — Fabric SQL (Tenant B identity)

The Fabric SQL infra + database deployment run in a **different tenant/subscription/client**
(**Tenant B**) than the Azure SQL work and the **Terraform state backend** (**Tenant A**). In a
single Terraform run the **state backend authenticates to Tenant A** (via the `ARM_*` env) while
the **azurerm + fabric providers authenticate to Tenant B** (the azurerm provider pinned in
[`terraform/providers.tf`](terraform/providers.tf); the fabric provider + the DACPAC publish via
`FABRIC_*`). This is the *"state in one subscription, infra in another"* separation-of-duties
pattern. Full rationale:
[`planning/2026-08-05-fabric-cross-tenant-automation-design.md`](../../planning/2026-08-05-fabric-cross-tenant-automation-design.md).

This page is the **one-time Tenant B identity setup**, as code — nothing clicked.

## Prerequisites (Tenant B)

- A **tenant admin has enabled *"Service principals can use Fabric APIs"*** (Fabric admin portal →
  Tenant settings → Developer settings), scoped to the **`data-deployment-sps`** security group (or
  org-wide). That group also carries the Fabric **workspace** access.
- You can **create app registrations** in Tenant B and are **Owner or User Access Administrator** on
  the Tenant B subscription (needed to grant the two roles below).
- `gh` is authenticated with write access to `JessAndRob/FabConEU_2026_workshop`.

## Setup (PowerShell, signed in to Tenant B)

```powershell
$tenantB = "<TENANT_B_TENANT_ID>"       # Tenant B directory (tenant) id
$subB    = "<TENANT_B_SUBSCRIPTION_ID>" # Tenant B sub where the Fabric capacity lives
$repo    = "JessAndRob/FabConEU_2026_workshop"
$appName = "fabcon26-fabric-github-actions"

az login --tenant $tenantB
az account set --subscription $subB

# 1) App registration + service principal (no secret — OIDC only)
$appId      = az ad app create --display-name $appName --query appId -o tsv
az ad sp create --id $appId | Out-Null
$spObjectId = az ad sp show --id $appId --query id -o tsv   # SP *object* id (not appId)

# 2) Two GitHub OIDC federated credentials: main (apply/destroy/automation) + PRs (plan)
@"
{ "name": "fabcon26-fabric-main",
  "issuer": "https://token.actions.githubusercontent.com",
  "subject": "repo:$repo:ref:refs/heads/main",
  "audiences": ["api://AzureADTokenExchange"] }
"@ | Set-Content -Path fic-main.json -Encoding utf8
az ad app federated-credential create --id $appId --parameters '@fic-main.json'

@"
{ "name": "fabcon26-fabric-pr",
  "issuer": "https://token.actions.githubusercontent.com",
  "subject": "repo:$repo:pull_request",
  "audiences": ["api://AzureADTokenExchange"] }
"@ | Set-Content -Path fic-pr.json -Encoding utf8
az ad app federated-credential create --id $appId --parameters '@fic-pr.json'

# 3) Role assignments on the Tenant B subscription: Contributor + User Access Administrator
#    (UAA lets the automation Terraform create its managed identity's custom role + assignment.)
$scope = "/subscriptions/$subB"
az role assignment create --assignee-object-id $spObjectId --assignee-principal-type ServicePrincipal --role "Contributor"               --scope $scope
az role assignment create --assignee-object-id $spObjectId --assignee-principal-type ServicePrincipal --role "User Access Administrator" --scope $scope

# 4) Add the SP to data-deployment-sps — this is what gives it the Fabric API tenant setting
#    + workspace access already granted to the group.
$groupId = az ad group show --group "data-deployment-sps" --query id -o tsv
az ad group member add --group $groupId --member-id $spObjectId

# 5) GitHub repo variables (non-secret under OIDC)
gh variable set FABRIC_CLIENT_ID           --repo $repo --body $appId
gh variable set FABRIC_TENANT_ID           --repo $repo --body $tenantB
gh variable set FABRIC_SUBSCRIPTION_ID     --repo $repo --body $subB
gh variable set FABRIC_CAPACITY_ADMIN_UPNS --repo $repo --body '["jess@sewells-consulting.co.uk","rob@sewells-consulting.co.uk"]'
```

## Verify

```powershell
az ad app federated-credential list --id $appId --query "[].subject" -o tsv
az role assignment list --assignee $spObjectId --scope $scope --query "[].roleDefinitionName" -o tsv
az ad group member check --group $groupId --member-id $spObjectId --query value -o tsv
gh variable list --repo $repo | Select-String FABRIC
```

## Notes

- **`FABRIC_CLIENT_ID` is the app (client) id** — used by the fabric provider, the azurerm provider
  (`TF_VAR_fabric_client_id`), and `azure/login`. The SP **object id** is only needed here (role +
  group); the module auto-adds it as a capacity admin at deploy time (alongside the presenter UPNs
  in `FABRIC_CAPACITY_ADMIN_UPNS`).
- The two federated credentials cover every Fabric workflow: `main` → apply / destroy /
  automation (`workflow_dispatch`), `pull_request` → plan.
- **Capacity admins:** users go in by **UPN** (email); service principals by **object ID** — per the
  [`azurerm_fabric_capacity`](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/fabric_capacity)
  provider doc.
