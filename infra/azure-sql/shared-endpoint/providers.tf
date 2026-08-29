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

  # Remote azurerm backend (Azure Storage), same pattern as the taught module (D5) — so the
  # plan-on-PR job in azure-sql-plan.yml can read state and show the *incremental* change
  # (e.g. "+5 databases" when attendee_count goes 10 -> 15), which is the whole point of the
  # bump-the-count demo. AAD/OIDC auth (no storage keys). The storage account / container /
  # key come from -backend-config at `terraform init` (see the workflow). A presenter running
  # locally swaps this for local state via backend_local_override.tf.example (no state
  # account needed) — see README.
  backend "azurerm" {
    use_oidc         = true
    use_azuread_auth = true
  }
}

provider "azurerm" {
  features {}
  # Passwordless: reuse the presenter's `az login` (or OIDC/SP in CI). Nothing committed.
}

# The mssql provider authenticates per-resource via the `server {}` block on each resource
# (see main.tf) using the SQL admin login this module creates — so there is nothing to set
# here. It connects over the public endpoint, which the firewall must allow (see README).
provider "mssql" {}
