#Requires -Version 7.0
#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.0.0' }
<#
    Readiness checks for the workshop demos -- the read-only half of the pair whose active
    half is demo/Reset-DemoEnvironment.ps1. This asserts the environment IS ready; the reset
    script MAKES it ready. Both read demo/DemoEnvironment.psd1 so they cannot drift.

    Run the whole thing:            Invoke-Pester ./tests/DemoEnvironment.Tests.ps1
    Just the fast repo-state part:  Invoke-Pester ./tests/DemoEnvironment.Tests.ps1 -Tag Repo
    Offline (no cloud/sign-in):     Invoke-Pester ./tests/DemoEnvironment.Tests.ps1 -ExcludeTag Auth,Cloud

    Tags:
      Repo     git state + files -- fast, offline, run this before every rehearsal.
      Tooling  the CLIs and modules the demos call -- run once on a new machine.
      Auth     `gh`/`az` sign-in state -- stateful and slower; skip when offline.
      Cloud    the deployed resources are up -- ONLINE and CROSS-TENANT: the demo + attendee
               Azure SQL databases and the Fabric capacity the morning apply brings up. Run
               after morning-of-checklist.md §1; needs `az login` to BOTH tenants. Each check
               targets its subscription from the env var named in demo/DemoEnvironment.psd1
               (CloudResources) when set, else the current `az` context.
#>

# -- Discovery: load the inventory so the -ForEach blocks below can see it -----------------
$repoRoot     = (git rev-parse --show-toplevel).Trim()
$inventory    = Import-PowerShellDataFile -Path (Join-Path $repoRoot 'demo/DemoEnvironment.psd1')

Describe 'Demo environment · git state' -Tag 'Repo' {

    BeforeAll {
        $script:repoRoot      = (git rev-parse --show-toplevel).Trim()
        Push-Location $script:repoRoot
        $script:currentBranch = (git rev-parse --abbrev-ref HEAD).Trim()
        $script:localBranches = @((git for-each-ref --format='%(refname:short)' refs/heads) -split "`n")
        $script:porcelain     = @(git status --porcelain)
    }
    AfterAll { Pop-Location }

    It 'is on the main branch' {
        # The demos branch OFF main; starting anywhere else means demo 05's `git pull` and the
        # wrap-up merge target the wrong place.
        $script:currentBranch | Should -Be 'main'
    }

    It 'has a clean working tree' {
        # Anything here means a previous run's residue (or unrelated WIP) is still present.
        $script:porcelain -join "`n" | Should -BeNullOrEmpty
    }

    It "has no leftover local demo branch '<_>'" -ForEach $inventory.DemoRunBranches {
        # This is the exact failure the whole exercise started from:
        #   git switch -c demo/source-control  ->  fatal: a branch named ... already exists
        $script:localBranches | Should -Not -Contain $_ -Because 'Reset-DemoEnvironment.ps1 removes it'
    }
}

Describe 'Demo environment · files' -Tag 'Repo' {

    BeforeAll { Push-Location (git rev-parse --show-toplevel).Trim() }
    AfterAll  { Pop-Location }

    It "has no demo-created scratch file '<_>'" -ForEach $inventory.CreatedFiles {
        Test-Path $_ | Should -BeFalse -Because 'the demos create it at runtime; a base checkout has none'
    }

    It "has tracked file '<_>' unmodified" -ForEach $inventory.MutatedTrackedFiles {
        # The demos overwrite these in place. If one shows a diff, a RESET was skipped.
        Test-Path $_ | Should -BeTrue
        (git status --porcelain -- $_) | Should -BeNullOrEmpty -Because 'the demos overwrite it and reset restores it'
    }

    It '<Description>' -ForEach $inventory.ContentAssertions {
        # A content trap `git status` cannot see: e.g. auto-pause committed as 75, so the
        # wrap-up plan reads "0 to change".
        $assert = $_
        $hit = Select-String -Path $assert.Path -Pattern $assert.Pattern -Context 0, 4
        $block = ($hit | ForEach-Object { $_.Line; $_.Context.PostContext }) -join "`n"
        $block | Should -Match $assert.Expect -Because "expected /$($assert.Expect)/ near '$($assert.Pattern)' in $($assert.Path)"
    }
}

Describe 'Demo environment · tooling' -Tag 'Tooling' {

    It "has '<Name>' on PATH  (demo <Demo>)" -ForEach $inventory.RequiredCommands {
        Get-Command $_.Name -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }

    It "has the '<Name>' module installed  (demo <Demo>)" -ForEach $inventory.RequiredModules {
        Get-Module -ListAvailable -Name $_.Name | Should -Not -BeNullOrEmpty
    }

    It 'has the .NET SDK major version global.json pins' {
        $dotnet = Get-Command dotnet -ErrorAction SilentlyContinue
        $dotnet | Should -Not -BeNullOrEmpty -Because 'demo 03 builds the SQL project'
        $major = [int](((dotnet --version) -split '\.')[0])
        $major | Should -BeGreaterOrEqual $inventory.DotnetMajorVersion
    }
}

Describe 'Demo environment · sign-in state' -Tag 'Auth' {

    It 'is signed in to GitHub (gh auth status)' {
        gh auth status *> $null
        $LASTEXITCODE | Should -Be 0 -Because 'demos 01, 04 and 05 push and dispatch workflows'
    }

    It 'has an active Azure CLI login (az account show)' {
        az account show *> $null
        $LASTEXITCODE | Should -Be 0 -Because 'demos 02 and 03 reach Azure'
    }
}

Describe 'Demo environment · cloud resources' -Tag 'Cloud' {
    # Online, CROSS-TENANT readiness for what the morning apply (checklist §1) brings up. Azure
    # SQL (demo + attendee) is checked in the sandbox subscription (Tenant A); Fabric in Tenant B.
    # Every check is skipped when `az` is not signed in, so it never fails a plain offline run.

    BeforeAll {
        # Re-load the inventory HERE, in the run phase. The top-level $inventory is populated
        # during Pester's discovery phase only; the -ForEach blocks above bind to it then, but a
        # run-phase BeforeAll sees it as $null. Reading $inventory.CloudResources here would make
        # $script:cloud null, so every `az ... -g $null` query returns empty and each Cloud check
        # fails with "got $null or empty" even when the resources are up. Load it ourselves.
        $script:cloud = (Import-PowerShellDataFile -Path (Join-Path (git rev-parse --show-toplevel).Trim() 'demo/DemoEnvironment.psd1')).CloudResources
        az account show *> $null
        $script:signedIn = ($LASTEXITCODE -eq 0)

        # Optional `--subscription` args from the env var named in the inventory; empty (current
        # context) when the var is unset. Keeps subscription ids out of the repo.
        function script:Get-SubArgs {
            param([string] $EnvName)
            $val = [Environment]::GetEnvironmentVariable($EnvName)
            if ($val) { @('--subscription', $val) } else { @() }
        }
    }

    It "the demo Azure SQL database '$($inventory.CloudResources.DemoDatabaseName)' exists and is not deleting" {
        if (-not $script:signedIn) { Set-ItResult -Skipped -Because 'az is not signed in (run the Auth checks first)'; return }
        $c       = $script:cloud
        $subArgs = script:Get-SubArgs $c.AzureSqlSubscriptionEnv
        $server  = (az sql server list -g $c.DemoResourceGroup @subArgs --query "[0].name" -o tsv 2>$null)
        $server  | Should -Not -BeNullOrEmpty -Because "azure-sql-apply (demo) creates a server in $($c.DemoResourceGroup)"
        $status  = (az sql db show -g $c.DemoResourceGroup --server $server --name $c.DemoDatabaseName @subArgs --query 'status' -o tsv 2>$null)
        # Online, or Paused if the serverless database has auto-paused since the apply -- both mean
        # it exists and is reachable (the first query wakes a paused one). Anything else is a problem.
        $status  | Should -BeIn @('Online', 'Paused') -Because 'the DACPAC published into it during the apply'
    }

    It "all $($inventory.CloudResources.AttendeeCount) attendee databases exist" {
        if (-not $script:signedIn) { Set-ItResult -Skipped -Because 'az is not signed in (run the Auth checks first)'; return }
        $c       = $script:cloud
        $subArgs = script:Get-SubArgs $c.AzureSqlSubscriptionEnv
        $server  = (az sql server list -g $c.AttendeeResourceGroup @subArgs --query "[0].name" -o tsv 2>$null)
        $server  | Should -Not -BeNullOrEmpty -Because "azure-sql-apply (attendee) creates a server in $($c.AttendeeResourceGroup)"
        # List every db name and filter in PowerShell. A server-side --query filter
        # ("[?starts_with(name,'...')]") does not survive PowerShell -> az.cmd argument passing --
        # the `[?` mangles, az exits non-zero, and the count comes back as 1. `[].name` is the same
        # safe shape as the demo check's `[0].name`, so the prefix match lives here instead.
        $names   = @(az sql db list -g $c.AttendeeResourceGroup --server $server @subArgs --query "[].name" -o tsv 2>$null)
        $dbs     = @($names | Where-Object { $_ -and $_.StartsWith($c.AttendeeDatabasePrefix) })
        $dbs.Count | Should -BeGreaterOrEqual $c.AttendeeCount -Because 'one database per attendee is deployed for the shared endpoint'
    }

    It "the Fabric capacity '$($inventory.CloudResources.FabricCapacityName)' is Active" {
        if (-not $script:signedIn) { Set-ItResult -Skipped -Because 'az is not signed in (run the Auth checks first)'; return }
        $c       = $script:cloud
        $subArgs = script:Get-SubArgs $c.FabricSubscriptionEnv
        $state   = (az resource show -g $c.FabricResourceGroup -n $c.FabricCapacityName --resource-type 'Microsoft.Fabric/capacities' @subArgs --query 'properties.state' -o tsv 2>$null)
        $state   | Should -Be 'Active' -Because 'the Fabric demos need the capacity resumed and the auto-pause disabled for the day'
    }
}
