# Azure SQL as code (Terraform)

Provision an Azure SQL server and database with **Terraform** — a resource group, a logical server,
a serverless database, and a firewall rule, all from a handful of `.tf` files. No portal clicking,
no admin password, fully repeatable.

!!! note "Follow along — or just watch"
    You'll need your **own Azure subscription** with rights to create resources. No subscription?
    Just watch — it's a live demo you can replay later from the downloads. See
    [Prerequisites](../setup/prerequisites.md).

## What you'll build

| Resource | Name (default) | Notes |
|---|---|---|
| Resource group | `rg-fabcon26-dev-weu` | |
| Logical SQL server | `sql-fabcon26-dev-weu-<rnd>` | Globally unique; TLS 1.2 min; **Entra-only auth** |
| SQL database | `sqldb-football-dev` | Serverless, auto-pause 60 min, 2 GB — a cost-aware lab default |
| Firewall rule | `AllowAzureServices` | Lets the pipeline runner reach the server |

## The concept

**Infrastructure as code**: the server and database are declared, not clicked. Terraform reads the
`.tf` files, works out the diff against real Azure, and applies it. Three ideas do the heavy lifting:

- **State** — Terraform records what it created, in a remote Azure Storage backend so you and CI
  share one source of truth (auth is AAD/OIDC — no storage keys).
- **Passwordless** — the server is **Microsoft Entra-only** (`azuread_authentication_only = true`):
  no SQL admin login, no password, nothing secret to commit or rotate.
- **CAF naming** — names follow the Azure Cloud Adoption Framework (`rg-`, `sql-`, `sqldb-`) with
  `fabcon26` as the workload token, so a `*fabcon26*` filter finds — and tears down — everything.

## Terraform (focus) / Bicep (reference)

=== "Terraform"
    The taught path. From the module folder:

    ```powershell
    $env:ARM_SUBSCRIPTION_ID = "<your-subscription-id>"

    # Local demo: use local state instead of the remote Azure Storage backend
    Copy-Item backend_local_override.tf.example backend_local_override.tf

    terraform init
    terraform plan     # see exactly what will be created
    terraform apply
    ```

    !!! note "Why the override?"
        The module ships with a remote **`azurerm`** backend (Azure Storage, AAD/OIDC)
        for CI and shared state. On a laptop that backend has no storage account to talk
        to, so a bare `terraform init` prompts for a container name. Copying
        `backend_local_override.tf.example` swaps in a **local** backend for the demo —
        no Azure Storage account, no prompts. The file is gitignored, so it never
        disturbs the remote backend CI relies on.

=== "Bicep"
    The same infrastructure is mirrored in **Bicep** for the ARM-native crowd — a subscription-scoped
    `main.bicep` creates the RG and calls `sql.bicep` (server + serverless DB + firewall, Entra-only).
    Compile with `az bicep build`, deploy with `az deployment sub create`. It's a reference variant;
    the taught path is Terraform.

## The code

The module lives in
[`infra/azure-sql/terraform`](https://github.com/JessAndRob/FabConEU_2026_workshop/tree/main/infra/azure-sql/terraform)
— only `entra_admin_login` + `entra_admin_object_id` are required; everything else has a cost-aware
default. The Bicep reference is in
[`infra/azure-sql/bicep`](https://github.com/JessAndRob/FabConEU_2026_workshop/tree/main/infra/azure-sql/bicep).
Download the module bundle and run it from code — nothing is clicked.

## Checkpoint

`terraform apply` created the resource group, the logical server, and the serverless database — and
you can sign in **passwordless** with your Entra identity. That database is the target the
[SQL project's DACPAC](../database/sql-projects.md) publishes into.

## Gotchas

- **Naming:** the CAF type-abbreviation leads (`rg-`/`sql-`/`sqldb-`), `fabcon26` is the workload
  token, and the globally-unique server gets a short random suffix.
- **Passwordless needs a real identity:** supply the Entra admin — a **group** is best (one group,
  everyone in it, including the CI identity, since a server allows only one Entra admin).
- **A Sponsorship/MSDN subscription can be region-restricted** below what the resource provider
  advertises. If `apply` fails with *"Subscriptions are restricted from provisioning in this
  region"*, move `location` + `location_abbreviation` together and retry.
- **Keep Terraform state out of the workload resource group** — the nightly destroy tears the
  workload down; state lives in its own persistent account so it's never deleted.

## What's next

Next: [Fabric SQL as code](fabric-sql.md) — the same, side by side on Fabric.
