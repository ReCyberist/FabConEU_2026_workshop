<!-- DRAFT: skeleton only. Prose to be fleshed out (task #22, Phase 3). -->

# CI/CD part 2 — deploy infrastructure

<!-- INTRO: apply Terraform from the pipeline — provisioning as a deliberate, passwordless action. -->

!!! note "Follow along — or just watch"
    Your own Azure subscription to deploy into. See [Prerequisites](../setup/prerequisites.md).

## What you'll build

<!-- A dispatchable apply that provisions the Azure SQL infra, plus a nightly destroy. -->

## The concept

<!-- OIDC passwordless (no secrets); remote state; apply-on-intent from main; environments &
     approvals (documented — see the gate note below). -->

## The code

Workflows:
[`azure-sql-apply.yml`](https://github.com/JessAndRob/FabConEU_2026_workshop/blob/main/.github/workflows/azure-sql-apply.yml)
and
[`azure-sql-destroy.yml`](https://github.com/JessAndRob/FabConEU_2026_workshop/blob/main/.github/workflows/azure-sql-destroy.yml).

## Checkpoint

<!-- One dispatch provisions the RG + server + DB; nightly destroy tears it down at 21:00 UTC. -->

## Gotchas

<!-- OIDC FIC subjects (main vs pull_request); a logical SQL server allows one Entra admin, so use
     an Entra *group* for presenters + CI SP (#18); a Sponsorship sub can be region-restricted. -->

!!! info "Approval gates (documented, not wired)"
    GitHub Environment required-reviewer gates need a Team/Enterprise plan on a private repo, so
    ours is documented as a pattern rather than enforced here (task #21).

## What's next

Next: [CI/CD part 3 — ship database changes](ship-database-changes.md).
