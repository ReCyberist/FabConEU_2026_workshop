# Prerequisites

This is a **bring-your-own** workshop. Nothing is provisioned for you, and there is no lab
environment handed out. You will get the most from the day by deploying along on your own Azure or
Fabric kit — but every step is a live demo you can equally watch, then replay later from the
downloads. The only hard requirement is a laptop and some curiosity.

Everything else on this page is **optional**, and depends on how hands-on you would like to be.

## At a glance

The hands-on work splits into **two independent, optional parts**. Choose either, both, or neither.

| You want to… | You will need |
|---|---|
| **Watch** (and replay later) | A laptop. That is all. |
| **Part 1 — deploy infrastructure** as code | Your **own Azure subscription**, plus a **Fabric capacity** for the Fabric path |
| **Part 2 — ship database changes** as code | A reachable **target SQL endpoint** — your own, or our shared one on the day |

The two parts are independent. You can do Part 2 without Part 1, as long as you already have a
target SQL endpoint to deploy into.

## Everyone

Whatever level you choose, do these three things before the day.

1. Create a **[GitHub account](https://github.com/signup)** if you do not have one.
2. Install **[git](https://git-scm.com/downloads)**. Confirm it is installed:

    ```powershell
    git --version
    ```

    You should see a version number, for example `git version 2.51.0`.

3. Fork **[`JessAndRob/FabConEU_2026_workshop`](https://github.com/JessAndRob/FabConEU_2026_workshop)**
   to your own GitHub account and clone the fork. All the code you deploy lives in that
   repository, and you run it from your own copy. With the
   **[GitHub CLI](https://cli.github.com/)**, both happen in one command:

    ```powershell
    gh repo fork JessAndRob/FabConEU_2026_workshop --clone
    cd FabConEU_2026_workshop
    ```

    You now have a folder named `FabConEU_2026_workshop` containing the workshop code, and
    `git remote -v` shows `origin` pointing at **your** fork.

!!! tip "No GitHub CLI?"
    Fork the repository on github.com, then clone your fork, replacing `<your-account>` with your
    own GitHub account name:

    ```powershell
    git clone https://github.com/<your-account>/FabConEU_2026_workshop.git
    cd FabConEU_2026_workshop
    ```

## Part 1 — deploy infrastructure (optional)

Provision Azure SQL and Fabric SQL **as code**. You bring the cloud to deploy into.

=== "Azure SQL"
    You will need:

    - An **Azure subscription** in which you hold the **Contributor** role. Part 1 creates a
      resource group, a logical SQL server, and a database.
    - **To run Terraform on your laptop:** the
      **[Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli)** and
      **[Terraform](https://developer.hashicorp.com/terraform/install)** version **1.8 or later**.
      The workshop is written and tested against **1.12**.
    - **To run it from a pipeline** (this is the path we teach): your GitHub fork, plus a one-time
      OIDC app registration in your subscription. The
      [Deploy infrastructure](../cicd/deploy-infra.md) page walks through creating it.

    Sign in to Azure with the Azure CLI, and confirm you are in the right subscription:

    ```powershell
    az login
    az account show --query "{subscription:name, tenant:tenantId}" --output table
    ```

    The subscription named in the output is the one Terraform will deploy into.

    !!! note "Passwordless throughout"
        Both paths authenticate with Microsoft Entra ID. There are no SQL logins, no connection
        strings, and no secrets for you to store or rotate.

    !!! tip "No Azure subscription? Deploy it later."
        Watch every step on the day, download the module bundle, and run it against your own kit
        when you have one.

=== "Fabric SQL"
    Everything in the **Azure SQL** tab, and in addition:

    - A **Microsoft Fabric capacity**.
    - If you deploy from a pipeline, a **Fabric tenant administrator** who can enable the tenant
      setting *"Service principals can use Fabric APIs"*. The [Fabric SQL](../infra/fabric-sql.md)
      page covers what to ask for.

    !!! warning "Fabric capacity costs real money"
        An **F-SKU capacity bills continuously** from the moment it is created. It does not pause
        itself when idle the way the Azure SQL database in this workshop does, and Terraform
        **cannot** create a free trial capacity. Read [Cost and teardown](#cost-and-teardown)
        below and decide before you deploy, not afterwards.

## Part 2 — ship database changes (optional)

Ship the sample database's schema **as code** with a SQL project, which builds into a DACPAC.

You will need a **reachable target SQL endpoint**. That is either your own Azure SQL or Fabric SQL
endpoint — one you created in Part 1, or one you already run — or our shared endpoint on the day.

Install two tools before you travel.

1. Install the **[.NET SDK](https://dotnet.microsoft.com/download)**, which builds the SQL project
   into a DACPAC. Use the version pinned in
   [`global.json`](https://github.com/JessAndRob/FabConEU_2026_workshop/blob/main/global.json),
   currently **8.x**. Confirm it:

    ```powershell
    dotnet --version
    ```

    The output starts with `8.` — for example `8.0.404`.

2. Install **[SqlPackage](https://learn.microsoft.com/sql/tools/sqlpackage/sqlpackage-download)**,
   which publishes the DACPAC to your target. It is a cross-platform `dotnet` tool:

    ```powershell
    dotnet tool install -g microsoft.sqlpackage
    sqlpackage /version
    ```

    The second command prints a version number. If it reports that `sqlpackage` is not
    recognised, close and reopen your terminal so the updated `PATH` takes effect.

## The shared endpoint (unsupported)

For anyone without a target SQL endpoint of their own, we will run **one shared SQL Server** on the
day. You push your database changes to it through the pipeline, and you get **your own database**
on that server — so there are no name collisions with the person sitting next to you.

!!! warning "Best-effort, and explicitly unsupported"
    The shared endpoint exists so that everyone *can* try Part 2. We will not be able to
    troubleshoot it during the workshop, so if it misbehaves, switch to watching. Everything
    deployed to it is temporary and is deleted after the event.

## Cost and teardown

!!! warning "Deploying into your own subscription costs money. Tear it down when you are done."
    - The **Azure SQL** database in this workshop is **serverless** and pauses itself when idle,
      which keeps it cheap. It is not free.
    - **Fabric** is the one to watch. An **F-SKU capacity bills continuously** until you pause or
      delete it.
    - Everything you deploy, you can **destroy as code**. The repository ships nightly `*-destroy`
      workflows, and every module page ends with its teardown command. Run it when you have
      finished, and please do not leave resources running after the workshop.

## Your local toolchain

Every tool here is cross-platform. Only the surrounding shell commands differ, and we demo in
**PowerShell**. Bring the tools that match the parts you want to do.

| Tool | Needed for | Notes |
|---|---|---|
| **git** | Everyone | Clones your fork. |
| **GitHub CLI** (`gh`) | Everyone (optional) | Forks and clones in one command. |
| **Azure CLI** (`az`) | Part 1, on your laptop | Passwordless sign-in with `az login`. |
| **Terraform** 1.8+ | Part 1, on your laptop | The infrastructure-as-code tool we teach. |
| **.NET SDK** 8.x | Part 2 | Builds the SQL project into a DACPAC. |
| **SqlPackage** | Part 2 | Publishes the DACPAC to your target SQL endpoint. |

To check everything at once, run:

```powershell
git --version
gh --version
az version --output table
terraform version
dotnet --version
sqlpackage /version
```

Each command prints a version number. A command that is *"not recognised"* is not installed, or
your terminal was open before you installed it — reopen the terminal and try again.

!!! tip "Deploying from the pipeline? You need very little of this locally."
    The path we teach runs Terraform and SqlPackage **in GitHub Actions**, where the hosted runners
    already have the tools. To follow that path you need your GitHub fork and your cloud, and
    nothing else.

## What's next

Next: [Source control for databases](../foundations/source-control.md).
