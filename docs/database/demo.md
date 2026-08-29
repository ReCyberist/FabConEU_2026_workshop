# Database demo

This is the database half of the day in the order we actually teach it. **Part 1** stops before
lunch with a DACPAC built and ready. **Part 2** resumes after lunch and uses that DACPAC to show
how safe and unsafe schema changes behave.

!!! note "Follow along — or just watch"
    You need the **.NET SDK**, **SqlPackage**, and a reachable **target SQL database**. See
    [Prerequisites](../setup/prerequisites.md), [The sample database](sample-database.md), and
    [Database as code — SQL projects](sql-projects.md).

## What you'll do

- **Part 1, before lunch**: build the football SQL project into a DACPAC and confirm the artifact exists.
- **Part 2, after lunch**: use that DACPAC to show one safe additive change, one destructive trap,
  and one safe way to retire the same column.

## The concept

- A **SQL project** is the schema in source control: one object per file, plus a project file.
- `dotnet build` produces the **DACPAC** and runs **T-SQL static analysis**.
- `sqlpackage /Action:DeployReport` is the database's version of `terraform plan`: it tells you
  what the deploy would do before it does it.

## Part 1 — Before Lunch

This is the **Morning 3** slot in the agenda: **12:15–12:45**, right before lunch. The goal here
is to build the artifact, not deploy it.

### Run it

1. In the repository root folder, move into the SQL project folder.

    ```powershell
    cd database/sql-projects
    Get-Location
    ```

    The path ends with `database\sql-projects`.

2. Build the SQL project.

    ```powershell
    dotnet build FabConFootball.sqlproj --configuration Release -warnaserror
    ```
    
    !!! note "Command parameter guide:"
        - `FabConFootball.sqlproj`: the SQL project file to build.
        - `--configuration Release`: build using the Release configuration.
        - `-warnaserror`: treat all build warnings as errors so the build fails if any warning appears.

    The build finishes successfully and produces a DACPAC.

    !!! info "Demo testing output for this step"
        ```text
        Determining projects to restore...
        Restored C:\GitHub\FabConEU_2026_workshop\database\sql-projects\FabConFootball.sqlproj (in 1.79 sec).
        Creating a model to represent the project...
        Loading project references...
        Loading project files...
        Building the project model and resolving object interdependencies...
        Validating the project model...
        Writing model to C:\GitHub\FabConEU_2026_workshop\database\sql-projects\obj\Release\Model.xml...
        FabConFootball -> C:\GitHub\FabConEU_2026_workshop\database\sql-projects\bin\Release\FabConFootball.dll
        Creating a model to represent the project...
        Loading project references...
        Loading project files...
        Building the project model and resolving object interdependencies...
        Validating the project model...
        No problems have been detected.
        The results are saved in C:\GitHub\FabConEU_2026_workshop\database\sql-projects\bin\Release\FabConFootball.StaticCodeAnalysis.Results.xml.
        FabConFootball -> C:\GitHub\FabConEU_2026_workshop\database\sql-projects\bin\Release\FabConFootball.dacpac

        Build succeeded.
            0 Warning(s)
            0 Error(s)

        Time Elapsed 00:00:31.64
        ```

    !!! warning "If build says a compatible .NET SDK was not found"
        This repository pins the SDK in `global.json` to **8.x**. If you only have **9.x** installed,
        `dotnet build` cannot run here.

        Install .NET 8 SDK, then reopen the terminal and verify:

        ```powershell
        winget install --exact --id Microsoft.DotNet.SDK.8
        dotnet --list-sdks
        ```

        The list must include at least one `8.0.xxx` entry. Then run the build again.

        If you cannot install 8.x on your machine, you can temporarily change `global.json` to your
        installed 9.x SDK for local testing. Do not commit that change; CI workflows use .NET 8.x.

3. Confirm that the DACPAC was created.

    ```powershell
    Get-Item .\bin\Release\FabConFootball.dacpac
    ```

    PowerShell prints the DACPAC path and file details.

4. Open the sample-database page or the project files and point out what just went into the build.

    In the repository Explorer, browse to these folders under `database/sql-projects`:
    `Tables`, `Views`, and `Programmability`.

    You can now show that the schema is just code in git: tables, views, procedures, and the
    post-deploy seed.

!!! info "Stop here for lunch"
    This is where the agenda pauses. By **12:45** the DACPAC is built; the live publish and change
    story start **after lunch**.

## Part 2 — After Lunch

This is the **Afternoon 1** and **Afternoon 2** story. Increment 1 and increment 2 happen before
the **15:15 break**. Increment 3 resumes after that break.

### Set up the target

1. Stay in `database/sql-projects` and get an Entra token for SqlPackage.

    ```powershell
    $token = az account get-access-token --resource https://database.windows.net/ --query accessToken -o tsv
    ```

    The command returns an access token string.

2. Set the target server, database, and publish profile.

    ```powershell
    $server  = "<your-server-name>"
    $db      = "<your-database-name>"
    $profile = "PublishProfiles/AzureSql.publish.xml"
    ```

    For Fabric, keep the same flow but change the values to your Fabric server and
    `PublishProfiles/FabricSql.publish.xml`.

### Increment 1 — Add a view safely

3. Copy the additive view into the project.

    ```powershell
    Copy-Item ..\demo\ship-changes\increment-1_vw_SquadAges.sql .\Views\vw_SquadAges.sql
    ```

    The project now contains `Views\vw_SquadAges.sql`.

4. Rebuild the DACPAC.

    ```powershell
    dotnet build FabConFootball.sqlproj --configuration Release -warnaserror
    ```

    The build succeeds with the new view included.

5. Generate the deploy report before you publish.

    ```powershell
    sqlpackage /Action:DeployReport `
        /SourceFile:"bin/Release/FabConFootball.dacpac" `
        /Profile:$profile `
        /TargetServerName:$server /TargetDatabaseName:$db /AccessToken:$token `
        /OutputPath:"deploy-report.xml"
    ```

    The report shows one view to create and no data-loss alert.

6. Publish the safe change.

    ```powershell
    sqlpackage /Action:Publish `
        /SourceFile:"bin/Release/FabConFootball.dacpac" `
        /Profile:$profile `
        /TargetServerName:$server /TargetDatabaseName:$db /AccessToken:$token
    ```

    The publish succeeds and the new view is deployed.

### Increment 2 — The destructive trap

7. Prove that `ShirtNumber` currently holds real data.

    ```powershell
    Invoke-Sqlcmd -ServerInstance $server -Database $db -AccessToken $token -EncryptConnection `
        -Query "SELECT TOP (5) PlayerId, ShirtNumber FROM football.Player WHERE ShirtNumber IS NOT NULL"
    ```

    The query returns rows with real `ShirtNumber` values.

8. Add the harmless view that hides the destructive change.

    ```powershell
    Copy-Item ..\demo\ship-changes\increment-2_vw_TeamRosterSizes.sql .\Views\vw_TeamRosterSizes.sql
    ```

    The project now contains `Views\vw_TeamRosterSizes.sql`.

9. Remove `ShirtNumber` from the project definition and the seed.

    ```powershell
    code .\Tables\Player.sql
    code .\Scripts\PostDeployment\Seed.sql
    ```

    In `Tables\Player.sql`, delete the `ShirtNumber` column. In `Scripts\PostDeployment\Seed.sql`,
    remove `ShirtNumber` from the `INSERT` column list, the `SELECT`, and the `VALUES` tuple names.

10. Rebuild the DACPAC and generate a fresh deploy report.

    ```powershell
    dotnet build FabConFootball.sqlproj --configuration Release -warnaserror

    sqlpackage /Action:DeployReport `
    !!! note "What these parameters mean"
        - `FabConFootball.sqlproj`: the SQL project file to build.
        - `--configuration Release`: build using the Release configuration.
        - `-warnaserror`: treat all build warnings as errors so the build fails if any warning appears.

    The build succeeds, and the deploy report flags a possible data-loss operation.

11. Show the anti-pattern by forcing the publish through.

    ```powershell
    sqlpackage /Action:Publish `
        /SourceFile:"bin/Release/FabConFootball.dacpac" `
        /Profile:$profile `
        /TargetServerName:$server /TargetDatabaseName:$db /AccessToken:$token `
        /p:BlockOnPossibleDataLoss=false
    ```

    The publish succeeds, even though it removes a populated column.

12. Prove the damage, then show the guardrail path.

    ```powershell
    Invoke-Sqlcmd -ServerInstance $server -Database $db -AccessToken $token -EncryptConnection `
        -Query "SELECT TOP (5) PlayerId, ShirtNumber FROM football.Player WHERE ShirtNumber IS NOT NULL"

    sqlpackage /Action:Publish `
        /SourceFile:"bin/Release/FabConFootball.dacpac" `
        /Profile:$profile `
        /TargetServerName:$server /TargetDatabaseName:$db /AccessToken:$token
    ```

    The first command proves the YOLO path lost the column or its data. The second command shows
    the shipped profile blocks the same change when `BlockOnPossibleDataLoss=True` is left alone.

!!! info "Stop here for the afternoon break"
    The agenda break is **15:15–15:45**. Increment 3 starts after that break.

### Increment 3 — Retire it safely

13. Open the safe-retire notes and walk through the two correct patterns.

    ```powershell
    code ..\demo\ship-changes\increment-3_safe-retire.md
    ```

    Show the two options: move the data first with a pre-deploy script, or model the change as a
    rename so SqlPackage emits `sp_rename` instead of drop-and-add.

14. Show the approval-gate pattern that holds the destructive deploy for a human decision.

    ```yaml
    jobs:
      publish:
        environment: test
    ```

    The teaching point is that destructive changes still ship as code, but never as a blind
    auto-apply.

## Checkpoint

By lunch, the DACPAC exists and builds cleanly. By the end of the afternoon, you have shown one
safe additive change, one destructive trap, and one safe way to retire the same column with a
human gate.

## Gotchas

- `dotnet build -warnaserror` is part of the demo, not a nice-to-have. If the seed still mentions
  `ShirtNumber` after you remove the column from `Player.sql`, the build should fail.
- `DeployReport` writes with `/OutputPath`. That is the database-plan artifact you review before
  publishing.
- The Fabric path uses the same DACPAC and almost the same commands, but it needs the
  `FabricSql.publish.xml` profile and a Fabric SQL server name.
- Increment 2 is only convincing if the target really contains seeded data first.

## What's next

Next: [CI/CD part 1 — build & validate](../cicd/build-validate.md).
