# CI/CD — GitHub Actions (content focus)

The **taught** CI/CD path. Workflows here provision infrastructure and ship database
changes automatically.

Planned workflows:
- **build/validate** — on PR: `terraform plan`, build the DACPAC from the SQL project,
  run checks. No changes to live resources.
- **deploy-infra** — on merge/approval: `terraform apply` per environment.
- **deploy-database** — deploy the DACPAC to Azure SQL & Fabric SQL.
- **package-downloads** — zip each module's code for the attendee site.
- **publish-site** — build MkDocs and deploy to GitHub Pages.

Use environments + required reviewers for the apply/deploy stages. No secrets in YAML —
use GitHub Actions secrets/OIDC to Azure.
