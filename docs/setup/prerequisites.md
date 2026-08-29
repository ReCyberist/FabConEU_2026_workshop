# Prerequisites

This is a **bring-your-own** workshop. Nothing is provisioned for you, and there is no lab
environment handed out. You will get the most from the day by deploying along on your own Azure or
Fabric kit — but every step is a live demo you can equally watch, then replay later from the
downloads. The only hard requirement is a laptop and some curiosity.

Everything else on this page is **optional**, and depends on how hands-on you would like to be.

!!! note "The install commands on this page use winget"
    We demo on Windows in **PowerShell**, so each install step shows
    **[winget](https://learn.microsoft.com/windows/package-manager/winget/)**, which ships with
    Windows 11 and Windows 10 (from version 1809). On macOS or Linux, follow the vendor link in
    the same step instead. Every tool here is cross-platform; only the install command differs.

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

Whatever level you choose, do these four things before the day. (If you have missed any, you can still do them right now but be quick !! You don't want to miss out on what we are saying.)

1. Create a **[GitHub account](https://github.com/signup)** if you do not have one.

2. Install **[git](https://git-scm.com/downloads)**:

    ```powershell
    winget install --exact --id Git.Git
    ```

    Close and reopen your terminal, then confirm it is installed:

    ```powershell
    git --version
    ```

    You see a version number, for example `git version 2.51.0`.

3. Install the **[GitHub CLI](https://cli.github.com/)** and sign in to it. The GitHub CLI is how
    you fork the repository, and later how you set the secrets your pipeline needs — all without
    leaving the terminal.

    ```powershell
    winget install --exact --id GitHub.cli
    ```

    Close and reopen your terminal, then confirm it is installed:

    ```powershell
    gh --version
    ```

    Now sign in:

    ```powershell
    gh auth login --hostname github.com --git-protocol https --web
    ```

    The command prints a **one-time code** and opens github.com in your browser. Enter the code
    in the browser and approve the sign-in. Then confirm it worked:

    ```powershell
    gh auth status
    ```

    The output reads `✓ Logged in to github.com account <your-account>`, and lists the token
    scopes `gist`, `read:org`, `repo` and `workflow`. If `workflow` is missing, run
    `gh auth refresh --scopes workflow` — you need it later to push pipeline changes.

4. Fork **[`JessAndRob/FabConEU_2026_workshop`](https://github.com/JessAndRob/FabConEU_2026_workshop)**
    to your own GitHub account and clone the fork. All the code you deploy lives in that
    repository, and you run it from your own copy. Both happen in one command:

    ```powershell
    gh repo fork JessAndRob/FabConEU_2026_workshop --clone
    cd FabConEU_2026_workshop
    ```

    You now have a folder named `FabConEU_2026_workshop` containing the workshop code, and
    `git remote -v` shows `origin` pointing at **your** fork.

!!! tip "Would rather not install the GitHub CLI?"
    Fork the repository on github.com, then clone your fork, replacing `<your-account>` with your
    own GitHub account name:

    ```powershell
    git clone https://github.com/<your-account>/FabConEU_2026_workshop.git
    cd FabConEU_2026_workshop
    ```

    Everything else on the day still works. You will set your pipeline secrets in the repository
    settings page rather than with `gh secret set`.

## Part 1 — deploy infrastructure (optional)

Provision Azure SQL and Fabric SQL **as code**. You bring the cloud to deploy into.

=== "Azure SQL"
    You need an **Azure subscription** in which you hold the **Contributor** role. Part 1 creates a
    resource group, a logical SQL server, and a database.

    **To run Terraform on your laptop**, install two more tools and sign in.

    1. Install the **[Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli)**:

        ```powershell
        winget install --exact --id Microsoft.AzureCLI
        ```

        Close and reopen your terminal, then confirm it is installed:

        ```powershell
        az version --output table
        ```

    2. Install **[Terraform](https://developer.hashicorp.com/terraform/install)**, version **1.8 or
        later**. The workshop is written and tested against **1.12**.

        ```powershell
        winget install --exact --id Hashicorp.Terraform
        ```

        Close and reopen your terminal, then confirm it is installed:

        ```powershell
        terraform version
        ```

        The output starts `Terraform v1.` followed by 8 or higher, for example `Terraform v1.12.0`.

    3. Sign in to Azure, and check which subscription you landed in:

        ```powershell
        az login
        az account show --query "{subscription:name, tenant:tenantId}" --output table
        ```

        The subscription named in the output is the one Terraform deploys into. If it is the wrong
        one, switch:

        ```powershell
        az account set --subscription "<subscription name or id>"
        ```

    **To run it from a pipeline instead** — this is the path we teach — you need your GitHub fork
    and a one-time OIDC app registration in your subscription. The
    [Deploy infrastructure](../cicd/deploy-infra.md) page walks through creating it on the day, so
    there is nothing to install for this beyond the tools in **Everyone** above.

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

    The Fabric Terraform provider is downloaded by `terraform init` on the day, so there is nothing
    extra to install on your laptop.

    !!! warning "Fabric capacity costs real money"
        An **F-SKU capacity bills continuously** from the moment it is created. It does not pause
        itself when idle the way the Azure SQL database in this workshop does, and Terraform
        **cannot** create a free trial capacity. Read [Cost and teardown](#cost-and-teardown)
        below and decide before you deploy, not afterwards.

## Part 2 — ship database changes (optional)

Ship the sample database's schema **as code** with a SQL project, which builds into a DACPAC.

You need a **reachable target SQL endpoint**. That is either your own Azure SQL or Fabric SQL
endpoint — one you created in Part 1, or one you already run — or our shared endpoint on the day.

Install two tools before you travel.

1. Install the **[.NET SDK](https://dotnet.microsoft.com/download)**, which builds the SQL project
    into a DACPAC. Use the version pinned in
    [`global.json`](https://github.com/JessAndRob/FabConEU_2026_workshop/blob/main/global.json),
    currently **8.x**.

    ```powershell
    winget install --exact --id Microsoft.DotNet.SDK.8
    ```

    Close and reopen your terminal, then confirm it is installed:

    ```powershell
    dotnet --version
    ```

    The output starts with `8.` — for example `8.0.404`.

2. Install **[SqlPackage](https://learn.microsoft.com/sql/tools/sqlpackage/sqlpackage-download)**,
    which publishes the DACPAC to your target. It is a cross-platform `dotnet` tool, so it installs
    the same way on every operating system:

    ```powershell
    dotnet tool install -g microsoft.sqlpackage
    sqlpackage /version
    ```

    The second command prints a version number. If it reports that `sqlpackage` is not recognised,
    close and reopen your terminal so the updated `PATH` takes effect.

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

Here is everything above in one table. Bring the tools that match the parts you want to do.

| Tool | Needed for | Install | Check |
|---|---|---|---|
| **git** | Everyone | `winget install --exact --id Git.Git` | `git --version` |
| **GitHub CLI** (`gh`) | Everyone | `winget install --exact --id GitHub.cli` | `gh auth status` |
| **Azure CLI** (`az`) | Part 1, on your laptop | `winget install --exact --id Microsoft.AzureCLI` | `az version` |
| **Terraform** 1.8+ | Part 1, on your laptop | `winget install --exact --id Hashicorp.Terraform` | `terraform version` |
| **.NET SDK** 8.x | Part 2 | `winget install --exact --id Microsoft.DotNet.SDK.8` | `dotnet --version` |
| **SqlPackage** | Part 2 | `dotnet tool install -g microsoft.sqlpackage` | `sqlpackage /version` |

To check everything at once, run:

```powershell
git --version
gh auth status
az version --output table
terraform version
dotnet --version
sqlpackage /version
```

Each command prints a version number, and `gh auth status` confirms you are signed in. A command
that is *"not recognised"* is not installed, or your terminal was open before you installed it —
reopen the terminal and try again.

!!! tip "Deploying from the pipeline? You need very little of this locally."
    The path we teach runs Terraform and SqlPackage **in GitHub Actions**, where the hosted runners
    already have the tools. To follow that path you need your GitHub fork and your cloud, and
    nothing else.

## What's next

Next: [Source control for databases](../foundations/source-control.md).
