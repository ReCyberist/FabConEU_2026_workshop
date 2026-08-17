# Database as code — SQL projects

Define your database **schema as code** in a SQL project (`.sqlproj`), build it into a **DACPAC**,
and publish that to a live database. It's the state-based, native path for SQL Server / Azure SQL /
Fabric SQL — you describe the *desired* schema and the tooling works out the change.

!!! note "Follow along — or just watch"
    You'll need the **.NET SDK** + **SqlPackage**, and a **target SQL** to publish into. See
    [Prerequisites](../setup/prerequisites.md).

## What you'll build

A **DACPAC** from the canonical football schema (see [The sample database](sample-database.md)) —
9 tables, 3 views, 3 stored procedures, and an idempotent seed — publishable to **both** Azure SQL
and Fabric SQL from the one build.

## The concept

An **SDK-style SQL project** (`Microsoft.Build.Sql`) is a folder of `.sql` files — one object per
file — plus a project file. Building it:

- compiles the schema into a **DACPAC** (a single deployable artifact), and
- runs **T-SQL static code analysis** — the schema is written to pass with **zero findings**
  (SARGable predicates, explicit column lists, set-based, no `MERGE`, no cursors).

```powershell
dotnet build database/sql-projects/FabConFootball.sqlproj -warnaserror
```

`-warnaserror` makes any smell or model warning fail the build — the same check CI runs.

### Publish profiles carry options, not secrets

Publishing is done by **SqlPackage** with a **publish profile** — an XML file that holds the deploy
*options* but **no connection string**. You pass the target server, database, and an Entra token on
the command line, so nothing secret is committed. The safe defaults we ship:

- `BlockOnPossibleDataLoss=True` — refuse a deploy that would drop data (the star of
  [CI/CD part 3](../cicd/ship-database-changes.md));
- `DropObjectsNotInSource=False` — don't wipe objects attendees created;
- `CreateNewDatabase=False` — the infrastructure provisions the database; the DACPAC only shapes it.

## Azure SQL / Fabric SQL

The **same DACPAC** deploys to both — only the publish profile (and the server) changes.

=== "Azure SQL"
    ```powershell
    sqlpackage /Action:Publish `
      /SourceFile:bin/Release/FabConFootball.dacpac `
      /Profile:PublishProfiles/AzureSql.publish.xml `
      /TargetServerName:<server>.database.windows.net `
      /TargetDatabaseName:<db> /AccessToken:$token
    ```

=== "Fabric SQL"
    Same command with the `FabricSql.publish.xml` profile (which adds `AllowIncompatiblePlatform`
    + `ExcludeObjectTypes=Logins;Users`) and a `…database.fabric.microsoft.com,1433` server. Fabric
    SQL surface-area caveats:
    [`notes/fabric-sql-notes.md`](https://github.com/JessAndRob/FabConEU_2026_workshop/blob/main/notes/fabric-sql-notes.md).

## The code

The project — schema, seed, and both publish profiles — is in
[`database/sql-projects`](https://github.com/JessAndRob/FabConEU_2026_workshop/tree/main/database/sql-projects).
The schema itself is walked through on [The sample database](sample-database.md).

## Checkpoint

`dotnet build` produces `FabConFootball.dacpac`; SqlPackage publishes all 9 tables, 3 views, 3
procedures, and the post-deploy seed into your target — **passwordless**, with an Entra token.

## Gotchas

- **Pin the .NET SDK** (`global.json`) or your machine / CI may grab a newer SDK the preview
  `Microsoft.Build.Sql` can't build under — local and CI must resolve the same one.
- **Profiles hold options, no secrets** — target + token go on the command line, so the profile is
  safe to commit.
- **`BlockOnPossibleDataLoss=True` is on by default** — a change that would lose data fails loudly
  instead of silently dropping it.

## What's next

Next: [CI/CD part 1 — build & validate](../cicd/build-validate.md).
