# Learnings Log 🔁

**Keep this updated.** Newest entries at the top. One entry per learning — a gotcha, a
better command, a broken assumption, a demo-timing note, a tester's confusion. See the
learnings loop in [`../CLAUDE.md`](../CLAUDE.md) §7.

Format:

```
## YYYY-MM-DD — short title
**Context:** what we were doing.
**Learning:** what we found out.
**Action:** what changed as a result (file updated, decision changed, task added). Link it.
```

---

## 2026-07-01 — Repo scaffolded and decisions locked
**Context:** First pass setting up the repo as the source of truth for the workshop.
**Learning:** Agreed the "all as code, focus in content" rule — the repo carries every
tooling variant (Terraform + Bicep, GitHub Actions + Azure DevOps, SQL projects + Flyway +
dbatools/dbops) but the taught content leads with **Terraform + GitHub Actions + SQL
projects**, covering **both Azure SQL and Fabric SQL** side by side. Site is **MkDocs
Material** → GitHub Pages.
**Action:** Recorded in [`decisions.md`](decisions.md) and [`../CLAUDE.md`](../CLAUDE.md).
Scaffold created; content still to be written (see [`../planning/tasks.md`](../planning/tasks.md)).

## 2026-07-04 — Canonical football schema built (men's + women's) as a SQL project
**Context:** First real code — building the canonical sample database (task #3) as the
content-focus SQL project.
**Learning:** Modelling **both the men's and women's game** cleanly falls out of a shared
`Club` that fields multiple `Team`s tagged by `Category` (Men/Women), with `Competition`
also carrying a category. One schema, both games, no duplication. Landed 9 tables, 3 views,
3 stored procedures + an idempotent, set-based post-deploy seed (PL + WSL played fixtures
with goals; El Clásico fixtures upcoming). Builds clean to a DACPAC with
`Microsoft.Build.Sql` (SDK-style) on `dotnet build`.
**Action:** Schema in [`../database/sql-projects/`](../database/sql-projects/); README
updated. Task #3 → DONE, #7 advanced. Runtime deploy not yet tested (no local SQL engine) —
see task #14.

## 2026-07-04 — Fabric SQL database ≠ Fabric Warehouse for T-SQL surface area
**Context:** Making sure the canonical schema deploys to both Azure SQL and Fabric SQL.
**Learning:** Our target is **SQL database in Fabric** (transactional, Azure SQL-compatible)
— IDENTITY, enforced constraints, indexes, views, procs all work. This is *not* the Fabric
**Data Warehouse**, whose T-SQL surface is far smaller (no enforced constraints, no
triggers, no indexes, IDENTITY behaves differently). Real watch-items for our target: no
TDE/Always Encrypted/ledger/in-memory, no spaces in column names, PKs can't be
`hierarchyid`/`sql_variant`/`timestamp`, no CDC.
**Action:** Documented in [`fabric-sql-notes.md`](fabric-sql-notes.md); referenced from the
`.sqlproj`. Grounded against Microsoft Learn.

## 2026-07-04 — Sample DB documented with a Mermaid ER diagram; CI builds docs on change
**Context:** Wanted an attendee page describing the sample database, with an entity diagram.
**Learning:** Material for MkDocs renders ```mermaid fences once you add the `custom_fences`
mapping (class `mermaid`) under `pymdownx.superfences` — no extra JS needed. `erDiagram`
gives a clean crow's-foot ER diagram from the schema. Verified with `mkdocs build --strict`
(catches broken nav/links) and confirmed the rendered HTML carries a `class="mermaid"`
block. Extended `ci.yml` with a **docs** job that runs `mkdocs build --strict`, gated by
`dorny/paths-filter` so it only runs when `docs/**`, `mkdocs.yml` or `requirements.txt`
change — the SQL-only PRs don't pay for it, and vice-versa.
**Action:** New page [`../docs/database/sample-database.md`](../docs/database/sample-database.md);
`mkdocs.yml` nav + mermaid config; docs job in [`../.github/workflows/ci.yml`](../.github/workflows/ci.yml).

## 2026-07-04 — Pin the .NET SDK, or CI grabs the wrong one
**Context:** First CI run on the PR failed even though the SQL project built fine locally.
**Learning:** The `ubuntu-latest` runner had a **preinstalled .NET 10 SDK**, and
`dotnet build` used it despite `setup-dotnet` installing 8.0.x — `setup-dotnet` installs a
version but doesn't *force* selection. The `Microsoft.Build.Sql/0.2.0-preview` SDK can't
build under .NET 10 (missing NuGet.Build.Tasks.Pack import). Fix: a repo-root
`global.json` pinning `sdk.version` to 8.0 (`rollForward: latestMinor`), so local and CI
resolve the same SDK. Separately, the CI actions were bumped off the deprecated Node 20
runtime to current majors — `actions/checkout@v7`, `actions/setup-dotnet@v5`,
`actions/upload-artifact@v7` (all Node 24). Keep the workflow on these majors, not the old
`@v4`.
**Action:** Added [`../global.json`](../global.json); CI green. Any `dotnet`-based job we
add later inherits the same pin.

## 2026-07-04 — CI to validate our own code; SQL static analysis keeps it clean
**Context:** Rob asked for a GitHub Action that checks all our code, growing as we go.
Jess flagged that moderator **Cláudio Silva** (perf expert) will notice smells.
**Learning:** SDK-style SQL projects run **T-SQL static code analysis** in-build via
`-p:RunSqlCodeAnalysis=true` (baked into the `.sqlproj` so it's always on). Combined with
`dotnet build -warnaserror`, any smell or model warning fails CI. Current schema: **0
findings**. Gotcha: from Git Bash the MSBuild `/p:` switch gets path-translated — use
`-p:` (or run under PowerShell).
**Action:** Added [`../.github/workflows/ci.yml`](../.github/workflows/ci.yml) (database
build + analysis job today; terraform/bicep/docs jobs to follow). Code-quality bar added to
[`../CLAUDE.md`](../CLAUDE.md) §4. Task #8 advanced.

## 2026-07-08 — Publish profiles carry options, not secrets; SqlPackage validates them offline
**Context:** Finishing task #7 — publish profiles for the SQL project's two targets
(Azure SQL Database + SQL database in Fabric), with no live engine to deploy against.
**Learning:** A `.publish.xml` profile can hold the DACPAC deploy *options* while keeping
**no connection string**, so nothing secret is committed — the target server/DB and the
Microsoft Entra token are passed on the SqlPackage command line at publish time. Safe
defaults we bake in for both: `BlockOnPossibleDataLoss=True`, `DropObjectsNotInSource=False`
(don't wipe attendee-created objects), `CreateNewDatabase=False` (infra provisions the DB),
and — required for Fabric, harmless for Azure SQL — `ScriptDatabaseOptions=False` (the
platform owns DB-level options and rejects most `ALTER DATABASE`). You can validate a profile
**without a live DB**: `sqlpackage /Action:Script /SourceFile:<dacpac> /Profile:<xml>
/OutputPath:... /TargetConnectionString:"...Connect Timeout=2"` — SqlPackage loads and
validates every option name *before* it connects, so an unrecognised option fails at load
while a good profile fails only at the connection stage. Gotcha: don't point the probe at
`(localdb)\...` — it hangs trying to start an instance; use a fast-failing TCP host with a
short `Connect Timeout`.
**Action:** Added [`../database/sql-projects/PublishProfiles/`](../database/sql-projects/PublishProfiles/)
(`AzureSql.publish.xml`, `FabricSql.publish.xml`); README publish section rewritten with
per-target commands. Task #7 → DONE; live-target verify still tracked by #14.

## 2026-07-08 — Azure SQL Terraform module: CAF naming + passwordless, validates & plans clean
**Context:** Task #4 — the Azure SQL infra module (content-focus IaC), the thing that
provisions the server + database the DACPAC publishes into.
**Learning:** Reconciled two naming rules that pull in different directions: **CAF** wants
the resource-type abbreviation first (`rg-`, `sql-`, `sqldb-`), while CLAUDE.md wants a
`fabcon26-*` teardown prefix. Solution — keep the CAF type-abbreviation leading and use
`fabcon26` as the *workload token* inside the name (`rg-fabcon26-dev-weu`,
`sql-fabcon26-dev-weu-<rnd>`, `sqldb-football-dev`), so `*fabcon26*` still filters
everything. The **logical SQL server name is globally unique**, so a `random_string` suffix
is appended. Went **passwordless**: `azuread_authentication_only = true` lets you omit the
SQL admin login/password entirely (azurerm accepts no `administrator_login` when Entra-only)
— no secret to commit. `min_capacity`/`auto_pause_delay_in_minutes` only apply to serverless
SKUs, so they're set conditionally via `can(regex("_S_", sku))` — flipping to a provisioned
SKU won't error. Verified offline: `terraform fmt/validate` clean and `plan` produces a
coherent **5-to-add** plan (picked up cached az-CLI auth; no live apply — that's #14).
Best-practice flag: this repo **gitignores `.terraform.lock.hcl`**; HashiCorp recommends
**committing** it so CI/teammates resolve identical provider versions — worth revisiting.
**Action:** New module [`../infra/azure-sql/terraform/`](../infra/azure-sql/terraform/)
(`providers/variables/main/outputs.tf` + `terraform.tfvars.example`); README rewritten with
the naming + passwordless rationale. Task #4 → DONE; unblocks the deploy pipeline (#9). The
Fabric mirror (#5) and Bicep reference (#6) should follow the same naming.

## 2026-07-09 — Command examples are PowerShell, not bash
**Context:** Jess asked that every shell example in the repo use PowerShell.
**Learning:** The presenters run Windows and demo in PowerShell, so bash-fenced examples
(`cp`, `export`, `\` line-continuations) don't match what they'll type on stage. Standardised
on **PowerShell for all command examples** in docs, READMEs, and planning — cmdlets +
`$env:VAR` syntax, fenced ` ```powershell `. Cross-platform tools (dotnet, terraform,
sqlpackage, mkdocs, pip) run the same; only the shell glue changes.
**Action:** Added the rule to [`../CLAUDE.md`](../CLAUDE.md) §4; converted the bash fence in
`CONTRIBUTING.md`. The SQL-project and Terraform module READMEs are converted on their own
open PRs (they own those files).

<!-- Add new entries above this line -->
