# CI/CD part 1 — build & validate

Every change is a **pull request**, and the pipeline checks it *before* anything merges — it builds
the database, runs static analysis, and shows a read-only `terraform plan`. Nothing is deployed
here; this is the safety net that catches mistakes in review.

!!! note "Follow along — or just watch"
    A GitHub account and your fork of the repo. See [Prerequisites](../setup/prerequisites.md).

## What you'll build

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

Jobs are **gated by paths**, so a SQL-only PR doesn't pay to build the docs, and vice-versa.

## The code

- [`ci.yml`](https://github.com/JessAndRob/FabConEU_2026_workshop/blob/main/.github/workflows/ci.yml) — database build + analyse, docs, terraform, and bicep validation.
- [`azure-sql-plan.yml`](https://github.com/JessAndRob/FabConEU_2026_workshop/blob/main/.github/workflows/azure-sql-plan.yml) — read-only plan on PR.

## Demo — watch CI validate a pull request

Open a pull request with one small, safe change and watch the checks run before anything merges.
The change is the additive view from the ship-changes demo, so it builds clean and loses no data.

!!! note "Presenter-led — follow along on your own fork"
    The presenter runs this against the workshop repository. To follow along, run the same commands
    in your own fork and open the pull request **inside your fork**, so your fork's own Actions run
    the checks.

1. In the repository root folder of your fork, create a branch.

    ```powershell
    git switch -c demo/add-squad-ages
    ```

    You are now on the `demo/add-squad-ages` branch.

2. Add the additive view to the SQL project.

    ```powershell
    Copy-Item database\demo\ship-changes\increment-1_vw_SquadAges.sql database\sql-projects\Views\vw_SquadAges.sql
    ```

    The project now contains `database\sql-projects\Views\vw_SquadAges.sql`.

3. Commit and push the branch.

    ```powershell
    git add database\sql-projects\Views\vw_SquadAges.sql
    git commit -m "Add vw_SquadAges view"
    git push --set-upstream origin demo/add-squad-ages
    ```

    The branch is now on your fork.

4. Open the pull request.

    ```powershell
    gh pr create --fill
    ```

    GitHub CLI prints the pull request URL.

5. Watch the checks on the pull request.

    ```powershell
    gh pr checks --watch
    ```

    The **database** check builds the DACPAC and runs T-SQL static analysis, and it passes. The
    **docs**, **Terraform**, and **Bicep** checks are skipped, because the pull request changed only
    a `.sql` file and the jobs are gated by path. Nothing is deployed.

6. Read the result on the pull request page.

    ```powershell
    gh pr view --web
    ```

    The checks are green, and the pull request is safe to merge. The database was built and analysed;
    it was never deployed.

!!! note "The plan-on-PR needs Azure access"
    The read-only `terraform plan` comment comes from `azure-sql-plan.yml`, which runs only on a
    pull request that touches an infrastructure module and needs the repository's Azure credentials.
    The presenter shows this one; a change to a `.sql` file (as above) does not trigger it.

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
