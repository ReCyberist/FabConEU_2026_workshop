<!-- DRAFT: skeleton only. Fleshed in Phase 2 (task #2) from ordering.md + decision D6. -->

# Prerequisites

<!-- INTRO: everything is bring-your-own; here's what each optional path needs. -->

!!! note "Follow along — or just watch"
    Nothing is provided for you. Bring what you have, follow along, or just watch and replay later.

## Everyone

<!-- GitHub account; ability to fork/clone the template repo; git locally. -->

## To do the infrastructure part (optional)

=== "Azure SQL"
    <!-- Your own Azure subscription with Contributor rights. -->

=== "Fabric SQL"
    <!-- Azure sub + a Fabric capacity (F-SKU bills; trial capacity can't be Terraform-created). -->

## To do the database-deploy part (optional)

<!-- A reachable target SQL (your own Azure SQL / Fabric SQL), OR our shared endpoint on the day. -->

## The shared endpoint (unsupported)

<!-- One SQL Server on a VM, a database per attendee, pushed to via pipeline. Best-effort, we
     won't troubleshoot it. -->

## Cost & teardown

<!-- Warn: deploying into your own sub costs money; tear it down. Point at the destroy workflow. -->

## Your local toolchain

<!-- git; for the DB part: dotnet SDK (pinned 8 via global.json) + SqlPackage. -->

## What's next

Next: [Source control for databases](../foundations/source-control.md).
