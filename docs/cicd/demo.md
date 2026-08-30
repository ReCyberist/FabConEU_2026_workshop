# CI/CD demo

This is the shortest live path through the CI/CD story: trigger validation, trigger a deliberate
apply, then confirm teardown. It keeps the "plan before apply" pattern visible while staying
practical in a workshop slot.

!!! note "Follow along - or just watch"
    You need a fork of the repository, GitHub CLI signed in, and Azure access configured for the
    workflows. See [Prerequisites](../setup/prerequisites.md), [CI/CD part 1](build-validate.md),
    [CI/CD part 2](deploy-infra.md), and [CI/CD part 3](ship-database-changes.md).

## What you'll do

- Trigger `ci.yml` and show that code is validated before merge.
- Trigger `azure-sql-apply.yml` from `main` and show deliberate deployment.
- Confirm the destroy workflow exists as the cost-control backstop.

## The concept

- **Validate on every change.** CI catches issues before deployment.
- **Apply on intent.** Provisioning is manual (`workflow_dispatch`) and explicit.
- **Teardown by default.** Nightly destroy keeps sandbox cost under control.

## Before you run it

Open a few workflow files first so attendees can see the controls before they watch a run.

1. Open the CI workflow YAML.

    ```powershell
    code .\.github\workflows\ci.yml
    ```

    Point out these details:

    - It runs on push, pull request, and manual dispatch.
    - It builds the SQL project with `-warnaserror`.
    - Docs, Terraform, and Bicep checks are included, with path filtering to avoid unnecessary runs.

2. Open the Azure SQL plan workflow YAML.

    ```powershell
    code .\.github\workflows\azure-sql-plan.yml
    ```

    Point out these details:

    - It is PR-only and read-only (`plan`, no `apply`).
    - It uses OIDC (`id-token: write`) instead of stored secrets.
    - It runs both the taught module and the shared-endpoint module as separate plan jobs.

3. Open the Azure SQL apply workflow YAML.

    ```powershell
    code .\.github\workflows\azure-sql-apply.yml
    ```

    Point out these details:

    - It is `workflow_dispatch` only.
    - `target` lets you choose `demo`, `attendee`, or `both`.
    - It includes DACPAC build, deploy report, publish, and smoke test in the same run.

## Run it

1. In the repository root folder, list the relevant workflows so attendees can see the exact names.

    ```powershell
    gh workflow list
    ```

    The list includes `CI`, `Azure SQL - Terraform apply`, and `Azure SQL - Terraform destroy`.

2. Trigger the validation workflow on `main`.

    ```powershell
    gh workflow run ci.yml --ref main
    ```

    GitHub queues a new CI run.

3. Watch the run and show the final status.

    ```powershell
    gh run list --workflow ci.yml --limit 1
    gh run watch
    ```

    The run finishes successfully and shows each job result.

4. Trigger the Azure SQL apply workflow from `main`.

    ```powershell
    gh workflow run azure-sql-apply.yml --ref main -f target=demo
    ```

    GitHub queues a deployment run for the demo flow.

5. Watch the apply run and open the run summary.

    ```powershell
    gh run list --workflow azure-sql-apply.yml --limit 1
    gh run watch
    gh run view --web
    ```

    The summary shows Terraform apply, DACPAC publish, and smoke-test results.

6. Confirm that teardown is in place.

    ```powershell
    code .\.github\workflows\azure-sql-destroy.yml
    ```

    The workflow shows a nightly schedule and manual dispatch.

## Checkpoint

You have shown the complete CI/CD control loop: validate automatically, deploy deliberately, and
tear down on schedule.

## Gotchas

- `azure-sql-plan.yml` runs on **pull requests**, not manual dispatch. To show the plan check,
  open a PR that touches `infra/azure-sql/terraform` or `infra/azure-sql/shared-endpoint`.
- Deploy workflows must run on `main` to match the configured OIDC credential subject.
- If deployment fails in the publish step, check Entra access for the CI principal first.

## What's next

Next: [Migrations, drift & teardown](../wrap-up/migrations-drift-teardown.md).
