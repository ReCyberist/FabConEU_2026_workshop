# Source control for databases

--8<-- "includes/clock-morning-1.md"

Everything that describes your infrastructure **and** your database lives in **one git
repository** — the single source of truth. Nothing is configured by clicking in a portal. The
repository *is* the system, and every change to it arrives the same way: as a pull request that
somebody can read before it happens.

That flow is the spine of the whole day. Infrastructure changes ride on it, schema changes ride on
it, and the pipelines you build this afternoon are triggered by it. So we are going to walk it
once, now, with a change that cannot possibly hurt anything.

!!! note "Follow along — or just watch"
    Following along needs **git**, the **GitHub CLI**, and the fork you made in
    [Prerequisites](../setup/prerequisites.md). No cloud subscription is needed for this section —
    everything here happens in GitHub. If you would rather watch, the checkpoint at the end tells
    you exactly what you missed.

## What you'll build

Your first pull request against your own fork: a branch, a committed change, a green set of
checks, and a merge. By the end of this section you will have shipped a change the way every other
change today gets shipped.

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

## Make your first change

Nine steps. They take about ten minutes, and the change itself is a single line in
[`ATTENDEES.md`](https://github.com/JessAndRob/FabConEU_2026_workshop/blob/main/ATTENDEES.md) — a
guest book that no pipeline reads, so there is nothing here you can break.

1. In the `FabConEU_2026_workshop` folder you cloned in
    [Prerequisites](../setup/prerequisites.md), confirm you are in your own fork:

    ```powershell
    git remote -v
    ```

    The `origin` lines show `https://github.com/<your-account>/FabConEU_2026_workshop.git`. If
    they show `JessAndRob` instead, you cloned the original rather than your fork. Go back to
    [Prerequisites](../setup/prerequisites.md) step 4.

2. Make sure you are starting from the current `main`:

    ```powershell
    git switch main
    git pull
    ```

    Git reports `Already up to date`, or lists the files it updated.

3. Create a branch for your change:

    ```powershell
    git switch --create add-my-name
    ```

    Git prints `Switched to a new branch 'add-my-name'`. Work never happens directly on `main` —
    not here, and not in the pipelines you build this afternoon.

4. Open `ATTENDEES.md` in your editor and add one line to the bottom of the list, in the shape the
    file describes:

    ```markdown
    - **Your name** — City, Country — the thing you would most like to stop doing by hand
    ```

    Save the file.

5. Check what git has noticed:

    ```powershell
    git diff
    ```

    The output shows one added line, prefixed with `+`. This diff is the thing a reviewer reads.
    A change nobody can read is a change nobody can review.

6. Stage and commit the change:

    ```powershell
    git add ATTENDEES.md
    git commit -m "docs: add <your name> to the attendee list"
    ```

    Git prints `1 file changed, 1 insertion(+)`.

7. Push the branch to your fork:

    ```powershell
    git push --set-upstream origin add-my-name
    ```

    Git confirms `branch 'add-my-name' set up to track 'origin/add-my-name'`.

8. Open a pull request from the branch into your fork's `main`:

    ```powershell
    gh pr create --base main --fill
    ```

    The command prints the URL of your new pull request. `--fill` reuses your commit message as
    the title and description, so there is nothing to type.

9. Watch the checks run, then merge:

    ```powershell
    gh pr checks --watch
    gh pr merge --squash --delete-branch
    ```

    `gh pr checks --watch` lists four checks and updates until they finish: **Build SQL project +
    code analysis**, **Build docs site**, **Terraform fmt + validate**, and **Bicep build**. All
    four pass. `gh pr merge` then squashes the change into `main` and deletes the branch.

!!! tip "Prefer the website?"
    Every step from 8 onwards can be done on github.com instead — open the pull request, read the
    checks, press **Merge**. The flow is identical, and so is the result. We use the CLI because
    it is faster to demonstrate and because it is what a pipeline does.

## What just happened

Four automated checks ran against a one-line change to a Markdown file, and that is not a waste.
Those same four checks are what stand between a broken Terraform module and your `main` branch for
the rest of the day. They are defined in
[`ci.yml`](https://github.com/JessAndRob/FabConEU_2026_workshop/blob/main/.github/workflows/ci.yml),
they run on **every** pull request, and none of them needs a cloud credential — they build, format
and validate, and nothing else.

There is a second workflow you have not triggered yet.
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

## The code

- The pipelines that just ran — [`ci.yml`](https://github.com/JessAndRob/FabConEU_2026_workshop/blob/main/.github/workflows/ci.yml)
- The read-only plan on pull requests — [`azure-sql-plan.yml`](https://github.com/JessAndRob/FabConEU_2026_workshop/blob/main/.github/workflows/azure-sql-plan.yml)
- Repository layout and working rules — [`CLAUDE.md`](https://github.com/JessAndRob/FabConEU_2026_workshop/blob/main/CLAUDE.md)
- The ignore rules that keep secrets out — [`.gitignore`](https://github.com/JessAndRob/FabConEU_2026_workshop/blob/main/.gitignore)

## Checkpoint

At this point you have:

- a fork of the workshop repository, cloned locally, with `origin` pointing at **your** account;
- one merged pull request, squashed into your fork's `main`, containing your line in
  `ATTENDEES.md`;
- four green checks on that pull request, from `ci.yml`;
- the `add-my-name` branch deleted.

Run `git switch main` then `git pull` to bring your merged change down locally. Your working
folder is now ready for the infrastructure work after the break.

If you did not follow along, nothing is missing: the next section starts from the repository as
you cloned it.

## Gotchas

- **Secrets never go in git.** Use repository variables plus OIDC and Entra, not committed
  credentials — nothing to rotate, nothing to leak.
- **`*.tfvars` is git-ignored**, and only `*.tfvars.example` is tracked, so your real variable
  values stay on your machine.
- **`gh pr create` fails with `no commits between main and add-my-name`** if you forgot to commit.
  Run `git status`, commit, push again.
- **Work on a branch, never on `main`.** If you have already committed to `main` by accident, run
  `git switch --create add-my-name` to move the branch pointer to your work, then
  `git switch main` and `git reset --hard origin/main` to put `main` back.

## What's next

Next: [Azure SQL as code](../infra/azure-sql.md) — the first thing we deploy, after the break.
