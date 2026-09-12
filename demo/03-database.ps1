<#
    DEMO 03 - Database as code, and shipping changes to it
    ATTENDEE PAGE: docs/database/demo.md
    SLOT:          PART 1  Morning 3   - 12:15-12:45 (build the DACPAC, then lunch)
                   PART 2  Afternoon 1 - 14:00-15:15 (increments 0 through 3, all in one slot)
    RUNTIME:       Part 1 ~10 min. Part 2 ~62 min, most of it waiting on sqlpackage.
                   Part 2 now fills the whole Afternoon 1 slot end to end -- there is almost
                   no slack. If behind, run only increment 3 Option B and describe Option A.

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
      Recovery     "just redeploy the last good version" -> the COLUMN comes back,
                   the DATA does not. Then name point-in-time restore as the real
                   answer, and do not wait for one.
                   2b now that the column exists again, publish WITHOUT the override
                      -> the guard fails loudly, as it should have all along
      Increment 3  retire the same column WITHOUT losing the data, two ways

    WHY 2b COMES AFTER THE RECOVERY
    It used to run straight after 2a and it did nothing: the column was already gone, so
    the same DACPAC had nothing left to drop and the publish just succeeded. The guard
    needs a populated column to refuse. The recovery puts one back, which is why the two
    are now one sequence rather than two.

    !! INCREMENT 2 DESTROYS DATA ON PURPOSE !!
    Run increment 2, the recovery AND 2b against a THROWAWAY database. Increment 3 needs
    ShirtNumber present and POPULATED, and the recovery deliberately leaves it present and
    EMPTY -- the seed only inserts missing rows, it does not update existing ones. That is
    the teaching point of the recovery, and it is also why increment 3 needs a different
    database. Ask us how we know.

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
Get-Item ./bin/Release/FabConFootball.dacpac
#endregion


#region 04 · Show them it is just files                                             [~90s]
Get-childItem ./bin/Release | Select-Object Name, Length

code ./bin/Release/FabConFootball.StaticCodeAnalysis.Results.xml
#
# STOP HERE FOR LUNCH. The DACPAC is built; publishing it is the afternoon.
code ./Tables/Club.sql    # opens a file in the current window; the Explorer already shows the folder tree
#endregion


# =======================================================================================
#  PART 2 - AFTER LUNCH.  Now we deploy it, and then we break it.
# =======================================================================================

#region 05 · Back from lunch -- where are we, and are we still signed in?           [~40s]
# The terminal may have been closed, moved, or gone to sleep. Check before you demo.
Test-Path ./FabConFootball.sqlproj      # must be True; if not: cd database/sql-projects
Get-Location
az login
#endregion


#region 06 · Token and target                                                       [~60s]
#
#          Attendees on the shared endpoint use SQL auth instead -- login attendeeNN,
#          database sqldb-attendeeNN, and /TargetUser /TargetPassword in place of
#          /AccessToken. The attendee page has both paths in tabs.
$token   = az account get-access-token --resource https://database.windows.net/ --query accessToken -o tsv
$server  = "sql-fabcon26-dev-uks-jnkojv.database.windows.net"
$db      = "sqldb-football-dev"
$profile = "PublishProfiles/AzureSql.publish.xml"
#endregion


#region 07 · Increment 0 - the baseline report                                     [~2m08s]
sqlpackage /Action:DeployReport `
    /SourceFile:"bin/Release/FabConFootball.dacpac" `
    /Profile:$profile `
    /TargetServerName:$server /TargetDatabaseName:$db /AccessToken:$token `
    /OutputPath:"deploy-report-increment-0.xml"
code deploy-report-increment-0.xml
#endregion


#region 08 · Increment 0 - publish the baseline                                    [~2m02s]
sqlpackage /Action:Publish `
    /SourceFile:"bin/Release/FabConFootball.dacpac" `
    /Profile:$profile `
    /TargetServerName:$server /TargetDatabaseName:$db /AccessToken:$token
#endregion


#region 09 · Increment 0 - prove the data is real                                   [~20s]

$ConnectionParams = @{
    SqlInstance = $server
    Database    = $db
    AccessToken = $token
}
$serverSMO = Connect-DbaInstance @ConnectionParams

$queryParams = @{
    SqlInstance = $serverSMO
    Database    = $db

    Query       = "SELECT TOP (5) PlayerId, FirstName, LastName, ShirtNumber FROM football.Player WHERE ShirtNumber IS NOT NULL"
}
Invoke-DbaQuery @queryParams
#endregion


#region 10 · Increment 1 - add a view                                               [~25s]
Copy-Item ../demo/ship-changes/increment-1_vw_SquadAges.sql ./Views/vw_SquadAges.sql
# Show them what just landed: a read-only SELECT with a computed AgeYears column. Additive,
# so nothing existing is touched -- which is why the next report is clean.
code ./Views/vw_SquadAges.sql
dotnet build FabConFootball.sqlproj --configuration Release -warnaserror
#endregion


#region 11 · Increment 1 - the clean report                                        [~1m57s]
sqlpackage /Action:DeployReport `
    /SourceFile:"bin/Release/FabConFootball.dacpac" `
    /Profile:$profile `
    /TargetServerName:$server /TargetDatabaseName:$db /AccessToken:$token `
    /OutputPath:"deploy-report.xml"
code deploy-report.xml
#endregion


#region 12 · Increment 1 - publish it                                              [~2m00s]
sqlpackage /Action:Publish `
    /SourceFile:"bin/Release/FabConFootball.dacpac" `
    /Profile:$profile `
    /TargetServerName:$server /TargetDatabaseName:$db /AccessToken:$token
#endregion


#region 13 · Increment 2 - look at the data one last time                           [~20s]
Invoke-DbaQuery @queryParams
#endregion


#region 14 · Increment 2 - the bundle                                               [~90s]
Copy-Item ../demo/ship-changes/increment-2_vw_TeamRosterSizes.sql ./Views/vw_TeamRosterSizes.sql
Copy-Item ../demo/ship-changes/increment-2_Player.sql ./Tables/Player.sql -Force
Copy-Item ../demo/ship-changes/increment-2_Seed.sql ./Scripts/PostDeployment/Seed.sql -Force
#endregion


#region 15 · Increment 2 - one deleted line                                         [~45s]
# Let them read it. One line gone from a table definition IS a dropped column.
git --no-pager diff -- ./Tables/Player.sql ./Scripts/PostDeployment/Seed.sql
#endregion


#region 16 · Increment 2 - and it is gone from both files                           [~20s]
# Prints NOTHING. No output = no matches. Say that out loud -- silence looks like a
# failed command from the back row.
Select-String -Path ./Tables/Player.sql,./Scripts/PostDeployment/Seed.sql -Pattern "ShirtNumber"
#endregion


#region 17 · Increment 2 - the report catches it                                   [~2m18s]
dotnet build FabConFootball.sqlproj --configuration Release -warnaserror
sqlpackage /Action:DeployReport `
    /SourceFile:"bin/Release/FabConFootball.dacpac" `
    /Profile:$profile `
    /TargetServerName:$server /TargetDatabaseName:$db /AccessToken:$token `
    /OutputPath:"deploy-report.xml"
code deploy-report.xml
#endregion


#region 18 · Increment 2a - THE PUNCHLINE. Slow down.                              [~2m00s]
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


#region 19 · Increment 2a - the damage                                              [~20s]
# This now ERRORS: "Invalid column name 'ShirtNumber'". That error is the punchline.
# Do not talk over it. Let them read it.
Invoke-DbaQuery @queryParams
#endregion


# ---------------------------------------------------------------------------------------
#  RECOVERY - "just redeploy the last good version". Let someone in the room suggest it.
#  It is the obvious answer, it is wrong, and it is far better learnt here than at work.
# ---------------------------------------------------------------------------------------

#region 20 · Recovery - rebuild the last good DACPAC                                [~35s]
git restore ./Tables/Player.sql ./Scripts/PostDeployment/Seed.sql
dotnet build FabConFootball.sqlproj --configuration Release -warnaserror
#endregion


#region 21 · Recovery - publish it, and put the column back                        [~2m00s]
# No override needed. ADDING a column loses nothing, so the shipped profile allows it.
sqlpackage /Action:Publish `
    /SourceFile:"bin/Release/FabConFootball.dacpac" `
    /Profile:$profile `
    /TargetServerName:$server /TargetDatabaseName:$db /AccessToken:$token
#endregion


#region 22 · Recovery - ask for the data back                                       [~20s]
# The query RUNS this time, and returns NO ROWS. Column back, every value NULL. The
# seed does not refill it -- it only inserts players that are missing, and none are.
#
#   "The pipeline gave us the column back. It did not give us the data back.
#    Source control has your schema. It has never had your data."
#
# The real answer is a point-in-time restore to a new database, BEFORE the bad publish:
#
#   az sql db restore --resource-group <rg> --server <server> --name $db `
#                     --dest-name "$db-restored" --time <utc-timestamp>
#
# Describe it, do not run it -- several minutes of nothing, and we do not have them.
Invoke-DbaQuery @queryParams
#endregion


#region 23 · Increment 2b - put the destructive change back                         [~35s]
Copy-Item ../demo/ship-changes/increment-2_Player.sql ./Tables/Player.sql -Force
Copy-Item ../demo/ship-changes/increment-2_Seed.sql   ./Scripts/PostDeployment/Seed.sql -Force
dotnet build FabConFootball.sqlproj --configuration Release -warnaserror
#endregion


#region 24 · Increment 2b - the guard we already ship                              [~1m30s]
# NOW it fails, because the column exists again and the table has rows:
#   *** Could not deploy package.
#   Rows were detected. The schema update is terminating because data loss might occur.
# The ONLY reason region 18 succeeded was a human typing /p:BlockOnPossibleDataLoss=false.
sqlpackage /Action:Publish `
    /SourceFile:"bin/Release/FabConFootball.dacpac" `
    /Profile:$profile `
    /TargetServerName:$server /TargetDatabaseName:$db /AccessToken:$token
#endregion


# ---------------------------------------------------------------------------------------
#  Increment 3 continues straight on, in the SAME Afternoon 1 slot -- no break between it
#  and 2b any more. The break (15:15-15:45) now comes AFTER the whole database demo.
#  Before increment 3: point $db at a database that still HAS a populated ShirtNumber --
#  NOT the throwaway you just used, where the recovery left the column empty. If the token
#  has expired mid-slot, rerun region 06.
# ---------------------------------------------------------------------------------------


#region 25 · Increment 3 - confirm the data is back                                 [~20s]
Invoke-DbaQuery @queryParams
#endregion


#region 26 · Increment 3 Option A - preserve the data                               [~35s]
New-Item -ItemType Directory -Path ./Scripts/PreDeployment -Force | Out-Null
Copy-Item ../demo/ship-changes/increment-3_Player.sql              ./Tables/Player.sql -Force
Copy-Item ../demo/ship-changes/increment-3_Migrate-ShirtNumber.sql ./Scripts/PreDeployment/Migrate-ShirtNumber.sql -Force
Copy-Item ../demo/ship-changes/increment-3_Seed.sql                ./Scripts/PostDeployment/Seed.sql -Force
Copy-Item ../demo/ship-changes/increment-3A_FabConFootball.sqlproj ./FabConFootball.sqlproj -Force
dotnet build FabConFootball.sqlproj --configuration Release -warnaserror
#endregion


#region 27 · Increment 3 Option A - report, publish, verify                        [~4m30s]
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
    SqlInstance = $serverSMO
    Database    = $db
    Query       = "SELECT TOP (5) PlayerId, LastName, SquadNumber FROM football.Player WHERE SquadNumber IS NOT NULL"
}
Invoke-DbaQuery @verifyParams
#endregion


#region 28 · Increment 3 Option B - model it as a rename                            [~35s]
Copy-Item ../demo/ship-changes/increment-3_Player.sql                 ./Tables/Player.sql -Force
Copy-Item ../demo/ship-changes/increment-3_Seed.sql                   ./Scripts/PostDeployment/Seed.sql -Force
Copy-Item ../demo/ship-changes/increment-3_FabConFootball.refactorlog ./FabConFootball.refactorlog -Force
Copy-Item ../demo/ship-changes/increment-3B_FabConFootball.sqlproj    ./FabConFootball.sqlproj -Force
dotnet build FabConFootball.sqlproj --configuration Release -warnaserror
#endregion


#region 29 · Increment 3 Option B - the clean report                               [~4m00s]
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


#region 30 · The gate                                                               [~2m]
code ../demo/ship-changes/increment-3_safe-retire.md
#endregion


#region 99 · RESET -- run this, it matters more here than anywhere                  [~15s]
git restore ./Tables/Player.sql ./Scripts/PostDeployment/Seed.sql ./FabConFootball.sqlproj
Remove-Item ./Views/vw_SquadAges.sql                        -ErrorAction SilentlyContinue
Remove-Item ./Views/vw_TeamRosterSizes.sql                  -ErrorAction SilentlyContinue
Remove-Item ./Scripts/PreDeployment/Migrate-ShirtNumber.sql -ErrorAction SilentlyContinue
Remove-Item ./FabConFootball.refactorlog                    -ErrorAction SilentlyContinue
Remove-Item ./deploy-report*.xml                            -ErrorAction SilentlyContinue
git status --short
#endregion
