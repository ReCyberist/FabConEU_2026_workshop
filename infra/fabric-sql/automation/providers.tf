terraform {
  required_version = ">= 1.8.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.14"
    }
  }

  # State in Tenant A (same backend as the Fabric module, different key). Auth via ARM_* env.
  # storage account / container / key supplied at init via -backend-config.
  backend "azurerm" {
    use_oidc         = true
    use_azuread_auth = true
  }
}

provider "azurerm" {
  features {}

  # Pinned to Tenant B (same pattern as the module). The state backend uses the ARM_* env
  # (Tenant A); explicit provider args here beat that env, so backend and provider diverge
  # cleanly. Vars default empty / use_oidc=false so a local `az login` (Tenant B) still works.
  subscription_id = var.fabric_subscription_id
  client_id       = var.fabric_client_id != "" ? var.fabric_client_id : null
  tenant_id       = var.fabric_tenant_id != "" ? var.fabric_tenant_id : null
  use_oidc        = var.fabric_use_oidc
}
