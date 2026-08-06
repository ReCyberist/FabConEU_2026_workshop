# Attendee content — Phase 1 (site skeleton) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create the full attendee-site page skeleton (12 templated stub pages + wired nav), held in teaser mode, with `mkdocs build --strict` green — the shape of the whole workshop site in the repo, nothing revealed.

**Architecture:** Extend `mkdocs.yml` with the complete topic-based nav (kept **commented**) and an expanded `exclude_docs` list, then create one stub Markdown page per agenda module under `docs/`, each following a shared 9-section template with real code links wired and prose left as intent comments. Because every new page is in `exclude_docs`, the published site stays the single teaser page and `mkdocs build --strict` never trips the "page not in nav" check.

**Tech Stack:** MkDocs 1.6 + Material, Python (pip/`requirements.txt`), Markdown, PowerShell for command examples.

**Scope:** Phase 1 only (the skeleton), per [the design spec](2026-08-04-attendee-content-design.md) §8. Phase 2 (prerequisites page) and Phase 3 (Azure SQL core polish) are **separate plans on their own branches** and are out of scope here. This plan runs on branch `docs/attendee-content-skeleton`.

## Global Constraints

Every task implicitly includes these (verbatim from the [spec](2026-08-04-attendee-content-design.md)):

- **Teaser mode preserved:** every new page path is added to `exclude_docs` in `mkdocs.yml`; the published site remains only the teaser home page.
- **Build gate after every task:** `mkdocs build --strict` exits 0, and the built `site/` contains only `index.html` + `404.html` (no module-page HTML).
- **No built page links to an excluded page:** `docs/index.md` must not link to any held page (links between two excluded pages are fine — neither is built).
- **Nav stays commented:** the full `nav` tree is present but commented out; reveal later = delete the `exclude_docs` entries **and** uncomment the nav (one PR).
- **PowerShell** for every command example; fence ` ```powershell `.
- **Prose = pages, code = downloads:** short excerpts only; link the real file on GitHub as `https://github.com/JessAndRob/FabConEU_2026_workshop/tree/main/<path>` (or `/blob/main/<path>` for a single file) + the download bundle. Never paste large code blocks.
- **Voice:** polished, friendly, attendee-facing. Exemplar = [`docs/database/sample-database.md`](../docs/database/sample-database.md).
- **Naming/secrets:** `fabcon26-*` prefixes; never a secret, connection string, or subscription id.
- **Honest caveats:** Fabric content carries a *"code ready, live-verification pending ([#20](tasks.md))"* callout; approval-gate content documents the **pattern + plan constraint** ([#21](tasks.md)), never implies it is wired.
- **Commit trailers:** every commit message ends with these two lines:
  ```
  Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
  Claude-Session: https://claude.ai/code/session_01FomQZPCUXLqFQLnNnCn8nQ
  ```

---

## File Structure

New files (all under `docs/`, all added to `exclude_docs`):

| File | Responsibility | Agenda |
|---|---|---|
| `docs/setup/welcome.md` | Welcome + how the (bring-your-own) day works | 09:00 |
| `docs/setup/prerequisites.md` | What to bring: two optional paths, shared endpoint, cost/teardown, toolchain | 09:20 |
| `docs/foundations/source-control.md` | Git for databases: repo layout, secrets | 09:45 |
| `docs/infra/azure-sql.md` | Provision Azure SQL as code (Terraform; Bicep reference) | 10:15 |
| `docs/infra/fabric-sql.md` | Provision Fabric SQL as code (caveated) | 11:15 |
| `docs/database/sql-projects.md` | Database schema as code (`.sqlproj`/DACPAC) | 12:00 |
| `docs/cicd/build-validate.md` | CI/CD part 1 — build & validate on PR | 13:45 |
| `docs/cicd/deploy-infra.md` | CI/CD part 2 — deploy infra from the pipeline | 14:30 |
| `docs/cicd/ship-database-changes.md` | CI/CD part 3 — ship DB changes safely | 15:30 |
| `docs/wrap-up/migrations-drift-teardown.md` | Migrations (bonus), drift, teardown | 16:15 |
| `docs/wrap-up/resources.md` | Downloads, further reading, feedback | 16:45 |
| `docs/reference/other-tooling.md` | Index of the "all as code" reference variants | stretch |

Modified: `mkdocs.yml` (nav + `exclude_docs`).
Untouched: `docs/index.md`, `docs/database/sample-database.md` (already exist).

**The shared stub template (9 sections)** — defined concretely in Task 1's `azure-sql.md` and consumed by Tasks 2–5. Sections: DRAFT banner comment · H1 + intro · `!!! note "Follow along — or just watch"` · `## What you'll build` · `## The concept` · optional side-by-side tabs · `## The code` (links) · `## Checkpoint` · `## Gotchas` · `## What's next`. Pages omit sections that don't apply (noted per page).

---

### Task 1: Scaffolding — nav, `exclude_docs`, template + exemplar page

Locks the nav structure, the teaser-preservation mechanism, and the canonical stub template.

**Files:**
- Modify: `mkdocs.yml` (the `exclude_docs` block and the `nav` block)
- Create: `docs/infra/azure-sql.md` (the canonical template exemplar)

**Interfaces:**
- Produces: the **standard stub template** (the exact section skeleton below) that Tasks 2–5 instantiate; the expanded `exclude_docs` list; the full commented `nav`.

- [ ] **Step 1: Install the docs toolchain**

Run: `pip install -r requirements.txt`
Expected: MkDocs + Material install cleanly (needed to run the build gate).

- [ ] **Step 2: Replace the `exclude_docs` block in `mkdocs.yml`** with the full held list:

```yaml
exclude_docs: |
  database/sample-database.md
  setup/welcome.md
  setup/prerequisites.md
  foundations/source-control.md
  infra/azure-sql.md
  infra/fabric-sql.md
  database/sql-projects.md
  cicd/build-validate.md
  cicd/deploy-infra.md
  cicd/ship-database-changes.md
  wrap-up/migrations-drift-teardown.md
  wrap-up/resources.md
  reference/other-tooling.md
```

- [ ] **Step 3: Replace the `nav` block in `mkdocs.yml`** with the full commented tree (only Home is live):

```yaml
nav:
  - Home: index.md
  # --- Held until reveal: delete the exclude_docs entries above AND uncomment below ---
  # - Getting started:
  #     - Welcome & how the day works: setup/welcome.md
  #     - Prerequisites: setup/prerequisites.md
  # - Foundations:
  #     - Source control for databases: foundations/source-control.md
  # - Infrastructure as code:
  #     - Azure SQL (Terraform): infra/azure-sql.md
  #     - Fabric SQL (Terraform): infra/fabric-sql.md
  # - Database as code:
  #     - The sample database: database/sample-database.md
  #     - SQL projects: database/sql-projects.md
  # - CI/CD:
  #     - Build & validate: cicd/build-validate.md
  #     - Deploy infrastructure: cicd/deploy-infra.md
  #     - Ship database changes: cicd/ship-database-changes.md
  # - Wrap up:
  #     - Migrations, drift & teardown: wrap-up/migrations-drift-teardown.md
  #     - Resources & next steps: wrap-up/resources.md
  # - Reference:
  #     - Other tooling: reference/other-tooling.md
```

- [ ] **Step 4: Create `docs/infra/azure-sql.md`** — the canonical stub (this exact content is the template):

```markdown
<!-- DRAFT: skeleton only. Structure + code links wired; prose to be fleshed out (task #22, Phase 3). -->

# Azure SQL as code (Terraform)

<!-- INTRO (1–2 sentences): why provision Azure SQL as code — repeatable, reviewable, no clicking. -->

!!! note "Follow along — or just watch"
    You'll need your **own Azure subscription** with rights to create resources for this module.
    No subscription? Just watch — it's a live demo you can replay later from the downloads. See
    [Prerequisites](../setup/prerequisites.md).

## What you'll build

<!-- AT A GLANCE: resource group + logical SQL server + serverless database + firewall rule;
     CAF-named, passwordless (Entra-only). A short bullet list or small table. -->

## The concept

<!-- ~5 min: infrastructure as code; Terraform state (remote azurerm backend); passwordless
     Entra auth; CAF + fabcon26 naming. -->

## Terraform (focus) / Bicep (reference)

=== "Terraform"
    <!-- The taught path: a short excerpt + the key init/plan/apply commands (see the module README). -->

=== "Bicep"
    <!-- Reference variant (all-as-code): mirrors the Terraform module; link only, short note. -->

## The code

The module lives in
[`infra/azure-sql/terraform`](https://github.com/JessAndRob/FabConEU_2026_workshop/tree/main/infra/azure-sql/terraform)
(Bicep reference in
[`infra/azure-sql/bicep`](https://github.com/JessAndRob/FabConEU_2026_workshop/tree/main/infra/azure-sql/bicep)).
Download the module bundle and run it from code — nothing is clicked.

## Checkpoint

<!-- The "we move on" state: `terraform apply` created the RG + server + DB, passwordless. -->

## Gotchas

<!-- Distil from LEARNINGS.md: CAF + fabcon26 naming; Entra-only passwordless (no admin login);
     a Sponsorship sub can be region-restricted (try, read the error); keep tf state out of the
     workload RG so nightly destroy can't delete it. -->

## What's next

Next: [Fabric SQL as code](fabric-sql.md) — the same, side by side on Fabric.
```

- [ ] **Step 5: Run the build gate**

Run: `mkdocs build --strict && find site -name '*.html' | sort`
Expected: exit 0; the `find` lists **only** `site/404.html` and `site/index.html`.

- [ ] **Step 6: Commit**

```bash
git add mkdocs.yml docs/infra/azure-sql.md
git commit -m "Scaffold attendee-site nav + first module stub" -m "Full commented nav + expanded exclude_docs keep the site in teaser mode; azure-sql.md is the canonical 9-section stub template. mkdocs build --strict green (teaser only)." -m "<standard trailers from Global Constraints>"
```

---

### Task 2: Getting started + Foundations stubs

**Files:**
- Create: `docs/setup/welcome.md`, `docs/setup/prerequisites.md`, `docs/foundations/source-control.md`

**Interfaces:**
- Consumes: the standard stub template (Task 1). Each page below instantiates it with the stated title, links, and section notes. All three are already in `exclude_docs` (Task 1).

- [ ] **Step 1: Create `docs/setup/welcome.md`**

```markdown
<!-- DRAFT: skeleton only. Prose to be fleshed out (task #22). -->

# Welcome & how the day works

<!-- INTRO: the promise — deploy infra *and* databases as code; "no clicking required". -->

## How the day works

<!-- Bring-your-own (D6): two optional, independent follow-along parts (IaC / DB-deploy), plus
     one shared *unsupported* endpoint. Build along on your own kit, or just watch and replay. -->

## What we'll cover

<!-- The module list mapped to the day (see agenda): source control → infra (Azure SQL + Fabric
     SQL) → SQL projects → CI/CD parts 1–3 → migrations/teardown. Side by side throughout. -->

## What's next

Next: [Prerequisites](prerequisites.md) — what to bring if you want to follow along.
```

- [ ] **Step 2: Create `docs/setup/prerequisites.md`** (fleshed later in Phase 2; stub now)

```markdown
<!-- DRAFT: skeleton only. Fleshed in Phase 2 (task #2) from ordering.md + decision D6. -->

# Prerequisites

<!-- INTRO: everything is bring-your-own; here's what each optional path needs. -->

!!! note "Follow along — or just watch"
    Nothing is provided for you. Bring what you have, follow along, or just watch and replay later.

## Everyone

<!-- GitHub account; ability to fork/clone the template repo; git locally. -->

## To do the infrastructure part (optional)

=== "Azure SQL"
    <!-- Your own Azure subscription with Contributor rights. -->

=== "Fabric SQL"
    <!-- Azure sub + a Fabric capacity (F-SKU bills; trial capacity can't be Terraform-created). -->

## To do the database-deploy part (optional)

<!-- A reachable target SQL (your own Azure SQL / Fabric SQL), OR our shared endpoint on the day. -->

## The shared endpoint (unsupported)

<!-- One SQL Server on a VM, a database per attendee, pushed to via pipeline. Best-effort, we
     won't troubleshoot it. -->

## Cost & teardown

<!-- Warn: deploying into your own sub costs money; tear it down. Point at the destroy workflow. -->

## Your local toolchain

<!-- git; for the DB part: dotnet SDK (pinned 8 via global.json) + SqlPackage. -->

## What's next

Next: [Source control for databases](../foundations/source-control.md).
```

- [ ] **Step 3: Create `docs/foundations/source-control.md`**

```markdown
<!-- DRAFT: skeleton only. Prose to be fleshed out (task #22, Phase 3). -->

# Source control for databases

<!-- INTRO: version-control everything — infra, schema, pipelines; the repo is the source of truth. -->

!!! note "Follow along — or just watch"
    You just need **git** and the template repo for this module. See [Prerequisites](../setup/prerequisites.md).

## What you'll build

<!-- A forked repo you can clone and work in. -->

## The concept

<!-- Why databases belong in git; repo layout (infra/ database/ docs/); keeping secrets OUT
     (variables + OIDC, never connection strings/subscription ids). -->

## The code

The repo layout is described in
[`CLAUDE.md`](https://github.com/JessAndRob/FabConEU_2026_workshop/blob/main/CLAUDE.md); secrets
are kept out via [`.gitignore`](https://github.com/JessAndRob/FabConEU_2026_workshop/blob/main/.gitignore)
and pipeline variables.

## Gotchas

<!-- Never commit a secret/connection string/subscription id; passwordless (OIDC/Entra) avoids them. -->

## What's next

Next: [Azure SQL as code](../infra/azure-sql.md).
```

- [ ] **Step 4: Build gate**

Run: `mkdocs build --strict && find site -name '*.html' | sort`
Expected: exit 0; only `site/404.html` and `site/index.html`.

- [ ] **Step 5: Commit**

```bash
git add docs/setup/welcome.md docs/setup/prerequisites.md docs/foundations/source-control.md
git commit -m "Add Getting-started + Foundations page stubs" -m "welcome, prerequisites, source-control skeletons on the standard template; teaser build stays green." -m "<standard trailers from Global Constraints>"
```

---

### Task 3: Infrastructure (Fabric) + Database stubs

**Files:**
- Create: `docs/infra/fabric-sql.md`, `docs/database/sql-projects.md`

**Interfaces:**
- Consumes: the standard stub template (Task 1). Both already in `exclude_docs`.

- [ ] **Step 1: Create `docs/infra/fabric-sql.md`**

```markdown
<!-- DRAFT: skeleton only. Prose to be fleshed out (task #22, Phase 3). -->

# Fabric SQL as code (Terraform)

<!-- INTRO: the side-by-side partner to Azure SQL — provision Fabric SQL as code. -->

!!! warning "Code ready — live-verification pending (task #20)"
    The Fabric module is written and validated offline, but the end-to-end pipeline run is
    blocked on a Fabric capacity + a tenant admin setting. Treat this page's flow as authoritative
    and the "verified" badge as pending.

!!! note "Follow along — or just watch"
    Needs your own Azure subscription **and** a Fabric capacity. See [Prerequisites](../setup/prerequisites.md).

## What you'll build

<!-- AT A GLANCE: capacity → workspace → SQL database (vs Azure's server → database). -->

## The concept

<!-- Two providers: azurerm (capacity) + microsoft/fabric (workspace + database); passwordless. -->

## Azure SQL / Fabric SQL

=== "Azure SQL"
    <!-- server → database (recap; see the Azure SQL page). -->

=== "Fabric SQL"
    <!-- capacity → workspace → database; the extra provider + capacity cost. -->

## The code

The module lives in
[`infra/fabric-sql/terraform`](https://github.com/JessAndRob/FabConEU_2026_workshop/tree/main/infra/fabric-sql/terraform).
Bicep can only provision the **capacity** (workspace + DB have no ARM type) — see
[`infra/fabric-sql/bicep`](https://github.com/JessAndRob/FabConEU_2026_workshop/tree/main/infra/fabric-sql/bicep).

## Checkpoint

<!-- capacity + workspace + database exist; DACPAC target reachable. -->

## Gotchas

<!-- Two providers; capacity name is lowercase-alnum only; tenant must enable "Service principals
     can use Fabric APIs"; F-SKU bills continuously (nightly destroy matters). -->

## What's next

Next: [Database as code — SQL projects](../database/sql-projects.md).
```

- [ ] **Step 2: Create `docs/database/sql-projects.md`**

```markdown
<!-- DRAFT: skeleton only. Prose to be fleshed out (task #22, Phase 3). -->

# Database as code — SQL projects

<!-- INTRO: define the schema as a .sqlproj, build a DACPAC, publish it — state-based DB as code. -->

!!! note "Follow along — or just watch"
    Needs the .NET SDK + SqlPackage, and a target SQL to publish into. See [Prerequisites](../setup/prerequisites.md).

## What you'll build

<!-- A DACPAC from the canonical football schema (see The sample database), publishable to both
     Azure SQL and Fabric SQL. -->

## The concept

<!-- SQL projects (SDK-style Microsoft.Build.Sql); DACPAC; publish profiles carry options not
     secrets; T-SQL static analysis keeps it clean. -->

## Azure SQL / Fabric SQL

=== "Azure SQL"
    <!-- AzureSql.publish.xml; SqlPackage /Action:Publish with an Entra /AccessToken. -->

=== "Fabric SQL"
    <!-- FabricSql.publish.xml (AllowIncompatiblePlatform + ExcludeObjectTypes=Logins;Users). -->

## The code

The project is in
[`database/sql-projects`](https://github.com/JessAndRob/FabConEU_2026_workshop/tree/main/database/sql-projects)
(schema, seed, and [publish profiles](https://github.com/JessAndRob/FabConEU_2026_workshop/tree/main/database/sql-projects/PublishProfiles)).
The schema itself is described on [The sample database](sample-database.md).

## Checkpoint

<!-- dotnet build produces the DACPAC; SqlPackage publishes schema + seed, passwordless. -->

## Gotchas

<!-- Pin the .NET SDK (global.json) or CI grabs the wrong one; profiles hold options, no secrets;
     BlockOnPossibleDataLoss=True by default. -->

## What's next

Next: [CI/CD part 1 — build & validate](../cicd/build-validate.md).
```

- [ ] **Step 3: Build gate**

Run: `mkdocs build --strict && find site -name '*.html' | sort`
Expected: exit 0; only `site/404.html` and `site/index.html`.

- [ ] **Step 4: Commit**

```bash
git add docs/infra/fabric-sql.md docs/database/sql-projects.md
git commit -m "Add Fabric SQL + SQL-projects page stubs" -m "fabric-sql (with the live-verify-pending caveat) and sql-projects skeletons; teaser build stays green." -m "<standard trailers from Global Constraints>"
```

---

### Task 4: CI/CD stubs

**Files:**
- Create: `docs/cicd/build-validate.md`, `docs/cicd/deploy-infra.md`, `docs/cicd/ship-database-changes.md`

**Interfaces:**
- Consumes: the standard stub template (Task 1). All three already in `exclude_docs`.

- [ ] **Step 1: Create `docs/cicd/build-validate.md`**

```markdown
<!-- DRAFT: skeleton only. Prose to be fleshed out (task #22, Phase 3). -->

# CI/CD part 1 — build & validate

<!-- INTRO: every change is a PR; the pipeline builds and validates it before anything merges. -->

!!! note "Follow along — or just watch"
    A GitHub account + the forked repo. See [Prerequisites](../setup/prerequisites.md).

## What you'll build

<!-- On PR: build the DACPAC + T-SQL static analysis, and a read-only `terraform plan`. -->

## The concept

<!-- CI validates our own code; plan-on-PR (read-only) vs apply-on-intent; paths-filter so jobs
     only run when their area changes. -->

## The code

Workflows:
[`ci.yml`](https://github.com/JessAndRob/FabConEU_2026_workshop/blob/main/.github/workflows/ci.yml)
(build + analysis + docs) and
[`azure-sql-plan.yml`](https://github.com/JessAndRob/FabConEU_2026_workshop/blob/main/.github/workflows/azure-sql-plan.yml)
(plan on PR).

## Checkpoint

<!-- A PR shows green build + analysis + a terraform plan in its checks. -->

## Gotchas

<!-- Pin .NET (global.json) in CI; plan-on-PR needs a `pull_request` OIDC federated credential
     (its subject isn't a branch ref); -warnaserror keeps analysis at zero findings. -->

## What's next

Next: [CI/CD part 2 — deploy infrastructure](deploy-infra.md).
```

- [ ] **Step 2: Create `docs/cicd/deploy-infra.md`**

```markdown
<!-- DRAFT: skeleton only. Prose to be fleshed out (task #22, Phase 3). -->

# CI/CD part 2 — deploy infrastructure

<!-- INTRO: apply Terraform from the pipeline — provisioning as a deliberate, passwordless action. -->

!!! note "Follow along — or just watch"
    Your own Azure subscription to deploy into. See [Prerequisites](../setup/prerequisites.md).

## What you'll build

<!-- A dispatchable apply that provisions the Azure SQL infra, plus a nightly destroy. -->

## The concept

<!-- OIDC passwordless (no secrets); remote state; apply-on-intent from main; environments &
     approvals (documented — see the gate note below). -->

## The code

Workflows:
[`azure-sql-apply.yml`](https://github.com/JessAndRob/FabConEU_2026_workshop/blob/main/.github/workflows/azure-sql-apply.yml)
and
[`azure-sql-destroy.yml`](https://github.com/JessAndRob/FabConEU_2026_workshop/blob/main/.github/workflows/azure-sql-destroy.yml).

## Checkpoint

<!-- One dispatch provisions the RG + server + DB; nightly destroy tears it down at 21:00 UTC. -->

## Gotchas

<!-- OIDC FIC subjects (main vs pull_request); a logical SQL server allows one Entra admin, so use
     an Entra *group* for presenters + CI SP (#18); a Sponsorship sub can be region-restricted. -->

!!! info "Approval gates (documented, not wired)"
    GitHub Environment required-reviewer gates need a Team/Enterprise plan on a private repo, so
    ours is documented as a pattern rather than enforced here (task #21).

## What's next

Next: [CI/CD part 3 — ship database changes](ship-database-changes.md).
```

- [ ] **Step 3: Create `docs/cicd/ship-database-changes.md`**

```markdown
<!-- DRAFT: skeleton only. Prose to be fleshed out (task #22, Phase 3). -->

# CI/CD part 3 — ship database changes

<!-- INTRO: a database change is a PR, and the pipeline shows exactly what it will do to your data
     before it does it — the DB's answer to `terraform plan`. -->

!!! note "Follow along — or just watch"
    A target SQL with seeded data to see data-loss safely. See [Prerequisites](../setup/prerequisites.md).

## What you'll build

<!-- Three PR increments: additive (safe/auto) → destructive drop (the trap) → safe retire + gate. -->

## The concept

<!-- DeployReport = the DB plan (flags data-loss ops before deploy); BlockOnPossibleDataLoss=True
     makes a blind publish fail loudly; destructive changes ship via a migration + a human gate. -->

## Azure SQL / Fabric SQL

=== "Azure SQL"
    <!-- The live-verified path (AzureSql.publish.xml). -->

=== "Fabric SQL"
    <!-- Same flow, FabricSql.publish.xml — gated on the capacity (#20). -->

## The code

The runnable demo (three increments + a follow-along README) is in
[`database/demo/ship-changes`](https://github.com/JessAndRob/FabConEU_2026_workshop/tree/main/database/demo/ship-changes).

## Checkpoint

<!-- Increment 1 auto-publishes; increment 2's drop is blocked/flagged; increment 3 ships safely. -->

## Gotchas

<!-- DeployReport writes with /OutputPath (not /DeployReportPath); the approval gate is documented,
     not wired (#21); the seed populates ShirtNumber so the data loss is real. -->

## What's next

Next: [Migrations, drift & teardown](../wrap-up/migrations-drift-teardown.md).
```

- [ ] **Step 4: Build gate**

Run: `mkdocs build --strict && find site -name '*.html' | sort`
Expected: exit 0; only `site/404.html` and `site/index.html`.

- [ ] **Step 5: Commit**

```bash
git add docs/cicd/build-validate.md docs/cicd/deploy-infra.md docs/cicd/ship-database-changes.md
git commit -m "Add CI/CD part 1-3 page stubs" -m "build-validate, deploy-infra, ship-database-changes skeletons; gate + Fabric caveats noted; teaser build stays green." -m "<standard trailers from Global Constraints>"
```

---

### Task 5: Wrap-up + Reference stubs; final Phase-1 gate

**Files:**
- Create: `docs/wrap-up/migrations-drift-teardown.md`, `docs/wrap-up/resources.md`, `docs/reference/other-tooling.md`

**Interfaces:**
- Consumes: the standard stub template (Task 1). All three already in `exclude_docs`.

- [ ] **Step 1: Create `docs/wrap-up/migrations-drift-teardown.md`**

```markdown
<!-- DRAFT: skeleton only. Prose to be fleshed out (task #22, Phase 3). -->

# Migrations, drift & teardown

<!-- INTRO: putting it together — migration-based options as a bonus, drift detection, clean teardown. -->

## The concept

<!-- State-based (SQL projects, our focus) vs migration-based (Flyway, dbatools/dbops); drift;
     always tear it down. -->

## Reference — migration-based options

<!-- Same schema, different tool. Links only (decision B). -->
- [Flyway](https://github.com/JessAndRob/FabConEU_2026_workshop/tree/main/database/flyway)
- [dbatools / dbops](https://github.com/JessAndRob/FabConEU_2026_workshop/tree/main/database/dbatools-dbops)

## Teardown

<!-- The nightly destroy workflows; deploying into your own sub = tear it down. -->

## What's next

Next: [Resources & next steps](resources.md).
```

- [ ] **Step 2: Create `docs/wrap-up/resources.md`**

```markdown
<!-- DRAFT: skeleton only. Prose to be fleshed out (task #22, Phase 3). -->

# Resources & next steps

<!-- INTRO: where to get everything and what to read next. -->

## Downloads

<!-- The per-module code bundles (packaging pipeline = task #12). -->

## Further reading

<!-- Terraform, SQL projects/DACPAC, Fabric SQL, GitHub Actions OIDC — key links. -->

## Feedback

<!-- How to give feedback → feeds our learnings. -->

## What's next

Back to [Home](../index.md).
```

- [ ] **Step 3: Create `docs/reference/other-tooling.md`**

```markdown
<!-- DRAFT: skeleton only. Prose to be fleshed out (task #22, Phase 3). -->

# Reference: other tooling

<!-- INTRO: "all as code" — every variant exists in the repo even though the taught path leads
     with Terraform + GitHub Actions + SQL projects. -->

| Area | Focus (taught) | Reference (also in the repo) |
|---|---|---|
| Infrastructure | Terraform | [Bicep](https://github.com/JessAndRob/FabConEU_2026_workshop/tree/main/infra/azure-sql/bicep) |
| CI/CD | GitHub Actions | [Azure DevOps](https://github.com/JessAndRob/FabConEU_2026_workshop/tree/main/infra/pipelines/azure-devops) |
| Database | SQL projects | [Flyway](https://github.com/JessAndRob/FabConEU_2026_workshop/tree/main/database/flyway) · [dbatools/dbops](https://github.com/JessAndRob/FabConEU_2026_workshop/tree/main/database/dbatools-dbops) |
```

- [ ] **Step 4: Final Phase-1 build gate + acceptance check**

Run: `mkdocs build --strict && find site -name '*.html' | sort && ls docs/setup docs/foundations docs/infra docs/database docs/cicd docs/wrap-up docs/reference`
Expected: build exit 0; `find` lists **only** `site/404.html` and `site/index.html`; all 12 stub files present across the listed directories.

- [ ] **Step 5: Verify `index.md` links no held page**

Run: `grep -nE '\]\((setup|foundations|infra|database|cicd|wrap-up|reference)/' docs/index.md`
Expected: **no matches** (the built teaser must not link to an excluded page).

- [ ] **Step 6: Commit**

```bash
git add docs/wrap-up/migrations-drift-teardown.md docs/wrap-up/resources.md docs/reference/other-tooling.md
git commit -m "Add wrap-up + reference page stubs (skeleton complete)" -m "migrations/drift/teardown, resources, other-tooling skeletons complete the Phase-1 site skeleton; mkdocs build --strict green, teaser-only." -m "<standard trailers from Global Constraints>"
```

---

## Self-Review

**1. Spec coverage** (against [design spec](2026-08-04-attendee-content-design.md) §8 Phase 1):
- All 12 §4 non-existing pages created → Tasks 1–5. ✅
- Full commented nav + `exclude_docs` for every new page → Task 1 steps 2–3. ✅
- Standard §5 template on each stub → Task 1 defines it; Tasks 2–5 instantiate. ✅
- `mkdocs build --strict` green, teaser-only, after every task → build gate in every task. ✅
- No built page links to an excluded page → Task 5 step 5 grep. ✅
- Fabric caveat (#20) + gate caveat (#21) present → Task 3 (`fabric-sql`), Task 4 (`deploy-infra`, `ship-database-changes`). ✅

**2. Placeholder scan:** The `<!-- ... -->` blocks are the intended stub content (this is a *skeleton* deliverable), not plan placeholders — every task states exactly what to create, with real links and the exact build/commit commands. `<standard trailers from Global Constraints>` resolves to the two verbatim trailer lines defined there. No "TBD"/"implement later" in the plan's own instructions. ✅

**3. Type consistency:** File paths, the `exclude_docs` list, and the nav entries match across Task 1 and the File Structure table; every `What's next` / `Follow along` relative link resolves to a real sibling path (verified against the directory layout). ✅

---

## Execution Handoff

Phase 1 is 5 tasks, each ending in a green `mkdocs build --strict` and a commit, on branch `docs/attendee-content-skeleton`.
