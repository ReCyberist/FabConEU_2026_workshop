# Azure Automation runbook (PowerShell 7.4). Runs as the account's system-assigned managed
# identity. Discovers the Fabric capacity in the workload resource group and resumes it via the
# ARM resume action. On-demand only (no schedule) — run before a demo. Idempotent.
$ErrorActionPreference = 'Stop'

Connect-AzAccount -Identity | Out-Null

$subscriptionId = Get-AutomationVariable -Name 'FabricSubscriptionId'
$resourceGroup  = Get-AutomationVariable -Name 'FabricWorkloadResourceGroup'
Set-AzContext -Subscription $subscriptionId | Out-Null

$capacities = Get-AzResource -ResourceGroupName $resourceGroup -ResourceType 'Microsoft.Fabric/capacities' -ErrorAction SilentlyContinue
if (-not $capacities) {
    Write-Output "No Fabric capacity in $resourceGroup - nothing to resume."
    return
}

foreach ($cap in $capacities) {
    $uri = "https://management.azure.com$($cap.ResourceId)/resume?api-version=2023-11-01"
    Write-Output "Resuming $($cap.Name)..."
    Invoke-AzRestMethod -Method POST -Uri $uri | Out-Null
    Write-Output "Resumed $($cap.Name)."
}
