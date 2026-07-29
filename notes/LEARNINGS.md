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

## 2026-07-18 — Fabric SQL Terraform module: two providers, capacity→workspace→database
**Context:** Task #5 — the Fabric SQL infra module, the "side by side" partner to the Azure
SQL module (#4).
**Learning:** Fabric SQL needs **two providers**, not one. The **capacity** is an *Azure*
resource — `azurerm_fabric_capacity` (`Microsoft.Fabric/capacities`, added to azurerm in
**v4.14**, so pin `~> 4.14` not `~> 4.0`) — while the **workspace** and **SQL database** are
Fabric items managed by the **`microsoft/fabric`** provider (~> 1.12, needs Terraform
>= 1.8) over the Fabric REST APIs. So the shape is **capacity → workspace → database**, where
Azure SQL is **server → database**. Gotchas that cost a validate cycle: (1) a Fabric capacity
name is **lowercase-alphanumeric only** (`^[a-z][a-z0-9]*$`, no hyphens), so it can't take the
hyphenated CAF form — build it from the tokens minus separators. (2) On `fabric_sql_database`
the connection details are **nested under a computed `properties` object**
(`properties.database_name` / `.server_fqdn` / `.connection_string`), *not* top-level
attributes — the registry docs page implied top-level and `validate` caught it; confirm
against `terraform providers schema -json`. Both providers are **passwordless** (reuse
`az login`; OIDC/SP in CI). `fmt`/`init`/`validate` are clean against the real schemas; no
live `plan`/`apply` (needs a real capacity — #14). The `fabric_sql_database` resource can also
deploy a `.sqlproj`/DACPAC directly via `definition`/`format` — noted as a future alternative,
but we keep the SqlPackage path for symmetry with Azure SQL.
**Action:** New module [`../infra/fabric-sql/terraform/`](../infra/fabric-sql/terraform/)
(`providers/variables/main/outputs.tf` + `terraform.tfvars.example`, README rewritten). Task
#5 → DONE. Reinforces the earlier flag to **commit `.terraform.lock.hcl`** — doubly true for
the fast-moving preview Fabric provider (still gitignored today; revisit with #17). Next: a
terraform `fmt`/`validate` CI job (#8) now covers both #4 and #5.

## 2026-07-18 — Attendee sandbox decided: bring-your-own (unblocks the prerequisites)
**Context:** Task #1 — the sandbox strategy that gates the prerequisites page (#2) and the tf
state backend owner (#17). Settled in a Jess + Rob chat.
**Learning:** We go **bring-your-own** — no per-attendee sandboxes. The hands-on is **two
independent parts**: IaC (needs the attendee's own Azure sub) and DB-deploy (needs a target
SQL), each optional depending on what they bring, plus **one shared SQL endpoint on the day
that we explicitly won't support**. The driver was support cost: "we can't spend a lot of time
troubleshooting labs, and if we provide something they'll expect that." Knock-on effects: it
**unblocks #2**, and it **defuses most of #17** — there's no shared attendee state account to
own (attendees use local state); only *our* CI/demo state backend still needs an owner.
**Shared endpoint resolved:** it's a **SQL Server on a VM** attendees push to via pipeline —
a database per attendee on one instance, so no DACPAC name collisions (task #19). **Deferred
("decide later"):** the Fabric IaC path's capacity cost (an F-SKU bills; a trial capacity
can't be TF-created), and *our* CI/demo state owner (#17) — both open caveats, neither blocks
the prereqs page.
**Action:** Recorded as [`decisions.md`](decisions.md) **D6**; prereq checklist + shared-endpoint
TODO in [`../planning/ordering.md`](../planning/ordering.md); tasks #1 → DONE, #2 unblocked,
#17 note updated, new #19 (shared VM target). CLAUDE.md §2 unchanged (D6 is an operational
decision, not a scope change).

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

## 2026-07-29 — First live Azure SQL apply succeeded in UK South; DACPAC publish job added
**Context:** Re-ran `azure-sql-apply.yml` after merging the region override (PR #11), then
wired the DB-as-code publish step onto the same workflow (tasks #9/#14).
**Learning 1 — the region override worked, single-region as designed.** Run
[`30436925832`](https://github.com/JessAndRob/FabConEU_2026_workshop/actions/runs/30436925832)
went green: **5 resources added** in **UK South** — `rg-fabcon26-dev-uks`,
`sql-fabcon26-dev-uks-lmf5m4` (+ DB `sqldb-football-dev`, allow-Azure-services firewall
rule, random suffix). RG ~24s, server ~1m24s, DB ~2m6s, whole run 4m36s. Confirms the
module is single-region: the DB inherits the server's location which inherits the RG's
`var.location`, so one `location`/`location_abbreviation` pair moves everything together —
there was never a cross-region split, just a half-finished apply on the earlier WEU failure.
**Learning 2 — Entra-only server + human admin blocks CI publish (the real gotcha).** The
server is `azuread_authentication_only = true` with the Entra admin set to a **user**
(`jpomfret7`). A logical SQL server allows exactly **one** Entra admin (user *or* group),
so the GitHub Actions OIDC service principal (`AZURE_CLIENT_ID`) has **no way to log into
the database** — it isn't the admin and, with SQL auth disabled, can't be a SQL login
either. The DACPAC publish job authenticates fine (OIDC → `az account get-access-token
--resource https://database.windows.net/` → SqlPackage `/AccessToken`) but will fail at the
**database login** until the CI principal is granted access. Recommended fix (matches the
module's own advice): make the server's Entra admin an **Entra group** containing both the
presenter and the CI SP, and point `SQL_ENTRA_ADMIN_OBJECT_ID` at the group. Tracked as
task #18.
**Learning 3 — publish wired as a second job on the apply workflow.** The apply job now
exposes `sql_server_fqdn`/`sql_database_name` as job outputs (`terraform output -raw` →
`$GITHUB_OUTPUT`); the `publish` job `needs: apply` and targets them, so one dispatch does
infra + DB. SqlPackage on the Linux runner installs via `dotnet tool install -g
microsoft.sqlpackage` (add `$HOME/.dotnet/tools` to `$GITHUB_PATH`). The token is masked
(`::add-mask::`) — nothing secret persists.
**Action:** Extended [`../.github/workflows/azure-sql-apply.yml`](../.github/workflows/azure-sql-apply.yml)
with the `publish` job. Tasks #9/#14 advanced, #18 added for the CI-SP DB-access
prerequisite. **The publish job is unverified end-to-end** until #18 is done.

## 2026-07-29 — End-to-end "infra + DB as code" verified: Entra group admin unblocks CI publish
**Context:** Closing the #18 auth gap so the DACPAC publish job (#9) could run for real.
**Learning — an Entra *group* as the SQL server admin is what makes passwordless CI
publish work.** Created group `fabcon26-sql-admins`, added the presenters **and** the CI
service principal, then pointed the server's Entra admin at the group (via the
`SQL_ENTRA_ADMIN_LOGIN`/`SQL_ENTRA_ADMIN_OBJECT_ID` repo vars → `terraform apply`, a clean
`1 changed` in-place update of the `azuread_administrator` block). Because the CI SP is now
a *member* of the admin group, its OIDC token authenticates against the DB with no SQL
login and no secret. Two gotchas worth repeating: (1) group membership needs the CI
principal's **service-principal object id** (`az ad sp show --id <appId> --query id`), which
is **not** the app/client id in `AZURE_CLIENT_ID`; (2) a logical SQL server allows exactly
one Entra admin, so a *group* is the only way to admin-grant more than one identity — this
is the reusable pattern for attendees too (one workshop group, everyone in it).
**Result:** Re-ran `azure-sql-apply.yml` (run
[`30441294528`](https://github.com/JessAndRob/FabConEU_2026_workshop/actions/runs/30441294528))
— both jobs green: `apply` 58s, `publish` 1m26s. SqlPackage reported **"Successfully
published database"**, creating all 9 tables + indexes/FKs/checks, 3 views, 3 procs, and
running the post-deploy seed — into `sqldb-football-dev` on `sql-fabcon26-dev-uks-lmf5m4`,
passwordless. First full infra→schema deploy of the workshop's content-focus path.
**Action:** Tasks #9 and #18 → DONE; #14 → Azure SQL side verified at deploy level (Fabric
SQL still open). No file changes — the publish job already shipped in PR #12.

## 2026-07-29 — Post-publish DB smoke test; and two auth/network gotchas testing it
**Context:** Optional polish after the end-to-end deploy — add a data-level smoke test to
the publish job and clear the Node 20 action-deprecation warnings.
**Learning 1 — action bumps to clear the Node 20 warnings.** `hashicorp/setup-terraform@v3`
and `azure/login@v2` both emitted "Node.js 20 is deprecated … forced to run on Node.js 24".
The fix is just newer majors: **`setup-terraform@v4`** (v4.0.1, Feb 2026) and
**`azure/login@v3`** (v3.0.0, Mar 2026), both Node-24 native. Bumped in the apply + destroy
workflows.
**Learning 2 — the OIDC federated credential only trusts `main`, so deploy workflows can't
be test-run from a branch.** Dispatching `azure-sql-apply.yml` on a feature branch fails at
`terraform init` with `AADSTS700213: No matching federated identity record found for
presented assertion subject 'repo:…:ref:refs/heads/<branch>'`. The credential subject is
`repo:JessAndRob/FabConEU_2026_workshop:ref:refs/heads/main` (see the 2026-07-22 entry), and
the OIDC subject for a branch run is that branch's ref — no match, no token. Practical
consequence: **these workflows can only be verified after merging to `main`** (or by adding
a branch/environment federated credential, which we deliberately don't for a sandbox).
**Learning 3 — GitHub-hosted runners pass `AllowAzureServices`, external clients don't.**
The server's only firewall opening is the `0.0.0.0` "allow Azure services" rule. That's why
the publish job connects fine — **GitHub-hosted runners run on Azure**, so they count as an
Azure service. A developer machine (or this agent's sandbox IP) is *not* Azure-internal and
gets `Client with IP address '…' is not allowed to access the server`, even with a valid
Entra token (the login is accepted; the network ACL is what blocks). To smoke-test from
outside, add a temporary `az sql server firewall-rule create` for your IP and remove it
after.
**Learning 4 — the smoke test itself.** A `pwsh` step installs the `SqlServer` module and
uses `Invoke-Sqlcmd -AccessToken` (reusing the publish job's Entra token — no new secret) to
assert the deployed schema *serves data*: rows from `Club`, `Fixture`, `vw_LeagueTable`,
`vw_TopScorers`, and `usp_GetLeagueTable` (called with a competition/season pulled from the
league-table view). `vw_UpcomingFixtures` is executed but not row-asserted — it's
date-relative (`GETDATE()`), so it can legitimately be empty as seeded fixtures age.
**Verified against the live UK South DB** (via a temporary firewall rule): all checks OK,
proc returned a 2-row table. The in-pipeline run is pending a merge to `main` (Learning 2).
**Action:** Bumps + smoke-test step in
[`../.github/workflows/azure-sql-apply.yml`](../.github/workflows/azure-sql-apply.yml) and
the setup-terraform bump in
[`../.github/workflows/azure-sql-destroy.yml`](../.github/workflows/azure-sql-destroy.yml).
Confirms task #14's Azure SQL side at the data level.

## 2026-07-29 — Plan on PR (read-only), apply stays manual — needs a `pull_request` FIC
**Context:** The only Azure SQL infra workflow was `azure-sql-apply.yml` — a manual apply
whose very name reads as dangerous — and there was no way to see an infra change's effect
before merging. Added a read-only check (chosen over a tag-based apply credential).
**Learning — the idiomatic split is *plan on PR, apply on intent*, and each ref-context
needs its own OIDC federated credential.** New `azure-sql-plan.yml` runs
`fmt`/`validate`/`plan` — **never apply** — on `pull_request` events touching
`infra/azure-sql/**`, so reviewers see the plan in the PR checks; provisioning stays a
deliberate `workflow_dispatch` apply from `main`. The catch that makes this non-obvious: a
`pull_request` run's OIDC subject is `repo:<owner>/<repo>:pull_request`, which the existing
`…:ref:refs/heads/main` credential does **not** cover — so plan needs a *second* federated
credential (`fabcon26-github-pr`, subject `…:pull_request`) on the same app registration.
Read-only details: plan uses **`-lock=false`** (a plan never mutates state, so it must not
contend for the state lock with a running apply/destroy) and reads the same remote state
key, so it reports true drift. Verified green on its own PR (#15) — *"No changes. Your
infrastructure matches the configuration."* (the DB was still up from the earlier apply).
Security note: the `pull_request` credential lets any same-repo PR mint a token with the
app's `Contributor` rights — fine for a private repo with trusted collaborators; a scoped
read-only identity is the hardening step if the repo ever opens up. A **tag**-based
credential was considered and rejected: it would only add another way to run *apply* from
outside `main`, which doesn't address the safety concern — plan-on-PR does.
**Action:** Added [`../.github/workflows/azure-sql-plan.yml`](../.github/workflows/azure-sql-plan.yml)
and the `fabcon26-github-pr` federated credential; recorded in `decisions.md` D5 (update).
Resolves the "scary apply" concern and, for the read path, the branch-can't-authenticate
limitation noted in the smoke-test entry above.

## 2026-07-29 — Bicep reference modules: Azure SQL mirrors fully, Fabric can only do the capacity
**Context:** Task #6 — the Bicep reference variant of the infra ("all as code": every tooling
variant exists even though the taught content leads with Terraform).
**Learning 1 — Azure SQL maps cleanly to Bicep, with a few ARM-vs-Terraform seams.** A
subscription-scoped `main.bicep` creates the RG and calls an RG-scoped `sql.bicep`
(server + serverless DB + firewall) — the idiomatic Bicep shape for "make the RG too".
Passwordless is `Microsoft.Sql/servers` `properties.administrators` with
`azureADOnlyAuthentication: true` and **no** SQL admin login. Seams worth noting: (a) Bicep
has **no decimal type**, so `minCapacity` (0.5) is passed as a string and converted with
`json()`; (b) the globally-unique server suffix is `take(uniqueString(resourceGroup().id), 6)`
(the deterministic stand-in for Terraform's `random_string`); (c) the DB `sku` is verbose
(`name`/`tier`/`family`/`capacity`) where Terraform takes a single `sku_name`, so a
provisioned SKU needs matching tier/family/capacity; (d) firewall loop uses
`items(allowedClientIps)` over the map.
**Learning 2 — Fabric SQL can NOT be fully done in Bicep, and that's the teaching point.**
Only the **capacity** is an ARM resource (`Microsoft.Fabric/capacities`). The **workspace**
and the **SQL database in Fabric** are Fabric control-plane items with **no ARM resource
type at all** — Bicep/ARM simply can't create them. So the Fabric Bicep provisions the
capacity only and documents the gap; the full `capacity → workspace → database` stack needs
the Terraform `microsoft/fabric` provider (#5) or the Fabric REST API/CLI. This is exactly
why the taught IaC path is Terraform, not Bicep, for Fabric.
**Learning 3 — validate Bicep offline with `az bicep build`.** `az bicep build --file x.bicep`
compiles to ARM JSON with no Azure connection (install once via `az bicep install`);
`az bicep build-params` validates a `.bicepparam`. All four templates + both param files
compile clean with **zero linter warnings**. `az deployment sub what-if` is the next step up
(needs Azure) for a real preview.
**Action:** Added [`../infra/azure-sql/bicep/`](../infra/azure-sql/bicep/) (`main.bicep`,
`sql.bicep`, `main.bicepparam`) and [`../infra/fabric-sql/bicep/`](../infra/fabric-sql/bicep/)
(`main.bicep`, `capacity.bicep`, `main.bicepparam`); both READMEs rewritten. Task #6 → DONE.
Live deploy still tracked by #14.

## 2026-07-29 — Azure DevOps reference pipelines: WIF is the OIDC equivalent
**Context:** Task #10 — the Azure DevOps reference variant of the CI/CD pipelines ("all as
code"; taught path stays GitHub Actions).
**Learning — the passwordless story ports cleanly, the mechanics differ.** Where GitHub
Actions uses **OIDC federated credentials**, Azure DevOps uses an **ARM service connection
configured for workload identity federation (WIF)** — same "no secrets" outcome. The bridge
to Terraform: `AzureCLI@2` with **`addSpnToEnvironment: true`** exposes `$servicePrincipalId`,
`$idToken`, `$tenantId` to the inline script, which exports them as `ARM_CLIENT_ID` /
`ARM_OIDC_TOKEN` / `ARM_TENANT_ID` + `ARM_USE_OIDC=true` — Terraform then auths exactly like
in CI on GitHub. Other mappings worth noting: GH repo **variables** → an ADO **variable
group** (`fabcon26-azure-sql`); `workflow_dispatch` → `trigger: none` + manual run; GH `cron`
→ ADO `schedules:` (also UTC) with **`always: true`** (ADO skips scheduled runs with no new
commits otherwise); job-to-job `outputs` → `##vso[task.setvariable ...;isOutput=true]` read
downstream via `stageDependencies.<Stage>.<job>.outputs['<step>.<var>']`; adding a dir to
`$PATH` → `##vso[task.prependpath]`. Terraform is preinstalled on the hosted `ubuntu-latest`
image (or pin via the `TerraformInstaller@1` extension task). The DACPAC publish + smoke test
reuse the same Entra-token approach as GHA. **Not executed** — no ADO org in this repo — but
all four YAML files parse and follow the schema; GitHub Actions remains the live-verified path.
**Action:** Added [`../infra/pipelines/azure-devops/`](../infra/pipelines/azure-devops/)
(`ci.yml`, `azure-sql-plan.yml`, `azure-sql-apply.yml`, `azure-sql-destroy.yml`) + README.
Task #10 → DONE.

<!-- Add new entries above this line -->
