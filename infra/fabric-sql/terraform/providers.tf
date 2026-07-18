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

  # Local state for now. Same remote-backend direction as the Azure SQL module —
  # see notes/decisions.md D5 and task #17 (gated on #1).
}

provider "azurerm" {
  features {}

  # azurerm v4 requires the subscription explicitly. Supply it out-of-band via the
  # ARM_SUBSCRIPTION_ID environment variable so no subscription id is committed.
}

provider "fabric" {
  # Passwordless by default: the provider reuses your Azure CLI login (az login).
  # For CI, set FABRIC_USE_OIDC=true (OIDC) or a service principal via env vars —
  # never commit credentials. The tenant can be pinned out-of-band with
  # FABRIC_TENANT_ID; left unset, the CLI's current tenant is used.
}
