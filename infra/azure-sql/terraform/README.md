# Azure SQL — Terraform (content focus)

Provision Azure SQL (logical server + database + firewall + Entra auth) with Terraform.
This is the **taught path** for the Azure SQL infra module. It produces the server and
database that the SQL project's DACPAC publishes into (see
[`../../../database/sql-projects/PublishProfiles/`](../../../database/sql-projects/PublishProfiles/)).

## What it creates

| Resource | Name (defaults) | Notes |
|----------|-----------------|-------|
| Resource group | `rg-fabcon26-dev-weu` | |
| Logical SQL server | `sql-fabcon26-dev-weu-<rnd>` | Globally unique (random suffix); TLS 1.2 min; **Entra-only auth**. |
| SQL database | `sqldb-football-dev` | GP serverless, auto-pause 60 min, 2 GB — cost-aware lab default. |
| Firewall rule(s) | `AllowAzureServices` (+ any client IPs) | Lets the pipeline runner reach the server. |

## Naming — Azure Cloud Adoption Framework (CAF)

Names follow the CAF convention
`<resource-type-abbreviation>-<workload>-<environment>-<region>[-<unique>]`:

- **`rg-`** resource group, **`sql-`** logical server, **`sqldb-`** database — the official
  [CAF abbreviations](https://learn.microsoft.com/azure/cloud-adoption-framework/ready/azure-best-practices/resource-abbreviations).
- The **workload token stays `fabcon26`**, so a `*fabcon26*` filter still finds and tears
  down every workshop resource (CLAUDE.md §4) while the type-abbreviation leads, as CAF
  wants.
- The logical server name must be **globally unique**, so a short random token is appended.
- Region is abbreviated (`weu`) per CAF; override `location` + `location_abbreviation`
  together for other regions.

## Passwordless by design

Auth is **Microsoft Entra-only** (`azuread_authentication_only = true`) — there is no SQL
admin login or password, so nothing secret is committed or needs rotating. Supply the Entra
admin identity (a **group** is recommended) via `entra_admin_login` +
`entra_admin_object_id`. The deploy pipeline authenticates with its own Entra identity.

## Firewall access (and a secret IP)

Public network access is gated by firewall rules. Two ways to allow a client through:

- `allow_azure_services` (on by default) opens the `0.0.0.0` "Azure services" rule so the
  GitHub-hosted runner can publish the DACPAC.
- `allowed_client_ips` — a **non-secret** `{ name = ip }` map for known machines, committed
  in tfvars.
- `presenter_client_ips` — a **list of IPs sourced from secrets**, for presenters' static IPs
  you don't want in source control. The apply/plan workflows build the list from one secret
  **per person** (`ROB_CLIENT_IP`, `JESS_CLIENT_IP`) so each rotates independently; unset
  secrets drop out ⇒ no rule. Empty list ⇒ no rules. Each person sets their own:

  ```powershell
  gh secret set ROB_CLIENT_IP  --repo JessAndRob/FabConEU_2026_workshop --body "<robs.static.ip>"
  gh secret set JESS_CLIENT_IP --repo JessAndRob/FabConEU_2026_workshop --body "<jess.static.ip>"
  ```

  Then run [`azure-sql-apply.yml`](../../../.github/workflows/azure-sql-apply.yml) to create a
  `presenter-<hash>` firewall rule per IP. The variable is `sensitive`, so Terraform prints the
  rule value as `(sensitive value)` and names the rule after a one-way hash — the IP appears
  **nowhere** in the plan/apply output, with GitHub Actions' secret masking as a second layer.
  Adding a third machine = a new secret + one more entry in the workflows'
  `presenter_client_ips` array. (Fork PRs don't receive secrets, so a PR plan from a fork would
  show the rules as absent — not a concern for this private repo.)

## Run it

Locally (local state, for iterating on the module itself):

```powershell
Copy-Item terraform.tfvars.example terraform.tfvars   # fill in the Entra admin identity
Copy-Item backend_local_override.tf.example backend_local_override.tf   # local state, no remote backend
$env:ARM_SUBSCRIPTION_ID = "<your-subscription-id>"

terraform init
terraform plan
terraform apply
```

The `backend_local_override.tf` swaps the committed remote `azurerm` backend (see **State**
below) for **local** state — Terraform auto-merges `*_override.tf` files and a `backend` block
in an override replaces the primary one. Without it, a bare `terraform init` tries to
initialize the remote backend and prompts for a container name; `terraform init -backend=false`
only unblocks `fmt`/`validate` (a subsequent `plan`/`apply` errors with *"Backend
initialization required"*). The override file and `terraform.tfstate*` are gitignored, so local
iteration never touches the shared remote backend.

Via GitHub Actions, against the shared remote state (see **State** below):
[`azure-sql-apply.yml`](../../../.github/workflows/azure-sql-apply.yml) (manual) and
[`azure-sql-destroy.yml`](../../../.github/workflows/azure-sql-destroy.yml) (nightly at
21:00 UTC + manual).

**State.** Uses a **remote `azurerm` backend** (Azure Storage, AAD/OIDC auth — no storage
keys), per [`notes/decisions.md`](../../../notes/decisions.md) **D5**. The state account
(`stfabcon26tf4766a4`) lives in its own persistent resource group
(`rg-fabcon26-state-weu`), kept separate from the workload resource group so the nightly
destroy workflow never touches the state store. This is the presenter's **personal sandbox**
backend (task #17's personal-use resolution); the *attendee-facing* backend/sandbox
strategy is still open (#1). `.terraform.lock.hcl` is committed so CI and teammates resolve
identical provider versions.

> **Status:** `fmt`, `init`, `validate` all run clean. Remote backend + OIDC auth wired up
> and GitHub Actions apply/destroy workflows added — first live `apply` still to be run;
> tracked with the runtime deploy in [`planning/tasks.md`](../../../planning/tasks.md) #14.

## Inputs

Only `entra_admin_login` and `entra_admin_object_id` are required; everything else has a
cost-aware default. See [`variables.tf`](variables.tf) for the full list and validation
rules, and [`terraform.tfvars.example`](terraform.tfvars.example) for a starting point.

Keep in step with the Bicep reference in [`../bicep/`](../bicep/) and the Fabric SQL
equivalent in [`../../fabric-sql/terraform/`](../../fabric-sql/terraform/).
