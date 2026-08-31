# Source control for databases

--8<-- "includes/clock-morning-1.md"

Everything that describes your infrastructure **and** your database lives in **one git
repository** — the single source of truth. Nothing is configured by clicking in a portal. The
repository *is* the system, and every change to it arrives the same way: as a pull request that
somebody can read before it happens.

That flow is the spine of the whole day. Infrastructure changes ride on it, schema changes ride on
it, and the pipelines you build this afternoon are triggered by it.

!!! tip "The hands-on part is on the demo page"
    This page is the *why*. The branch, the commit, the push and the pull request are walked
    through step by step on **[Source control demo](demo.md)** — that is the page to have open
    when we start typing.

## The concept

**Databases belong in source control**, the same as application code. When the schema, the
infrastructure and the pipelines all live in git:

- every change is a **reviewable diff** — not a mystery somebody applied in SSMS at 2 a.m.;
- you can **branch, review, and roll back**;
- the repository is **repeatable** — anyone, including a fresh CI runner, can rebuild from it.

The hard part is rarely the tooling. It is agreeing that the repository, not the server, is the
truth — which is exactly the conversation we have just had.

### Repository layout

The repository separates *what teaches* from *what runs* (full rules in
[`CLAUDE.md`](https://github.com/JessAndRob/FabConEU_2026_workshop/blob/main/CLAUDE.md) §3):

```
infra/       infrastructure as code (Azure SQL + Fabric SQL; Terraform + Bicep)
database/    database as code (SQL projects — the focus — + Flyway, dbatools)
docs/        the pages you are reading (built to this site)
.github/     the CI/CD pipelines
```

Prose teaches on the site; the **code is downloaded** and run from the repository — so pages link
to real files rather than pasting large blocks.

### Keep secrets out

The golden rule: **never commit a secret, a connection string, or a subscription id.**

The whole workshop is **passwordless**. GitHub Actions authenticates to Azure with **OIDC**
(short-lived tokens, nothing stored) and to SQL with **Microsoft Entra** (no SQL logins). There is
simply nothing secret to leak. The
[`.gitignore`](https://github.com/JessAndRob/FabConEU_2026_workshop/blob/main/.gitignore) backs
that up, keeping state files, build output and anything credential-shaped out of the repository:

```gitignore
*.tfstate*         # Terraform state (can hold sensitive values)
*.tfvars           # your local variables (only *.tfvars.example is tracked)
*.publishsettings  # Azure credentials
.env  *.pem  *.key
```

### A change is a proposal

A branch isolates the work. A commit is the smallest thing a reviewer can read. A pull request is
where the review, the automated checks and the argument all happen — *before* anything reaches
`main`.

Four checks stand behind every pull request in this repository, defined in
[`ci.yml`](https://github.com/JessAndRob/FabConEU_2026_workshop/blob/main/.github/workflows/ci.yml):
**Build SQL project + code analysis**, **Build docs site**, **Terraform fmt + validate**, and
**Bicep build**. None of them needs a cloud credential — they build, format and validate, and
nothing else. They are what stands between a broken Terraform module and your `main` branch for
the rest of the day, and they run on a one-line Markdown change just as readily as on a schema
change. That is the point.

There is a second workflow.
[`azure-sql-plan.yml`](https://github.com/JessAndRob/FabConEU_2026_workshop/blob/main/.github/workflows/azure-sql-plan.yml)
runs `terraform plan` on any pull request that touches the Azure SQL Terraform modules, and
surfaces the result on the pull request itself. It is **read-only** — it never applies anything —
so a reviewer can see precisely which resources a change would create, change or destroy *before*
agreeing to it.

That is the idea the rest of the day pays off: **a change is a proposal, and the pipeline tells
you what the proposal would do.** We plant it here, run it for real against infrastructure in
[Deploy infrastructure](../cicd/deploy-infra.md), and then point the same idea at your data in
[Ship database changes](../cicd/ship-database-changes.md), where the thing being proposed is a
schema change and the question is whether it will quietly delete a column.

!!! warning "The Terraform plan check needs credentials your fork does not have yet"
    `azure-sql-plan.yml` signs in to Azure with OIDC, using repository variables
    (`AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`) that only exist once you have
    done the one-time setup on the [Deploy infrastructure](../cicd/deploy-infra.md) page. Until
    then, a pull request in your fork that touches `infra/azure-sql/terraform/**` will show that
    check as **failed**. That is expected, and it is not something you have broken. The four
    `ci.yml` checks still pass, because they need no credentials at all.

## The demo

👉 **[Source control demo](demo.md)** — branch, change a file, review the diff, commit, push, and
open a pull request against `main`. Nine steps, about ten minutes, and nothing in it can break
anything. Later in the day the file you change will be Terraform or T-SQL; the flow stays exactly
the same.

## The code

- The pipelines behind every pull request — [`ci.yml`](https://github.com/JessAndRob/FabConEU_2026_workshop/blob/main/.github/workflows/ci.yml)
- The read-only plan on pull requests — [`azure-sql-plan.yml`](https://github.com/JessAndRob/FabConEU_2026_workshop/blob/main/.github/workflows/azure-sql-plan.yml)
- Repository layout and working rules — [`CLAUDE.md`](https://github.com/JessAndRob/FabConEU_2026_workshop/blob/main/CLAUDE.md)
- The ignore rules that keep secrets out — [`.gitignore`](https://github.com/JessAndRob/FabConEU_2026_workshop/blob/main/.gitignore)

## Gotchas

- **Secrets never go in git.** Use repository variables plus OIDC and Entra, not committed
  credentials — nothing to rotate, nothing to leak.
- **`*.tfvars` is git-ignored**, and only `*.tfvars.example` is tracked, so your real variable
  values stay on your machine.
- **Work on a branch, never on `main`.** If you have already committed to `main` by accident, run
  `git switch --create <branch-name>` to move the branch pointer to your work, then
  `git switch main` and `git reset --hard origin/main` to put `main` back.

## What's next

Next: [Source control demo](demo.md) — then [Azure SQL as code](../infra/azure-sql.md) after the
break.
