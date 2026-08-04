# Demo — Ship database changes as code (15:30 module)

The reproducible demo for **CI/CD part 3 — ship database changes automatically**. Design +
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
  /DeployReportPath:"deploy-report.xml"
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
Invoke-Sqlcmd -ServerInstance $server -Database $db -AccessToken $token -EncryptConnection `
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

Follow [`increment-3_safe-retire.md`](increment-3_safe-retire.md): preserve the data with a
**pre-deploy migration** (Option A) or model it as a **rename** so SqlPackage emits `sp_rename`
(Option B, zero data movement) — then ship the deploy behind a **GitHub Environment
required-reviewer gate**. The DeployReport now shows no data-loss alert (A/B preserved it), and
a human still approves the promotion to Test.

---

## Presenter / timing notes
- Order = 1 → 2 → 3. **Increment 2 is the punchline** — pause on the silent-loss moment before
  showing the guard.
- Each segment has a hard "we move on" time (agenda timing discipline); the increment files are
  the checkpoints, so anyone following along on their own kit can catch up.
- **Wiring this into the pipeline** (a `deploy-report` job that posts the plan on the PR, the
  Dev→Test promotion with the approval gate, and a throwaway naive-publish for 2a) is the
  remaining build — see [task #21](../../../planning/tasks.md).
