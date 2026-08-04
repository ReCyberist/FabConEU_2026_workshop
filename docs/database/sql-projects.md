<!-- DRAFT: skeleton only. Prose to be fleshed out (task #22, Phase 3). -->

# Database as code — SQL projects

<!-- INTRO: define the schema as a .sqlproj, build a DACPAC, publish it — state-based DB as code. -->

!!! note "Follow along — or just watch"
    Needs the .NET SDK + SqlPackage, and a target SQL to publish into. See [Prerequisites](../setup/prerequisites.md).

## What you'll build

<!-- A DACPAC from the canonical football schema (see The sample database), publishable to both
     Azure SQL and Fabric SQL. -->

## The concept

<!-- SQL projects (SDK-style Microsoft.Build.Sql); DACPAC; publish profiles carry options not
     secrets; T-SQL static analysis keeps it clean. -->

## Azure SQL / Fabric SQL

=== "Azure SQL"
    <!-- AzureSql.publish.xml; SqlPackage /Action:Publish with an Entra /AccessToken. -->

=== "Fabric SQL"
    <!-- FabricSql.publish.xml (AllowIncompatiblePlatform + ExcludeObjectTypes=Logins;Users). -->

## The code

The project is in
[`database/sql-projects`](https://github.com/JessAndRob/FabConEU_2026_workshop/tree/main/database/sql-projects)
(schema, seed, and [publish profiles](https://github.com/JessAndRob/FabConEU_2026_workshop/tree/main/database/sql-projects/PublishProfiles)).
The schema itself is described on [The sample database](sample-database.md).

## Checkpoint

<!-- dotnet build produces the DACPAC; SqlPackage publishes schema + seed, passwordless. -->

## Gotchas

<!-- Pin the .NET SDK (global.json) or CI grabs the wrong one; profiles hold options, no secrets;
     BlockOnPossibleDataLoss=True by default. -->

## What's next

Next: [CI/CD part 1 — build & validate](../cicd/build-validate.md).
