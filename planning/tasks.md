# Tasks — ownership, status, deadlines

Status: `TODO` · `DOING` · `BLOCKED` · `DONE`. Owner: **J** (Jess) / **R** (Rob) / _open_.

| # | Task | Owner | Status | Due | Notes |
|---|------|-------|--------|-----|-------|
| 1 | Decide attendee sandbox strategy (own sub / shared / lab provider) | — | TODO | — | Gates prerequisites. See [`ordering.md`](ordering.md). |
| 2 | Write attendee prerequisites page in `docs/` | — | TODO | — | Depends on #1. |
| 3 | Build canonical sample DB schema (football theme) | J | DONE | 2026-07-04 | Men's + women's. 9 tables, 3 views, 3 sps + seed. Builds to DACPAC. In `database/sql-projects`. |
| 4 | Terraform: Azure SQL module | J | DONE | 2026-07-08 | `infra/azure-sql/terraform`: RG + server + DB + firewall. CAF naming, Entra-only (passwordless), serverless DB. `fmt`/`validate`/`plan` clean (5 to add). Live `apply` untested → #14. |
| 5 | Terraform: Fabric SQL module | — | TODO | — | Side by side with #4. |
| 6 | Bicep equivalents (reference) | — | TODO | — | Bonus/reference. |
| 7 | SQL project (`.sqlproj`) for sample DB | J | DOING | — | Schema + seed build clean. TODO: publish profiles for Azure SQL + Fabric SQL targets. |
| 8 | GitHub Actions: build/validate pipeline | J + R | DOING | — | `ci.yml` builds SQL project + T-SQL static analysis (`-warnaserror`), runs on push + PR. Add terraform/bicep/docs jobs next. |
| 9 | GitHub Actions: deploy infra + DB pipeline | — | TODO | — | Content focus. |
| 10 | Azure DevOps pipeline equivalents (reference) | — | TODO | — | Bonus/reference. |
| 11 | MkDocs site skeleton + Pages deploy workflow | — | TODO | — | `mkdocs.yml` exists; Mermaid enabled; CI builds docs on change. Still need the **Pages deploy** workflow. |
| 16 | Attendee page: sample database (ER diagram) | J | DONE | 2026-07-04 | `docs/database/sample-database.md`, Mermaid `erDiagram`. |
| 12 | Code-bundle packaging pipeline (zip per module) | — | TODO | — | Prose=pages, code=downloads. |
| 13 | Full dry run + timing pass | J + R | TODO | — | Feed results into agenda + learnings. |
| 14 | Runtime-test schema: publish DACPAC + seed to a real DB | — | TODO | — | Verify views/procs/seed against Azure SQL & Fabric SQL. No local engine in dev today. |
| 15 | Design the "ship changes as code" increments | — | TODO | — | Baseline exists; plan the PR-driven schema changes for the 15:30 agenda module. |

Add tasks as they arise; close them when done and note anything learned.
