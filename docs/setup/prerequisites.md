# Prerequisites

This is a **bring-your-own** workshop — there's no lab environment handed out. You'll get the
most from the day by following along on **your own** Azure / Fabric kit, but everything is a live
demo you can equally **just watch** and replay later from the downloads. So the only hard
requirement is a laptop and some curiosity — everything below is *optional*, depending on how
hands-on you want to be.

!!! note "Follow along — or just watch"
    Nothing is provisioned for you. Bring what you have and follow along on your own kit, or watch
    and replay later — every module works at all three levels.

## At a glance

The hands-on splits into **two independent, optional parts**. Pick either, both, or neither:

| You want to… | You'll need |
|---|---|
| **Just watch** (and replay later) | A laptop. That's it. |
| **Deploy infrastructure** as code (Part 1) | Your **own Azure subscription** — plus a **Fabric capacity** for the Fabric path |
| **Ship database changes** as code (Part 2) | A reachable **target SQL** — your own, or our shared endpoint on the day |

The parts are independent: you can do the database part without the infrastructure part if you
already have a SQL target to deploy into.

## Everyone

Whatever level you choose, bring:

- A **GitHub account**.
- **[git](https://git-scm.com/downloads)** installed locally.
- A **fork of the workshop template repo** —
  [`JessAndRob/FabConEU_2026_workshop`](https://github.com/JessAndRob/FabConEU_2026_workshop). All
  the code you'll deploy lives there; you run it from your own fork.

```powershell
git clone https://github.com/<your-fork>/FabConEU_2026_workshop.git
cd FabConEU_2026_workshop
```

## To do the infrastructure part (optional)

Provision Azure SQL and/or Fabric SQL **as code**. You bring the cloud to deploy into.

=== "Azure SQL"
    - An **Azure subscription** where you have **Contributor** rights (to create a resource group,
      a logical SQL server, and a database).
    - To run it **locally**: the
      **[Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli)** (`az login`) and
      **[Terraform](https://developer.hashicorp.com/terraform/install)** (1.8+; the workshop uses
      ~1.12). It's all **passwordless** — Microsoft Entra auth, no SQL logins or secrets to manage.
    - To run it **from a pipeline** (the taught path): your GitHub fork plus a one-time OIDC app
      registration in your subscription — the [Deploy infrastructure](../cicd/deploy-infra.md) page
      walks through it.

    !!! tip "No Azure subscription? Follow along."
        You can still watch every step and grab the module bundle to run against your own kit later.

=== "Fabric SQL"
    Everything in the **Azure SQL** tab, **plus**:

    - A **Microsoft Fabric capacity**. ⚠️ An **F-SKU bills real money continuously** (no serverless
      auto-pause), and a **trial capacity can't be created by Terraform** — so weigh the cost before
      you deploy (see **Cost and teardown** below).
    - If you deploy from a pipeline, a **Fabric tenant admin** to enable *"Service principals can use
      Fabric APIs"*. The [Fabric SQL](../infra/fabric-sql.md) page covers the details.

## To do the database-deploy part (optional)

Ship the sample database's schema **as code** with a SQL project (`.sqlproj` → DACPAC). You'll need:

- A **reachable target SQL** — your own **Azure SQL** or **Fabric SQL** endpoint (from the
  infrastructure part, or one you already run) — **or** our **shared endpoint on the day** (below).
- The **[.NET SDK](https://dotnet.microsoft.com/download)** (the version pinned in
  [`global.json`](https://github.com/JessAndRob/FabConEU_2026_workshop/blob/main/global.json) —
  currently **8.x**) to build the DACPAC.
- **[SqlPackage](https://learn.microsoft.com/sql/tools/sqlpackage/sqlpackage-download)** to publish
  it — a cross-platform `dotnet` tool:

```powershell
dotnet tool install -g microsoft.sqlpackage
```

## The shared endpoint (unsupported)

For anyone without a SQL target of their own, we'll stand up **one shared SQL Server** on the day.
You push your database changes to it through the pipeline and get **your own database** on it — so
there are no name collisions with the person next to you.

!!! warning "Best-effort, and explicitly unsupported"
    The shared endpoint exists so everyone *can* try the database part — but we **won't be able to
    troubleshoot it** during the workshop. If it misbehaves, switch to watching. Anything you deploy
    there is temporary and wiped after the event.

## Cost and teardown

!!! warning "Deploying into your own subscription costs money — tear it down"
    - **Azure SQL** here is a **serverless** database that auto-pauses when idle, so it stays cheap —
      but it isn't free.
    - **Fabric** is the one to watch: an **F-SKU capacity bills continuously** until you pause or
      delete it.
    - Everything you deploy, you can **destroy as code**. The repo ships nightly `*-destroy`
      workflows, and each module page lists the teardown command — run it when you're done. Please
      don't leave resources running after the workshop.

## Your local toolchain

Everything here is cross-platform; only the shell glue changes, and we demo in **PowerShell**.
Bring what matches the parts you want to do:

| Tool | For | Notes |
|---|---|---|
| **git** | Everyone | Fork and clone the repo. |
| **Azure CLI** (`az`) | Infrastructure part (local) | Passwordless `az login`. |
| **Terraform** (1.8+) | Infrastructure part (local) | The taught infrastructure-as-code tool. |
| **.NET SDK** (8.x, per `global.json`) | Database part | Builds the `.sqlproj` into a DACPAC. |
| **SqlPackage** | Database part | Publishes the DACPAC (`dotnet tool install -g microsoft.sqlpackage`). |

!!! tip "Prefer the pipeline? You barely need any of this locally."
    The taught path runs Terraform and SqlPackage **in GitHub Actions**, so to follow along you
    mostly just need your GitHub fork and your cloud — the hosted runners bring the tools.

## What's next

Next: [Source control for databases](../foundations/source-control.md).
