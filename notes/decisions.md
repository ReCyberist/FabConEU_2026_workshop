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

## D6 — Attendee sandbox: bring-your-own, two independent lab parts, one unsupported shared endpoint
**Date:** 2026-07-18
**Decision:** We do **not** provision per-attendee sandboxes. Attendees use **whatever cloud
access they already have**. The hands-on splits into **two independent parts**, each gated on
what the attendee brings:
1. **IaC part** — needs their **own Azure subscription** with rights to create resources (and,
   for the Fabric path, a Fabric capacity). Have it → deploy along; don't → follow/watch.
2. **Database-deploy part** — needs a **target SQL** (an Azure SQL or Fabric SQL endpoint they
   can reach). Have one → deploy; don't → follow/watch.
The parts are **independent**: you can do part 2 without part 1 if you already have a target
SQL. Attendees can **build along live or replay later** — both supported. On the day we
provide **one shared SQL endpoint** as a best-effort target for part 2, **explicitly
unsupported** (we will not troubleshoot it), so people with nothing of their own can still try.
**Why:** We can't spend the day troubleshooting heterogeneous lab environments, and providing
managed sandboxes creates an expectation and a support burden ("if we provide something they'll
expect that"). BYO keeps us out of the provisioning/support business while letting everyone
participate at some level. (Rob + Jess, chat 2026-07-18.)
**Consequence:**
- The attendee **prerequisites page (#2)** can now be written: state the two paths, what each
  needs, cost + teardown warnings, and that the shared endpoint is unsupported. **Unblocks #2.**
- **Partly resolves #17's gate:** there is *no shared attendee state account* to own —
  attendees run their own state (local state is fine for a one-shot lab). The owner of *our
  own* CI/demo state backend is deferred ("decide later", task #17).
- **The shared endpoint is a SQL Server on a VM** (2026-07-18): attendees push their database
  changes to it **via pipeline**, unsupported. A full SQL Server instance hosts a database per
  attendee, so the DACPAC name-collision problem goes away (each attendee owns their own DB on
  the one instance). Provisioning it is **task #18**.
- **Deferred ("decide later"):** the Fabric IaC path's capacity cost (an F-SKU bills; a trial
  capacity can't be Terraform-created), and the CI/demo state owner (#17). Both noted as open
  caveats; neither blocks the prerequisites page.
