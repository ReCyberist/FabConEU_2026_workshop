# Azure SQL — Terraform (content focus)

Provision Azure SQL (server + database + firewall/network + auth) with Terraform. This is
the **taught path** for the Azure SQL infra module.

To build here:
- `main.tf`, `variables.tf`, `outputs.tf`, `providers.tf` (AzureRM).
- Sensible, parameterised defaults; resources prefixed `fabcon26-`.
- Remote state guidance (or local state for the lab, documented as such).

Keep in step with the Bicep reference in [`../bicep/`](../bicep/) and the Fabric SQL
equivalent in [`../../fabric-sql/terraform/`](../../fabric-sql/terraform/).
