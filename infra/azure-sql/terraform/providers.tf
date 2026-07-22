terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  # Remote azurerm backend (Azure Storage) — see notes/decisions.md D5. AAD auth (no
  # storage account keys), matching the passwordless design used everywhere else. The
  # storage account/container/key are supplied via -backend-config at `terraform init`
  # (see infra/pipelines/github-actions), since they're environment-specific.
  backend "azurerm" {
    use_oidc         = true
    use_azuread_auth = true
  }
}

provider "azurerm" {
  features {}

  # Passwordless OIDC auth throughout (notes/decisions.md D5). Supply ARM_CLIENT_ID,
  # ARM_TENANT_ID, ARM_SUBSCRIPTION_ID and ARM_USE_OIDC=true as environment variables
  # (e.g. from the CI workflow) rather than committing any of them here.
}
