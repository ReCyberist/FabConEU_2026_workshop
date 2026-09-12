#Requires -Version 7.0
#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.0.0' }
<#
    Readiness checks for the workshop demos -- the read-only half of the pair whose active
    half is demo/Reset-DemoEnvironment.ps1. This asserts the environment IS ready; the reset
    script MAKES it ready. Both read demo/DemoEnvironment.psd1 so they cannot drift.

    Run the whole thing:            Invoke-Pester ./tests/DemoEnvironment.Tests.ps1
    Just the fast repo-state part:  Invoke-Pester ./tests/DemoEnvironment.Tests.ps1 -Tag Repo
    Everything but sign-in state:   Invoke-Pester ./tests/DemoEnvironment.Tests.ps1 -ExcludeTag Auth

    Tags:
      Repo     git state + files -- fast, offline, run this before every rehearsal.
      Tooling  the CLIs and modules the demos call -- run once on a new machine.
      Auth     `gh`/`az` sign-in state -- stateful and slower; skip when offline.
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
