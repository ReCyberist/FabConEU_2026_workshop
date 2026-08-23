# Source control for databases

Before you deploy anything, everything that describes your infrastructure **and** your database
lives in **one git repository** — the single source of truth. Nothing is configured by clicking in
a portal; the repo *is* the system. That's the whole "as code" promise, and it starts here.

!!! note "Follow along — or just watch"
    You just need **git** and a fork of the
    [template repo](https://github.com/JessAndRob/FabConEU_2026_workshop). See
    [Prerequisites](../setup/prerequisites.md).

## What you'll build

A **fork** of the workshop repo you can clone, branch, and open pull requests against — the same
PR-driven flow you'll use to ship infrastructure and schema changes for the rest of the day.

## The concept

**Databases belong in source control**, the same as application code. When the schema, the
infrastructure, and the pipelines all live in git:

- every change is a **reviewable diff** and a **pull request** — not a mystery someone applied in
  SSMS at 2 a.m.;
- you can **branch, review, and roll back**;
- the repo is **repeatable** — anyone, including a fresh CI runner, can rebuild from it.

### Repo layout

The repo separates *what teaches* from *what runs* (full rules in
[`CLAUDE.md`](https://github.com/JessAndRob/FabConEU_2026_workshop/blob/main/CLAUDE.md) §3):

```
infra/       infrastructure as code (Azure SQL + Fabric SQL; Terraform + Bicep)
database/    database as code (SQL projects — the focus — + Flyway, dbatools)
docs/        the pages you're reading (built to this site)
.github/     the CI/CD pipelines
```

Prose teaches on the site; the **code is downloaded** and run from the repo — so pages link to the
real files rather than pasting big blocks.

### Keep secrets out

The golden rule: **never commit a secret, a connection string, or a subscription id.** The whole
workshop is **passwordless** — GitHub Actions authenticates to Azure with **OIDC** (short-lived
tokens, nothing stored) and to SQL with **Microsoft Entra** (no SQL logins). There's simply nothing
secret to leak. A [`.gitignore`](https://github.com/JessAndRob/FabConEU_2026_workshop/blob/main/.gitignore)
backs that up — keeping state files, build output, and anything credential-shaped out of the repo:

```gitignore
*.tfstate*         # Terraform state (can hold sensitive values)
*.tfvars           # your local variables (only *.tfvars.example is tracked)
*.publishsettings  # Azure creds
.env  *.pem  *.key
```

## The code

- Repo layout + working rules — [`CLAUDE.md`](https://github.com/JessAndRob/FabConEU_2026_workshop/blob/main/CLAUDE.md)
- The ignore rules that keep secrets out — [`.gitignore`](https://github.com/JessAndRob/FabConEU_2026_workshop/blob/main/.gitignore)

Fork it, clone your fork, and you're ready:

```powershell
git clone https://github.com/<your-fork>/FabConEU_2026_workshop.git
cd FabConEU_2026_workshop
```

## Gotchas

- **Secrets never go in git.** Use pipeline **variables** + OIDC/Entra, not committed credentials —
  nothing to rotate, nothing to leak.
- **`*.tfvars` is git-ignored** (only `*.tfvars.example` is tracked), so your real variable values
  stay local.

## What's next

Next: [Azure SQL as code](../infra/azure-sql.md).
