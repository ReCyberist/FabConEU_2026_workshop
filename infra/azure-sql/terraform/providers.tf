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

  # For the workshop we use local state (documented as such). For anything shared or
  # production, switch to a remote backend (e.g. azurerm) — see README.
}

provider "azurerm" {
  features {}

  # azurerm v4 requires the subscription to be set explicitly. Supply it out-of-band via
  # the ARM_SUBSCRIPTION_ID environment variable so no subscription id is committed.
}
