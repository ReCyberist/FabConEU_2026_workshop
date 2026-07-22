# Tasks — ownership, status, deadlines

Status: `TODO` · `DOING` · `BLOCKED` · `DONE`. Owner: **J** (Jess) / **R** (Rob) / _open_.

| # | Task | Owner | Status | Due | Notes |
|---|------|-------|--------|-----|-------|
| 1 | Decide attendee sandbox strategy (own sub / shared / lab provider) | J + R | DONE | 2026-07-18 | **Decided D6: bring-your-own.** 2 independent parts (IaC needs own Azure sub; DB deploy needs a target SQL) + shared **unsupported** endpoint = **SQL Server on a VM**, pushed to via pipeline (→ #18). **Deferred:** Fabric-path capacity cost; *our* CI state owner (#17). See [`../notes/decisions.md`](../notes/decisions.md) D6. |
| 2 | Write attendee prerequisites page in `docs/` | — | TODO | — | **Unblocked by #1 (D6).** Two optional paths + shared unsupported endpoint; cost/teardown warnings. Prereq checklist drafted in [`ordering.md`](ordering.md). |
| 3 | Build canonical sample DB schema (football theme) | J | DONE | 2026-07-04 | Men's + women's. 9 tables, 3 views, 3 sps + seed. Builds to DACPAC. In `database/sql-projects`. |
| 4 | Terraform: Azure SQL module | J | DONE | 2026-07-08 | `infra/azure-sql/terraform`: RG + server + DB + firewall. CAF naming, Entra-only (passwordless), serverless DB. `fmt`/`validate`/`plan` clean (5 to add). Live `apply` untested → #14. |
| 5 | Terraform: Fabric SQL module | J | DONE | 2026-07-18 | `infra/fabric-sql/terraform`: RG + **Fabric capacity** (azurerm, F2) + **workspace** + **SQL database** (microsoft/fabric ~>1.12). Passwordless, CAF naming (capacity name is alnum-only). `fmt`/`init`/`validate` clean vs real schemas; live `plan`/`apply` untested → #14. |
| 6 | Bicep equivalents (reference) | — | TODO | — | Bonus/reference. |
| 7 | SQL project (`.sqlproj`) for sample DB | J | DONE | 2026-07-08 | Schema + seed build clean. Publish profiles for Azure SQL + Fabric SQL in `PublishProfiles/`; validated by SqlPackage (no live target — see #14). |
| 8 | GitHub Actions: build/validate pipeline | J + R | DOING | — | `ci.yml` builds SQL project + T-SQL static analysis (`-warnaserror`), runs on push + PR. Add terraform/bicep/docs jobs next. |
| 9 | GitHub Actions: deploy infra + DB pipeline | — | TODO | — | Content focus. |
| 10 | Azure DevOps pipeline equivalents (reference) | — | TODO | — | Bonus/reference. |
| 11 | MkDocs site skeleton + Pages deploy workflow | J | DONE | 2026-07-18 | `pages.yml` deploys to GitHub Pages on push to `main` (artifact deploy, `github-pages` env). Verified `mkdocs build --strict` clean. **One-time:** set Pages source to "GitHub Actions" (`gh api` cmd in workflow header). |
| 12 | Code-bundle packaging pipeline (zip per module) | — | TODO | — | Prose=pages, code=downloads. |
| 13 | Full dry run + timing pass | J + R | TODO | — | Feed results into agenda + learnings. |
| 14 | Runtime-test schema: publish DACPAC + seed to a real DB | — | TODO | — | Verify views/procs/seed against Azure SQL & Fabric SQL. No local engine in dev today. |
| 15 | Design the "ship changes as code" increments | — | TODO | — | Baseline exists; plan the PR-driven schema changes for the 15:30 agenda module. Demo idea captured in [`Ideas.md`](../notes/Ideas.md): Dev/Test Fabric SQL pipeline, add view + drop populated column, show blind-deploy data loss vs. schema-compare-then-apply. |
| 16 | Attendee page: sample database (ER diagram) | J | DONE | 2026-07-04 | `docs/database/sample-database.md`, Mermaid `erDiagram`. |
| 17 | Terraform remote state backend (Azure Storage) + bootstrap | — | TODO | — | Decided **D5**: `azurerm` backend, OIDC + Entra auth, per-module state keys, `az` bootstrap script. **Gate partly cleared by D6:** no shared *attendee* state (BYO → local state per attendee); this is only for **our** CI/demo state — owner deferred ("decide later"). Retrofit #4/#5 once landed. |
| 18 | Shared unsupported DB-deploy target: SQL Server on a VM + push pipeline | — | TODO | — | From **D6**. One SQL Server VM as the best-effort, **unsupported** target for attendees without their own SQL; each attendee gets their own DB (no DACPAC name collisions); deploy via pipeline. Provision + teardown as code. |

Add tasks as they arise; close them when done and note anything learned.
