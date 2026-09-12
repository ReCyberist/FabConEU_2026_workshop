# CI/CD part 1 — build & validate

--8<-- "includes/clock-afternoon-1.md"

Every change is a **pull request**, and the pipeline checks it *before* anything merges — it builds
the database, runs static analysis, and shows a read-only `terraform plan`. Nothing is deployed
here; this is the safety net that catches mistakes in review.

!!! tip "The hands-on part is on the demo page"
    This page is the *why*. Triggering the workflows and watching the checks run is walked through
    step by step on **[CI/CD demo](demo.md)**.

## What gets built

On every push and PR, [`ci.yml`](https://github.com/JessAndRob/FabConEU_2026_workshop/blob/main/.github/workflows/ci.yml) runs four path-gated jobs:

- **Database** — compiles the SQL project to a DACPAC and runs **T-SQL static code
  analysis** (`-warnaserror`, so any smell fails); uploads the DACPAC as an artifact.
- **Docs** — `mkdocs build --strict`, only when `docs/**`, `mkdocs.yml` or `requirements.txt` change.
- **Terraform** — `fmt -check` + an offline `validate` (`-backend=false`) for each module, when
  `infra/**/terraform/**` changes.
- **Bicep** — `az bicep build` on the templates + `build-params` on the `.bicepparam` files, when
  `infra/**/bicep/**` changes.

And on a PR that touches the infra module,
[`azure-sql-plan.yml`](https://github.com/JessAndRob/FabConEU_2026_workshop/blob/main/.github/workflows/azure-sql-plan.yml)
posts a read-only **`terraform plan`** in the checks — the change you're about to make, before you
make it.

## The concept

Two ideas do the work here:

- **CI validates our own code.** The SQL project's static analysis plus `-warnaserror` keeps the
  schema at **zero findings** — the front row won't spot a smell.
- **Plan on PR, apply on intent.** A PR gets a *read-only* `terraform plan` so reviewers see the
  effect; **applying** stays a deliberate, manual action from `main` (that's part 2). A plan never
  mutates state (it runs `-lock=false`), so it can't clash with a real apply.

Jobs are **gated by paths**, so a SQL-only PR doesn't pay to build the docs, and vice-versa. A
pull request that changes one `.sql` file runs the database job and skips the other three — and
the read-only plan, which only reacts to infrastructure changes and needs the repository's Azure
credentials, does not run at all.

## The demo

👉 **[CI/CD demo](demo.md)** — read the workflow files, trigger validation, then watch the checks
come back green with nothing deployed.

## The code

- [`ci.yml`](https://github.com/JessAndRob/FabConEU_2026_workshop/blob/main/.github/workflows/ci.yml) — database build + analyse, docs, terraform, and bicep validation.
- [`azure-sql-plan.yml`](https://github.com/JessAndRob/FabConEU_2026_workshop/blob/main/.github/workflows/azure-sql-plan.yml) — read-only plan on PR.

## Checkpoint

Open a PR and its checks go green: the DACPAC builds and analyses clean, and — for an infra change
— a `terraform plan` shows exactly what *would* change, with nothing yet applied.

## Gotchas

- **Pin the .NET SDK** (`global.json`). The runner ships several SDKs and the preview SQL SDK needs
  the pinned one — `setup-dotnet` installs a version but doesn't *force* selection.
- **Plan-on-PR needs its own OIDC credential.** A PR run's token subject is `…:pull_request`, which
  the `…:ref:refs/heads/main` credential doesn't cover — so plan uses a second federated credential.
- **`-warnaserror`** is what turns "a warning" into "a failed build" — that's the point.

## What's next

Next: [CI/CD part 2 — deploy infrastructure](deploy-infra.md).
