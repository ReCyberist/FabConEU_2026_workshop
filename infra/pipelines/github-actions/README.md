# CI/CD — GitHub Actions (content focus)

The **taught** CI/CD path. Workflows here provision infrastructure and ship database
changes automatically.

Landed workflows:
- **[`azure-sql-apply.yml`](../../../.github/workflows/azure-sql-apply.yml)** —
  `terraform apply` against the personal sandbox subscription. Runs on **push to `main`**
  (a `detect-changes` job routes to the demo and/or shared-endpoint flow whose files changed —
  "plan on PR, apply on merge") and on manual `workflow_dispatch` with a `target` input.
  OIDC auth, remote `azurerm` state.
- **[`azure-sql-destroy.yml`](../../../.github/workflows/azure-sql-destroy.yml)** —
  nightly at 21:00 UTC + manual: `terraform destroy` for the same module,
  so nothing is left running (and billing) overnight.
- **`pages.yml`** — deploy MkDocs to GitHub Pages on push to `main`.

Planned workflows:
- **build/validate** — on PR: `terraform plan`, build the DACPAC from the SQL project,
  run checks. No changes to live resources.
- **deploy-database** — deploy the DACPAC to Azure SQL & Fabric SQL.
- **package-downloads** — zip each module's code for the attendee site.

Use environments + required reviewers for the apply/deploy stages. No secrets in YAML —
use GitHub Actions secrets/OIDC to Azure.
