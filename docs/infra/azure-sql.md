<!-- DRAFT: skeleton only. Structure + code links wired; prose to be fleshed out (task #22, Phase 3). -->

# Azure SQL as code (Terraform)

<!-- INTRO (1–2 sentences): why provision Azure SQL as code — repeatable, reviewable, no clicking. -->

!!! note "Follow along — or just watch"
    You'll need your **own Azure subscription** with rights to create resources for this module.
    No subscription? Just watch — it's a live demo you can replay later from the downloads. See
    [Prerequisites](../setup/prerequisites.md).

## What you'll build

<!-- AT A GLANCE: resource group + logical SQL server + serverless database + firewall rule;
     CAF-named, passwordless (Entra-only). A short bullet list or small table. -->

## The concept

<!-- ~5 min: infrastructure as code; Terraform state (remote azurerm backend); passwordless
     Entra auth; CAF + fabcon26 naming. -->

## Terraform (focus) / Bicep (reference)

=== "Terraform"
    <!-- The taught path: a short excerpt + the key init/plan/apply commands (see the module README). -->

=== "Bicep"
    <!-- Reference variant (all-as-code): mirrors the Terraform module; link only, short note. -->

## The code

The module lives in
[`infra/azure-sql/terraform`](https://github.com/JessAndRob/FabConEU_2026_workshop/tree/main/infra/azure-sql/terraform)
(Bicep reference in
[`infra/azure-sql/bicep`](https://github.com/JessAndRob/FabConEU_2026_workshop/tree/main/infra/azure-sql/bicep)).
Download the module bundle and run it from code — nothing is clicked.

## Checkpoint

<!-- The "we move on" state: `terraform apply` created the RG + server + DB, passwordless. -->

## Gotchas

<!-- Distil from LEARNINGS.md: CAF + fabcon26 naming; Entra-only passwordless (no admin login);
     a Sponsorship sub can be region-restricted (try, read the error); keep tf state out of the
     workload RG so nightly destroy can't delete it. -->

## What's next

Next: [Fabric SQL as code](fabric-sql.md) — the same, side by side on Fabric.
