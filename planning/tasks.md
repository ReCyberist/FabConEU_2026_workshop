# Tasks — ownership, status, deadlines

Status: `TODO` · `DOING` · `BLOCKED` · `DONE`. Owner: **J** (Jess) / **R** (Rob) / _open_.

| # | Task | Owner | Status | Due | Notes |
|---|------|-------|--------|-----|-------|
| 1 | Decide attendee sandbox strategy (own sub / shared / lab provider) | — | TODO | — | Gates prerequisites **and** the tf state backend owner (#17). See [`ordering.md`](ordering.md). |
| 2 | Write attendee prerequisites page in `docs/` | — | TODO | — | Depends on #1. |
| 3 | Build canonical sample DB schema (football theme) | J | DONE | 2026-07-04 | Men's + women's. 9 tables, 3 views, 3 sps + seed. Builds to DACPAC. In `database/sql-projects`. |
| 4 | Terraform: Azure SQL module | J | DONE | 2026-07-08 | `infra/azure-sql/terraform`: RG + server + DB + firewall. CAF naming, Entra-only (passwordless), serverless DB. `fmt`/`validate`/`plan` clean (5 to add). Remote state + OIDC wired up (see #17); apply/destroy workflows added (#9). Live `apply` still to run → #14. |
| 5 | Terraform: Fabric SQL module | — | TODO | — | Side by side with #4. |
| 6 | Bicep equivalents (reference) | — | TODO | — | Bonus/reference. |
| 7 | SQL project (`.sqlproj`) for sample DB | J | DONE | 2026-07-08 | Schema + seed build clean. Publish profiles for Azure SQL + Fabric SQL in `PublishProfiles/`; validated by SqlPackage (no live target — see #14). |
| 8 | GitHub Actions: build/validate pipeline | J + R | DOING | — | `ci.yml` builds SQL project + T-SQL static analysis (`-warnaserror`), runs on push + PR. Add terraform/bicep/docs jobs next. |
| 9 | GitHub Actions: deploy infra + DB pipeline | J | DOING | 2026-07-22 | `azure-sql-apply.yml` (manual) + `azure-sql-destroy.yml` (nightly 21:00 UTC + manual) for the Azure SQL module against J's personal sandbox sub. OIDC auth, no secrets. **DB-deploy job added** (2026-07-29): `publish` job `needs: apply`, builds the DACPAC and SqlPackage-publishes into the provisioned DB via Entra token + `AzureSql.publish.xml`. **Unverified end-to-end** — blocked on #18 (CI SP can't log into the Entra-only DB yet). |
| 10 | Azure DevOps pipeline equivalents (reference) | — | TODO | — | Bonus/reference. |
| 11 | MkDocs site skeleton + Pages deploy workflow | J | DONE | 2026-07-18 | `pages.yml` deploys to GitHub Pages on push to `main` (artifact deploy, `github-pages` env). Verified `mkdocs build --strict` clean. **One-time:** set Pages source to "GitHub Actions" (`gh api` cmd in workflow header). |
| 12 | Code-bundle packaging pipeline (zip per module) | — | TODO | — | Prose=pages, code=downloads. |
| 13 | Full dry run + timing pass | J + R | TODO | — | Feed results into agenda + learnings. |
| 14 | Runtime-test schema: publish DACPAC + seed to a real DB | J | DOING | — | **Live Azure SQL target now exists** (2026-07-29): first `azure-sql-apply.yml` run succeeded in UK South (`sqldb-football-dev` on `sql-fabcon26-dev-uks-lmf5m4`). Publish job wired (#9) but not yet run against it — blocked on #18. Still need Fabric SQL side. Nightly destroy tears the DB down at 21:00 UTC, so verify runs must fit before then (or pause the destroy). |
| 15 | Design the "ship changes as code" increments | — | TODO | — | Baseline exists; plan the PR-driven schema changes for the 15:30 agenda module. Demo idea captured in [`Ideas.md`](../notes/Ideas.md): Dev/Test Fabric SQL pipeline, add view + drop populated column, show blind-deploy data loss vs. schema-compare-then-apply. |
| 16 | Attendee page: sample database (ER diagram) | J | DONE | 2026-07-04 | `docs/database/sample-database.md`, Mermaid `erDiagram`. |
| 17 | Terraform remote state backend (Azure Storage) + bootstrap | J | DOING | 2026-07-22 | Decided **D5**: `azurerm` backend, OIDC + Entra auth, per-module state keys. **Personal-sandbox instance landed**: `stfabcon26tf4766a4` in its own persistent `rg-fabcon26-state-weu` (kept separate from workload RGs so nightly destroy never touches state). Retrofitted into #4. **Still open:** the *attendee-facing* state account owner/strategy — blocked on #1. |

| 18 | Grant CI service principal access to the Entra-only Azure SQL DB | — | TODO | — | The server is `azuread_authentication_only = true` with a **user** as Entra admin, so the GitHub Actions OIDC SP (`AZURE_CLIENT_ID`) can't log into the DB — blocks the #9 `publish` job and #14 verify. A server allows one Entra admin (user *or* group). Recommended: create an Entra **group**, add presenter + CI SP, point `SQL_ENTRA_ADMIN_OBJECT_ID` at the group. Keep it "as code" and reusable for attendees. |

Add tasks as they arise; close them when done and note anything learned.
