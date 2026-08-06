<!-- DRAFT: skeleton only. Prose to be fleshed out (task #22, Phase 3). -->

# Source control for databases

<!-- INTRO: version-control everything — infra, schema, pipelines; the repo is the source of truth. -->

!!! note "Follow along — or just watch"
    You just need **git** and the template repo for this module. See [Prerequisites](../setup/prerequisites.md).

## What you'll build

<!-- A forked repo you can clone and work in. -->

## The concept

<!-- Why databases belong in git; repo layout (infra/ database/ docs/); keeping secrets OUT
     (variables + OIDC, never connection strings/subscription ids). -->

## The code

The repo layout is described in
[`CLAUDE.md`](https://github.com/JessAndRob/FabConEU_2026_workshop/blob/main/CLAUDE.md); secrets
are kept out via [`.gitignore`](https://github.com/JessAndRob/FabConEU_2026_workshop/blob/main/.gitignore)
and pipeline variables.

## Gotchas

<!-- Never commit a secret/connection string/subscription id; passwordless (OIDC/Entra) avoids them. -->

## What's next

Next: [Azure SQL as code](../infra/azure-sql.md).
