# Reference: other tooling

Everything today leads with **Terraform**, **GitHub Actions** and **SQL projects** — one clear
path, taught end to end. But those are not the only respectable ways to do any of this, and the
repository does not pretend otherwise. Every alternative we mention on stage is in there too, as
working code or as a documented reference, so nothing we say is hand-waved and you can pick the
tools that suit your own shop.

This page is the map to those alternatives. The taught path is the one we test, demo and stand
behind; the variants here are for the curious, and for anyone whose house already runs on a
different set of tools.

| Area | What we teach | Also in the repo |
|---|---|---|
| Infrastructure | Terraform | [Bicep](https://github.com/JessAndRob/FabConEU_2026_workshop/tree/main/infra/azure-sql/bicep) |
| CI/CD | GitHub Actions | [Azure DevOps](https://github.com/JessAndRob/FabConEU_2026_workshop/tree/main/infra/pipelines/azure-devops) |
| Database | SQL projects (DACPAC) | [Flyway](https://github.com/JessAndRob/FabConEU_2026_workshop/tree/main/database/flyway) · [dbatools / dbops](https://github.com/JessAndRob/FabConEU_2026_workshop/tree/main/database/dbatools-dbops) |

## Infrastructure — Bicep

If your world is Azure-native and you would rather not add a third-party tool, **Bicep** does the
same job as the Terraform modules. The repo carries a full mirror:

- [`infra/azure-sql/bicep`](https://github.com/JessAndRob/FabConEU_2026_workshop/tree/main/infra/azure-sql/bicep)
  — `main.bicep` (subscription scope) into `sql.bicep`: the logical server, database and firewall
  rules, Entra-only and serverless, matching the Terraform demo module resource for resource.
- [`infra/fabric-sql/bicep`](https://github.com/JessAndRob/FabConEU_2026_workshop/tree/main/infra/fabric-sql/bicep)
  — `main.bicep` into `capacity.bicep`, the **Fabric capacity only**. The Fabric workspace and SQL
  database have no ARM resource type, so there is nothing for Bicep to declare there; for those you
  use Terraform (the `microsoft/fabric` provider) or the Fabric REST API. The README says so plainly.

Both build clean with `az bicep build`, and the `.bicepparam` examples validate.

## CI/CD — Azure DevOps

The pipelines are taught in **GitHub Actions**, but the same flow — plan on a pull request, apply on
merge, tear down on a schedule — is mirrored for **Azure DevOps** in
[`infra/pipelines/azure-devops`](https://github.com/JessAndRob/FabConEU_2026_workshop/tree/main/infra/pipelines/azure-devops):
`ci.yml`, `azure-sql-plan.yml`, a two-stage `azure-sql-apply.yml` (apply, then publish and smoke
test) and a scheduled `azure-sql-destroy.yml`. Authentication is passwordless, using a
**workload-identity service connection** for OIDC parity with the GitHub Actions path.

The YAML is written and validated but not executed on stage — we have no Azure DevOps organisation
in the loop, so GitHub Actions is the live path and this is the reference. If Azure DevOps is your
home, it is a faithful starting point rather than a finished product.

## Database — Flyway and dbatools / dbops

SQL projects and a DACPAC are a **state-based** approach: you declare the schema you want, and
SqlPackage works out the difference. Plenty of teams prefer **migration-based** deployment instead —
an ordered set of scripts, each one applied once. The repo documents two migration paths, both
targeting the *same* canonical football schema so you can compare like with like:

- [`database/flyway`](https://github.com/JessAndRob/FabConEU_2026_workshop/tree/main/database/flyway)
  — versioned SQL migrations (`V1__*.sql`, `V2__*.sql`, …), the tool-agnostic migration story.
- [`database/dbatools/dbops`](https://github.com/JessAndRob/FabConEU_2026_workshop/tree/main/database/dbatools-dbops)
  — PowerShell-first migrations, close to home for anyone already living in
  [dbatools](https://dbatools.io).

!!! note "These two are reference notes, not finished modules"
    Bicep and Azure DevOps are built out; Flyway and dbatools/dbops are, for now, a README each
    describing the approach and the rule that keeps them honest — the resulting schema must match
    the SQL project exactly. They are on the list to grow into runnable examples, and the READMEs
    are the current state of play.

## The rule behind all of it

"All as code" is the point. The variant we teach earns the spotlight because it is the one we test
and demo; the others exist so the choice is yours and nothing here is a black box. Pick the tools
your team already trusts — the discipline is the same whichever you land on.
