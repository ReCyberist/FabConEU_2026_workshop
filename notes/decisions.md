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
