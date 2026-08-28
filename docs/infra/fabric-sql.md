<!-- DRAFT: skeleton only. Prose to be fleshed out (task #22, Phase 3). -->

# Fabric SQL as code (Terraform)

<!-- INTRO: the side-by-side partner to Azure SQL — provision Fabric SQL as code. -->

!!! success "Verified end-to-end (task #20, 2026-08-20)"
    The Fabric module has been deployed live: one pipeline run provisions the capacity binding →
    workspace → SQL database, publishes the DACPAC, and passes a data smoke test — passwordless,
    side by side with Azure SQL. Open follow-ups (none block this flow): nightly clean-slate
    teardown (#26) and a least-privilege capacity-access refactor (#27).

!!! note "Follow along — or just watch"
    Needs your own Azure subscription **and** a Fabric capacity. See [Prerequisites](../setup/prerequisites.md).

## What you'll build

<!-- AT A GLANCE: capacity → workspace → SQL database (vs Azure's server → database). -->

## The concept

<!-- Two providers: azurerm (capacity) + microsoft/fabric (workspace + database); passwordless. -->

## Azure SQL / Fabric SQL

=== "Azure SQL"
    <!-- server → database (recap; see the Azure SQL page). -->

=== "Fabric SQL"
    <!-- capacity → workspace → database; the extra provider + capacity cost. -->

## The code

The module lives in
[`infra/fabric-sql/terraform`](https://github.com/JessAndRob/FabConEU_2026_workshop/tree/main/infra/fabric-sql/terraform).
Bicep can only provision the **capacity** (workspace + DB have no ARM type) — see
[`infra/fabric-sql/bicep`](https://github.com/JessAndRob/FabConEU_2026_workshop/tree/main/infra/fabric-sql/bicep).

## Checkpoint

<!-- capacity + workspace + database exist; DACPAC target reachable. -->

## Gotchas

<!-- Two providers; capacity name is lowercase-alnum only; tenant must enable "Service principals
     can use Fabric APIs"; F-SKU bills continuously (nightly destroy matters). -->

## What's next

Next: [Database as code — SQL projects](../database/sql-projects.md).
