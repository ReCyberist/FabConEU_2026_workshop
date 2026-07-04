# Fabric SQL database — T-SQL surface-area notes

Working notes for keeping the **one canonical schema** deployable to **both Azure SQL
Database and Fabric SQL database**. Grounded in Microsoft Learn (see links). Add to this
list whenever a build/deploy surprises us, and cross-link from
[`LEARNINGS.md`](LEARNINGS.md).

> ⚠️ Two different Fabric SQL surfaces exist — don't confuse them:
> - **SQL database in Fabric** (the transactional OLTP database) — **this is our target.**
>   It's engine-compatible with Azure SQL Database, so standard T-SQL mostly "just works".
> - **Fabric Data Warehouse** (and the SQL analytics endpoint) — a *much* smaller T-SQL
>   surface (no IDENTITY the usual way, no enforced constraints, no triggers, no indexes,
>   etc.). We are **not** targeting this for the sample database.

## What our sample schema deliberately stays inside

The canonical schema (`database/sql-projects`) uses only features supported on **both**
Azure SQL DB and Fabric SQL database:

- `IDENTITY` clustered primary keys — supported (Fabric SQL database, unlike the Warehouse).
- Enforced `FOREIGN KEY`, `UNIQUE`, `CHECK`, `DEFAULT` constraints — supported.
- Non-clustered indexes — supported.
- Views and stored procedures — supported.
- `NVARCHAR`, `DATE`, `DATETIME2`, `TINYINT`, `BIT`, `SMALLINT` — supported.

## Watch-list — things NOT supported on Fabric SQL database

From [Limitations in SQL database in Microsoft Fabric](https://learn.microsoft.com/fabric/database/sql/limitations):

- **No TDE / customer-managed keys / Always Encrypted / ledger / in-memory OLTP tables.**
- **Primary keys can't** be `hierarchyid`, `sql_variant`, or `timestamp` (rowversion).
- **Column names can't contain spaces** or `, ; { } ( ) \n \t =`. (We use PascalCase, no spaces.)
- **No `BACKUP`/`RESTORE`** — automatic system backups only.
- **No CDC** (Change Data Capture). Temporal tables *are* supported on both.
- `BULK INSERT` works via `OPENROWSET` with OneLake as the source (differs from Azure SQL).

## Deployment

- We build a **DACPAC** from the SQL project and publish with **SqlPackage**. SqlPackage
  supports Fabric SQL database targets (connect to `…database.fabric.microsoft.com`,
  Microsoft Entra auth). See
  [SqlPackage for SQL database in Fabric](https://learn.microsoft.com/fabric/database/sql/sqlpackage).
- If a future object trips the Fabric surface area, SqlPackage publish can be told to skip
  unsupported objects — but prefer keeping the canonical schema portable instead.

_Last grounded against Microsoft Learn: 2026-07-04._
