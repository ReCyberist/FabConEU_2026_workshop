# Shared, unsupported workshop endpoint (Azure SQL)

> ⚠️ **This is not the module you teach with.** The taught Azure SQL module lives in
> [`../terraform`](../terraform): remote state, Entra-only (passwordless), one database.
> **This** module is the best-effort DB-deploy target we hand attendees on the day
> ([decisions.md **D6**](../../../notes/decisions.md)) — **explicitly unsupported**, opened
> to the internet, on **SQL authentication**, and **destroyed the same day**.

## What it builds

One logical SQL server carrying:

- an **elastic pool** (all attendee databases share it → one predictable cost for the day),
- **one empty database per attendee** — `sqldb-attendee01` … `sqldb-attendeeNN`,
- **one SQL login per attendee** — `attendee01` … `attendeeNN`, every one using the **same
  shared password** (`Taylor==Metallica` by default), each mapped to a `db_owner` **user in its
  own database only**. So everyone gets `db_owner` on their sandbox and cannot touch anyone
  else's.

```
sql-fabcon26-shared-uks-xxxxxx.database.windows.net
├── elastic pool  ep-fabcon26-shared-uks   (4 vCores, shared)
├── sqldb-attendee01   ← login attendee01 (db_owner)
├── sqldb-attendee02   ← login attendee02 (db_owner)
└── …                                       password: Taylor==Metallica
```

## Why it differs from the taught module

| | Taught module (`../terraform`) | This shared endpoint |
|---|---|---|
| Auth | Entra-only, passwordless | **SQL logins** (can't hand a room Entra identities) |
| Shape | server → 1 database | server → **pool → N databases** |
| State | remote azurerm backend (D5) | **remote** backend too (so the PR plan sees real state) + a local override for laptop runs |
| Network | firewall by IP | **open to the internet** for the day |
| Lifespan | managed | **destroyed same day**, unsupported |

The database-per-attendee design is what removes DACPAC name collisions — each attendee
publishes into their own DB (D6).

## Prerequisites

- `az login` to the subscription that will host it (the module authenticates azurerm from
  your CLI session).
- Terraform >= 1.5, and the providers this module pins: `azurerm ~> 4.0`, `random ~> 3.6`,
  and **`betr-io/mssql ~> 0.3`** (creates the logins/users — installed on `terraform init`).
- The machine running `terraform` must be able to **reach the server on 1433**. With the
  default `allow_all_ips = true` that's automatic; if you turn it off, add your IP to
  `allowed_client_ips` or the login/user steps can't connect.

## Run it

From the repo root. The committed backend is the remote Azure Storage one (so CI's plan can
read shared state); to stand it up from your own machine, drop in the local-state override
first so `terraform init` needs no state account:

```powershell
cd infra/azure-sql/shared-endpoint
Copy-Item backend_local_override.tf.example backend_local_override.tf   # local state, laptop runs
Copy-Item terraform.tfvars.example terraform.tfvars
code terraform.tfvars          # set attendee_count, region, pool size

terraform init
terraform plan
terraform apply
```

Hand out the connection details (the attendee password is a normal, non-sensitive output;
the admin password is separate and sensitive):

```powershell
terraform output attendee_password
terraform output attendee_connection_strings          # one ready-to-paste string per attendee
terraform output -raw admin_password                  # presenters only — NOT for attendees
```

Each attendee connects to **their** database with **their** login, e.g. attendee07:

```powershell
Server:   sql-fabcon26-shared-uks-xxxxxx.database.windows.net
Database: sqldb-attendee07
Login:    attendee07
Password: Taylor==Metallica
```

…and publishes the sample DACPAC into it exactly like the taught path:

```powershell
sqlpackage /Action:Publish `
  /SourceFile:FabConFootball.dacpac `
  /TargetServerName:"sql-fabcon26-shared-uks-xxxxxx.database.windows.net" `
  /TargetDatabaseName:"sqldb-attendee07" `
  /TargetUser:"attendee07" `
  /TargetPassword:"Taylor==Metallica"
```

## Run locally against the shared (remote) state

This is what makes the demo feel real: after the apply workflow has deployed the endpoint,
point your laptop at the **same remote state** so `terraform plan` shows **no changes** —
then edit `attendee_count` and watch the plan show only the delta. The trick is to init the
**remote** backend (don't copy the local override) and authenticate the state account with
your `az login` instead of CI's OIDC:

```powershell
cd infra/azure-sql/shared-endpoint
az login
az account set --subscription <the-workshop-subscription-id>

# init the REAL remote state (same key the workflows use). use_oidc=false -> use your az login;
# use_azuread_auth=true is already in providers.tf (needs Storage Blob Data Contributor on the
# state account). Do NOT create backend_local_override.tf here — that would use local state.
terraform init `
  -backend-config="resource_group_name=rg-fabcon26-state-weu" `
  -backend-config="storage_account_name=stfabcon26tf4766a4" `
  -backend-config="container_name=tfstate" `
  -backend-config="key=azure-sql/shared-endpoint.terraform.tfstate" `
  -backend-config="use_oidc=false"
```

The module already defaults to **UK South** (where this sandbox subscription provisions), so
there's nothing else to match — plan straight away:

```powershell
terraform plan     # => No changes. Your infrastructure matches the configuration.
```

Then the demo:

```powershell
# edit attendee_count 10 -> 15 in variables.tf, then:
terraform plan     # => Plan: 15 to add? No — 15 to add is a fresh build; against the deployed
                   #    10 it shows "5 to add" (5 databases + 5 logins + 5 users).
terraform apply    # apply the delta straight from your laptop, OR commit + run the workflow
```

> The crisp **"+5"** only appears because the deployed 10 are already recorded in the shared
> state you just init'd against. If you instead used the local override (local state), the
> plan would show all 15 as new. Same reason the CI plan job reads remote state.

## Tear it down (do this the same day)

```powershell
terraform destroy
```

If you ran locally (local override), keep `terraform.tfstate` with you; if you lose it (or
never held it), delete by resource group instead — everything is prefixed for exactly this:

```powershell
az group delete --name rg-fabcon26-shared-uks --yes --no-wait
```

## Demo: "we have more attendees → we need more databases"

This module is also a **teaching prop for infrastructure as code**. The count of databases
is one number in [`variables.tf`](variables.tf) (`attendee_count`, default **10**). Change
it, open a PR, and the **plan job proves what will happen** before anything runs:

```powershell
# on a branch, edit attendee_count 10 -> 15 in variables.tf, then:
git commit -am "more attendees: 10 -> 15 databases"
git push
```

The PR triggers [`azure-sql-plan.yml`](../../../.github/workflows/azure-sql-plan.yml), whose
**`terraform plan (shared endpoint)`** job prints the exact delta:

```
+ 5 azurerm_mssql_database
+ 5 mssql_login
+ 5 mssql_user
Plan: 15 to add, 0 to change, 0 to destroy.
```

One reviewable number → a precise, reviewed plan of exactly the resources it creates. That
job is **read-only** (`-lock=false -refresh=false`); it never provisions.

**Then choose how to make it real:**

- **From CI (the usual demo close):** merge the PR and run
  [`azure-sql-apply.yml`](../../../.github/workflows/azure-sql-apply.yml) with the **`target`**
  input set to `attendee` (or `both`) — the shared endpoint is the `attendee-endpoint` job in
  that workflow. It applies the committed `attendee_count` against the shared remote state, so
  it creates exactly the extra databases/logins the plan showed, and prints the attendee
  handout (server, password, per-attendee connection strings) to the run summary.
- **From your laptop (against the same remote state):** see *Run locally against the shared
  state* below — plan/apply the delta directly.

The endpoint is torn down nightly by
[`shared-endpoint-destroy.yml`](../../../.github/workflows/shared-endpoint-destroy.yml)
(21:00 UTC) so nothing bills overnight.

## Cost

An elastic pool bills while it exists (no serverless auto-pause), so this is a **stand-up-
in-the-morning, destroy-in-the-evening** resource — not something to leave running. Default
`GP_Gen5` 4 vCores is a few £/day; bump `pool_capacity` only if a large room deploys
simultaneously.

## Security note — the password is a giveaway, not a secret

`attendee_password` defaults to `Taylor==Metallica` and is committed on purpose: it is a
disposable credential printed on a slide for an endpoint that is open to the internet and
gone by nightfall. This is the one deliberate exception to CLAUDE.md's "never commit
secrets" rule. The **server admin** password is *not* handed out — it's generated and
surfaced only as a `sensitive` output for presenters.

## ⚠️ Status: validated, not yet applied live

`terraform init` + `terraform validate` pass (so the schema and every attribute — including
the `betr-io/mssql` `login_name` / `roles` and the elastic-pool SKU block — are correct),
and `.terraform.lock.hcl` is committed. What's **not** yet exercised is a real
`terraform apply` against Azure. Confirm on first live run:

1. the `mssql_login` / `mssql_user` resources actually create logins in `master` and
   `db_owner` users in each pooled DB (validate checks the shape, not the runtime T-SQL);
2. the elastic-pool SKU (`GP_Gen5` / `GeneralPurpose` / `Gen5` / capacity) is accepted in
   your region and pooled DBs create with `sku_name = "ElasticPool"`;
3. the firewall is open *before* the login/user resources connect (the `depends_on` is
   there for this, but verify ordering on a cold apply).

**Full pipeline now wired, but no live apply has run yet.** The shared endpoint rides along
in the Azure SQL workflows as its own job: plan-on-PR (`plan-shared-endpoint` job in
[`azure-sql-plan.yml`](../../../.github/workflows/azure-sql-plan.yml)), apply
(`attendee-endpoint` job in [`azure-sql-apply.yml`](../../../.github/workflows/azure-sql-apply.yml),
run with `target: attendee` or `both`), and nightly teardown
([`shared-endpoint-destroy.yml`](../../../.github/workflows/shared-endpoint-destroy.yml),
21:00 UTC + dispatch). What's unproven is a real run against Azure — the checks above are
the things to watch on the first `apply`. For the demo's crisp `+5`, seed the initial 10
first (run the apply once with `target: attendee`, or one local apply against the remote state).

Tracked as **task #19** in [`../../../planning/tasks.md`](../../../planning/tasks.md).
Log anything surprising in [`../../../notes/LEARNINGS.md`](../../../notes/LEARNINGS.md).
