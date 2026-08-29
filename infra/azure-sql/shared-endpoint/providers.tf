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
    # SQL logins + database users are created *inside* SQL, not by the ARM control plane,
    # so azurerm can't make them — the mssql provider connects to the server and runs the
    # T-SQL (CREATE LOGIN / CREATE USER / role membership) declaratively. See README.
    mssql = {
      source  = "betr-io/mssql"
      version = "~> 0.3"
    }
  }

  # LOCAL state, deliberately. Unlike the taught module (remote azurerm backend, D5), this
  # is a throwaway endpoint a presenter stands up once and tears down the same day — local
  # state keeps it self-contained (no bootstrap, no state account) and matches "local state
  # is fine for a one-shot lab" from D6. Keep the state file off the machine when done.
}

provider "azurerm" {
  features {}
  # Passwordless: reuse the presenter's `az login` (or OIDC/SP in CI). Nothing committed.
}

# The mssql provider authenticates per-resource via the `server {}` block on each resource
# (see main.tf) using the SQL admin login this module creates — so there is nothing to set
# here. It connects over the public endpoint, which the firewall must allow (see README).
provider "mssql" {}
