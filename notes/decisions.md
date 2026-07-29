# Decisions (ADR-lite)

Why we chose what we chose. When a learning overturns a decision, add a new dated entry
rather than silently rewriting history, and update [`../CLAUDE.md`](../CLAUDE.md) §2.

---

## D1 — Cover both Azure SQL and Fabric SQL, side by side
**Date:** 2026-07-01
**Decision:** The workshop teaches both platforms in parallel, comparing them, rather than
picking one.
**Why:** The abstract title is "Azure SQL **or** Fabric SQL" and the FabCon audience wants
to understand the trade-offs and migration story between them. Tabbed content in MkDocs
makes side-by-side comparison natural.
**Consequence:** More content to build and keep in sync; use tabs and shared modules to
avoid duplication.

## D2 — All IaC/CI-CD tooling as code; content focuses on Terraform + GitHub Actions
**Date:** 2026-07-01
**Decision:** Ship working Terraform **and** Bicep for infra, and GitHub Actions **and**
Azure DevOps pipelines — but the written pages and live demos lead with **Terraform +
GitHub Actions**.
**Why:** Attendees use different stacks; having every variant in the repo makes us credible
and useful. But teaching all of them at once dilutes the day, so the narrative picks one
opinionated path (Terraform + GitHub Actions) and treats the rest as reference/bonus.
**Consequence:** Each infra module needs parallel implementations kept roughly in step.

## D3 — Database as code: all approaches present; content focuses on SQL projects
**Date:** 2026-07-01
**Decision:** Provide SQL projects (`.sqlproj`/DACPAC), Flyway, and dbatools/dbops as
working code. Written content focuses on **SQL projects**.
**Why:** SQL projects are the native, state-based path for SQL/Fabric and integrate
cleanly with the pipelines; the migration-based options (Flyway, dbatools/dbops) matter to
part of the audience and to our own dbatools heritage, so they stay in the repo.
**Consequence:** Sample database schema must be expressible in all three; keep one canonical
schema.

## D4 — Attendee site: MkDocs Material on GitHub Pages
**Date:** 2026-07-01
**Decision:** Build the attendee site with MkDocs Material, publish via GitHub Pages.
**Why:** Low-friction, excellent for technical docs (nav, admonitions, tabs, code blocks),
Python toolchain the presenters are comfortable with. Prose as pages, code as downloads.
**Consequence:** Need `mkdocs.yml`, `requirements.txt`, and a Pages deploy workflow.

## D5 — Terraform state: remote azurerm backend (Azure Storage) for both CI and attendees
**Date:** 2026-07-09
**Decision:** Store Terraform state in an **Azure Storage Account** via the `azurerm`
backend for **both** the CI/CD pipeline and attendees running the lab — not local state.
Passwordless auth throughout: **OIDC** federated credentials from GitHub Actions, and
**Entra** auth to the blob (`use_azuread_auth`, not storage account keys). One state key per
module/environment (e.g. `azure-sql/dev.tfstate`). A one-time idempotent **bootstrap**
(`az` CLI script) provisions the state resource group + storage account (globally-unique
name, blob versioning + soft-delete on, public access off), sidestepping the chicken-and-egg
of a backend that doesn't exist yet.
**Why:** Local state can't survive GitHub Actions' ephemeral runners — no persistence, no
locking, nothing shared between the plan and apply jobs. The workshop's whole thesis is
CI/CD that provisions infrastructure, so remote state with locking is the honest taught
path, not a deferral.
**Consequence:** Need the bootstrap script + `-backend-config` wiring (backend blocks can't
take variables). **Who** creates and owns the state storage account depends on the attendee
sandbox model, so this is gated on **task #1**. Tracked as **task #17**; the initial
`infra/azure-sql/terraform` module ships with local state until #17 lands. Also revisit the
repo's gitignore of `.terraform.lock.hcl` (HashiCorp recommends committing it).

**Update 2026-07-22:** Landed for J's **personal sandbox** subscription — storage account
`stfabcon26tf4766a4` in its own persistent `rg-fabcon26-state-weu` (deliberately outside the
workload resource group, so the nightly destroy workflow can never delete the state store
itself), OIDC app registration + federated credential scoped to `ref:refs/heads/main`,
`Contributor` at subscription scope + `Storage Blob Data Contributor` on the state account.
`.terraform.lock.hcl` un-ignored and committed per the note above. This resolves D5 for
personal/demo use only — the *attendee-facing* bootstrap script and state-account ownership
are still open, gated on #1 as originally decided.

**Update 2026-07-29:** Split the pipeline into *plan on PR, apply on intent*. Added
`azure-sql-plan.yml` — a read-only `fmt`/`validate`/`plan` (`-lock=false`) that runs on
`pull_request` events touching `infra/azure-sql/**` — while `apply` stays a manual
`workflow_dispatch` from `main`. This needed a **second** federated credential on the
`fabcon26-github-actions` app: `fabcon26-github-pr`, subject
`repo:JessAndRob/FabConEU_2026_workshop:pull_request` (a PR run's OIDC subject is
`…:pull_request`, not a branch ref, so `…:ref:refs/heads/main` doesn't match it). Cements
plan-on-PR as the taught CI/CD pattern for the module and keeps `apply` deliberate.
