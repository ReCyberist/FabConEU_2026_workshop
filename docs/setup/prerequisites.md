# Prerequisites

This is a **bring-your-own** workshop, and every step is a live demo. You can deploy along on your
own Azure or Fabric kit, or you can watch and replay the whole thing later from the downloads —
both are entirely respectable choices. The only hard requirement is a laptop and some curiosity.

There is **no lab environment**: we do not hand out subscriptions, capacities or credentials, so
anything you deploy today you deploy into your own cloud. The single exception is a **shared SQL
Server** we run on the day, for anyone who wants to practise deploying a database but has no
endpoint of their own to deploy into. It is best-effort and unsupported — see
[The shared endpoint](#the-shared-endpoint-unsupported) below.

Everything else on this page is **optional**, and depends on how hands-on you would like to be.

## Choose your operating system

Every install step on this page is tabbed. Pick your operating system **once**, in any tab below,
and the whole page follows you — including the tabs tucked inside Part 1.

=== "Windows"
    Install commands use **[winget](https://learn.microsoft.com/windows/package-manager/winget/)**,
    which ships with Windows 11 and with Windows 10 from version 1809. Run them in **PowerShell**.
    This is what we demo on.

=== "macOS"
    Install commands use **[Homebrew](https://brew.sh/)**. If you do not have it yet, install it
    first with the one-line command on [brew.sh](https://brew.sh/). Run everything in **Terminal**.

=== "Debian & Ubuntu"
    Install commands use **apt**. Four of the tools live in vendor repositories rather than in the
    distribution archive, so **add those repositories once** using the block below before you
    install anything.

    ??? note "Add the package repositories — run this once"
        This block adds three repositories — GitHub, HashiCorp and Microsoft — and the signing
        keys your machine uses to check that their packages are genuine. Every install step
        later on this page is then a single `apt install`.

        ```bash
        # Prerequisites for adding repositories
        sudo apt update && sudo apt install -y curl gpg lsb-release
        sudo mkdir -p -m 755 /etc/apt/keyrings

        # GitHub CLI
        curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
          | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null
        sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
          | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null

        # HashiCorp (Terraform)
        curl -fsSL https://apt.releases.hashicorp.com/gpg \
          | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
        echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
          | sudo tee /etc/apt/sources.list.d/hashicorp.list > /dev/null

        # Microsoft (Azure CLI)
        curl -fsSL https://packages.microsoft.com/keys/microsoft.asc \
          | sudo gpg --dearmor -o /etc/apt/keyrings/microsoft.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/azure-cli/ $(lsb_release -cs) main" \
          | sudo tee /etc/apt/sources.list.d/azure-cli.list > /dev/null

        sudo apt update
        ```

        **On Debian only**, add one more repository for the .NET SDK. Ubuntu 22.04 and later ship
        the .NET SDK in their own archive, and adding this repository on Ubuntu causes a package
        conflict — so skip it there.

        ```bash
        curl -fsSL -O https://packages.microsoft.com/config/debian/12/packages-microsoft-prod.deb
        sudo dpkg -i packages-microsoft-prod.deb
        rm packages-microsoft-prod.deb
        sudo apt update
        ```

!!! note "A word on the macOS commands"
    We demo on Windows and test on Debian, so the Homebrew commands here are the vendors' own
    formulae rather than something we have run ourselves. They are the documented way to install
    each tool. If one has drifted since we wrote this, the vendor link in the same step is the
    authority — and every tool on this page is genuinely cross-platform, so only the install
    command differs.

## At a glance

The hands-on work splits into **two independent, optional parts**. Choose either, both, or neither.

| You want to… | You will need |
|---|---|
| **Watch** (and replay later) | A laptop. That is all. |
| **Part 1 — deploy infrastructure** as code | Your **own Azure subscription**, plus a **Fabric capacity** for the Fabric path |
| **Part 2 — ship database changes** as code | A reachable **target SQL endpoint** — your own, or our shared SQL Server on the day |

The two parts are independent. You can do Part 2 without Part 1, as long as you already have a
target SQL endpoint to deploy into.

## Everyone

Whatever level you choose, do these four things before the day. (If you have missed any, you can still do them right now but be quick !! You don't want to miss out on what we are saying.)

1. Create a **[GitHub account](https://github.com/signup)** if you do not have one.

2. Install **[git](https://git-scm.com/downloads)**:

    === "Windows"

        ```powershell
        winget install --exact --id Git.Git
        ```

    === "macOS"

        ```bash
        brew install git
        ```

    === "Debian & Ubuntu"

        ```bash
        sudo apt install git
        ```

    Close and reopen your terminal, then confirm it is installed:

    ```powershell
    git --version
    ```

    You see a version number, for example `git version 2.51.0`.

3. Install the **[GitHub CLI](https://cli.github.com/)** and sign in to it. The GitHub CLI is how
    you fork the repository, and later how you set the secrets your pipeline needs — all without
    leaving the terminal.

    === "Windows"

        ```powershell
        winget install --exact --id GitHub.cli
        ```

    === "macOS"

        ```bash
        brew install gh
        ```

    === "Debian & Ubuntu"

        ```bash
        sudo apt install gh
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

        === "Windows"

            ```powershell
            winget install --exact --id Microsoft.AzureCLI
            ```

        === "macOS"

            ```bash
            brew install azure-cli
            ```

        === "Debian & Ubuntu"

            ```bash
            sudo apt install azure-cli
            ```

        Close and reopen your terminal, then confirm it is installed:

        ```powershell
        az version --output table
        ```

    2. Install **[Terraform](https://developer.hashicorp.com/terraform/install)**, version **1.8 or
        later**. The workshop is written and tested against **1.12**.

        === "Windows"

            ```powershell
            winget install --exact --id Hashicorp.Terraform
            ```

        === "macOS"

            ```bash
            brew tap hashicorp/tap
            brew install hashicorp/tap/terraform
            ```

        === "Debian & Ubuntu"

            ```bash
            sudo apt install terraform
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

    === "Windows"

        ```powershell
        winget install --exact --id Microsoft.DotNet.SDK.8
        ```

    === "macOS"

        ```bash
        brew install --cask dotnet-sdk@8
        ```

    === "Debian & Ubuntu"

        ```bash
        sudo apt install dotnet-sdk-8.0
        ```

        On Debian this comes from the Microsoft repository added at the top of the page. On
        Ubuntu 22.04 and later it comes from the Ubuntu archive, and no extra repository is needed.

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

    The second command prints a version number. If instead it reports that `sqlpackage` cannot be
    found, the tools folder is not on your `PATH`:

    === "Windows"

        Close and reopen your terminal so the updated `PATH` takes effect, then run
        `sqlpackage /version` again.

    === "macOS"

        Add the tools folder to your `PATH`, then run `sqlpackage /version` again:

        ```bash
        echo 'export PATH="$PATH:$HOME/.dotnet/tools"' >> ~/.zshrc
        source ~/.zshrc
        ```

    === "Debian & Ubuntu"

        Add the tools folder to your `PATH`, then run `sqlpackage /version` again:

        ```bash
        echo 'export PATH="$PATH:$HOME/.dotnet/tools"' >> ~/.bashrc
        source ~/.bashrc
        ```

## The shared endpoint (unsupported)

This is the one thing we do provide, and it exists for a single purpose: so that nobody who wants
to practise deploying a database is stopped by not having somewhere to deploy it to.

It is **one shared SQL Server**, running only on the day. You push your database changes to it
through the pipeline, and you get **your own database** on that server — so there are no name
collisions with the person sitting next to you. It is not a lab environment: it is a target for
Part 2, and nothing else. Part 1 still needs your own Azure subscription.

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

=== "Windows"

    | Tool | Needed for | Install | Check |
    |---|---|---|---|
    | **git** | Everyone | `winget install --exact --id Git.Git` | `git --version` |
    | **GitHub CLI** (`gh`) | Everyone | `winget install --exact --id GitHub.cli` | `gh auth status` |
    | **Azure CLI** (`az`) | Part 1, on your laptop | `winget install --exact --id Microsoft.AzureCLI` | `az version` |
    | **Terraform** 1.8+ | Part 1, on your laptop | `winget install --exact --id Hashicorp.Terraform` | `terraform version` |
    | **.NET SDK** 8.x | Part 2 | `winget install --exact --id Microsoft.DotNet.SDK.8` | `dotnet --version` |
    | **SqlPackage** | Part 2 | `dotnet tool install -g microsoft.sqlpackage` | `sqlpackage /version` |

=== "macOS"

    | Tool | Needed for | Install | Check |
    |---|---|---|---|
    | **git** | Everyone | `brew install git` | `git --version` |
    | **GitHub CLI** (`gh`) | Everyone | `brew install gh` | `gh auth status` |
    | **Azure CLI** (`az`) | Part 1, on your laptop | `brew install azure-cli` | `az version` |
    | **Terraform** 1.8+ | Part 1, on your laptop | `brew install hashicorp/tap/terraform` | `terraform version` |
    | **.NET SDK** 8.x | Part 2 | `brew install --cask dotnet-sdk@8` | `dotnet --version` |
    | **SqlPackage** | Part 2 | `dotnet tool install -g microsoft.sqlpackage` | `sqlpackage /version` |

=== "Debian & Ubuntu"

    Add the package repositories first — see [Choose your operating
    system](#choose-your-operating-system) at the top of this page.

    | Tool | Needed for | Install | Check |
    |---|---|---|---|
    | **git** | Everyone | `sudo apt install git` | `git --version` |
    | **GitHub CLI** (`gh`) | Everyone | `sudo apt install gh` | `gh auth status` |
    | **Azure CLI** (`az`) | Part 1, on your laptop | `sudo apt install azure-cli` | `az version` |
    | **Terraform** 1.8+ | Part 1, on your laptop | `sudo apt install terraform` | `terraform version` |
    | **.NET SDK** 8.x | Part 2 | `sudo apt install dotnet-sdk-8.0` | `dotnet --version` |
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
that reports it cannot be found is not installed, or your terminal was open before you installed
it — reopen the terminal and try again.

!!! tip "Deploying from the pipeline? You need very little of this locally."
    The path we teach runs Terraform and SqlPackage **in GitHub Actions**, where the hosted runners
    already have the tools. To follow that path you need your GitHub fork and your cloud, and
    nothing else.

## What's next

Next: [Source control for databases](../foundations/source-control.md).
