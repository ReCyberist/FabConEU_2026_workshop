# Resources & next steps

--8<-- "includes/clock-afternoon-2.md"

Everything you saw today is in the repo, and here's where to go deeper.

## Downloads

!!! info "Per-module code bundles — coming soon"
    Downloadable bundles for each module will land here closer to the event (they're produced by a
    packaging pipeline — [task #12](https://github.com/JessAndRob/FabConEU_2026_workshop/blob/main/planning/tasks.md)).
    Until then, all the code lives in the
    [workshop repo](https://github.com/JessAndRob/FabConEU_2026_workshop) — fork it, and each page
    links to the exact files it walks through.

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
