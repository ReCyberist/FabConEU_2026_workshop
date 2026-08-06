# Azure Automation runbook (PowerShell 7.4). Runs as the account's system-assigned managed
# identity. Discovers the Fabric capacity in the workload resource group (its name is
# random-suffixed, so we discover rather than hard-code) and suspends it via the ARM suspend
# action. Idempotent — a no-op if there is no capacity (e.g. after the nightly destroy).
$ErrorActionPreference = 'Stop'

Connect-AzAccount -Identity | Out-Null

$subscriptionId = Get-AutomationVariable -Name 'FabricSubscriptionId'
$resourceGroup  = Get-AutomationVariable -Name 'FabricWorkloadResourceGroup'
Set-AzContext -Subscription $subscriptionId | Out-Null

$capacities = Get-AzResource -ResourceGroupName $resourceGroup -ResourceType 'Microsoft.Fabric/capacities' -ErrorAction SilentlyContinue
if (-not $capacities) {
    Write-Output "No Fabric capacity in $resourceGroup - nothing to pause."
    return
}

foreach ($cap in $capacities) {
    $uri = "https://management.azure.com$($cap.ResourceId)/suspend?api-version=2023-11-01"
    Write-Output "Suspending $($cap.Name)..."
    Invoke-AzRestMethod -Method POST -Uri $uri | Out-Null
    Write-Output "Suspended $($cap.Name)."
}
