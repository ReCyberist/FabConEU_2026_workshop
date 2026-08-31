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
- **Part 2, after lunch**: publish the baseline DACPAC as-is, then show one safe additive change,
  one destructive trap, and one safe way to retire the same column.

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

    If you are following along on the shared attendee endpoint, skip this step.

2. Set the target server, database, and publish profile.

    ```powershell
    $server  = "<your-server-name>"
    $db      = "<your-database-name>"
    $profile = "PublishProfiles/AzureSql.publish.xml"
    ```

    If you are using the workshop shared attendee endpoint, set your values like this:

    ```powershell
    $attendee = "07"   # your attendee number from the workshop handout
    $server   = "<shared-server-fqdn>"
    $db       = "sqldb-attendee$attendee"
    $profile  = "PublishProfiles/AzureSql.publish.xml"
    ```

    The workshop pattern is one database per attendee:
    - Login: `attendeeNN`
    - Database: `sqldb-attendeeNN`

    Use your own `NN` value from the handout so you only change your assigned database.

    !!! note "Attendee follow-along uses SQL authentication"
        The shared attendee databases use SQL login/password, not Entra token auth.

        Set these values from your handout:

        ```powershell
        $login    = "attendee$attendee"
        $password = "<shared-attendee-password>"
        ```

        In all `sqlpackage` commands below, replace:
        - `/AccessToken:$token`
        with:
        - `/TargetUser:$login /TargetPassword:$password`

        Create a credential once:

        ```powershell
        $securePassword = ConvertTo-SecureString $password -AsPlainText -Force
        $sqlCredential  = [System.Management.Automation.PSCredential]::new($login, $securePassword)
        ```

        In all `Invoke-DbaQuery` commands below, replace:
        - `AccessToken = $token`
        with:
        - `SqlCredential = $sqlCredential`

    For Fabric, keep the same flow but change the values to your Fabric server and
    `PublishProfiles/FabricSql.publish.xml`.

### Increment 0 — Publish baseline as-is

3. Generate a deploy report for the current DACPAC before adding any increment files.

    === "Presenter path (Entra token)"

        ```powershell
        sqlpackage /Action:DeployReport `
            /SourceFile:"bin/Release/FabConFootball.dacpac" `
            /Profile:$profile `
            /TargetServerName:$server /TargetDatabaseName:$db /AccessToken:$token `
            /OutputPath:"deploy-report-increment-0.xml"
        ```

    === "Attendee path (SQL login)"

        ```powershell
        sqlpackage /Action:DeployReport `
            /SourceFile:"bin/Release/FabConFootball.dacpac" `
            /Profile:$profile `
            /TargetServerName:$server /TargetDatabaseName:$db `
            /TargetUser:$login /TargetPassword:$password `
            /OutputPath:"deploy-report-increment-0.xml"
        ```

    1. Open the report XML and format it in VS Code.

        ```powershell
        code deploy-report-increment-0.xml
        ```

        In VS Code, Open the Command Palette, and run **Format Document**.

    This report is your baseline. On an empty or new attendee database, it shows object creation.
    On an already-initialised attendee database, it should show little or no drift.

    !!! info "Demo testing timing for this step"
        Example output from a shared attendee database run:

        ```text
        Generating report for database 'sqldb-attendee07' on server 'sql-fabcon26-shared-uks-dqecvi.database.windows.net'.
        Successfully generated report to file C:\GitHub\FabConEU_2026_workshop\database\sql-projects\deploy-report-increment-0.xml.
        Time elapsed 0:02:07.54
        ```

    !!! warning "If `sqlpackage` is not recognized"
        Install SqlPackage as a global .NET tool, then reopen your terminal:

        ```powershell
        dotnet tool install -g microsoft.sqlpackage
        ```

        If it is already installed, ensure the global tools path is available in this session:

        ```powershell
        $env:PATH = "$env:PATH;$HOME\\.dotnet\\tools"
        sqlpackage /version
        ```

        If `sqlpackage /version` prints a version number, continue with the next step.

4. Publish the DACPAC as-is to establish the known starting point.

    === "Presenter path (Entra token)"

        ```powershell
        sqlpackage /Action:Publish `
            /SourceFile:"bin/Release/FabConFootball.dacpac" `
            /Profile:$profile `
            /TargetServerName:$server /TargetDatabaseName:$db /AccessToken:$token
        ```

    === "Attendee path (SQL login)"

        ```powershell
        sqlpackage /Action:Publish `
            /SourceFile:"bin/Release/FabConFootball.dacpac" `
            /Profile:$profile `
            /TargetServerName:$server /TargetDatabaseName:$db `
            /TargetUser:$login /TargetPassword:$password
        ```

    The publish succeeds and sets the database to the baseline schema and seed state.

    !!! info "Demo testing timing for this step"
        Example output from a shared attendee database run:

        ```text
        Publishing to database 'sqldb-attendee07' on server 'sql-fabcon26-shared-uks-dqecvi.database.windows.net'.
        Initializing deployment (Start)
        Initializing deployment (Complete)
        Analyzing deployment plan (Start)
        Analyzing deployment plan (Complete)
        Updating database (Start)
        Creating Schema [football]...
        Creating Table [football].[Stadium]...
        ...
        Update complete.
        Updating database (Complete)
        Successfully published database.
        Time elapsed 0:02:02.33
        ```

5. Verify that baseline data exists before the later destructive-trap demo.

    === "Presenter path (Entra token)"

        ```powershell
        $queryParams = @{
            SqlInstance = $server
            Database    = $db
            AccessToken = $token
            Query       = "SELECT TOP (5) PlayerId, FirstName, LastName, ShirtNumber FROM football.Player WHERE ShirtNumber IS NOT NULL"
        }

        Invoke-DbaQuery @queryParams
        ```

    === "Attendee path (SQL login)"

        ```powershell
        $queryParams = @{
            SqlInstance   = $server
            Database      = $db
            SqlCredential = $sqlCredential
            Query         = "SELECT TOP (5) PlayerId, FirstName, LastName, ShirtNumber FROM football.Player WHERE ShirtNumber IS NOT NULL"
        }

        Invoke-DbaQuery @queryParams
        ```

    The query returns rows with real `ShirtNumber` values.

### Increment 1 — Add a view safely

6. Copy the additive view into the project.

    ```powershell
    Copy-Item ..\demo\ship-changes\increment-1_vw_SquadAges.sql .\Views\vw_SquadAges.sql
    ```

    The project now contains `Views\vw_SquadAges.sql`.

7. Rebuild the DACPAC.

    ```powershell
    dotnet build FabConFootball.sqlproj --configuration Release -warnaserror
    ```

    The build succeeds with the new view included.

    !!! info "Demo testing timing for this step"
        Example output:

        ```text
        No problems have been detected.
        The results are saved in C:\GitHub\FabConEU_2026_workshop\database\sql-projects\bin\Release\FabConFootball.StaticCodeAnalysis.Results.xml.
        FabConFootball -> C:\GitHub\FabConEU_2026_workshop\database\sql-projects\bin\Release\FabConFootball.dacpac

        Build succeeded.
            0 Warning(s)
            0 Error(s)

        Time Elapsed 00:00:12.53
        ```

8. Generate the deploy report before you publish.

    === "Presenter path (Entra token)"

        ```powershell
        sqlpackage /Action:DeployReport `
            /SourceFile:"bin/Release/FabConFootball.dacpac" `
            /Profile:$profile `
            /TargetServerName:$server /TargetDatabaseName:$db /AccessToken:$token `
            /OutputPath:"deploy-report.xml"
        ```

    === "Attendee path (SQL login)"

        ```powershell
        sqlpackage /Action:DeployReport `
            /SourceFile:"bin/Release/FabConFootball.dacpac" `
            /Profile:$profile `
            /TargetServerName:$server /TargetDatabaseName:$db `
            /TargetUser:$login /TargetPassword:$password `
            /OutputPath:"deploy-report.xml"
        ```

    The report shows one view to create and no data-loss alert (note the empty `<Alerts />` node.). 
    There maybe some check constraints that are recreated.

    !!! info "Demo testing timing for this step"
        Example output from a shared attendee database run:

        ```text
        Generating report for database 'sqldb-attendee07' on server 'sql-fabcon26-shared-uks-dqecvi.database.windows.net'.
        Successfully generated report to file C:\GitHub\FabConEU_2026_workshop\database\sql-projects\deploy-report-increment-0.xml.
        Time elapsed 0:02:07.84
        ```

9. Publish the safe change.

    === "Presenter path (Entra token)"

        ```powershell
        sqlpackage /Action:Publish `
            /SourceFile:"bin/Release/FabConFootball.dacpac" `
            /Profile:$profile `
            /TargetServerName:$server /TargetDatabaseName:$db /AccessToken:$token
        ```

    === "Attendee path (SQL login)"

        ```powershell
        sqlpackage /Action:Publish `
            /SourceFile:"bin/Release/FabConFootball.dacpac" `
            /Profile:$profile `
            /TargetServerName:$server /TargetDatabaseName:$db `
            /TargetUser:$login /TargetPassword:$password
        ```

    The publish succeeds and the new view is deployed. You can see it in SSMS.

    !!! info "Demo testing timing for this step"
        Example output from a shared attendee database run:

        ```text
        Publishing to database 'sqldb-attendee07' on server 'sql-fabcon26-shared-uks-dqecvi.database.windows.net'.
        Initializing deployment (Start)
        Initializing deployment (Complete)
        Analyzing deployment plan (Start)
        Analyzing deployment plan (Complete)
        Updating database (Start)
        ...
        Creating View [football].[vw_SquadAges]...
        Checking existing data against newly created constraints
        Update complete.
        Updating database (Complete)
        Successfully published database.
        Time elapsed 0:01:59.97
        ```

### Increment 2 — The destructive trap

10. Prove that `ShirtNumber` currently holds real data.

    === "Presenter path (Entra token)"

        ```powershell
        $queryParams = @{
            SqlInstance = $server
            Database    = $db
            AccessToken = $token
            Query       = "SELECT TOP (5) PlayerId, FirstName, LastName, ShirtNumber FROM football.Player WHERE ShirtNumber IS NOT NULL"
        }

        Invoke-DbaQuery @queryParams
        ```

    === "Attendee path (SQL login)"

        ```powershell
        $queryParams = @{
            SqlInstance   = $server
            Database      = $db
            SqlCredential = $sqlCredential
            Query         = "SELECT TOP (5) PlayerId, FirstName, LastName, ShirtNumber FROM football.Player WHERE ShirtNumber IS NOT NULL"
        }

        Invoke-DbaQuery @queryParams
        ```

    The query returns rows with real `ShirtNumber` values.

11. Add the harmless view that hides the destructive change.

    ```powershell
    Copy-Item ..\demo\ship-changes\increment-2_vw_TeamRosterSizes.sql .\Views\vw_TeamRosterSizes.sql
    ```

    The project now contains `Views\vw_TeamRosterSizes.sql`.

12. Remove `ShirtNumber` from the project definition and the seed.

    ```powershell
    Copy-Item ..\demo\ship-changes\increment-2_Player.sql .\Tables\Player.sql -Force
    Copy-Item ..\demo\ship-changes\increment-2_Seed.sql .\Scripts\PostDeployment\Seed.sql -Force
    git --no-pager diff -- .\Tables\Player.sql .\Scripts\PostDeployment\Seed.sql
    Select-String -Path .\Tables\Player.sql,.\Scripts\PostDeployment\Seed.sql -Pattern "ShirtNumber"
    ```

    The copy-in files remove `ShirtNumber` from both `Tables\Player.sql` and
    `Scripts\PostDeployment\Seed.sql`. The diff output shows exactly what changed.
    The `Select-String` command should return no matches.

13. Rebuild the DACPAC and generate a fresh deploy report.

    ```powershell
    dotnet build FabConFootball.sqlproj --configuration Release -warnaserror
    ```

    !!! info "Demo testing timing for this step"
        Example build output:

        ```text
        No problems have been detected.
        The results are saved in C:\GitHub\FabConEU_2026_workshop\database\sql-projects\bin\Release\FabConFootball.StaticCodeAnalysis.Results.xml.
        FabConFootball -> C:\GitHub\FabConEU_2026_workshop\database\sql-projects\bin\Release\FabConFootball.dacpac

        Build succeeded.
            0 Warning(s)
            0 Error(s)

        Time Elapsed 00:00:19.99
        ```

    === "Presenter path (Entra token)"

        ```powershell
        sqlpackage /Action:DeployReport `
            /SourceFile:"bin/Release/FabConFootball.dacpac" `
            /Profile:$profile `
            /TargetServerName:$server /TargetDatabaseName:$db /AccessToken:$token `
            /OutputPath:"deploy-report.xml"
        ```

    === "Attendee path (SQL login)"

        ```powershell
        sqlpackage /Action:DeployReport `
            /SourceFile:"bin/Release/FabConFootball.dacpac" `
            /Profile:$profile `
            /TargetServerName:$server /TargetDatabaseName:$db `
            /TargetUser:$login /TargetPassword:$password `
            /OutputPath:"deploy-report.xml"
        ```

    The build succeeds, and the deploy report flags a possible data-loss operation.

    !!! info "Demo testing output for this step"
        Example deploy-report output from a shared attendee database run:

        ```text
        Generating report for database 'sqldb-attendee07' on server 'sql-fabcon26-shared-uks-dqecvi.database.windows.net'.
        *** The column [football].[Player].[ShirtNumber] is being dropped, data loss could occur.
        Successfully generated report to file C:\GitHub\FabConEU_2026_workshop\database\sql-projects\deploy-report.xml.
        Time elapsed 0:01:57.74
        ```

14. Show the anti-pattern by forcing the publish through.

    === "Presenter path (Entra token)"

        ```powershell
        sqlpackage /Action:Publish `
            /SourceFile:"bin/Release/FabConFootball.dacpac" `
            /Profile:$profile `
            /TargetServerName:$server /TargetDatabaseName:$db /AccessToken:$token `
            /p:BlockOnPossibleDataLoss=false
        ```

    === "Attendee path (SQL login)"

        ```powershell
        sqlpackage /Action:Publish `
            /SourceFile:"bin/Release/FabConFootball.dacpac" `
            /Profile:$profile `
            /TargetServerName:$server /TargetDatabaseName:$db `
            /TargetUser:$login /TargetPassword:$password `
            /p:BlockOnPossibleDataLoss=false
        ```

    The publish succeeds, even though it removes a populated column.

15. Prove the damage, then show the guardrail path.

    === "Presenter path (Entra token)"

        ```powershell
        $queryParams = @{
            SqlInstance = $server
            Database    = $db
            AccessToken = $token
            Query       = "SELECT TOP (5) PlayerId, FirstName, LastName, ShirtNumber FROM football.Player WHERE ShirtNumber IS NOT NULL"
        }

        Invoke-DbaQuery @queryParams

        sqlpackage /Action:Publish `
            /SourceFile:"bin/Release/FabConFootball.dacpac" `
            /Profile:$profile `
            /TargetServerName:$server /TargetDatabaseName:$db /AccessToken:$token
        ```

    === "Attendee path (SQL login)"

        ```powershell
        $queryParams = @{
            SqlInstance   = $server
            Database      = $db
            SqlCredential = $sqlCredential
            Query         = "SELECT TOP (5) PlayerId, FirstName, LastName, ShirtNumber FROM football.Player WHERE ShirtNumber IS NOT NULL"
        }

        Invoke-DbaQuery @queryParams

        sqlpackage /Action:Publish `
            /SourceFile:"bin/Release/FabConFootball.dacpac" `
            /Profile:$profile `
            /TargetServerName:$server /TargetDatabaseName:$db `
            /TargetUser:$login /TargetPassword:$password
        ```

    The first command proves the YOLO path lost the column or its data. The second command shows
    the shipped profile blocks the same change when `BlockOnPossibleDataLoss=True` is left alone.

!!! info "Stop here for the afternoon break"
    The agenda break is **15:15–15:45**. Increment 3 starts after that break.

### Increment 3 — Retire it safely

Increment 3 keeps Increment 2's goal — retire `ShirtNumber` — but preserves the data. There are
two safe patterns. **Option A** is the general one: a data-preserving migration you can adapt to
any change. **Option B** is the clean special case when the change is only a rename. Both are
shipped in `database/demo/ship-changes` and applied the same copy-in way as the earlier
increments, and both end at the same schema, where `Player.SquadNumber` replaces
`Player.ShirtNumber`.

The order matters. A publish runs in three phases: the **pre-deployment script**, then the
**schema change**, then the **post-deployment script**. The schema change is what adds
`SquadNumber` and drops `ShirtNumber`, so the new column does not exist during the pre-deployment
phase. That is why the copy cannot be a single statement, and why Option A splits the work either
side of the schema change.

!!! note "Two options, one end state"
    Option A works for any data-preserving change; Option B is the tidy choice when the change is
    purely a rename. You do not need both — pick the one that fits your change. The deploy reports
    below are what `sqlpackage` produces for each.

16. Confirm the target still holds `ShirtNumber` data.

    === "Presenter path (Entra token)"

        ```powershell
        $queryParams = @{
            SqlInstance = $server
            Database    = $db
            AccessToken = $token
            Query       = "SELECT TOP (5) PlayerId, LastName, ShirtNumber FROM football.Player WHERE ShirtNumber IS NOT NULL"
        }

        Invoke-DbaQuery @queryParams
        ```

    === "Attendee path (SQL login)"

        ```powershell
        $queryParams = @{
            SqlInstance   = $server
            Database      = $db
            SqlCredential = $sqlCredential
            Query         = "SELECT TOP (5) PlayerId, LastName, ShirtNumber FROM football.Player WHERE ShirtNumber IS NOT NULL"
        }

        Invoke-DbaQuery @queryParams
        ```

    The query returns rows with `ShirtNumber` values. Run the Increment 2 forced publish (the
    `/p:BlockOnPossibleDataLoss=false` path) against a throwaway database, not this one, so this
    target still has the data to preserve.

#### Option A — a data-preserving migration

17. Copy in the Option A files.

    ```powershell
    New-Item -ItemType Directory -Path .\Scripts\PreDeployment -Force | Out-Null
    Copy-Item ..\demo\ship-changes\increment-3_Player.sql              .\Tables\Player.sql -Force
    Copy-Item ..\demo\ship-changes\increment-3_Migrate-ShirtNumber.sql .\Scripts\PreDeployment\Migrate-ShirtNumber.sql -Force
    Copy-Item ..\demo\ship-changes\increment-3_Seed.sql                .\Scripts\PostDeployment\Seed.sql -Force
    Copy-Item ..\demo\ship-changes\increment-3A_FabConFootball.sqlproj .\FabConFootball.sqlproj -Force
    ```

    The pre-deployment script copies `ShirtNumber` into a staging table before the drop; the
    post-deployment step lands those values in `SquadNumber` after the schema change creates it.

18. Build the DACPAC.

    ```powershell
    dotnet build FabConFootball.sqlproj --configuration Release -warnaserror
    ```

    The build succeeds with zero warnings and zero analysis findings:

    ```text
    Build succeeded.
        0 Warning(s)
        0 Error(s)
    ```

19. Generate the deploy report.

    === "Presenter path (Entra token)"

        ```powershell
        sqlpackage /Action:DeployReport `
            /SourceFile:"bin/Release/FabConFootball.dacpac" `
            /Profile:$profile `
            /TargetServerName:$server /TargetDatabaseName:$db /AccessToken:$token `
            /OutputPath:"deploy-report.xml"
        ```

    === "Attendee path (SQL login)"

        ```powershell
        sqlpackage /Action:DeployReport `
            /SourceFile:"bin/Release/FabConFootball.dacpac" `
            /Profile:$profile `
            /TargetServerName:$server /TargetDatabaseName:$db `
            /TargetUser:$login /TargetPassword:$password `
            /OutputPath:"deploy-report.xml"
        ```

    The report still flags the column drop. Option A preserves the data, not the column, so the
    report contains a data-loss alert:

    ```xml
    <Alert Name="DataIssue"><Issue Value="The column [football].[Player].[ShirtNumber] is being dropped, data loss could occur." Id="1" /></Alert>
    ```

20. Publish, explicitly allowing the drop.

    === "Presenter path (Entra token)"

        ```powershell
        sqlpackage /Action:Publish `
            /SourceFile:"bin/Release/FabConFootball.dacpac" `
            /Profile:$profile `
            /TargetServerName:$server /TargetDatabaseName:$db /AccessToken:$token `
            /p:BlockOnPossibleDataLoss=false
        ```

    === "Attendee path (SQL login)"

        ```powershell
        sqlpackage /Action:Publish `
            /SourceFile:"bin/Release/FabConFootball.dacpac" `
            /Profile:$profile `
            /TargetServerName:$server /TargetDatabaseName:$db `
            /TargetUser:$login /TargetPassword:$password `
            /p:BlockOnPossibleDataLoss=false
        ```

    The publish succeeds. This is the same flag as the Increment 2 forced publish, used
    deliberately here: the migration already moved the data to safety before the drop.

21. Confirm the data survived in the new column.

    === "Presenter path (Entra token)"

        ```powershell
        $queryParams = @{
            SqlInstance = $server
            Database    = $db
            AccessToken = $token
            Query       = "SELECT TOP (5) PlayerId, LastName, SquadNumber FROM football.Player WHERE SquadNumber IS NOT NULL"
        }

        Invoke-DbaQuery @queryParams
        ```

    === "Attendee path (SQL login)"

        ```powershell
        $queryParams = @{
            SqlInstance   = $server
            Database      = $db
            SqlCredential = $sqlCredential
            Query         = "SELECT TOP (5) PlayerId, LastName, SquadNumber FROM football.Player WHERE SquadNumber IS NOT NULL"
        }

        Invoke-DbaQuery @queryParams
        ```

    `SquadNumber` holds the old shirt numbers. The data survived the drop.

#### Option B — model it as a rename

Option B is the cleaner path when the change is only a rename. The project's refactorlog records
the intent, so the publish emits `sp_rename` instead of drop-and-add: no data-loss alert, and no
override needed. Demonstrate it from a target that still has `ShirtNumber` (re-establish the
baseline on a fresh database if Option A already ran here).

22. Copy in the Option B files.

    ```powershell
    Copy-Item ..\demo\ship-changes\increment-3_Player.sql                 .\Tables\Player.sql -Force
    Copy-Item ..\demo\ship-changes\increment-3_Seed.sql                   .\Scripts\PostDeployment\Seed.sql -Force
    Copy-Item ..\demo\ship-changes\increment-3_FabConFootball.refactorlog .\FabConFootball.refactorlog -Force
    Copy-Item ..\demo\ship-changes\increment-3B_FabConFootball.sqlproj    .\FabConFootball.sqlproj -Force
    ```

    There is no pre-deployment migration this time. The refactorlog carries the rename intent.

23. Build the DACPAC.

    ```powershell
    dotnet build FabConFootball.sqlproj --configuration Release -warnaserror
    ```

    The build succeeds with zero warnings and zero analysis findings.

24. Generate the deploy report.

    Run the same `sqlpackage /Action:DeployReport` command as in Option A above. This time the
    report is clean, because the change is a rename, not a drop:

    ```xml
    <Alerts />
    ```

25. Publish under the shipped profile.

    Run the same `sqlpackage /Action:Publish` command as in Option A above, but without
    `/p:BlockOnPossibleDataLoss=false`. The shipped profile keeps `BlockOnPossibleDataLoss=True`,
    and the publish still succeeds because a rename loses no data. The generated script contains
    `EXECUTE sp_rename ... 'COLUMN'`.

26. Confirm the data is in the renamed column.

    Run the same `SquadNumber` query as in Option A above. The values are present because the
    column was renamed in place, with no copy and no drop.

#### Gate the destructive deploy

27. Require a human approval before the deploy lands.

    ```yaml
    jobs:
      publish:
        environment: test
    ```

    Protect that environment with required reviewers so a human reads the deploy report before
    approving. The publish stays automated; the approval is the only manual step, and it is still
    defined as code.

    !!! note "Plan and identity notes"
        GitHub required-reviewer and wait-timer rules for private repositories require Team or
        Enterprise plans (public repositories are different).

        Adding `environment:` changes the OIDC subject to
        `repo:<org>/<repo>:environment:<name>`. Add a matching federated credential for the deploy
        principal in addition to any branch-based subject you already use.

Destructive changes can still ship as code, with a data-preserving approach — a migration
(Option A) or a rename (Option B) — and a human approval gate. Never a blind auto-apply.

## Checkpoint

By lunch, the DACPAC exists and builds cleanly. By the end of the afternoon, you have published
the baseline, shown one safe additive change, one destructive trap, and one safe way to retire the
same column with a human gate.

## Gotchas

- `dotnet build -warnaserror` runs T-SQL static analysis and must stay at zero findings. Note that
  the post-deployment seed is *not* checked against the schema at build time, so a seed that still
  mentions `ShirtNumber` after you remove the column from `Player.sql` still builds — that mismatch
  fails later, at publish time, when the seed runs against the database. Update the seed together
  with the table.
- `DeployReport` writes with `/OutputPath`. That is the database-plan artifact you review before
  publishing.
- The Fabric path uses the same DACPAC and almost the same commands, but it needs the
  `FabricSql.publish.xml` profile and a Fabric SQL server name.
- Increment 2 is only convincing if the target really contains seeded data first.

## What's next

Next: [CI/CD part 1 — build & validate](../cicd/build-validate.md).
