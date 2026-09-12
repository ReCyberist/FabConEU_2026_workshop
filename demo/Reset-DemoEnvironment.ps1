#Requires -Version 7.0
<#
.SYNOPSIS
    Put the repository back to a state where every demo can be run again from the top.

.DESCRIPTION
    The demos overwrite tracked files, create scratch files, and cut throwaway branches --
    then each script's own RESET region is meant to undo it. This is the belt-and-braces
    version: one command that undoes ALL of them at once, for when a run was abandoned
    half-way, a RESET was skipped, or you just want to be certain before walking on stage.

    It does exactly four things, and nothing else -- it never runs `git clean`, never
    force-pushes, and only ever touches the specific branches and files the demos own
    (listed in demo/DemoEnvironment.psd1):

      1. Deletes leftover LOCAL demo branches   (the reason `git switch -c demo/...` fails).
      2. Deletes leftover REMOTE demo branches   (skip with -SkipRemote).
      3. Restores tracked files the demos overwrite (Player.sql, Seed.sql, .sqlproj,
         variables.tf) to their committed state.
      4. Removes the scratch files the demos create (tfvars, deploy reports, demo notes...).

    After that it re-checks the environment and prints anything it could not fix itself
    (for the full read-only check, run tests/DemoEnvironment.Tests.ps1).

    Verify first: pass -WhatIf to see every action without doing any of it.

.PARAMETER SkipRemote
    Do not touch origin. Use offline, or when you do not want remote branches deleted.

.PARAMETER Force
    Skip the per-action confirmation prompts. -WhatIf still previews without doing anything.

.EXAMPLE
    ./demo/Reset-DemoEnvironment.ps1 -WhatIf
    Show what a reset would do, change nothing.

.EXAMPLE
    ./demo/Reset-DemoEnvironment.ps1
    Reset local + remote, prompting before the destructive steps.

.EXAMPLE
    ./demo/Reset-DemoEnvironment.ps1 -SkipRemote -Force
    Reset the local repo only, no prompts. The pre-demo-morning default.
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [switch] $SkipRemote,
    [switch] $Force
)

$ErrorActionPreference = 'Stop'

# -- Locate the repo root and the inventory, independent of the caller's directory ---------
$repoRoot = (git rev-parse --show-toplevel 2>$null)
if (-not $repoRoot) {
    throw 'Not inside a git repository. Run this from anywhere within the FabCon workshop repo.'
}
$repoRoot = $repoRoot.Trim()
$inventoryPath = Join-Path $PSScriptRoot 'DemoEnvironment.psd1'
if (-not (Test-Path $inventoryPath)) {
    throw "Cannot find the demo inventory at $inventoryPath."
}
$inv = Import-PowerShellDataFile -Path $inventoryPath

# -force on ShouldProcess: turn a High-impact confirm into a silent yes when asked.
if ($Force) { $ConfirmPreference = 'None' }

Push-Location $repoRoot
try {
    Write-Host "Resetting demo environment in $repoRoot" -ForegroundColor Cyan
    $currentBranch = (git rev-parse --abbrev-ref HEAD).Trim()

    # =====================================================================================
    # 1 · Get off any demo branch, back onto main
    # =====================================================================================
    if ($inv.DemoRunBranches -contains $currentBranch) {
        if ($PSCmdlet.ShouldProcess("branch '$currentBranch'", 'switch away to main before deleting')) {
            git switch main | Out-Null
            $currentBranch = 'main'
        }
    }

    # =====================================================================================
    # 2 · Delete leftover LOCAL demo branches (only the ones the demos create)
    # =====================================================================================
    Write-Host "`n[1/4] Local demo branches" -ForegroundColor Yellow
    $localBranches = (git for-each-ref --format='%(refname:short)' refs/heads) -split "`n"
    foreach ($branch in $inv.DemoRunBranches) {
        if ($localBranches -contains $branch) {
            if ($PSCmdlet.ShouldProcess("local branch '$branch'", 'git branch -D')) {
                git branch -D $branch | Out-Null
                Write-Host "  deleted  $branch" -ForegroundColor Green
            }
        }
        else {
            Write-Host "  absent   $branch" -ForegroundColor DarkGray
        }
    }

    # =====================================================================================
    # 3 · Delete leftover REMOTE demo branches
    # =====================================================================================
    Write-Host "`n[2/4] Remote demo branches" -ForegroundColor Yellow
    if ($SkipRemote) {
        Write-Host "  skipped (-SkipRemote)" -ForegroundColor DarkGray
    }
    else {
        # One network round-trip to learn what actually exists on origin, so we only try to
        # delete real branches and do not spew errors for absent ones.
        $remoteRefs = @()
        try {
            $remoteRefs = (git ls-remote --heads origin 2>$null) |
                ForEach-Object { ($_ -split '\s+')[-1] -replace '^refs/heads/', '' }
        }
        catch {
            Write-Warning "  could not reach origin; skipping remote cleanup. Re-run with network, or -SkipRemote."
        }
        foreach ($branch in $inv.RemoteDemoRunBranches) {
            if ($remoteRefs -contains $branch) {
                if ($PSCmdlet.ShouldProcess("origin/$branch", 'git push origin --delete')) {
                    git push origin --delete $branch 2>$null | Out-Null
                    Write-Host "  deleted  origin/$branch" -ForegroundColor Green
                }
            }
            else {
                Write-Host "  absent   origin/$branch" -ForegroundColor DarkGray
            }
        }
    }

    # =====================================================================================
    # 4 · Restore tracked files the demos overwrite (only these -- never a blanket restore)
    # =====================================================================================
    Write-Host "`n[3/4] Tracked files the demos overwrite" -ForegroundColor Yellow
    foreach ($file in $inv.MutatedTrackedFiles) {
        if (-not (Test-Path $file)) { continue }
        $dirty = (git status --porcelain -- $file)
        if ($dirty) {
            if ($PSCmdlet.ShouldProcess($file, 'git restore (discard demo changes)')) {
                git restore -- $file
                Write-Host "  restored $file" -ForegroundColor Green
            }
        }
        else {
            Write-Host "  clean    $file" -ForegroundColor DarkGray
        }
    }

    # =====================================================================================
    # 5 · Remove the scratch files the demos create
    # =====================================================================================
    Write-Host "`n[4/4] Scratch files the demos create" -ForegroundColor Yellow
    $leaked = @()
    foreach ($file in $inv.CreatedFiles) {
        if (-not (Test-Path $file)) {
            Write-Host "  absent   $file" -ForegroundColor DarkGray
            continue
        }
        # These are meant to be untracked scratch. If one is TRACKED, a demo commit leaked it
        # into a branch (it has happened -- see notes/fabcon.md). Deleting the file would just
        # stage a deletion; the real fix is at the git level, so flag it instead of removing.
        git ls-files --error-unmatch -- $file *> $null
        if ($LASTEXITCODE -eq 0) {
            $leaked += $file
            Write-Host "  TRACKED  $file  <- committed by a demo; not removing (see summary)" -ForegroundColor Red
            continue
        }
        if ($PSCmdlet.ShouldProcess($file, 'Remove-Item')) {
            Remove-Item $file -Force
            Write-Host "  removed  $file" -ForegroundColor Green
        }
    }
    # Tidy empty scratch directories (harmless if they persist -- git ignores empty dirs).
    foreach ($dir in $inv.CreatedDirectories) {
        if ((Test-Path $dir) -and -not (Get-ChildItem -Path $dir -Force)) {
            if ($PSCmdlet.ShouldProcess($dir, 'Remove empty directory')) {
                Remove-Item $dir -Force
            }
        }
    }

    # =====================================================================================
    # Post-check: report anything reset cannot fix by itself
    # =====================================================================================
    if (-not $WhatIfPreference) {
        Write-Host "`nPost-reset check" -ForegroundColor Cyan
        $problems = @()

        if ($currentBranch -ne 'main') {
            $problems += "Not on main (on '$currentBranch'). Switch to main before the demos."
        }
        $residual = git status --porcelain
        if ($residual) {
            $problems += "Working tree is not clean. `git status` shows changes outside the demo file list -- inspect them by hand."
        }
        foreach ($file in $leaked) {
            $problems += "$file is TRACKED but should be scratch -- a demo commit leaked it into this branch. Remove it with 'git rm --cached $file' and commit, or reset the branch to a clean main."
        }
        foreach ($assert in $inv.ContentAssertions) {
            $hit = Select-String -Path $assert.Path -Pattern $assert.Pattern -Context 0, 4 -ErrorAction SilentlyContinue
            $block = $hit | ForEach-Object { $_.Line; $_.Context.PostContext }
            $ok = ($block -join "`n") -match $assert.Expect
            if (-not $ok) {
                $problems += "$($assert.Description) -- NOT met in $($assert.Path). This is committed on your branch; fix it in a commit, reset cannot."
            }
        }

        if ($problems) {
            Write-Host "  Reset did what it could, but these need a human:" -ForegroundColor Red
            $problems | ForEach-Object { Write-Host "   - $_" -ForegroundColor Red }
            Write-Host "`n  Full read-only check: Invoke-Pester ./tests/DemoEnvironment.Tests.ps1 -Tag Repo" -ForegroundColor DarkGray
        }
        else {
            Write-Host "  Repository is ready to run the demos again." -ForegroundColor Green
        }
    }
}
finally {
    Pop-Location
}
