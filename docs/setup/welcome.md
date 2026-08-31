# Welcome & how the day works

Welcome to a full day of deploying **Azure SQL and Fabric SQL as code**. By the end you will have
provisioned infrastructure, shipped a database schema, and wired both into CI/CD pipelines that do
it for you — **no clicking required**. Everything you see today, you can rebuild from the repository
tomorrow.

## How the day works

This is a **bring-your-own** workshop. There is no lab environment: you deploy into whatever cloud
you already have, or you watch and replay it later. The hands-on work splits into **two
independent, optional parts**, and you choose your own level for each.

- **Watch.** Every step is a live demo. Sit back, follow the reasoning, and download the code later.
- **Part 1 — deploy infrastructure** as code, into your own Azure subscription. Azure SQL, Fabric
  SQL, or both.
- **Part 2 — ship database changes** as code, into a target SQL endpoint. Use your own, or — if you
  have no endpoint to deploy into — the one shared SQL Server we run on the day, which is
  best-effort and **unsupported**.

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

## The shape of the day

We run from **09:00 to 17:00**. The breaks and lunch are set by the venue, so those times are
fixed and we work around them.

| Time | What |
|---|---|
| **09:00 – 10:30** | The hardest part of IT, and source control for databases |
| 10:30 – 11:00 | ☕ Break |
| **11:00 – 12:15** | Infrastructure as code — Azure SQL and Fabric SQL, side by side |
| **12:15 – 12:45** | Database as code — from database to DACPAC |
| 12:45 – 14:00 | 🍽 Lunch |
| **14:00 – 15:15** | SQL projects — making changes, breaking things, testing |
| 15:15 – 15:45 | ☕ Break |
| **15:45 – 17:00** | Pulling it all together, and your questions |
| 17:00 | End |

Two promises about those times.

**We start at 09:00, and we do not wait.** Barcelona is a city with opinions about breakfast, and
we understand entirely — but the room that arrived on time has a day to get through. If you come
in late, come in anyway: sit down, say nothing, and pick up the thread. We will not rewind, and
nobody will make you feel awkward about it.

**The breaks and lunch start on time too.** We stop when the clock says stop, even mid-sentence,
and we would rather cut our own material than eat into your coffee. Jess takes food extremely
seriously, and a workshop that runs into lunch is a workshop that has already lost the room.

!!! info "Falling behind is fine, and entirely expected"
    Each follow-along segment has a point at which we move on, whether or not everyone has
    finished. That is not us being unkind — it is the only way the room stays together.

    Every module page ends with a **Checkpoint** section describing exactly where you should be
    at that point: which resources exist, and what should be working. If you fall behind, or your
    own subscription decides to have a moment, read the Checkpoint, rejoin at the next module, and
    pick the rest up afterwards from the downloads. Nobody gets stranded, and nobody has to admit
    out loud that they are lost.

## Being good to each other

We would like everyone to leave having learnt something, which mostly comes down to a few small
courtesies.

- **Take phone calls outside.** Nobody minds you stepping out — that is what the door is for.
  Please put phones and laptops on silent while you are in the room.
- **Ask questions.** If something does not make sense, say so. Somebody else in the room is
  quietly wondering the same thing, and you will be doing them a favour. There is no question here
  too basic to ask.
- **Expect other people to do things differently.** This room will contain people who swear by
  Bicep, people who will never give up Flyway, and at least one person who is genuinely happy with
  their existing process. They are not wrong, they are solving a different problem. Argue with the
  idea by all means; never with the person holding it.
- **Mind the shared endpoint.** If you are using it, you are sharing it with the person next to
  you. Deploy your own database, leave everybody else's alone.

The conference code of conduct applies for the whole day, and we will happily enforce it.

## A note on the sample data

We build the day against a real football database, covering both the men's and the women's game.
It is more interesting than `Northwind`, and it gives us realistic schema changes to ship: a new
season, a renamed competition, a column nobody thought about until the transfer window opened.

## What's next

Next: [Prerequisites](prerequisites.md) — what to bring if you want to follow along.
