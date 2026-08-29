# Welcome & how the day works

Welcome to a full day of deploying **Azure SQL and Fabric SQL as code**. By the end you will have
provisioned infrastructure, shipped a database schema, and wired both into CI/CD pipelines that do
it for you — **no clicking required**. Everything you see today, you can rebuild from the repository
tomorrow.

## How the day works

This is a **bring-your-own** workshop. Nothing is provisioned for you: you use whatever cloud you
already have, or none at all. The hands-on work splits into **two independent, optional parts**, and
you choose your own level for each.

- **Watch.** Every step is a live demo. Sit back, follow the reasoning, and download the code later.
- **Part 1 — deploy infrastructure** as code, into your own Azure subscription. Azure SQL, Fabric
  SQL, or both.
- **Part 2 — ship database changes** as code, into a target SQL endpoint. Use your own, or the
  shared endpoint we run on the day — which is best-effort and **unsupported**.

The two parts are independent. You can do Part 2 without Part 1, as long as you already have a
target SQL endpoint to deploy into. All three levels are equally respectable, and you can change
your mind at any point in the day.

👉 **[Prerequisites](prerequisites.md)** lists what each level needs, and what to install before
you arrive.

!!! tip "Prose here, code in the repository"
    You **read** the steps on this site. You **download and run** the code from the
    [workshop repository](https://github.com/JessAndRob/FabConEU_2026_workshop). Pages link to the
    real files and show short excerpts rather than large blocks, so what you run is exactly what is
    version controlled — never a copy that has quietly drifted out of date.

## What we'll cover

In this order, with **Azure SQL and Fabric SQL shown side by side** throughout.

1. **The hardest part of IT** — the people, the egos and the feelings that no tool can fix. It goes
   first on purpose. Everything after it — branching, review, approval gates, who is allowed to drop
   a column — is a people problem before it is a technical one. A people problem wearing a YAML
   costume.
2. **[Source control for databases](../foundations/source-control.md)** — one git repository as the
   single source of truth, and the pull-request flow the whole day rides on.
3. **Infrastructure as code** — provision [Azure SQL](../infra/azure-sql.md) and
   [Fabric SQL](../infra/fabric-sql.md) with Terraform, side by side.
4. **[Database as code](../database/sql-projects.md)** — define the schema in a SQL project and
   build it into a deployable DACPAC.
5. **CI/CD** — [build and validate](../cicd/build-validate.md) on every pull request,
   [deploy infrastructure](../cicd/deploy-infra.md) from the pipeline, and then the part everything
   else has been building towards: [ship database changes](../cicd/ship-database-changes.md)
   safely, with the pipeline telling you what a change will do to your data *before* it does it.
6. **[Migrations, drift and teardown](../wrap-up/migrations-drift-teardown.md)** — the alternative
   approaches, keeping the real world and the declared world in step, and always tearing it down
   afterwards.

!!! info "The breaks are fixed; the teaching flexes"
    Coffee breaks and lunch are set by the venue, so those times are not ours to move. Each
    follow-along segment has a point at which we move on regardless of who has finished.

    Every module page ends with a **Checkpoint** section describing exactly where you should be
    at that point — which resources exist, and what should be working. If you fall behind, or
    something in your own subscription misbehaves, read the Checkpoint, skip to the next module,
    and pick the rest up later from the downloads. Nobody gets stranded, and nobody has to admit
    out loud that they are lost.

## A note on the sample data

We build the day against a real football database, covering both the men's and the women's game.
It is more interesting than `Northwind`, and it gives us realistic schema changes to ship: a new
season, a renamed competition, a column nobody thought about until the transfer window opened.

## What's next

Next: [Prerequisites](prerequisites.md) — what to bring if you want to follow along.
