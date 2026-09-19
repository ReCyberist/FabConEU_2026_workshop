# Resources, contacts & next steps

--8<-- "includes/clock-afternoon-2.md"

This is where the day lands: **16:30–17:00** is questions and where to go next. Everything you saw
today is in the repo, here's where to go deeper, and here's how to find us afterwards.

## The code

Everything you saw today, and the day itself, in four links:

- **Repo** — [github.com/JessAndRob/FabConEU_2026_workshop](https://github.com/JessAndRob/FabConEU_2026_workshop)
  — fork it, and each page links to the exact files it walks through.
- **Site** — [jessandrob.github.io/FabConEU_2026_workshop](https://jessandrob.github.io/FabConEU_2026_workshop/)
  — these pages, to read again at your own pace.
- **Code bundles** — [per-module zips](https://github.com/JessAndRob/FabConEU_2026_workshop/releases/tag/bundles-latest),
  rebuilt automatically on every push to `main` by the
  [packaging workflow](https://github.com/JessAndRob/FabConEU_2026_workshop/blob/main/.github/workflows/bundle.yml).
  Grab a single module, or fork the whole repo above.
- **Learnings log** — [every gotcha we hit, with the fix](https://github.com/JessAndRob/FabConEU_2026_workshop/blob/main/notes/LEARNINGS.md).
  The honest running notes from building this workshop, edges and all.

## Further reading

The tools behind the taught path (Terraform + GitHub Actions + SQL projects), plus the Fabric
specifics:

- **Terraform** — [azurerm provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
  (Azure SQL + the Fabric capacity) and the
  [microsoft/fabric provider](https://registry.terraform.io/providers/microsoft/fabric/latest/docs)
  (Fabric workspace + SQL database).
- **SQL projects & DACPAC** — [Microsoft.Build.Sql (SDK-style SQL projects)](https://learn.microsoft.com/sql/tools/sql-database-projects/sql-database-projects)
  and [SqlPackage](https://learn.microsoft.com/sql/tools/sqlpackage/sqlpackage).
- **SQL database in Fabric** — [overview](https://learn.microsoft.com/fabric/database/sql/overview),
  [limitations](https://learn.microsoft.com/fabric/database/sql/limitations), and
  [SqlPackage against Fabric](https://learn.microsoft.com/fabric/database/sql/sqlpackage).
- **Passwordless CI/CD** — [authenticate GitHub Actions to Azure with OIDC](https://learn.microsoft.com/azure/developer/github/connect-from-azure-openid-connect).
- **Naming** — the [Cloud Adoption Framework naming conventions](https://learn.microsoft.com/azure/cloud-adoption-framework/ready/azure-best-practices/resource-naming)
  the modules follow.

## Find us

Come and say hello at the break or after the session — questions, war stories, and disagreements
all welcome.

You can also reach us after the day:

- **Jess Pomfret** — [jesspomfret.com](https://jesspomfret.com)
- **Rob Sewell** — [blog.robsewell.com](https://blog.robsewell.com)

And two open-source projects we help maintain, if you want to go further with PowerShell and SQL
Server:

- **dbatools** — [dbatools.io](https://dbatools.io) — the community PowerShell toolkit for SQL Server.
- **dbachecks** — [dbachecks.io](https://dbachecks.io) — configurable, environment-wide SQL Server
  validation.

## Feedback

Loved it, or spotted something we can do better? **Rate the session in the FabCon Europe app /
session survey** — it's the fastest way to reach us and the organisers, and it genuinely shapes the
next version of this workshop. You're also welcome to open an issue on the
[repo](https://github.com/JessAndRob/FabConEU_2026_workshop/issues).

## What's next

That's the day: infrastructure **and** databases, deployed as code, on both Azure SQL and Fabric
SQL — nothing clicked. Take the repo, deploy it into your own world, and tear it down when you're
done.

Back to [Home](../index.md).
