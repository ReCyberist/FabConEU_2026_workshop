<#
    DEMO 03 - Database as code, and shipping changes to it
    ATTENDEE PAGE: docs/database/demo.md
    SLOT:          PART 1  Morning 3   - 12:15-12:45 (build the DACPAC, then lunch)
                   PART 2  Afternoon 1 - 14:00-15:15 (increments 0, 1, 2)
                           Afternoon 2 - 15:45-17:00 (increment 3)
    RUNTIME:       Part 1 ~10 min. Part 2 ~55 min, most of it waiting on sqlpackage.

    THE POINT
    Part 1: the schema is code, and `dotnet build` turns it into one deployable artifact.
    Part 2: `sqlpackage /Action:DeployReport` is the database's `terraform plan`. Additive
    changes sail through. A destructive one is caught -- and increment 2 is the punchline
    of the entire day, so do not rush it.

    THE SHAPE OF PART 2
      Increment 0  publish the baseline, prove ShirtNumber holds real data
      Increment 1  add a view -- clean report, safe publish, invite follow-along
      Increment 2  drop a POPULATED column, bundled with an innocent view
                   2a force it -> the data is silently gone      <- LET THIS LAND
                   2b the guard we ship -> it fails loudly
      Increment 3  retire the same column WITHOUT losing the data, two ways

    !! INCREMENT 2 DESTROYS DATA ON PURPOSE !!
    Run 2a against a THROWAWAY database, not the one you need for increment 3. Increment 3
    needs ShirtNumber present and populated. Re-publishing the baseline over a database
    that has already lost the column will NOT refill it -- the seed only inserts missing
    rows, it does not update existing ones. Ask us how we know.

    BEFORE YOU START
      - .NET 8 SDK (global.json pins it) and sqlpackage on PATH.
      - A target database, and a throwaway one for 2a.
      - dbatools installed, for Invoke-DbaQuery.
      - Increment files live in database/demo/ship-changes/ -- design notes and the
        rationale are in database/demo/ship-changes/README.md and increment-3_safe-retire.md.

    See demo/README.md for how to run one of these (short version: F8, never F5).
#>

#region 00 · Guard rail -- do not remove, do not question
# ---------------------------------------------------------------------------------------
# You pressed F5, didn't you.
#
# This is a DEMO script, not a deployment. Top to bottom it would build a DACPAC, publish
# it to a live database, drop a populated column with the safety explicitly disabled, and
# then do it again a different way. It contains, by design, the exact command that loses
# real data. That command should be run by a person who meant it.
#
# `break` stops F5. It does NOT stop F8.
#
# Cursor in a region below -> F8 -> read the SAY line -> then talk.
# ---------------------------------------------------------------------------------------
break
#endregion


# =======================================================================================
#  PART 1 - BEFORE LUNCH.  Build the artifact. Do not deploy anything.
# =======================================================================================

#region 01 · Into the project                                                       [~10s]
cd database/sql-projects
Get-Location
#endregion


#region 02 · Build it                                                               [~32s]
dotnet build FabConFootball.sqlproj --configuration Release -warnaserror
#endregion


#region 03 · There it is                                                            [~10s]
Get-Item .\bin\Release\FabConFootball.dacpac
#endregion


#region 04 · Show them it is just files                                             [~90s]
Get-childItem .\bin\Release | Select-Object Name, Length

code ./bin/Release/FabConFootball.StaticCodeAnalysis.Results.xml
#
# STOP HERE FOR LUNCH. The DACPAC is built; publishing it is the afternoon.
code ./Tables
#endregion


# =======================================================================================
#  PART 2 - AFTER LUNCH.  Now we deploy it, and then we break it.
# =======================================================================================

#region 05 · Token and target                                                       [~60s]
#
#          Attendees on the shared endpoint use SQL auth instead -- login attendeeNN,
#          database sqldb-attendeeNN, and /TargetUser /TargetPassword in place of
#          /AccessToken. The attendee page has both paths in tabs.
$token   = az account get-access-token --resource https://database.windows.net/ --query accessToken -o tsv
$server  = "<your-server-name>"
$db      = "<your-database-name>"
$profile = "PublishProfiles/AzureSql.publish.xml"
#endregion


#region 06 · Increment 0 - the baseline report                                     [~2m08s]
sqlpackage /Action:DeployReport `
    /SourceFile:"bin/Release/FabConFootball.dacpac" `
    /Profile:$profile `
    /TargetServerName:$server /TargetDatabaseName:$db /AccessToken:$token `
    /OutputPath:"deploy-report-increment-0.xml"
code deploy-report-increment-0.xml
#endregion


#region 07 · Increment 0 - publish the baseline                                    [~2m02s]
sqlpackage /Action:Publish `
    /SourceFile:"bin/Release/FabConFootball.dacpac" `
    /Profile:$profile `
    /TargetServerName:$server /TargetDatabaseName:$db /AccessToken:$token
#endregion


#region 08 · Increment 0 - prove the data is real                                   [~20s]
$queryParams = @{
    SqlInstance = $server
    Database    = $db
    AccessToken = $token
    Query       = "SELECT TOP (5) PlayerId, FirstName, LastName, ShirtNumber FROM football.Player WHERE ShirtNumber IS NOT NULL"
}
Invoke-DbaQuery @queryParams
#endregion


#region 09 · Increment 1 - add a view                                               [~25s]
Copy-Item ..\demo\ship-changes\increment-1_vw_SquadAges.sql .\Views\vw_SquadAges.sql
dotnet build FabConFootball.sqlproj --configuration Release -warnaserror
#endregion


#region 10 · Increment 1 - the clean report                                        [~1m57s]
sqlpackage /Action:DeployReport `
    /SourceFile:"bin/Release/FabConFootball.dacpac" `
    /Profile:$profile `
    /TargetServerName:$server /TargetDatabaseName:$db /AccessToken:$token `
    /OutputPath:"deploy-report.xml"
code deploy-report.xml
#endregion


#region 11 · Increment 1 - publish it                                              [~2m00s]
sqlpackage /Action:Publish `
    /SourceFile:"bin/Release/FabConFootball.dacpac" `
    /Profile:$profile `
    /TargetServerName:$server /TargetDatabaseName:$db /AccessToken:$token
#endregion


#region 12 · Increment 2 - look at the data one last time                           [~20s]
Invoke-DbaQuery @queryParams
#endregion


#region 13 · Increment 2 - the bundle                                               [~90s]
Copy-Item ..\demo\ship-changes\increment-2_vw_TeamRosterSizes.sql .\Views\vw_TeamRosterSizes.sql
Copy-Item ..\demo\ship-changes\increment-2_Player.sql .\Tables\Player.sql -Force
Copy-Item ..\demo\ship-changes\increment-2_Seed.sql .\Scripts\PostDeployment\Seed.sql -Force
git --no-pager diff -- .\Tables\Player.sql .\Scripts\PostDeployment\Seed.sql
#endregion


#region 14 · Increment 2 - the report catches it                                   [~2m18s]
dotnet build FabConFootball.sqlproj --configuration Release -warnaserror
sqlpackage /Action:DeployReport `
    /SourceFile:"bin/Release/FabConFootball.dacpac" `
    /Profile:$profile `
    /TargetServerName:$server /TargetDatabaseName:$db /AccessToken:$token `
    /OutputPath:"deploy-report.xml"
code deploy-report.xml
#endregion


#region 15 · Increment 2a - THE PUNCHLINE. Slow down.                              [~2m00s]
# ---------------------------------------------------------------------------------------
# !! THROWAWAY DATABASE ONLY. This really does destroy the data. If $db is the database
# !! you need for increment 3, change it NOW, before you run this.
# ---------------------------------------------------------------------------------------
sqlpackage /Action:Publish `
    /SourceFile:"bin/Release/FabConFootball.dacpac" `
    /Profile:$profile `
    /TargetServerName:$server /TargetDatabaseName:$db /AccessToken:$token `
    /p:BlockOnPossibleDataLoss=false
#endregion


#region 16 · Increment 2a - the damage                                              [~20s]
Invoke-DbaQuery @queryParams
#endregion


#region 17 · Increment 2b - the guard we already ship                              [~1m30s]
sqlpackage /Action:Publish `
    /SourceFile:"bin/Release/FabConFootball.dacpac" `
    /Profile:$profile `
    /TargetServerName:$server /TargetDatabaseName:$db /AccessToken:$token
#endregion


# ---------------------------------------------------------------------------------------
#  BREAK  15:15-15:45.  Increment 3 resumes after it.
#  Before you walk off: make sure $db points at a database that still HAS a populated
#  ShirtNumber. Increment 3 needs it, and re-publishing the baseline will NOT refill it.
# ---------------------------------------------------------------------------------------


#region 18 · Increment 3 - confirm the data is back                                 [~20s]
Invoke-DbaQuery @queryParams
#endregion


#region 19 · Increment 3 Option A - preserve the data                               [~35s]
New-Item -ItemType Directory -Path .\Scripts\PreDeployment -Force | Out-Null
Copy-Item ..\demo\ship-changes\increment-3_Player.sql              .\Tables\Player.sql -Force
Copy-Item ..\demo\ship-changes\increment-3_Migrate-ShirtNumber.sql .\Scripts\PreDeployment\Migrate-ShirtNumber.sql -Force
Copy-Item ..\demo\ship-changes\increment-3_Seed.sql                .\Scripts\PostDeployment\Seed.sql -Force
Copy-Item ..\demo\ship-changes\increment-3A_FabConFootball.sqlproj .\FabConFootball.sqlproj -Force
dotnet build FabConFootball.sqlproj --configuration Release -warnaserror
#endregion


#region 20 · Increment 3 Option A - report, publish, verify                        [~4m30s]
sqlpackage /Action:DeployReport `
    /SourceFile:"bin/Release/FabConFootball.dacpac" `
    /Profile:$profile `
    /TargetServerName:$server /TargetDatabaseName:$db /AccessToken:$token `
    /OutputPath:"deploy-report.xml"
sqlpackage /Action:Publish `
    /SourceFile:"bin/Release/FabConFootball.dacpac" `
    /Profile:$profile `
    /TargetServerName:$server /TargetDatabaseName:$db /AccessToken:$token `
    /p:BlockOnPossibleDataLoss=false
$verifyParams = @{
    SqlInstance = $server
    Database    = $db
    AccessToken = $token
    Query       = "SELECT TOP (5) PlayerId, LastName, SquadNumber FROM football.Player WHERE SquadNumber IS NOT NULL"
}
Invoke-DbaQuery @verifyParams
#endregion


#region 21 · Increment 3 Option B - model it as a rename                            [~35s]
Copy-Item ..\demo\ship-changes\increment-3_Player.sql                 .\Tables\Player.sql -Force
Copy-Item ..\demo\ship-changes\increment-3_Seed.sql                   .\Scripts\PostDeployment\Seed.sql -Force
Copy-Item ..\demo\ship-changes\increment-3_FabConFootball.refactorlog .\FabConFootball.refactorlog -Force
Copy-Item ..\demo\ship-changes\increment-3B_FabConFootball.sqlproj    .\FabConFootball.sqlproj -Force
dotnet build FabConFootball.sqlproj --configuration Release -warnaserror
#endregion


#region 22 · Increment 3 Option B - the clean report                               [~4m00s]
sqlpackage /Action:DeployReport `
    /SourceFile:"bin/Release/FabConFootball.dacpac" `
    /Profile:$profile `
    /TargetServerName:$server /TargetDatabaseName:$db /AccessToken:$token `
    /OutputPath:"deploy-report.xml"
sqlpackage /Action:Publish `
    /SourceFile:"bin/Release/FabConFootball.dacpac" `
    /Profile:$profile `
    /TargetServerName:$server /TargetDatabaseName:$db /AccessToken:$token
Invoke-DbaQuery @verifyParams
#endregion


#region 23 · The gate                                                               [~2m]
code ..\demo\ship-changes\increment-3_safe-retire.md
#endregion


#region 99 · RESET -- run this, it matters more here than anywhere                  [~15s]
git restore .\Tables\Player.sql .\Scripts\PostDeployment\Seed.sql .\FabConFootball.sqlproj
Remove-Item .\Views\vw_SquadAges.sql                        -ErrorAction SilentlyContinue
Remove-Item .\Views\vw_TeamRosterSizes.sql                  -ErrorAction SilentlyContinue
Remove-Item .\Scripts\PreDeployment\Migrate-ShirtNumber.sql -ErrorAction SilentlyContinue
Remove-Item .\FabConFootball.refactorlog                    -ErrorAction SilentlyContinue
Remove-Item .\deploy-report*.xml                            -ErrorAction SilentlyContinue
git status --short
#endregion
