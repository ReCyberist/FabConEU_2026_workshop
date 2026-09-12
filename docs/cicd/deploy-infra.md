# CI/CD part 2 — deploy infrastructure

--8<-- "includes/clock-afternoon-2.md"

Now provision for real — **`terraform apply` from the pipeline**. Deployment is a *deliberate*,
passwordless action: you dispatch it from `main`, it stands up the Azure SQL infrastructure, and a
nightly job tears it back down so nothing bills overnight.

!!! tip "The hands-on part is on the demo page"
    This page is the *why*. Dispatching the apply and watching it run is walked through step by
    step on **[CI/CD demo](demo.md)**.

## What gets built

- A **manually-dispatched apply**
  ([`azure-sql-apply.yml`](https://github.com/JessAndRob/FabConEU_2026_workshop/blob/main/.github/workflows/azure-sql-apply.yml))
  that provisions the resource group, server, and database — then publishes the DACPAC into it. One
  dispatch does infrastructure **and** database.
- A **nightly destroy**
  ([`azure-sql-destroy.yml`](https://github.com/JessAndRob/FabConEU_2026_workshop/blob/main/.github/workflows/azure-sql-destroy.yml),
  21:00 UTC + manual) so a forgotten sandbox doesn't keep billing.

## The concept

- **Passwordless via OIDC.** GitHub Actions mints a short-lived token that Azure trusts (a federated
  credential on an app registration) — **no secrets stored**. The same identity authenticates to the
  database via Microsoft Entra.
- **Apply on intent, not on every push.** Provisioning is a `workflow_dispatch` from `main` — named
  "apply" on purpose. The PR only ever *plans* (part 1).
- **Shared remote state.** The apply and the nightly destroy run on separate ephemeral runners, so
  they read/write one **remote azurerm backend** to agree on what exists.

!!! info "Environments & approval gates (documented, not wired)"
    Holding a deploy for a human is a **GitHub Environment required-reviewer** gate. On a *private*
    repo those protection rules need a **Team/Enterprise** plan, so ours is documented as the pattern
    (and it's the resolution in [part 3](ship-database-changes.md)) rather than enforced on this repo.

## The demo

👉 **[CI/CD demo](demo.md)** — dispatch `azure-sql-apply.yml` from `main`, watch the run, and
confirm the nightly teardown is in place.

## The code

- [`azure-sql-apply.yml`](https://github.com/JessAndRob/FabConEU_2026_workshop/blob/main/.github/workflows/azure-sql-apply.yml) — apply + publish + smoke test.
- [`azure-sql-destroy.yml`](https://github.com/JessAndRob/FabConEU_2026_workshop/blob/main/.github/workflows/azure-sql-destroy.yml) — nightly + manual teardown.

## Checkpoint

One dispatch of `azure-sql-apply.yml` provisions the RG + server + database **and** publishes the
schema + seed — passwordless, end to end. The nightly destroy removes it at 21:00 UTC; re-run apply
to recreate.

## Gotchas

- **OIDC credential subjects are per-context** — `…:ref:refs/heads/main` for the apply,
  `…:pull_request` for the plan. A deploy workflow can only be verified after merging to `main` (a
  feature-branch run's subject doesn't match the credential).
- **A logical SQL server allows one Entra admin** — so make it a **group** (presenters + the CI
  identity), and add the service principal by its **object id**, not its client id.
- **Sponsorship subscriptions can be region-restricted** — override `location` if an apply is refused
  in a region.

## What's next

Next: [CI/CD part 3 — ship database changes](ship-database-changes.md).
