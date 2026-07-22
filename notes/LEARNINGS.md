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

## 2026-07-18 — GitHub Pages deploy: artifact deployment, not the gh-pages branch
**Context:** Task #11 — the workflow that publishes the MkDocs Material site so attendees
can read it. `ci.yml` already builds the docs `--strict`; this adds the actual deploy.
**Learning:** Used the **modern GitHub Pages artifact deployment** (`actions/configure-pages`
+ `actions/upload-pages-artifact` + `actions/deploy-pages`) rather than the older
`mkdocs gh-deploy` that force-pushes a `gh-pages` branch. The artifact path gives a proper
`github-pages` deployment environment with the live URL surfaced on the run, needs no branch
juggling, and keeps history clean. It requires `permissions: pages:write` **and**
`id-token: write` (OIDC) — miss the id-token and the deploy step fails. Kept it a **separate
workflow** from `ci.yml` (validation vs. deploy are different concerns) and gated it to
`main` pushes touching `docs/**`, `mkdocs.yml`, `requirements.txt`, or the workflow itself.
Gotcha, still "nothing is clicked": the Pages **source** must be set to *GitHub Actions*
once — but that's doable in code via `gh api -X POST repos/<owner>/<repo>/pages -f
build_type=workflow`, documented in the workflow header. Verified `mkdocs build --strict`
exits 0 locally (the scary "MkDocs 2.0" banner from the Material team is informational, not a
build failure).
**Action:** Added [`../.github/workflows/pages.yml`](../.github/workflows/pages.yml).
Task #11 → DONE. Next docs step: fill in `site_url` in `mkdocs.yml` once the Pages URL is
live, and expand the `nav`.

## 2026-07-18 — Pages sites are public even from a private repo; teaser via exclude_docs
**Context:** Wanted a public **teaser** page live now but to hold the real workshop content
until a reveal date. Repo is private.
**Learning:** A **GitHub Pages site is public even when the repo is private** — on standard
plans, enabling Pages publishes to a public URL anyone can reach (only GitHub Enterprise
Cloud can access-control a Pages site). So you can't password-hide it; the best is an
*unlisted* URL. You **can** control *what content* ships, in code: MkDocs 1.6's top-level
`exclude_docs:` (gitignore-style globs) omits pages from the built site while leaving them in
the repo on `main` — and, crucially, `mkdocs build --strict` stays green because excluded
pages don't trip the "exists but not in nav" check (they must also be removed/commented from
`nav`, or nav errors on the missing file). Verified: with `database/sample-database.md`
excluded, `mkdocs build --strict` publishes only `index.html` (+ auto `404.html`).
**Reveal = a one-PR diff:** delete the `exclude_docs` block and un-comment the nav entries.
**Action:** "Teaser mode" wired in [`../mkdocs.yml`](../mkdocs.yml) (documented block) with
[`../docs/index.md`](../docs/index.md) reworked into a teaser. Content pages stay on `main`,
held back until reveal.

## 2026-07-22 — Azure SQL apply/destroy workflows: personal-sandbox state backend + Git Bash gotcha
**Context:** Task #9/#17 — wanted GitHub Actions workflows to `terraform apply` the Azure
SQL module into Jess's personal sub, plus a nightly `terraform destroy` (21:00 UK, "we like
to go to bed then") so nothing bills overnight. Needed remote state so apply and destroy —
separate ephemeral runners — see the same state.
**Learning 1 — keep the state storage account out of the workload RG.** The state backend
(`stfabcon26tf4766a4`) lives in its own persistent `rg-fabcon26-state-weu`, never in the
`rg-fabcon26-dev-weu` that `terraform destroy` tears down nightly. Obvious in hindsight, but
worth stating: if the destroy target and the state store shared a resource group, the first
nightly run would delete its own backend.
**Learning 2 — two cron entries means two runs a day, not one.** First tried covering DST
by registering **two** cron triggers (20:00 and 21:00 UTC, one per UK offset) with a gate
step that skipped whichever one didn't land at 21:00 `Europe/London`. That does work, but
it means the workflow **fires twice every day** — one run always a no-op — which is more
confusing in the Actions history than it's worth for a personal sandbox. Settled on a
single fixed **21:00 UTC** cron instead: one run a day, genuinely 9pm in winter (GMT) and
10pm in summer (BST). Worth remembering for anything less forgiving of the drift.
**Learning 3 — Git Bash mangles leading-slash args.** `az role assignment create --scope
"/subscriptions/<id>"` failed with a cryptic `MissingSubscription` error — MSYS/Git Bash's
path conversion was rewriting the `/subscriptions/...` argument as if it were a Windows path
before `az` ever saw it. Fix: prefix the command with `MSYS_NO_PATHCONV=1`. Applies to any
`az`/`gh`/CLI argument that starts with `/` when run from this repo's Bash tool.
**Learning 4 — OIDC federated credential subject matching.** The federated credential
subject `repo:<owner>/<repo>:ref:refs/heads/main` covers both `schedule` events and
`workflow_dispatch` runs launched from `main` (both evaluate to that ref) — no separate
`environment:` subject needed for this simple case.
**Action:** Added [`../.github/workflows/azure-sql-apply.yml`](../.github/workflows/azure-sql-apply.yml)
and [`../.github/workflows/azure-sql-destroy.yml`](../.github/workflows/azure-sql-destroy.yml).
Backend + OIDC wired into `infra/azure-sql/terraform/providers.tf`; `.terraform.lock.hcl`
un-ignored and committed. Repo variables set (`AZURE_CLIENT_ID`, `AZURE_TENANT_ID`,
`AZURE_SUBSCRIPTION_ID`, `TF_STATE_*`, `SQL_ENTRA_ADMIN_*`) — all non-secret with OIDC, so
`vars` not `secrets`. Recorded in `notes/decisions.md` D5 (update) and `planning/tasks.md`
#9/#17. First live `apply` still to be run — task #14.

## 2026-07-22 — Azure Sponsorship subs can be region-restricted below what the RP advertises
**Context:** First real `azure-sql-apply.yml` run (task #14). Resource group created fine
in West Europe, then `azurerm_mssql_server` failed: `ProvisioningDisabled — Subscriptions
are restricted from provisioning in this region`.
**Learning:** `az provider show --namespace Microsoft.Sql` lists West Europe as a perfectly
valid region for `Microsoft.Sql/servers` — that list is the **resource provider's**
supported regions, not a promise that *your subscription* can provision there. This
particular subscription is `quotaId: Sponsored_2016-01-01` (Azure Sponsorship), and new/
sponsorship subscriptions are commonly region-restricted (often exactly the popular EU
regions) independent of RP or quota. There's no clean CLI query for "which regions can
*this* subscription actually provision in" — the practical check is just: try, read the
error. No resources were actually created in Azure before the error (confirmed via `az
resource list` on the resource group — empty), so nothing needed cleaning up beyond the
now-pointless empty resource group.
**Action:** Added `AZURE_LOCATION`/`AZURE_LOCATION_ABBREVIATION` repo variables (`uksouth`/
`uks`) and wired them as `-var` overrides into both `azure-sql-apply.yml` and
`azure-sql-destroy.yml`, rather than changing the module's own default (`westeurope` stays
the documented/taught default — this restriction is specific to this one sandbox
subscription, not the module). Ran `azure-sql-destroy.yml` once to clear the empty
West Europe resource group before switching regions.

<!-- Add new entries above this line -->
