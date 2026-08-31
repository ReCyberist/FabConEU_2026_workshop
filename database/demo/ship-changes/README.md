# Demo — Ship database changes as code (afternoon sections)

The reproducible demo for the **afternoon "ship database changes" story** — increments 1–2 in
Afternoon 1 (14:00–15:15) and increment 3 in Afternoon 2 (15:45–17:00) of the
[agenda](../../../agenda/agenda.md). Design +
rationale live in [`planning/ship-changes-increments.md`](../../../planning/ship-changes-increments.md);
this folder is the runnable version.

> **No provided lab — follow along on your own kit if you have it, or just watch.** Everything
> here is a live demo the presenter drives; attendees with their own Azure SQL / Fabric SQL
> target can follow along, and everyone can replay it later from the repo. See
> [D6](../../../notes/decisions.md).

**Thesis:** a database change is a **pull request**, and the pipeline shows you *exactly what it
will do to your data before it does it* — the DB's answer to `terraform plan`, via
`sqlpackage /Action:DeployReport`. Additive changes flow automatically; destructive ones stop
for a human.

**Setup:** two environments, **Dev** and **Test**; **Test holds seeded data** (`ShirtNumber`
is populated), so data loss is real and visible. Same flow on **Azure SQL** and **Fabric SQL**
— only the publish profile differs (Fabric is gated on a capacity — [issue #20](../../../notes/decisions.md)).

All commands run from `database/sql-projects/` in **PowerShell**. First, a token + target:

```powershell
cd database/sql-projects
$token  = az account get-access-token --resource https://database.windows.net/ --query accessToken -o tsv
$server = "sql-fabcon26-dev-uks-XXXXXX.database.windows.net"   # from `terraform output`, or the Fabric connection page
$db     = "sqldb-football-dev"
dotnet build FabConFootball.sqlproj --configuration Release -warnaserror   # builds bin/Release/FabConFootball.dacpac
```

Swap `AzureSql.publish.xml` → `FabricSql.publish.xml` (and a `…database.fabric.microsoft.com,1433`
server) for the Fabric run — the Fabric profile already carries `AllowIncompatiblePlatform` +
`ExcludeObjectTypes` (see [task #20](../../../planning/tasks.md)).

---

## Increment 1 — additive change (safe, automatable)

Add [`increment-1_vw_SquadAges.sql`](increment-1_vw_SquadAges.sql) as
`Views/vw_SquadAges.sql`, rebuild, then **get the DB plan**:

```powershell
sqlpackage /Action:DeployReport `
  /SourceFile:"bin/Release/FabConFootball.dacpac" `
  /Profile:"PublishProfiles/AzureSql.publish.xml" `
  /TargetServerName:$server /TargetDatabaseName:$db /AccessToken:$token `
  /OutputPath:"deploy-report.xml"
```

The report lists *one view to create* and **no `DataIssue` alerts** → safe. Publishing is the
same automated step the pipeline runs; it just works. **This is the confidence-builder** —
invite attendees to do this one on their own target.

---

## Increment 2 — destructive change (the trap)

Apply [`increment-2_drop-shirtnumber.md`](increment-2_drop-shirtnumber.md) (drop the populated
`Player.ShirtNumber`) **bundled** with the harmless
[`increment-2_vw_TeamRosterSizes.sql`](increment-2_vw_TeamRosterSizes.sql), rebuild. Show the
data is there first:

```powershell
Invoke-DbaQuery -SqlInstance $server -Database $db -AccessToken $token `
  -Query "SELECT TOP (5) PlayerId, ShirtNumber FROM football.Player WHERE ShirtNumber IS NOT NULL"
```

Now the two paths, back to back:

**2a — YOLO (the anti-pattern).** Force it through, ignoring the guard:

```powershell
sqlpackage /Action:Publish /SourceFile:"bin/Release/FabConFootball.dacpac" `
  /Profile:"PublishProfiles/AzureSql.publish.xml" `
  /TargetServerName:$server /TargetDatabaseName:$db /AccessToken:$token `
  /p:BlockOnPossibleDataLoss=false      # <-- the mistake
```

Re-run the `SELECT` → the column (and its data) is **silently gone**. *"This is why you can't
just publish the DACPAC and hope."*

**2b — the guard we already ship.** The [publish profiles](../../sql-projects/PublishProfiles/)
set `BlockOnPossibleDataLoss=True`, so the *same* publish **without** the override:

```powershell
sqlpackage /Action:Publish /SourceFile:"bin/Release/FabConFootball.dacpac" `
  /Profile:"PublishProfiles/AzureSql.publish.xml" `
  /TargetServerName:$server /TargetDatabaseName:$db /AccessToken:$token
```

…**fails loudly** — *"…blocked because the operation could result in data loss"* — and Test is
untouched. And the DeployReport above already flagged it on the PR (`<Alert Name="DataIssue">`).

---

## Increment 3 — retire it *safely* (the right way)

Same goal as Increment 2 — stop carrying `ShirtNumber` — but **without losing data**. Two
techniques, both shipped as runnable files; design and rationale are in
[`increment-3_safe-retire.md`](increment-3_safe-retire.md). Both replace `Player.ShirtNumber`
with `Player.SquadNumber` and share the same seed
([`increment-3_Seed.sql`](increment-3_Seed.sql), which populates `SquadNumber`).

> **Start from a populated database.** Increment 3 needs `ShirtNumber` present *and populated*.
> Run Increment 2's destructive forced-publish against a **throwaway** database and keep your main
> Test database intact — or publish the baseline DACPAC to a **fresh** database and use that.
> Re-publishing the baseline over a database that already had the column dropped will **not**
> refill it: the seed only inserts missing rows, it does not update existing ones.

### Option A — preserve the data with a pre-deploy migration (the general pattern)

For any change that genuinely moves or transforms data, not only a rename. A **pre-deploy**
script stashes the old values *before* the schema change drops the column; a **post-deploy**
step lands them in the new column *after*. (SqlPackage runs pre-deploy → schema change →
post-deploy, and the new column does not exist until the schema step — so you cannot write to it
in pre-deploy. Full explanation in [`increment-3_safe-retire.md`](increment-3_safe-retire.md).)

```powershell
New-Item -ItemType Directory -Path .\Scripts\PreDeployment -Force | Out-Null
Copy-Item ..\demo\ship-changes\increment-3_Player.sql              .\Tables\Player.sql -Force
Copy-Item ..\demo\ship-changes\increment-3_Migrate-ShirtNumber.sql .\Scripts\PreDeployment\Migrate-ShirtNumber.sql -Force
Copy-Item ..\demo\ship-changes\increment-3_Seed.sql                .\Scripts\PostDeployment\Seed.sql -Force
Copy-Item ..\demo\ship-changes\increment-3A_FabConFootball.sqlproj .\FabConFootball.sqlproj -Force
dotnet build FabConFootball.sqlproj --configuration Release -warnaserror
```

The DeployReport **still flags the column drop** (`<Alert Name="DataIssue">`) — the schema step
really does drop `ShirtNumber`, and the migration preserves the *data*, not the column. So this
publish explicitly allows the drop — the *same* flag as Increment 2's YOLO, but a considered
decision because the data was already preserved:

```powershell
sqlpackage /Action:Publish /SourceFile:"bin/Release/FabConFootball.dacpac" `
  /Profile:"PublishProfiles/AzureSql.publish.xml" `
  /TargetServerName:$server /TargetDatabaseName:$db /AccessToken:$token `
  /p:BlockOnPossibleDataLoss=false
Invoke-DbaQuery -SqlInstance $server -Database $db -AccessToken $token `
  -Query "SELECT TOP (5) PlayerId, LastName, SquadNumber FROM football.Player WHERE SquadNumber IS NOT NULL"
```

`SquadNumber` holds the old shirt numbers (Saka 7, Palmer 10, …).

### Option B — model it as a rename (zero data movement, clean report)

When it is genuinely a rename, the **refactorlog** records the intent so SqlPackage emits
`sp_rename` instead of drop-and-add. No pre-deploy migration, no data-loss alert, and it
publishes under the shipped safe profile with **no override**:

```powershell
Copy-Item ..\demo\ship-changes\increment-3_Player.sql                .\Tables\Player.sql -Force
Copy-Item ..\demo\ship-changes\increment-3_Seed.sql                  .\Scripts\PostDeployment\Seed.sql -Force
Copy-Item ..\demo\ship-changes\increment-3_FabConFootball.refactorlog .\FabConFootball.refactorlog -Force
Copy-Item ..\demo\ship-changes\increment-3B_FabConFootball.sqlproj    .\FabConFootball.sqlproj -Force
dotnet build FabConFootball.sqlproj --configuration Release -warnaserror
```

The DeployReport is **clean** (`<Alerts />`), and the publish keeps the shipped profile as-is
(`BlockOnPossibleDataLoss=True` — no `/p` override). The generated script contains
`EXECUTE sp_rename … 'COLUMN'`; the column — and its data — is renamed in place.

### The gate (either option)

Ship the deploy behind a **GitHub Environment required-reviewer approval** so a human reads the
DeployReport before it lands. This is documented, not wired: required-reviewer rules need a Team
or Enterprise plan on private repos (the pattern is in
[`increment-3_safe-retire.md`](increment-3_safe-retire.md)).

> **Verified:** both file-sets **build** clean (`-warnaserror`, zero T-SQL analysis findings),
> and the deploy behaviour is confirmed **offline** by comparing the built DACPACs against the
> baseline DACPAC (`sqlpackage /Action:Script` and `/Action:DeployReport`): Option A → column
> drop with a `DataIssue` alert; Option B → `sp_rename` with an empty `<Alerts />`. A **live**
> publish to a real database is the remaining check — see [task #21](../../../planning/tasks.md).

---

## Presenter / timing notes
- Order = 1 → 2 → 3. **Increment 2 is the punchline** — pause on the silent-loss moment before
  showing the guard.
- Each segment has a hard "we move on" time (agenda timing discipline); the increment files are
  the checkpoints, so anyone following along on their own kit can catch up.
- **Wiring this into the pipeline** (a `deploy-report` job that posts the plan on the PR, the
  Dev→Test promotion with the approval gate, and a throwaway naive-publish for 2a) is the
  remaining build — see [task #21](../../../planning/tasks.md).
