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
                   the DATA does not. Then name point-in-time restore (and a DB copy)
                   as the real answers, and do not wait for one.
                   2b now that the column exists again, publish WITHOUT the override
                      -> the guard fails loudly, as it should have all along
      Reseed       put the values back with a data-only UPDATE, so the whole demo runs
                   on ONE database. Say out loud this is a demo convenience, not the
                   real recovery -- the real recovery is the restore we just described.
      Increment 3  retire the same column WITHOUT losing the data, two ways

    WHY 2b COMES AFTER THE RECOVERY
    It used to run straight after 2a and it did nothing: the column was already gone, so
    the same DACPAC had nothing left to drop and the publish just succeeded. The guard
    needs a populated column to refuse. The recovery puts one back, which is why the two
    are now one sequence rather than two.

    !! INCREMENT 2 DESTROYS DATA ON PURPOSE !!
    Increment 2a really does drop a populated column. The recovery deliberately leaves it
    present and EMPTY -- the seed only inserts missing rows, it does not update existing ones.
    That is the teaching point of the recovery. Increment 3 then needs ShirtNumber present
    AND populated, so the Reseed region puts the values back with a data-only UPDATE and the
    whole demo stays on ONE database. Say plainly the reseed is a demo convenience: in
    production you recover with a restore, not by re-typing the values.

    BEFORE YOU START
      - .NET 8 SDK (global.json pins it) and sqlpackage on PATH.
      - A single target database (the reseed removes the old need for a throwaway).
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
$server  = "sql-fabcon26-dev-uks-0rix69.database.windows.net"
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
# !! This really does destroy the data in $db. That is the point -- let it land. The
# !! Reseed region below puts the values back before increment 3, so one database is fine.
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
# A database COPY (CREATE DATABASE ... AS COPY OF ...) is the other real option to keep a
# pristine environment around. Describe both, run neither -- each is several minutes of
# nothing, and we do not have them. We put the values back a faster way in the Reseed region.
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


#region 24b · Reseed - put the values back so we stay on ONE database               [~15s]
# 2a destroyed the data, the recovery brought the COLUMN back but left it empty, and 2b was
# blocked -- so ShirtNumber is present and NULL for everyone. Increment 3 needs it populated.
# This runs a data-only UPDATE that fills the empty rows with the real shirt numbers.
#
# SAY IT OUT LOUD: in production you do NOT re-type your data. This is a point-in-time
# restore or a database copy (both described a moment ago). We UPDATE here purely so the
# demo carries on against this one database instead of a second, pristine one.
$reseedParams = @{
    SqlInstance = $serverSMO
    Database    = $db
    File        = "../demo/ship-changes/increment-2_Restore-ShirtNumber.sql"
}
Invoke-DbaQuery @reseedParams
#endregion


# ---------------------------------------------------------------------------------------
#  Increment 3 continues straight on, in the SAME Afternoon 1 slot -- no break between it
#  and 2b any more. The break (15:15-15:45) now comes AFTER the whole database demo.
#  The Reseed region above put ShirtNumber back, so this same $db is ready. If the token
#  has expired mid-slot, rerun region 06.
# ---------------------------------------------------------------------------------------


#region 25 · Increment 3 - confirm the data is back                                 [~20s]
# Returns rows now, because the Reseed region just refilled ShirtNumber.
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
code deploy-report.xml

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
Remove-Item ./Scripts/PreDeployment/Migrate-ShirtNumber.sql -ErrorAction SilentlyContinue           # not needed for this version
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
