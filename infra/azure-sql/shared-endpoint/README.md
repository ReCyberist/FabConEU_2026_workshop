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
  shared password** (`F@bc0n2026!` by default), each mapped to a `db_owner` **user in its
  own database only**. So everyone gets `db_owner` on their sandbox and cannot touch anyone
  else's.

```
sql-fabcon26-shared-weu-xxxxxx.database.windows.net
├── elastic pool  ep-fabcon26-shared-weu   (4 vCores, shared)
├── sqldb-attendee01   ← login attendee01 (db_owner)
├── sqldb-attendee02   ← login attendee02 (db_owner)
└── …                                       password: F@bc0n2026!
```

## Why it differs from the taught module

| | Taught module (`../terraform`) | This shared endpoint |
|---|---|---|
| Auth | Entra-only, passwordless | **SQL logins** (can't hand a room Entra identities) |
| Shape | server → 1 database | server → **pool → N databases** |
| State | remote azurerm backend (D5) | **local** (throwaway, one-shot) |
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

From the repo root:

```powershell
cd infra/azure-sql/shared-endpoint
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
Server:   sql-fabcon26-shared-weu-xxxxxx.database.windows.net
Database: sqldb-attendee07
Login:    attendee07
Password: F@bc0n2026!
```

…and publishes the sample DACPAC into it exactly like the taught path:

```powershell
sqlpackage /Action:Publish `
  /SourceFile:FabConFootball.dacpac `
  /TargetServerName:"sql-fabcon26-shared-weu-xxxxxx.database.windows.net" `
  /TargetDatabaseName:"sqldb-attendee07" `
  /TargetUser:"attendee07" `
  /TargetPassword:"F@bc0n2026!"
```

## Tear it down (do this the same day)

```powershell
terraform destroy
```

State is local, so keep `terraform.tfstate` with you; if you lose it, delete by resource
group instead — everything is prefixed for exactly this:

```powershell
az group delete --name rg-fabcon26-shared-weu --yes --no-wait
```

## Cost

An elastic pool bills while it exists (no serverless auto-pause), so this is a **stand-up-
in-the-morning, destroy-in-the-evening** resource — not something to leave running. Default
`GP_Gen5` 4 vCores is a few £/day; bump `pool_capacity` only if a large room deploys
simultaneously.

## Security note — the password is a giveaway, not a secret

`attendee_password` defaults to `F@bc0n2026!` and is committed on purpose: it is a
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

Tracked as **task #19** in [`../../../planning/tasks.md`](../../../planning/tasks.md).
Log anything surprising in [`../../../notes/LEARNINGS.md`](../../../notes/LEARNINGS.md).
