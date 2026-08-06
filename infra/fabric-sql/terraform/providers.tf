terraform {
  # The microsoft/fabric provider requires Terraform >= 1.8.
  required_version = ">= 1.8.0"

  required_providers {
    # azurerm provisions the Fabric *capacity* (an Azure resource:
    # Microsoft.Fabric/capacities). azurerm_fabric_capacity landed in v4.14.
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.14"
    }
    # The Fabric provider manages items *inside* Fabric — the workspace and the
    # SQL database — via the Fabric REST APIs (not ARM).
    fabric = {
      source  = "microsoft/fabric"
      version = "~> 1.12"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  # Remote azurerm backend (Azure Storage) — see notes/decisions.md D5. AAD auth (no
  # storage account keys), matching the passwordless design used everywhere else. The
  # storage account/container/key are supplied via -backend-config at `terraform init`
  # (see infra/pipelines/github-actions), since they're environment-specific. Uses its own
  # state key (fabric-sql/dev.terraform.tfstate) so it never collides with the Azure SQL
  # module's state.
  backend "azurerm" {
    use_oidc         = true
    use_azuread_auth = true
  }
}

provider "azurerm" {
  features {}

  # Pinned to Tenant B (the Fabric infra). The Terraform STATE BACKEND authenticates
  # separately to Tenant A via the ARM_* env — explicit provider args here beat those env
  # vars, so backend (Tenant A) and provider (Tenant B) diverge cleanly in one run. See
  # planning/2026-08-05-fabric-cross-tenant-automation-design.md §4b. Vars default empty /
  # use_oidc=false so a local `az login` (into Tenant B) still works; CI supplies them.
  subscription_id = var.fabric_subscription_id
  client_id       = var.fabric_client_id != "" ? var.fabric_client_id : null
  tenant_id       = var.fabric_tenant_id != "" ? var.fabric_tenant_id : null
  use_oidc        = var.fabric_use_oidc
}

provider "fabric" {
  # Passwordless by default: the provider reuses your Azure CLI login (az login).
  # For CI, set FABRIC_USE_OIDC=true (OIDC) or a service principal via env vars —
  # never commit credentials. The tenant can be pinned out-of-band with
  # FABRIC_TENANT_ID; left unset, the CLI's current tenant is used.
}
