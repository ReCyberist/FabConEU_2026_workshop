# SQL Projects — `.sqlproj` / DACPAC (content focus)

The **taught path** for database-as-code, and the **canonical source of the sample
schema**. An SDK-style SQL project (`Microsoft.Build.Sql`) defines the football schema;
the build produces a DACPAC that the pipeline publishes with SqlPackage to **Azure SQL
Database** and **Fabric SQL database**.

## The sample: football, men's *and* women's

A `football` schema modelling both the men's and women's game from one shared set of clubs.

| Object | Purpose |
|--------|---------|
| `Stadium`, `Club`, `Competition`, `Season` | Reference data. A `Club` fields multiple `Team`s. |
| `Team` | One row per club per **category** (Men / Women), linked to the `Competition` it plays in. |
| `Player`, `Referee` | People. |
| `Fixture` | A match; scores are NULL until played. |
| `Goal` | One row per goal (penalties / own goals flagged). |
| `vw_LeagueTable`, `vw_TopScorers`, `vw_UpcomingFixtures` | Views over the above. |
| `usp_GetLeagueTable`, `usp_RecordFixtureResult`, `usp_TransferPlayer` | Stored procedures. |

Seed data lives in `Scripts/PostDeployment/Seed.sql` (idempotent, set-based) and covers
the Premier League + Women's Super League (played fixtures with goals) plus upcoming
El Clásico fixtures.

## Layout

```
sql-projects/
├── FabConFootball.sqlproj          SDK-style project (RunSqlCodeAnalysis enabled)
├── Security/football.sql           CREATE SCHEMA
├── Tables/*.sql                    one object per file
├── Views/*.sql
├── Programmability/*.sql           stored procedures
└── Scripts/PostDeployment/Seed.sql post-deploy seed (excluded from the build model)
```

## Build locally

```powershell
dotnet build database/sql-projects/FabConFootball.sqlproj -warnaserror
```

This compiles the schema to `bin/<config>/FabConFootball.dacpac` **and** runs T-SQL static
code analysis (`RunSqlCodeAnalysis` is on in the project). `-warnaserror` makes any smell
or model warning fail — the same check CI runs (`.github/workflows/ci.yml`).

## Publish (manual authoring only — the pipeline is the source of truth for "deployed")

Two publish profiles live in [`PublishProfiles/`](PublishProfiles/), one per target. They
carry the deploy **options** (safe defaults: block on data loss, don't drop attendee
objects, let the platform own DB-level options) but **no connection string** — supply the
target and Microsoft Entra auth at publish time.

**Azure SQL Database:**

```powershell
sqlpackage /Action:Publish `
  /SourceFile:bin/Release/FabConFootball.dacpac `
  /Profile:PublishProfiles/AzureSql.publish.xml `
  /TargetServerName:fabcon26-sql.database.windows.net `
  /TargetDatabaseName:fabcon26-football `
  /AccessToken:$token
```

**SQL database in Fabric** (server + DB name come from the database's *Settings → Connection
strings* page):

```powershell
sqlpackage /Action:Publish `
  /SourceFile:bin/Release/FabConFootball.dacpac `
  /Profile:PublishProfiles/FabricSql.publish.xml `
  /TargetServerName:"<guid>.database.fabric.microsoft.com,1433" `
  /TargetDatabaseName:"fabcon26-football-<guid>" `
  /AccessToken:$token
```

Fabric SQL surface-area caveats: [`../../notes/fabric-sql-notes.md`](../../notes/fabric-sql-notes.md).

## Keep it clean

The schema is written to pass static code analysis with **zero** findings and no obvious
performance smells (SARGable predicates, explicit column lists, set-based seed, no `MERGE`,
no cursors). Keep it that way — see the code-quality bar in [`../../CLAUDE.md`](../../CLAUDE.md) §4.
