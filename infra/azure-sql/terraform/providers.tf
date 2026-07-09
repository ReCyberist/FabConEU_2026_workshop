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

  # Local state for now. Decided direction is a remote azurerm backend (Azure Storage) for
  # both CI and attendees — see notes/decisions.md D5 and task #17 (gated on #1). Local
  # state can't survive GitHub Actions' ephemeral runners.
}

provider "azurerm" {
  features {}

  # azurerm v4 requires the subscription to be set explicitly. Supply it out-of-band via
  # the ARM_SUBSCRIPTION_ID environment variable so no subscription id is committed.
}
