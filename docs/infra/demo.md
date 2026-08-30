# Infrastructure as code demo

This is the live infrastructure part of the day in its shortest useful form: open the module,
review the local variables, run `terraform init`, inspect the plan, then apply it. The shape is
the same on both platforms; the main difference is what gets created.

!!! note "Follow along — or just watch"
	You need your **own Azure subscription**. For the Fabric path, you also need a **Fabric
	capacity**. See [Prerequisites](../setup/prerequisites.md), [Azure SQL as code](azure-sql.md),
	and [Fabric SQL as code](fabric-sql.md).

## What you'll do

Run one Terraform module from the repository and let it build the target platform from code.

- **Azure SQL** creates a resource group, a logical SQL server, a serverless database, and the
	  firewall rules needed for the demo.
- **Fabric SQL** creates or binds to a capacity, then builds a workspace and a SQL database in
	  Fabric.

## The concept

- **The flow is the same on both paths.** Open the module, review the variables, initialise the
	  backend and providers, inspect the plan, then apply it.
- **Terraform works from declared state, not clicks.** The `.tf` files describe what should exist;
	  `terraform plan` shows the diff, and `terraform apply` makes Azure or Fabric match it.
- **Passwordless is the default.** Both paths use Microsoft Entra rather than stored SQL
	  credentials.

## Azure SQL

### Run it

1. In the repository root folder, move into the Azure SQL Terraform module.

	```powershell
	cd infra/azure-sql/terraform
	Get-Location
	```

	The path ends with `infra\azure-sql\terraform`.

2. Sign in to Azure and set the subscription the demo should deploy into.

	```powershell
	az login
	$env:ARM_SUBSCRIPTION_ID = "<your-subscription-id>"
	az account show --query "{subscription:name, id:id}" --output table
	```

	The table shows the subscription you want to use.

3. Create a local `terraform.tfvars` file and review the Entra admin values before you plan.

	```powershell
	Copy-Item terraform.tfvars.example terraform.tfvars
	code terraform.tfvars
	```

	Set `entra_admin_login` and `entra_admin_object_id`, then save the file.

	If you need the object ID for the demo Entra admin group, run the following - updating for your group name:

	```powershell
	az ad group show --group "fabcon26-sql-admins" --query id -o tsv
	```

	The command prints the object ID you can paste into `entra_admin_object_id`.

4. In `terraform.tfvars`, change the demo overrides to deploy the `test` environment in `uksouth`.

	```hcl
	environment           = "test"
	location              = "uksouth"
	location_abbreviation = "uks"
	database_name         = "soccer"
	```

	Save the file. Keeping `location` and `location_abbreviation` in step avoids naming drift.
	If you prefer `futbol`, use that instead of `soccer`. Do not use `fútbol` with the accent here:
	`database_name` must be lowercase alphanumeric.

5. In the same folder, switch the demo to local state so it does not prompt for the remote backend.

	```powershell
	Copy-Item backend_local_override.tf.example backend_local_override.tf
	```

	The folder now contains `backend_local_override.tf`.

6. Initialise Terraform.

	```powershell
	terraform init
	```

	Terraform installs the required providers and reports that initialization completed successfully.

7. Review the plan before you create anything.

	```powershell
	terraform plan
	```

	The plan shows the Azure SQL resources to add: the resource group, logical server, serverless
	database, and firewall rules.

8. Apply the plan.

	```powershell
	terraform apply
	```

	Terraform prompts for confirmation, then creates the resources and finishes with `Apply
	complete!`.

	!!! note "Jess's test run"
		Jess's deploy to the `test` environment in `uksouth` took **4m31s**.

		Example output from that run:

		```text
		Apply complete! Resources: 4 added, 0 changed, 0 destroyed.

		Outputs:

		resource_group_name = "rg-fabcon26-test-uks"
		sql_database_name = "sqldb-football-test"
		sql_server_fqdn = "sql-fabcon26-test-uks-myw0ki.database.windows.net"
		sql_server_name = "sql-fabcon26-test-uks-myw0ki"
		```

		Your names will differ if you changed `database_name`, and the server suffix is always unique.

9. Open the [Azure portal](https://portal.azure.com) and confirm that the resources now exist.

	In the portal, open the resource group and confirm that you can see the logical SQL server and
	the serverless database.

## Fabric SQL

!!! danger "Jess & Rob"
	**This Fabric demo is not tested yet. Do not present it as live-verified.**

### Run it

1. Move into the Fabric SQL Terraform module.

	```powershell
	cd infra/fabric-sql/terraform
	Get-Location
	```

	If you are currently in `infra/azure-sql/terraform`, move up first and then across:

	```powershell
	cd ../../fabric-sql/terraform
	Get-Location
	```

	The path ends with `infra\fabric-sql\terraform`.

2. Sign in to Azure and set the subscription that holds, or can create, the Fabric capacity.

	```powershell
	az login
	$env:ARM_SUBSCRIPTION_ID = "<your-subscription-id>"
	$env:TF_VAR_fabric_subscription_id = $env:ARM_SUBSCRIPTION_ID
	az account show --query "{subscription:name, id:id}" --output table
	```

	The table shows the subscription you want to use for the Fabric capacity.

	The second line sets the one variable the Fabric module requires: `fabric_subscription_id`,
	which pins the `azurerm` provider that builds the capacity. For this local demo it is the same
	subscription, so reuse the value. Without it, `terraform plan` stops and prompts for the value.

3. Create a local `terraform.tfvars` file and review the variables for your Fabric path.

	```powershell
	Copy-Item terraform.tfvars.example terraform.tfvars
	code terraform.tfvars
	```

	Review the file and save any changes you need. If you plan to bind to an existing capacity,
	set the relevant capacity values before you continue.

4. In `terraform.tfvars`, change the demo overrides to deploy the `test` environment in `uksouth`.

	```hcl
	environment           = "test"
	location              = "uksouth"
	location_abbreviation = "uks"
	database_name         = "soccer"
	```

	Save the file. Keeping `location` and `location_abbreviation` in step avoids naming drift.
	If you prefer `futbol`, use that instead of `soccer`. Do not use `fútbol` with the accent here:
	`database_name` must be lowercase alphanumeric.

5. In the same folder, switch the demo to local state so it does not prompt for the remote backend.

	```powershell
	Copy-Item backend_local_override.tf.example backend_local_override.tf
	```

	The folder now contains `backend_local_override.tf`.

6. Initialise Terraform.

	```powershell
	terraform init
	```

	Terraform installs both the `azurerm` and `microsoft/fabric` providers and reports that
	initialization completed successfully.

7. Review the plan before you create anything.

	```powershell
	terraform plan
	```

	The plan shows the Fabric resources to add: the capacity or capacity binding, the workspace, and
	the SQL database.

8. Apply the plan.

	```powershell
	terraform apply
	```

	Terraform prompts for confirmation, then creates the resources and finishes with `Apply
	complete!`.

9. Open the Azure and Fabric portals and confirm that the resources now exist.

	```powershell
	Start-Process "https://portal.azure.com"
	Start-Process "https://app.fabric.microsoft.com"
	```

	In Azure, confirm that the Fabric capacity exists in the resource group. In Fabric, confirm that
	the workspace and SQL database are present.

## Checkpoint

You now have the infrastructure target for the next part of the day. On Azure SQL, that is a
logical server and serverless database. On Fabric SQL, that is a capacity-backed workspace with a
SQL database in Fabric. In both cases, the target was created from code, not by clicking in a
portal.

## Tear it down

Do this when you finish. Workshop resources that survive the workshop become a bill.

### Azure SQL

From `infra/azure-sql/terraform`, destroy the resources you just created:

```powershell
terraform destroy
```

Terraform shows the resources it will remove, prompts for confirmation, and finishes with `Destroy
complete!`.

!!! note "Jess's test run"
	Jess's destroy of the Azure SQL `test` environment in `uksouth` took **2m12s**.

	Example output from that run:

	```text
	Destroy complete! Resources: 5 destroyed.
	```

### Fabric SQL

From `infra/fabric-sql/terraform`, destroy the resources you just created:

```powershell
terraform destroy
```

Terraform shows the resources it will remove, prompts for confirmation, and finishes with `Destroy
complete!`.

If you set `use_existing_capacity = true`, `terraform destroy` removes only the **workspace** and
the **SQL database**. It does **not** destroy the existing Fabric capacity, because that capacity
is a data source, not a managed resource. In that mode, pause the capacity when you finish so it
stops billing.

## Gotchas

- **Use the local-backend override for the demo.** Without `backend_local_override.tf`, a local
	  `terraform init` tries to use the remote backend that CI shares.
- **Azure SQL needs a real Entra admin identity.** A group is the safest choice because the server
	  allows one Entra admin.
- **Fabric needs more than an Azure subscription.** A tenant admin must allow service principals to
	  use Fabric APIs, and an F-SKU capacity bills while it exists.
- **`ARM_SUBSCRIPTION_ID` does not set the Fabric provider subscription.** The Fabric module's
	  `azurerm` provider reads its subscription from the `fabric_subscription_id` variable, which has
	  no default. Set `TF_VAR_fabric_subscription_id` (step 2) or `terraform plan` prompts for it.
- **The two platforms are similar, not identical.** Azure SQL is `server → database`; Fabric SQL is
	  `capacity → workspace → database`, with an extra provider.

## What's next

Next: [Database as code — SQL projects](../database/sql-projects.md).
