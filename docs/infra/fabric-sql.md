# Fabric SQL as code (Terraform)

--8<-- "includes/clock-morning-2.md"

Provision **SQL database in Fabric** with **Terraform** — the same "as code" story as Azure SQL,
one step longer. Where Azure SQL is *server → database*, Fabric is *capacity → workspace →
database*, and it takes **two providers** to build. No portal clicking, no password, fully
repeatable — side by side with the Azure SQL module.

!!! success "Verified end-to-end (task #20, 2026-08-20)"
    The Fabric module has been deployed live: one pipeline run provisions the capacity binding →
    workspace → SQL database, publishes the DACPAC, and passes a data smoke test — passwordless,
    side by side with Azure SQL. Open follow-ups (none block this flow): nightly clean-slate
    teardown (#26) and a least-privilege capacity-access refactor (#27).

!!! tip "The hands-on part is on the demo page"
    This page is the *why* and the *what*. The commands are walked through step by step on
    **[Infrastructure as code demo](demo.md)**, in the *Fabric SQL* section.

!!! warning "This is *SQL database in Fabric* — not the Fabric Data Warehouse"
    Our target is the **transactional** SQL database in Fabric, which is engine-compatible with
    Azure SQL (IDENTITY, enforced constraints, indexes, views, procedures all work) — so the
    *same* schema and DACPAC deploy to both. The Fabric **Data Warehouse** is a different, much
    smaller T-SQL surface; we don't target it. Details:
    [`notes/fabric-sql-notes.md`](https://github.com/JessAndRob/FabConEU_2026_workshop/blob/main/notes/fabric-sql-notes.md).

## What gets built

The taught path provisions the whole stack as code (the module can also **bind to a capacity you
already run** — see the gotchas):

| Resource | Name (default) | Provider | Notes |
|---|---|---|---|
| Resource group | `rg-fabcon26-dev-uks` | azurerm | Holds the capacity |
| Fabric capacity | `capfabcon26dev<rnd>` | azurerm | `Microsoft.Fabric/capacities`, **F2** SKU — **bills continuously** |
| Workspace | `ws-fabcon26-dev-uks` | microsoft/fabric | The container for Fabric items, bound to the capacity |
| SQL database | `football-dev` | microsoft/fabric | The **SQL database in Fabric** the DACPAC publishes into |

```mermaid
flowchart LR
    DACPAC["SQL project<br/>DACPAC"]

    subgraph SUB["Azure subscription — azurerm provider"]
        subgraph RG["Resource group · rg-fabcon26-dev-uks"]
            CAP["Fabric capacity<br/>capfabcon26dev·<br/>Microsoft.Fabric/capacities · F2"]
        end
    end

    subgraph FAB["Microsoft Fabric — microsoft/fabric provider"]
        WS["Workspace<br/>ws-fabcon26-dev-uks"]
        DB[("SQL database in Fabric<br/>football-dev")]
        WS --> DB
    end

    CAP -- "bound to (gives compute)" --> WS
    DACPAC -- "sqlpackage publish" --> DB
```

The extra moving part versus Azure SQL is the **capacity**, and the dashed boundary is the
provider split: `azurerm` builds the capacity (an Azure resource), `microsoft/fabric` builds the
workspace and database (Fabric items) — one `terraform apply` authenticates to both.

## The concept

**Infrastructure as code**, one provider heavier than Azure SQL:

- **Two providers, by necessity.** The **capacity** is an *Azure* resource
  (`azurerm_fabric_capacity`), but the **workspace** and **SQL database** are Fabric items managed
  by the **`microsoft/fabric`** provider over the Fabric REST APIs. So a single `terraform apply`
  authenticates to **both** — azurerm for the capacity, the fabric provider for everything on top.
- **capacity → workspace → database.** The capacity is the compute/billing unit; a workspace binds
  to it (that's what gives the database compute); the SQL database lives in the workspace. Azure
  SQL's *server → database* has no capacity to reason about.
- **Passwordless.** Both providers use Microsoft Entra (reuse `az login` locally; OIDC in CI) — no
  keys, nothing secret to commit.

## Azure SQL / Fabric SQL

=== "Azure SQL"
    **server → database.** One provider (`azurerm`). A logical server holds the database; a
    serverless SKU auto-pauses when idle, so cost takes care of itself. See the
    [Azure SQL page](azure-sql.md).

=== "Fabric SQL"
    **capacity → workspace → database.** Two providers (`azurerm` + `microsoft/fabric`). The extra
    moving part is the **capacity** — it has real cost implications (an F-SKU bills continuously,
    with no serverless auto-pause), so teardown or pausing matters more than on Azure SQL.

## The demo

👉 **[Infrastructure as code demo](demo.md)** — the *Fabric SQL* section runs the module end to
end. It follows the same shape as the Azure SQL walkthrough on the same page, with one extra
variable (`fabric_subscription_id`) and a second provider to initialise.

## The code

The module lives in
[`infra/fabric-sql/terraform`](https://github.com/JessAndRob/FabConEU_2026_workshop/tree/main/infra/fabric-sql/terraform).

Bicep can only provision the **capacity** (the workspace + SQL database have no ARM resource
type), so the full stack is Terraform-only — see
[`infra/fabric-sql/bicep`](https://github.com/JessAndRob/FabConEU_2026_workshop/tree/main/infra/fabric-sql/bicep).

## Checkpoint

By the end of this section the capacity (or the binding to your existing one), the workspace and
the SQL database all exist, reachable at `…database.fabric.microsoft.com,1433` and signed in
**passwordless** with your Entra identity. That database is the target the
[SQL project's DACPAC](../database/sql-projects.md) publishes into — the *same* DACPAC as Azure SQL,
only the publish profile changes.

## Gotchas

- **Two providers means two auths** — `azurerm` (`ARM_*`) for the capacity + state, and the
  `microsoft/fabric` provider (`FABRIC_*`) for the workspace + database. In GitHub Actions the
  fabric provider auto-detects the OIDC token, so `id-token: write` is the only extra wiring.
- **A Fabric tenant admin must enable *"Service principals can use Fabric APIs"*** — without it a
  pipeline identity can't touch Fabric at all. No Terraform or pipeline can flip this setting; it's
  the one hard prerequisite a human has to arrange.
- **Capacity names are lowercase-alphanumeric only** (`^[a-z][a-z0-9]*$`, no hyphens), so they
  can't take the CAF hyphenated form — the module builds the name from the same tokens minus
  separators, with a `cap` prefix and a random suffix (capacity names are globally unique).
- **An F-SKU bills continuously** — there's no serverless auto-pause. Either let the nightly
  destroy tear it down, or **pause it when idle**. The module also has a `use_existing_capacity`
  toggle: bind the workspace to a capacity you run and pause yourself, and Terraform will **never**
  destroy it (it's a read-only data source, not managed state).
- **A workspace created by a service principal is invisible to humans** — the creating SP is its
  only member. The module grants the presenters the **Admin** role **as code**
  (`fabric_workspace_role_assignment`), because the workspace is recreated on every apply and a
  portal grant wouldn't survive.
- **Resolving an *existing* capacity needs capacity-admin rights** — the `fabric_capacity` data
  source only lists capacities the principal administers, so binding to one you didn't create is a
  one-time out-of-band grant (the Fabric analog of the Azure SQL Entra-admin step).

## What's next

Next: [Infrastructure as code demo](demo.md), then
[Database as code — SQL projects](../database/sql-projects.md).
