# Welcome & how the day works

Welcome to a full day of deploying **Azure SQL and Fabric SQL as code**. By the end you'll have
provisioned infrastructure, shipped a database schema, and wired both into CI/CD pipelines that do
it automatically — **no clicking required**. Everything you see, you can rebuild from the repo.

!!! note "Follow along — or just watch"
    There's no lab handed out. Bring your own Azure / Fabric kit and follow along, or just watch and
    replay later from the downloads. See [Prerequisites](prerequisites.md).

## How the day works

This is a **bring-your-own** workshop — you use whatever cloud you already have (or none). The
hands-on splits into **two independent, optional parts**, and you choose your level for each:

- **Just watch.** Every step is a live demo. Sit back, follow the reasoning, grab the code later.
- **Deploy infrastructure** as code, into your own Azure subscription (Azure SQL and/or Fabric SQL).
- **Ship database changes** as code, into a SQL target — your own, or the shared endpoint we stand
  up on the day (best-effort and **unsupported** — see [Prerequisites](prerequisites.md)).

The two parts are independent: you can do the database part without the infrastructure part if you
already have a database to deploy into.

!!! tip "Prose here, code in the repo"
    You **read** the steps on this site; you **download and run** the code from the
    [workshop repo](https://github.com/JessAndRob/FabConEU_2026_workshop). Pages link to the real
    files and show short excerpts rather than big blocks — so what you run is exactly what's version
    controlled, never a copy that's drifted.

## What we'll cover

Roughly in order, with **Azure SQL and Fabric SQL shown side by side** throughout:

1. **The hardest part of IT** — the people, egos and feelings the tooling can't fix. It goes first
   on purpose: everything after it (branching, review, approval gates, who's allowed to drop a
   column) is a people problem wearing a YAML costume.
2. **[Source control for databases](../foundations/source-control.md)** — one git repo as the single
   source of truth; the PR-driven flow the whole day rides on.
3. **Infrastructure as code** — provision [Azure SQL](../infra/azure-sql.md) and
   [Fabric SQL](../infra/fabric-sql.md) with Terraform, side by side.
4. **[Database as code](../database/sql-projects.md)** — define the schema in a SQL project and
   build it into a deployable DACPAC.
5. **CI/CD** — [build & validate](../cicd/build-validate.md) on every PR,
   [deploy infrastructure](../cicd/deploy-infra.md) from the pipeline, and the punchline:
   [ship database changes](../cicd/ship-database-changes.md) safely, with the pipeline telling you
   what a change will do to your data *before* it does it.
6. **[Migrations, drift & teardown](../wrap-up/migrations-drift-teardown.md)** — the alternatives,
   keeping real and declared in sync, and always tearing it down.

!!! info "The breaks are fixed; the teaching flexes"
    Coffee breaks and lunch are set by the venue. Each follow-along segment has a hard "we move on"
    point, and we publish the checkpoint state so anyone building along — or just watching — stays in
    sync. Fall behind? Grab the checkpoint and rejoin at the next module.

## What's next

Next: [Prerequisites](prerequisites.md) — what to bring if you want to follow along.
