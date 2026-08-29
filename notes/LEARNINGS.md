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

## 2026-08-29 — Presenter firewall IPs are GitHub secrets that go stale
**Context:** Reviewing the morning-of checklist (PR #43) before the workshop — specifically
what has to be true before dispatching `azure-sql-apply`.
**Learning:** The rules that let our laptops reach the Azure SQL server aren't hand-added on
the day — Terraform builds them as code from the `ROB_CLIENT_IP` / `JESS_CLIENT_IP` GitHub
**secrets** (`presenter_client_ips` in
[`azure-sql-apply.yml`](../.github/workflows/azure-sql-apply.yml)). They were set from home,
so in Barcelona they're stale, and apply won't re-open the firewall if you fix them *after*
running it. Secret **values can't be read back** — you can only `gh secret list` (names +
timestamps) — so "check they're current" really means "re-set them to today's egress IP."
**Action:** Added a "refresh the presenter IP secrets first" step to
[`../planning/morning-of-checklist.md`](../planning/morning-of-checklist.md) §1 and cross-linked
it from the §3 manual-firewall fallback (that manual `az` rule is now only for a skipped step
or a one-off third machine).

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

## 2026-07-29 — Fabric SQL CI/CD: verified the Fabric-specific bits against MS Learn, then built the pipeline
**Context:** Task #20 — the Fabric mirror of the Azure SQL pipeline (#9). Before writing it,
verified the three things that differ from Azure SQL against Microsoft Learn.
**Learning 1 — dual-provider OIDC.** The job needs *two* passwordless auths: `azurerm`
(`ARM_*`, for the `Microsoft.Fabric/capacities` resource + the state backend) **and** the
`microsoft/fabric` provider (`FABRIC_USE_OIDC=true` + `FABRIC_CLIENT_ID` + `FABRIC_TENANT_ID`).
In GitHub Actions the fabric provider **auto-detects** `ACTIONS_ID_TOKEN_REQUEST_URL/TOKEN`
(so `id-token: write` is all the extra wiring). Same OIDC app as Azure SQL — reuse
`AZURE_CLIENT_ID`/`AZURE_TENANT_ID`.
**Learning 2 — SqlPackage → Fabric needs two extra publish properties.** A DACPAC built for a
non-Fabric platform is refused unless you set **`AllowIncompatiblePlatform=True`**, and
**`ExcludeObjectTypes=Logins;Users`** avoids compat problems (Fabric has no logins). Added
both to `FabricSql.publish.xml` (belt-and-braces for us — our schema has neither). The DB must
already exist (the module provisions it); endpoint is `…database.fabric.microsoft.com,1433`;
token audience is the same `https://database.windows.net/` as Azure SQL. Source:
[Fabric SqlPackage](https://learn.microsoft.com/en-us/fabric/database/sql/sqlpackage).
**Learning 3 — the #18 analog is simpler in Fabric, but there's a hard tenant gate.** Fabric
SQL is Entra-only (no SQL auth/logins). The CI principal needs **Read item permission** via a
**Fabric workspace role** — with Fabric access controls you *don't* need manual
`CREATE USER` (unlike a raw contained user). BUT a **tenant admin must enable "Service
principals can use Fabric APIs"** or SPs can't connect at all — this is the real blocker, and
no pipeline/Terraform can flip it. Source:
[Fabric SQL authentication](https://learn.microsoft.com/en-us/fabric/database/sql/authentication).
**Learning 4 — cost shape.** An F-SKU capacity **bills continuously** (no serverless
auto-pause), so the nightly `fabric-sql-destroy.yml` matters more than the Azure SQL one; a
future `use_existing_capacity` toggle would let trial-capacity users avoid the F2 charge
(trial capacities can't be Terraform-created).
**Action:** Wired the remote backend into `infra/fabric-sql/terraform/providers.tf`
(state key `fabric-sql/dev.terraform.tfstate`); added the two publish properties; added
[`../.github/workflows/fabric-sql-plan.yml`](../.github/workflows/fabric-sql-plan.yml),
[`fabric-sql-apply.yml`](../.github/workflows/fabric-sql-apply.yml), and
[`fabric-sql-destroy.yml`](../.github/workflows/fabric-sql-destroy.yml). YAML + `fmt` clean.
**Untested end-to-end** — blocked on the tenant setting + workspace role + a capacity (task
#20; live verify is the Fabric side of #14).

## 2026-08-04 — "Ship changes as code" designed around a DB `plan` and the guard we already ship
**Context:** Task #15 — designing the PR-driven schema-change increments for the 15:30 module.
**Learning:** The clean framing is *"a database change is a PR, and the pipeline shows you what
it will do to your data before it does it"* — the DB analog of `terraform plan`, driven by
**`sqlpackage /Action:DeployReport`** (emits the would-be operations incl. `DataIssue`
data-loss alerts, applies nothing). The punchline demo (drop the populated
`Player.ShirtNumber`) needs almost no new safety code because **our publish profiles already
set `BlockOnPossibleDataLoss=True`** — so the "good path" is: the report flags the drop on the
PR, and the guard makes a blind publish fail loudly instead of silently losing data. "Manual
apply" = a **GitHub Environment required-reviewer gate**, not an out-of-band step (still
as-code). Nice reuse: the seed already populates `ShirtNumber`, so the data loss is real with
zero extra setup. Same flow on Azure SQL and Fabric SQL (per-target profile only).
**Action:** Designed in [`../planning/ship-changes-increments.md`](../planning/ship-changes-increments.md);
task #15 → DONE, implementation split out as #21. Answered the open questions in
[`Ideas.md`](Ideas.md).

## 2026-08-04 — "Ship changes" demo built as runnable artifacts; DeployReport is the DB's `plan`
**Context:** Task #21 — turning the #15 design into the actual demo. Built the demo-as-code
first (the reusable teaching content), before the CI wiring.
**Learning:** The three increments live in [`../database/demo/ship-changes/`](../database/demo/ship-changes/)
as real, copy-into-the-project SQL + a follow-along `README` with the exact commands — not just
prose. Two things worth recording: (1) **`sqlpackage /Action:DeployReport` is the "database
plan"** — it emits an XML report of what a publish *would* do, including `<Alert
Name="DataIssue">` for a column drop, and (per MS Learn) it flags the data-loss *operation*
from the schema diff, so it surfaces the risk **before** any deploy. (2) The "good path" needed
almost no new safety code — our publish profiles already ship `BlockOnPossibleDataLoss=True`,
so a blind publish **fails loudly** instead of silently dropping the populated `ShirtNumber`;
the demo just contrasts that with a throwaway `/p:BlockOnPossibleDataLoss=false`. Schema-fidelity
gotcha while writing the views: `Team` has **no `Name`** — a team's display name is
`Club.Name` + `Category` (the men's/women's split), so `vw_TeamRosterSizes` joins `Club`.
Can't build/verify locally — `global.json` pins .NET **8** (`rollForward: latestMinor`) and this
box only has .NET 9 + no SqlPackage; validation happens in CI / against a live DB.
**Action:** Added the demo folder; task #21 → DOING (content done; the `deploy-report` CI job,
Dev→Test approval gate, and naive-publish workflow remain, best done against a live DB).

## 2026-08-04 — DeployReport in CI: it's `/OutputPath`, not `/DeployReportPath` — validated live
**Context:** Wiring the "database plan" (`sqlpackage /Action:DeployReport`) into
`azure-sql-apply.yml` before the publish step (task #21).
**Learning:** The SqlPackage **DeployReport** CLI action writes its XML with **`/OutputPath:`**.
`/DeployReportPath` is an **MSBuild property**, not a CLI arg — passing it fails the action with
*"'DeployReportPath' is not a valid argument for the 'DeployReport' action."* A live
`azure-sql-apply` run caught this (the step failed before publish); the branch-only checks
couldn't, because the OIDC federated credential only trusts `main`, so the deploy workflow can
only be exercised after merge (recurring theme). Fixed → re-ran → green. The report's shape is
useful to know for the demo: `<DeploymentReport><Alerts/><Operations>…</Operations>` — against
a **fresh/empty** DB `Alerts` is empty and every object is a `Create`; a **column drop against a
populated** DB is where an `<Alert Name="DataIssue">` (possible data loss) shows up. So the
pipeline now emits a real "DB plan" artifact before every publish, and the same grep that shows
"None reported" here will surface the data-loss alert in the #15/#21 demo.
**Action:** `/OutputPath` fix in [`../.github/workflows/azure-sql-apply.yml`](../.github/workflows/azure-sql-apply.yml)
and the demo README; deploy-report step live-verified (run `30902247159`, whole apply→report→
publish→smoke pipeline green). Task #21 advanced.

## 2026-08-04 — GitHub Environment approval gates need a paid plan on private repos
**Context:** Wiring the #15/#21 "manual approval" gate as a **GitHub Environment required
reviewer** on the deploy job.
**Learning:** On a **private** repo, environment **protection rules** (required reviewers *and*
wait timer) require **GitHub Team or Enterprise** — they're only free on public repos. The API
`PUT …/environments/{name}` creates the bare environment on any plan, but adding a
protection rule returns **`422 — Please ensure the billing plan supports the … protection
rule`** (hit this even though `orgs/…/plan.name` reported "team" — worth checking billing/seats
in the UI). Second gotcha for when it *is* enabled: referencing `environment: <name>` on a job
changes that job's **OIDC `sub` claim** to `repo:<org>/<repo>:environment:<name>`, so the deploy
principal needs a **third federated credential** for that subject (like the `pull_request` one we
added) or `azure/login` fails with AADSTS700213. So the gate is a *coordinated* change (env rule
+ FIC + YAML), not a one-liner.
**Decision:** Left the gate **documented** (the production-grade pattern is in
[`../database/demo/ship-changes/increment-3_safe-retire.md`](../database/demo/ship-changes/increment-3_safe-retire.md))
rather than wired, since it can't be enforced on this repo's plan; deleted the bare `production`
environment to keep things clean. Task #21 note updated.

## 2026-08-06 — Cross-tenant Terraform: state in one tenant, infra in another (Fabric SQL)
**Context:** Task #20 — the Fabric SQL infra + DB deploy had to run in a *different* tenant /
subscription / client (**Tenant B**) than the Azure SQL work and the Terraform state backend
(**Tenant A**), without touching any Azure SQL wiring.
**Learning:** The reusable *separation-of-duties* pattern — **state in one subscription, the infra
it describes in another** — comes down to splitting the azurerm **backend** from the azurerm
**provider**, which both default to reading `ARM_*`. The clean split: leave the **backend** on the
`ARM_*` env (Tenant A) and **pin the provider explicitly in `providers.tf`** (`subscription_id` /
`client_id` / `tenant_id` / `use_oidc` from vars = Tenant B). Explicit provider args beat the
`ARM_*` env, so backend and provider authenticate to different tenants **in one `terraform` run**.
The `microsoft/fabric` provider uses its own `FABRIC_*` env (no clash), and the DACPAC publish's
`azure/login` moves to Tenant B. One GitHub OIDC token is exchanged at *both* tenants — so Tenant B
needs its own app registration with `main` + `pull_request` federated credentials (mirroring
Tenant A). Two gotchas worth keeping: (1) `azurerm_fabric_capacity.administration_members` takes
**users by UPN** and **service principals by object id** — and the module now *always* includes the
deploying caller as a capacity admin (an explicit list previously *replaced* it, which would break
the workspace→capacity assignment); (2) the Tenant B CI app needs **User Access Administrator** on
top of Contributor so Terraform can create the automation identity's custom role + assignment as
code.
**Also landed (task #23):** a **persistent Azure Automation** (its own state key) that pauses the
Fabric capacity **every 2h** and resumes **on demand** via PowerShell runbooks under a
system-assigned managed identity with a sub-scoped least-privilege custom role. The runbooks
**discover the capacity by its (stable) resource group** because the capacity name is random and
nightly-recreated. Since pausing preserves the workspace + DB + data (unlike destroy), the nightly
Fabric destroy is now a candidate to relax.
**Action:** Module + workflows rewired; `infra/fabric-sql/automation/` added; Tenant B setup
documented in [`../infra/fabric-sql/CROSS-TENANT-SETUP.md`](../infra/fabric-sql/CROSS-TENANT-SETUP.md).
Design [`../planning/2026-08-05-fabric-cross-tenant-automation-design.md`](../planning/2026-08-05-fabric-cross-tenant-automation-design.md),
plan [`../planning/2026-08-06-fabric-cross-tenant-automation-plan.md`](../planning/2026-08-06-fabric-cross-tenant-automation-plan.md).
Branch `feat/fabric-cross-tenant-automation`; tasks #20 advanced, #23 added. Live plan→apply is the
next step (the long-blocked Fabric side of #14).

## 2026-08-04 — Attendee site skeleton: 12 templated stubs, held in teaser mode
**Context:** Task #22 — turning the attendee site from a lone teaser into the full workshop
shape. Designed the content system first (a [spec](../planning/2026-08-04-attendee-content-design.md)
+ [plan](../planning/2026-08-04-attendee-content-skeleton-plan.md) via the brainstorming/
writing-plans flow), then built **Phase 1**: the page skeleton.
**Learning:** Held the whole skeleton out of the published site with **`exclude_docs`** while
keeping `mkdocs build --strict` green. The key property: an excluded page is dropped from the
build entirely, so it neither publishes nor trips the strict *"page exists but not in nav"* check
— **and its own internal links aren't validated either**. So a stub can link `[Prerequisites]` /
`[What's next]` to other held pages and strict stays happy; the only rule is that the one *built*
page (`index.md`) must not link to a held page (verified with a grep). Confirmed the teaser build
emits exactly `index.html` + `404.html` with all 12 stubs present in the repo. Toolchain note for
a Debian box: system pip is PEP 668 *externally-managed*, so mkdocs went in a throwaway **venv in
the scratchpad** (never in the repo — nothing to gitignore or accidentally commit) and the build
wrote to a scratch `site/` dir, keeping the working tree clean. **Reveal stays a one-PR diff** —
drop the `exclude_docs` entries and uncomment the nav, both already staged in `mkdocs.yml`.
**Action:** 12 stub pages under `docs/` (setup / foundations / infra / database / cicd / wrap-up /
reference) on a shared 9-section template, plus the full commented nav. Branch
`docs/attendee-content-skeleton`. Task #22 → DOING (Phase 1 done; Phase 2 = flesh the prerequisites
page #2, Phase 3 = polish the Azure SQL core, each its own branch).

## 2026-08-06 — PowerShell `$var:` scope syntax silently corrupts OIDC federated-credential subjects
**Context:** The first cross-tenant `fabric-sql-plan` failed at the azurerm-provider token
exchange with `AADSTS700213 — No matching federated identity record found for subject
repo:JessAndRob/FabConEU_2026_workshop:pull_request`, even though a `fabcon26-fabric-pr` federated
credential existed on the Tenant B app.
**Learning:** The credential existed but its **subject was missing the repo** — stored as `repo:`
and `repo:/heads/main` instead of the full `repo:<org>/<repo>:pull_request` /
`…:ref:refs/heads/main`. Cause: the setup built the subject in a **double-quoted** here-string as
`"repo:$repo:pull_request"`, and PowerShell parses `$repo:pull_request` as a **namespaced
variable** (`$scope:name`, exactly like `$env:PATH`) — so `$repo` is dropped and the `:pull_request`
tail is swallowed. Fix: delimit with **`${repo}`** (`"repo:${repo}:pull_request"`), or use a
single-quoted here-string with the repo hard-coded. Diagnostic that pinpoints it:
`az ad app federated-credential list --id <appId> --query "[].{name:name,subject:subject}" -o table`
— **AADSTS700213 means the app was found but no subject matched** (credential present ≠ correct).
**Action:** Recreated both subjects (`main` + `pr`); patched
[`../infra/fabric-sql/CROSS-TENANT-SETUP.md`](../infra/fabric-sql/CROSS-TENANT-SETUP.md) to use
`${repo}` + a warning. Unblocks the first live Fabric plan (tasks #20).

## 2026-08-17 — The people module goes to the front of the day, and the morning pays for it
**Context:** Rob wanted the "hardest part of IT" hook — the egos-and-feelings bit, written up
in `README.md` under "👉 Start here" — promoted from a repo-front line into an actual agenda
module, at 09:30, ahead of any tech.
**Learning:** A full-day agenda that already runs 09:00–17:00 has **no slack** — the 30 minutes
had to come out of the same morning, because the 11:00 break, 12:45 lunch and 17:00 end are
fixed. Three sources, in order of how painless they were: the environment check (25 → 10 min;
it's bring-your-own per D6, so individual help belongs in the breaks, not the room's time);
splitting the Azure SQL Terraform module **across** the 11:00 break so `terraform apply` runs
while everyone's at coffee (same 45 min of teaching, 15 minutes of waiting deleted); and
SQL projects 45 → 30, which is the one genuine squeeze on a focus module. The afternoon was
left completely untouched — worth preserving as a property, it makes the change reviewable.
**Action:** [`../agenda/agenda.md`](../agenda/agenda.md) rebuilt (new 09:30 row, hook text in
Rob's voice under the table, plus a "where the 30 minutes came from" note so the trade is
auditable at the dry run). Task **#24** added to build the module content; the SQL-projects
squeeze is explicitly flagged for **#13** (dry run) — if 30 min doesn't hold, take it back from
the 16:15 block. **Doc nit spotted, not fixed:** this file's header says "Newest entries at the
top" but every entry is appended at the bottom above the `<!-- Add new entries -->` marker —
one of the two is wrong and should be settled.

## 2026-08-17 — The repo had no `.gitattributes`, and it made every file look modified
**Context:** Committing the agenda change (above), `git status` reported **all 102 files
modified** — 7,600 insertions against 7,549 deletions — despite only three files being touched.
**Learning:** Every file on disk was **CRLF** while the index held **LF**, with no
`.gitattributes` and `core.autocrlf` unset, so git saw each file as a whole-file rewrite. Real
diffs become unreviewable — a three-line agenda edit is indistinguishable from a rewrite of the
Terraform modules, which is exactly the failure mode PR review is supposed to prevent. Note
that `git add --renormalize .` does **nothing** until `.gitattributes` exists — the renormalise
uses whatever attributes are in force at the time, so the order is: add the file, *then*
renormalise.
**Action:** Added [`../.gitattributes`](../.gitattributes) — `* text=auto` plus explicit
`eol=lf` for `*.sh` (Linux runners), `eol=crlf` for `*.bat`/`*.cmd`, and `binary` for images and
`.dacpac`/`.bacpac`. Renormalise + commit run by hand on Windows (see below).
**Second learning — git can't be driven from a Cowork cloud session over the device bridge.**
The bridge mount is deletion-restricted, so git cannot unlink `.git/index.lock` after an index
operation: the lock survives, and the *next* git command dies with "Another git process seems to
be running." It also strands `tmp_obj_*` files under `.git/objects`. Reads and file edits over
the bridge are fine; **anything that writes the git index must be run on the Windows box** (or
in a Cowork session running *on the computer* rather than in the cloud). Leftovers from this
session were quarantined in `.git/_cowork_to_delete/` — safe to delete.

## 2026-08-20 — `use_existing_capacity` toggle: bind to a capacity we pause, never destroy
**Context:** We now have a **persistent paid F-SKU** (`cappymccapface` in `fabcon-demo-rg`,
Tenant B) to run the first live Fabric apply against, rather than creating/nightly-destroying an
F2. The module always created the capacity; needed a way to *use ours* and guarantee Terraform
can never tear it down. Also pruned all merged branches and tracked the slides deck (#25).
**Learning 1 — the fabric provider gives you the correct binding id; azurerm's `.id` may not.**
`terraform providers schema -json` (microsoft/fabric v1.13) shows `fabric_workspace.capacity_id`
wants **"the ID of the Fabric Capacity"** — the Fabric **GUID** — and there's a
**`data "fabric_capacity"`** that resolves a capacity **by `display_name` tenant-wide** to exactly
that GUID (no resource group needed for the lookup). That flagged a **latent risk in the untested
create path**: it binds `capacity_id = azurerm_fabric_capacity.this.id`, which is the **ARM resource
id**, not the GUID. Left the create path as-is (can't live-test it today) with a `# KNOWN RISK`
comment; the existing path uses `data.fabric_capacity.existing[0].id` (unambiguously the GUID). If
the first *create-mode* apply rejects the ARM id, resolve the created capacity via
`data.fabric_capacity` too. Reinforces the repo's standing rule: **confirm provider shapes against
`providers schema -json`, not the registry docs.**
**Learning 2 — `count = 0` is the teardown guarantee.** With `use_existing_capacity = true` the
capacity is a **read-only data source** and the `azurerm_fabric_capacity` / `azurerm_resource_group`
resources drop to `count = 0`, so they're **never in state** — `terraform destroy` provably cannot
touch the capacity (or its RG); it removes only the workspace + SQL DB. Cost control becomes
**pause, not destroy** (pausing preserves workspace/DB/data), so the **nightly 21:00 destroy cron
was disabled** (commented out; manual `workflow_dispatch` kept) — leaving it on would wipe the DB we
just deployed onto a persistent capacity every night. Re-enable the cron only if we revert to the
module creating its own F-SKU.
**Learning 3 — drive the mode from a repo variable with a safe default.** Workflows pass
`TF_VAR_use_existing_capacity: ${{ vars.FABRIC_USE_EXISTING_CAPACITY || 'false' }}` — unset ⇒ the
taught create-as-code path still works; set to `true` ⇒ existing-capacity mode. Needs three Tenant B
repo vars: `FABRIC_USE_EXISTING_CAPACITY=true`, `FABRIC_EXISTING_CAPACITY_NAME=cappymccapface`,
`FABRIC_EXISTING_CAPACITY_RG=fabcon-demo-rg`.
**Action:** Toggle in [`../infra/fabric-sql/terraform/`](../infra/fabric-sql/terraform/) (main /
variables / outputs / tfvars.example / README) + the three `fabric-sql-*` workflows;
`.terraform.lock.hcl` generated & kept (repo convention). `fmt`/`validate` clean offline; **live
plan→apply is the next step** (still after a merge — OIDC only trusts `main`). Tasks #20/#14
advanced, #25 added (slides). **Still needs: set the 3 repo vars, then run `fabric-sql-plan` on the
PR and `fabric-sql-apply` after merge.**

## 2026-08-20 — First live Fabric deploy end-to-end; two access gotchas on the way
**Context:** Straight after the `use_existing_capacity` toggle merged (PR #33), took the Fabric
path live for the first time against our persistent paid F-SKU **`cappymccapface`** (`fabcon-demo-rg`,
Tenant B) — the long-blocked Fabric side of #14/#20.
**The milestone:** `fabric-sql-apply` went **green end-to-end** (run `32393958396`): `terraform apply`
= *2 added* (workspace + SQL DB), capacity untouched; DACPAC publish = **"Successfully published
database"**; smoke test passed (every seeded view + `usp_GetLeagueTable` returning rows on the real
Fabric SQL DB). First working "infra + DB as code" deploy to Fabric, side by side with Azure SQL.
**Gotcha 1 — `data.fabric_capacity` only sees capacities the CI SP is a capacity ADMIN of.** The
first `fabric-sql-plan` failed: *"Unable to find Capacity with 'display_name': cappymccapface"* —
even though auth succeeded (no `AADSTS700213`; the fabric provider queried the API fine). The
`fabric_capacity` **data source lists capacities the principal can see**, and a capacity we created
out-of-band doesn''t include the CI SP. In *create* mode the module auto-adds the deploying SP as a
capacity admin, so this never surfaced; for an *existing* capacity it''s the Fabric analog of #18 —
a one-time out-of-band grant. **Also ruled out** as red herrings first: a *paused* capacity (resumed,
still failed) and a display-name typo. **Least-privilege note (parked, issue-worthy):** capacity
**admin** is more than needed — Fabric **"Capacity contributor"** lets a principal assign workspaces
without admin; but the list-capacities API may not return contributor-only capacities, so the truly
minimal setup is to **pass the capacity GUID directly** (drop the data source) + grant contributor.
We took admin for now to get moving.
**Gotcha 2 — a workspace created by an SP is invisible to humans.** After the apply, Jess/Rob
couldn''t see the workspace: its creator (the CI SP) is the **only member**. Fix = grant them the
**Admin** role **as code** via `fabric_workspace_role_assignment` (PR #34, `workspace_admin_object_ids`
→ repo var `FABRIC_WORKSPACE_ADMIN_OBJECT_IDS`, a JSON array of **Entra USER object ids** — GUIDs,
**not** UPNs; principal `type = "User"`). Must be as-code because the workspace is recreated on every
apply — a portal grant wouldn''t survive. Plan confirmed *2 role assignments to add, 0 change, 0
destroy* (workspace/DB/capacity untouched).
**Gotcha 3 (design, not bug) — pause ≠ destroy, so the nightly-destroy question reopened.** With the
every-2h capacity pause already zeroing overnight cost, a nightly *destroy* is now only about a
**clean slate each morning**, not money — and destroying Fabric items needs the capacity **resumed**
first (resume → destroy → re-pause). Captured as a decision for Rob in **issue #35** rather than
silently wiring it.
**Process note — the fabric provider schema is the source of truth.** Used
`terraform providers schema -json` (via a temp `backend "local"` override, since `providers schema`
needs backend init) to confirm both `data.fabric_capacity` (look up by `display_name`) and
`fabric_workspace_role_assignment` (`principal = { id, type }` object, not a block) *before* writing —
no validate cycles wasted, per the standing rule.
**Action:** Toggle + workspace-admin grant shipped (PRs #33/#34, merged); repo vars set
(`FABRIC_USE_EXISTING_CAPACITY`, `FABRIC_EXISTING_CAPACITY_NAME/RG`, `FABRIC_WORKSPACE_ADMIN_OBJECT_IDS`).
Tasks #14 (**Fabric side now verified end-to-end**) and #20 updated. Open follow-ups: nightly-teardown
decision (issue #35), least-privilege contributor+GUID refactor, and a possible PR-time plan comment.

## 2026-08-28 — Morning-of readiness checklist captured from the operational gotchas
**Context:** Planning the run-of-day. Realised the demo environment is **not** standing when we
walk in — nightly destroy (21:00 UTC) wipes the infra and the Fabric capacity auto-pauses every
2h — so "be demo-ready" is an actual procedure, not a given.
**Learning:** The morning setup is fully derivable from gotchas already logged, and they cluster:
(1) both `*-apply` workflows must be re-dispatched **from `main`** (OIDC only trusts main) to
rebuild infra + republish the DACPAC; (2) the Fabric capacity must be **resumed to `Active`**
before anything Fabric resolves; (3) `az login` to **both tenants** (the Fabric path is
cross-tenant); (4) the Fabric **workspace-admin grant re-applies** on every apply because the
workspace is recreated; (5) any laptop-to-DB demo needs a **temporary firewall rule** (external
clients are blocked). Site reveal (drop `exclude_docs` + uncomment nav) should happen **early, not
live**.
**Action:** Wrote [`../planning/morning-of-checklist.md`](../planning/morning-of-checklist.md);
added task **#28**. Standalone eval flagged the real gap as **content + a timed dry run** (#13,
#22, #24, #25), not code — the core "infra + DB as code" path is proven live on both platforms.

<!-- Add new entries above this line -->
