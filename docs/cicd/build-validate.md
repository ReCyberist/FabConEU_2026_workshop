<!-- DRAFT: skeleton only. Prose to be fleshed out (task #22, Phase 3). -->

# CI/CD part 1 — build & validate

<!-- INTRO: every change is a PR; the pipeline builds and validates it before anything merges. -->

!!! note "Follow along — or just watch"
    A GitHub account + the forked repo. See [Prerequisites](../setup/prerequisites.md).

## What you'll build

<!-- On PR: build the DACPAC + T-SQL static analysis, and a read-only `terraform plan`. -->

## The concept

<!-- CI validates our own code; plan-on-PR (read-only) vs apply-on-intent; paths-filter so jobs
     only run when their area changes. -->

## The code

Workflows:
[`ci.yml`](https://github.com/JessAndRob/FabConEU_2026_workshop/blob/main/.github/workflows/ci.yml)
(build + analysis + docs) and
[`azure-sql-plan.yml`](https://github.com/JessAndRob/FabConEU_2026_workshop/blob/main/.github/workflows/azure-sql-plan.yml)
(plan on PR).

## Checkpoint

<!-- A PR shows green build + analysis + a terraform plan in its checks. -->

## Gotchas

<!-- Pin .NET (global.json) in CI; plan-on-PR needs a `pull_request` OIDC federated credential
     (its subject isn't a branch ref); -warnaserror keeps analysis at zero findings. -->

## What's next

Next: [CI/CD part 2 — deploy infrastructure](deploy-infra.md).
