# CI/CD — GitHub Actions (content focus)

The **taught** CI/CD path. Workflows here provision infrastructure and ship database
changes automatically.

Landed workflows:
- **[`azure-sql-apply.yml`](../../../.github/workflows/azure-sql-apply.yml)** —
  manual (`workflow_dispatch`): `terraform apply` for `infra/azure-sql/terraform` against
  the personal sandbox subscription. OIDC auth, remote `azurerm` state.
- **[`azure-sql-destroy.yml`](../../../.github/workflows/azure-sql-destroy.yml)** —
  nightly at 21:00 UK time (DST-aware) + manual: `terraform destroy` for the same module,
  so nothing is left running (and billing) overnight.
- **`pages.yml`** — deploy MkDocs to GitHub Pages on push to `main`.

Planned workflows:
- **build/validate** — on PR: `terraform plan`, build the DACPAC from the SQL project,
  run checks. No changes to live resources.
- **deploy-database** — deploy the DACPAC to Azure SQL & Fabric SQL.
- **package-downloads** — zip each module's code for the attendee site.

Use environments + required reviewers for the apply/deploy stages. No secrets in YAML —
use GitHub Actions secrets/OIDC to Azure.
