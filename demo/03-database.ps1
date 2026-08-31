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
# WHAT     Everything in this demo runs from database/sql-projects. Every Copy-Item below
#          uses ..\demo\ship-changes\ relative to here, so if you wander off this folder
#          nothing will work.
# SAY      "One folder. One object per file. This is a database, in git."
# EXPECT   The path ends with database\sql-projects.
# IF STUCK `cd` to the repo root first.
# PAGE     docs/database/demo.md - Part 1, step 1
cd database/sql-projects
Get-Location
#endregion


#region 02 · Build it                                                               [~32s]
# WHAT     Compiles every .sql file into one DACPAC, and runs T-SQL static code analysis on
#          the way past. -warnaserror turns any smell into a failed build.
# SAY      "Thirty seconds, and the whole schema is one file. And notice what else just
#           happened -- static analysis ran, and it found nothing. That bar is not
#           decoration; our moderator tunes queries for a living."
# EXPECT   "No problems have been detected." then "Build succeeded. 0 Warning(s) 0 Error(s)"
# IF STUCK "A compatible .NET SDK was not found" -> global.json pins 8.x and you have only
#          9.x. `winget install --exact --id Microsoft.DotNet.SDK.8`, reopen the terminal.
#          Do not edit global.json on stage; CI uses 8.x and you will forget to put it back.
# PAGE     docs/database/demo.md - Part 1, step 2
dotnet build FabConFootball.sqlproj --configuration Release -warnaserror
#endregion


#region 03 · There it is                                                            [~10s]
# WHAT     Proves the artifact exists. One file, and it is the only thing that gets
#          deployed anywhere.
# SAY      "That is the whole database. Nine tables, three views, three procedures and the
#           seed, in one file I can hand to a pipeline."
# EXPECT   A file listing with a recent timestamp.
# IF STUCK If it is missing, the build in 02 did not actually succeed -- scroll up and read
#          the errors rather than re-running.
# PAGE     docs/database/demo.md - Part 1, step 3
Get-Item .\bin\Release\FabConFootball.dacpac
#endregion


#region 04 · Show them it is just files                                             [~90s]
# WHAT     Browse Tables, Views and Programmability in the Explorer. No command needed --
#          this is a talking beat, and a good one to end the morning on.
# SAY      "Nothing here is magic. It is one file per object, in a folder, in git. Which
#           means every one of them can be reviewed, branched and rolled back like any
#           other code you own."
# EXPECT   Nothing. You are pointing at the sidebar.
# IF STUCK n/a
# PAGE     docs/database/demo.md - Part 1, step 4
#
# STOP HERE FOR LUNCH. The DACPAC is built; publishing it is the afternoon.
code .\Tables
#endregion


# =======================================================================================
#  PART 2 - AFTER LUNCH.  Now we deploy it, and then we break it.
# =======================================================================================

#region 05 · Token and target                                                       [~60s]
# WHAT     An Entra token, and the three variables every sqlpackage command below reuses.
#          Fill in your server and database before you run this.
# SAY      "No password. A token, good for an hour, that I did not have to store anywhere."
# EXPECT   $token holds a long string; the three variables are set.
# IF STUCK Token expired mid-session (they last about an hour) -> just re-run this region.
#          This is the single most common failure in the afternoon. If a sqlpackage command
#          suddenly starts failing on auth, come back here first.
#
#          Attendees on the shared endpoint use SQL auth instead -- login attendeeNN,
#          database sqldb-attendeeNN, and /TargetUser /TargetPassword in place of
#          /AccessToken. The attendee page has both paths in tabs.
# PAGE     docs/database/demo.md - Part 2, Set up the target, steps 1-2
$token   = az account get-access-token --resource https://database.windows.net/ --query accessToken -o tsv
$server  = "<your-server-name>"
$db      = "<your-database-name>"
$profile = "PublishProfiles/AzureSql.publish.xml"
#endregion


#region 06 · Increment 0 - the baseline report                                     [~2m08s]
# WHAT     A deploy report against the current DACPAC, before any increment. This is the
#          command the whole afternoon hangs off, so introduce it properly.
# SAY      "This is the database's terraform plan. It tells me exactly what a publish would
#           do -- and it changes nothing at all. If you take one command home today, this
#           is the one."
# EXPECT   "Successfully generated report to file ... deploy-report-increment-0.xml"
# IF STUCK "sqlpackage is not recognized" -> `dotnet tool install -g microsoft.sqlpackage`,
#          then reopen the terminal. If it is installed but not found in THIS session:
#          $env:PATH = "$env:PATH;$HOME\.dotnet\tools"
# PAGE     docs/database/demo.md - Increment 0, step 3
sqlpackage /Action:DeployReport `
    /SourceFile:"bin/Release/FabConFootball.dacpac" `
    /Profile:$profile `
    /TargetServerName:$server /TargetDatabaseName:$db /AccessToken:$token `
    /OutputPath:"deploy-report-increment-0.xml"
code deploy-report-increment-0.xml
#endregion


#region 07 · Increment 0 - publish the baseline                                    [~2m02s]
# WHAT     Establishes the known starting point, so every later report is a diff against
#          something we all watched happen.
# SAY      Two minutes of scrolling output. Narrate the publish profile while it runs:
#          BlockOnPossibleDataLoss=True, DropObjectsNotInSource=False,
#          CreateNewDatabase=False -- options, not secrets, which is why it is committed.
# EXPECT   "Successfully published database."
# IF STUCK Auth failure -> re-run region 05, the token has expired.
# PAGE     docs/database/demo.md - Increment 0, step 4
sqlpackage /Action:Publish `
    /SourceFile:"bin/Release/FabConFootball.dacpac" `
    /Profile:$profile `
    /TargetServerName:$server /TargetDatabaseName:$db /AccessToken:$token
#endregion


#region 08 · Increment 0 - prove the data is real                                   [~20s]
# WHAT     Shows ShirtNumber populated. THIS REGION IS LOAD-BEARING. Without it, the data
#          loss in increment 2 is an abstraction. Get these rows on screen and leave them
#          there.
# SAY      "Remember these. Saka seven, Palmer ten. We are going to come back to them, and
#           when we do I would like you to be cross about it."
# EXPECT   Five rows with real ShirtNumber values.
# IF STUCK No rows -> the seed did not run, or you are pointed at the wrong database.
#          Check $db. Do not continue to increment 2 without this; the punchline needs it.
# PAGE     docs/database/demo.md - Increment 0, step 5
$queryParams = @{
    SqlInstance = $server
    Database    = $db
    AccessToken = $token
    Query       = "SELECT TOP (5) PlayerId, FirstName, LastName, ShirtNumber FROM football.Player WHERE ShirtNumber IS NOT NULL"
}
Invoke-DbaQuery @queryParams
#endregion


#region 09 · Increment 1 - add a view                                               [~25s]
# WHAT     Copies in the additive view and rebuilds. One new file, nothing touched.
# SAY      "The safe kind of change. I am adding something; I am not moving anything that
#           already exists."
# EXPECT   Build succeeds, 0 warnings, 0 errors.
# IF STUCK Copy fails -> you are not in database/sql-projects. Check with Get-Location.
# PAGE     docs/database/demo.md - Increment 1, steps 6-7
Copy-Item ..\demo\ship-changes\increment-1_vw_SquadAges.sql .\Views\vw_SquadAges.sql
dotnet build FabConFootball.sqlproj --configuration Release -warnaserror
#endregion


#region 10 · Increment 1 - the clean report                                        [~1m57s]
# WHAT     The report for an additive change. Point at the EMPTY <Alerts /> node -- that
#          emptiness is the whole message.
# SAY      "One view to create. And look at that -- Alerts, empty. Nothing here can lose
#           anybody anything, so this is the kind of change a pipeline can merge and deploy
#           without waking a human at three in the morning."
# EXPECT   One view to create; <Alerts /> empty. Some check constraints may be recreated --
#          that is normal and not a data-loss operation. Say so if anyone asks.
# IF STUCK Token expired -> region 05.
# PAGE     docs/database/demo.md - Increment 1, step 8
sqlpackage /Action:DeployReport `
    /SourceFile:"bin/Release/FabConFootball.dacpac" `
    /Profile:$profile `
    /TargetServerName:$server /TargetDatabaseName:$db /AccessToken:$token `
    /OutputPath:"deploy-report.xml"
code deploy-report.xml
#endregion


#region 11 · Increment 1 - publish it                                              [~2m00s]
# WHAT     The safe publish. No overrides, no arguments, no drama.
# SAY      "This is the one to try on your own kit. It cannot hurt anything."
# EXPECT   "Creating View [football].[vw_SquadAges]..." then "Successfully published".
# IF STUCK Token expired -> region 05.
# PAGE     docs/database/demo.md - Increment 1, step 9
sqlpackage /Action:Publish `
    /SourceFile:"bin/Release/FabConFootball.dacpac" `
    /Profile:$profile `
    /TargetServerName:$server /TargetDatabaseName:$db /AccessToken:$token
#endregion


#region 12 · Increment 2 - look at the data one last time                           [~20s]
# WHAT     The same query as region 08. Run it again, deliberately, so the before and after
#          are two minutes apart rather than twenty.
# SAY      "One more look. Saka seven, Palmer ten."
# EXPECT   The same five populated rows.
# IF STUCK If this is empty you have already run 2a against this database. Switch $db to a
#          fresh one and re-publish the baseline before continuing.
# PAGE     docs/database/demo.md - Increment 2, step 10
Invoke-DbaQuery @queryParams
#endregion


#region 13 · Increment 2 - the bundle                                               [~90s]
# WHAT     An innocent view AND a Player table without ShirtNumber AND a matching seed.
#          Three files. The `git diff` at the end is the moment -- show it, and let the
#          room try to spot the problem before you point at it.
# SAY      "A view, and a small tidy-up of the table. This is a realistic pull request. Now
#           -- who has spotted it? Because in a forty-file review at half past four on a
#           Friday, I have not."
# EXPECT   The diff shows vw_TeamRosterSizes added, and ShirtNumber quietly gone from both
#          Player.sql and Seed.sql.
# IF STUCK Nothing tricky. If the diff is huge, `git --no-pager diff -- .\Tables\Player.sql`
#          on its own is the clearer picture.
# PAGE     docs/database/demo.md - Increment 2, steps 11-12
Copy-Item ..\demo\ship-changes\increment-2_vw_TeamRosterSizes.sql .\Views\vw_TeamRosterSizes.sql
Copy-Item ..\demo\ship-changes\increment-2_Player.sql .\Tables\Player.sql -Force
Copy-Item ..\demo\ship-changes\increment-2_Seed.sql .\Scripts\PostDeployment\Seed.sql -Force
git --no-pager diff -- .\Tables\Player.sql .\Scripts\PostDeployment\Seed.sql
#endregion


#region 14 · Increment 2 - the report catches it                                   [~2m18s]
# WHAT     Rebuild, then report. The report says the quiet part out loud.
# SAY      "And there it is. The pipeline read the change and told me, in one line, exactly
#           what it was going to cost me. Before it did it."
# EXPECT   "*** The column [football].[Player].[ShirtNumber] is being dropped, data loss
#           could occur." and a DataIssue alert in the XML.
# IF STUCK Token expired -> region 05.
# PAGE     docs/database/demo.md - Increment 2, step 13
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
# WHAT     Forces the publish through with BlockOnPossibleDataLoss=false. This is the
#          anti-pattern, played straight.
# SAY      "The report told me. I read it. And then I did this, because I was in a hurry
#           and it was Friday." -- then, as it runs: "notice that it is not complaining.
#           There is no warning. It is doing exactly what I asked."
# EXPECT   "Successfully published database." No error. That is the horror.
# IF STUCK Token expired -> region 05.
# PAGE     docs/database/demo.md - Increment 2, step 14
sqlpackage /Action:Publish `
    /SourceFile:"bin/Release/FabConFootball.dacpac" `
    /Profile:$profile `
    /TargetServerName:$server /TargetDatabaseName:$db /AccessToken:$token `
    /p:BlockOnPossibleDataLoss=false
#endregion


#region 16 · Increment 2a - the damage                                              [~20s]
# WHAT     The same query, a third time. It now returns nothing, because the column is gone.
# SAY      Run it. Then STOP TALKING. Let the empty result sit there for a good three
#          seconds before you say anything. This is the most valuable silence of the day
#          and every instinct you have will be to fill it.
#          Then: "No error. No warning. No column. And no way back, because the backup is
#           from this morning and it is now four o'clock."
# EXPECT   "Invalid column name 'ShirtNumber'." -- the column does not exist any more.
# IF STUCK If it still returns rows, the publish in 15 did not take. Check the output above.
# PAGE     docs/database/demo.md - Increment 2, step 15
Invoke-DbaQuery @queryParams
#endregion


#region 17 · Increment 2b - the guard we already ship                              [~1m30s]
# WHAT     The SAME publish, against a database that still has the column, WITHOUT the
#          override. The profile sets BlockOnPossibleDataLoss=True, so it refuses.
# SAY      "Same DACPAC. Same command. One flag removed -- the flag that was never mine to
#           set. And now it will not let me."
# EXPECT   It FAILS: "...blocked because the operation could result in data loss". A red
#          error is the success condition here. Say that out loud, or half the room will
#          think the demo broke.
# IF STUCK Point $db at a database that still HAS ShirtNumber before running this, or the
#          publish has nothing to refuse and succeeds -- which ruins the beat.
# PAGE     docs/database/demo.md - Increment 2, step 15
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
# WHAT     Same query again, on the good database. Re-establishes the starting point after
#          the break, for you and for the room.
# SAY      "Same problem as before lunch -- I want to stop carrying this column. Same goal
#           as the change that lost us the data. Different method."
# EXPECT   Populated ShirtNumber rows.
# IF STUCK Empty -> you are on the throwaway from 2a. Change $db and re-run region 05.
# PAGE     docs/database/demo.md - Increment 3, step 16
Invoke-DbaQuery @queryParams
#endregion


#region 19 · Increment 3 Option A - preserve the data                               [~35s]
# WHAT     A pre-deploy script stashes the values before the schema change drops the
#          column; a post-deploy step lands them in the new one afterwards.
# SAY      "SqlPackage runs pre-deploy, then the schema change, then post-deploy. Which
#           means you cannot write to the new column in pre-deploy -- it does not exist
#           yet. We got that wrong first time and the error is Msg 207. It is in the notes."
# EXPECT   Build succeeds, 0 warnings.
# IF STUCK Full rationale is in database/demo/ship-changes/increment-3_safe-retire.md.
#          Read it before the dry run, not on stage.
# PAGE     docs/database/demo.md - Increment 3, Option A, steps 17-18
New-Item -ItemType Directory -Path .\Scripts\PreDeployment -Force | Out-Null
Copy-Item ..\demo\ship-changes\increment-3_Player.sql              .\Tables\Player.sql -Force
Copy-Item ..\demo\ship-changes\increment-3_Migrate-ShirtNumber.sql .\Scripts\PreDeployment\Migrate-ShirtNumber.sql -Force
Copy-Item ..\demo\ship-changes\increment-3_Seed.sql                .\Scripts\PostDeployment\Seed.sql -Force
Copy-Item ..\demo\ship-changes\increment-3A_FabConFootball.sqlproj .\FabConFootball.sqlproj -Force
dotnet build FabConFootball.sqlproj --configuration Release -warnaserror
#endregion


#region 20 · Increment 3 Option A - report, publish, verify                        [~4m30s]
# WHAT     The report STILL flags the drop, because the schema step really does drop the
#          column. What changed is that the data was already copied out first.
# SAY      "Same alert as the change that lost the data. Same flag on the publish, even.
#           The difference is not the command -- it is that I did the work first, and I
#           know what I am agreeing to. That is what a considered decision looks like, and
#           it looks almost identical to a reckless one. Which is the point of the gate."
# EXPECT   DataIssue alert in the report; publish succeeds; SquadNumber holds the old shirt
#          numbers (Saka 7, Palmer 10).
# IF STUCK Token expired -> region 05.
# PAGE     docs/database/demo.md - Increment 3, Option A, steps 19-21
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
# WHAT     The refactorlog records that this is a RENAME, so SqlPackage emits sp_rename
#          instead of drop-and-add. No pre-deploy script. No data movement at all.
# SAY      "Option A is the general pattern -- it works for any change that has to move
#           data. But this particular change was only ever a rename, and if you tell the
#           tooling that, it does something much better."
# EXPECT   Build succeeds, 0 warnings.
# IF STUCK Note this replaces the .sqlproj again (3B, not 3A). If the build complains about
#          a missing pre-deploy script, the wrong .sqlproj is in place -- re-run the
#          Copy-Item lines.
# PAGE     docs/database/demo.md - Increment 3, Option B, steps 22-23
Copy-Item ..\demo\ship-changes\increment-3_Player.sql                 .\Tables\Player.sql -Force
Copy-Item ..\demo\ship-changes\increment-3_Seed.sql                   .\Scripts\PostDeployment\Seed.sql -Force
Copy-Item ..\demo\ship-changes\increment-3_FabConFootball.refactorlog .\FabConFootball.refactorlog -Force
Copy-Item ..\demo\ship-changes\increment-3B_FabConFootball.sqlproj    .\FabConFootball.sqlproj -Force
dotnet build FabConFootball.sqlproj --configuration Release -warnaserror
#endregion


#region 22 · Increment 3 Option B - the clean report                               [~4m00s]
# WHAT     Report, then publish under the SHIPPED profile with no override at all.
# SAY      "Empty Alerts. No override. The generated script says sp_rename, and the column
#           and its data are renamed in place. Same outcome as Option A, no data-loss
#           alert, and nobody had to be woken up to approve it."
# EXPECT   <Alerts /> empty; publish succeeds with NO /p: override; SquadNumber populated.
# IF STUCK If the report still shows a DataIssue, the refactorlog did not make it into the
#          build -- check that increment-3B (not 3A) is the .sqlproj in place.
# PAGE     docs/database/demo.md - Increment 3, Option B, steps 24-26
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
# WHAT     Talking beat, no command. A GitHub Environment required-reviewer rule holds the
#          deploy until a human has read the report.
# SAY      "Everything we have shown you says the same thing: make the change visible
#           before it happens. The gate is the last piece -- somebody has to say yes."
# EXPECT   Nothing runs.
# IF STUCK BE HONEST: this is documented, not wired on our repo. Required-reviewer rules
#          need a Team or Enterprise plan on a private repo (task #21). Say that. The
#          pattern is in database/demo/ship-changes/increment-3_safe-retire.md.
# PAGE     docs/database/demo.md - Increment 3, Gate the destructive deploy, step 27
code ..\demo\ship-changes\increment-3_safe-retire.md
#endregion


#region 99 · RESET -- run this, it matters more here than anywhere                  [~15s]
# WHAT     Puts database/sql-projects back. This demo OVERWRITES THREE TRACKED FILES --
#          Player.sql, Seed.sql and the .sqlproj -- and creates four more. Committing that
#          state breaks the demo for whoever runs it next. It has happened. Twice.
# SAY      Nothing. The room has gone home.
# EXPECT   `git status` reports a clean tree.
# IF STUCK Deliberately explicit rather than a blanket `git clean` -- a tidy-up that eats
#          somebody's unrelated work is a bad way to end the day. If you added files of
#          your own under sql-projects, they are safe.
# PAGE     (presenter only -- deliberately not on the attendee page)
git restore .\Tables\Player.sql .\Scripts\PostDeployment\Seed.sql .\FabConFootball.sqlproj
Remove-Item .\Views\vw_SquadAges.sql                        -ErrorAction SilentlyContinue
Remove-Item .\Views\vw_TeamRosterSizes.sql                  -ErrorAction SilentlyContinue
Remove-Item .\Scripts\PreDeployment\Migrate-ShirtNumber.sql -ErrorAction SilentlyContinue
Remove-Item .\FabConFootball.refactorlog                    -ErrorAction SilentlyContinue
Remove-Item .\deploy-report*.xml                            -ErrorAction SilentlyContinue
git status --short
#endregion
