@{
    # =====================================================================================
    #  Demo environment inventory -- the single source of truth for "what the demos touch".
    #
    #  Read by BOTH:
    #    - demo/Reset-DemoEnvironment.ps1   (acts on it: deletes, restores, removes)
    #    - tests/DemoEnvironment.Tests.ps1  (asserts on it: everything below is back to base)
    #
    #  Keep the two in step by keeping this file the only list. When a demo starts touching
    #  a new branch or file, add it HERE, not in the reset or the tests.
    #
    #  NOTE: .github/scripts/check-demo-paths.py has its own EXPECTED_ABSENT list for CI path
    #  checking (it is Python and cannot read this file). If you add a CreatedFile here, add
    #  it there too -- they serve different jobs but describe the same demo residue.
    # =====================================================================================

    # Local branches the live demo scripts CREATE and then -D in their own RESET regions.
    # A leftover here is what makes `git switch -c demo/source-control` fail on a re-run.
    #   demo/source-control          -> demo/01-source-control.ps1  region 02
    #   demo/merge-rob, merge-jess   -> demo/01b-merge-conflict.ps1 regions 02/04
    #   demo/wrapup-change           -> demo/05-wrap-up.ps1         region 02
    DemoRunBranches = @(
        'demo/source-control'
        'demo/merge-rob'
        'demo/merge-jess'
        'demo/wrapup-change'
    )

    # Of those, the ones a demo also PUSHES to origin (so a stale remote can linger too).
    # demo/merge-jess is never pushed; the wrap-up branch is usually removed by --delete-branch
    # on merge, but a failed run leaves it behind.
    RemoteDemoRunBranches = @(
        'demo/source-control'
        'demo/merge-rob'
        'demo/wrapup-change'
    )

    # Tracked files a demo OVERWRITES in place (Copy-Item -Force / an on-stage edit).
    # A ready environment has these identical to HEAD; reset restores them.
    #   Player.sql / Seed.sql / .sqlproj -> demo/03-database.ps1 increments 2 and 3
    #   variables.tf                     -> demo/05-wrap-up.ps1   region 03 (the 60->75 edit)
    MutatedTrackedFiles = @(
        'database/sql-projects/Tables/Player.sql'
        'database/sql-projects/Scripts/PostDeployment/Seed.sql'
        'database/sql-projects/FabConFootball.sqlproj'
        'infra/azure-sql/terraform/demo/variables.tf'
    )

    # Untracked files a demo CREATES. A ready environment does not have these; reset removes
    # them. (Build output under bin/ and obj/ is gitignored and harmless -- not listed.)
    CreatedFiles = @(
        'notes/fabcon.md'                                                    # 01 region 03
        'notes/team-notes.md'                                                # 01b regions 02/04
        'infra/azure-sql/terraform/demo/terraform.tfvars'                    # 02 region 03
        'infra/azure-sql/terraform/demo/backend_local_override.tf'           # 02 region 06
        'infra/fabric-sql/terraform/terraform.tfvars'                        # 02 region 14
        'infra/fabric-sql/terraform/backend_local_override.tf'               # 02 region 16
        'database/sql-projects/Views/vw_SquadAges.sql'                       # 03 increment 1
        'database/sql-projects/Views/vw_TeamRosterSizes.sql'                 # 03 increment 2
        'database/sql-projects/Views/vw_Standings.sql'                       # 05 regions 04/08
        'database/sql-projects/Scripts/PreDeployment/Migrate-ShirtNumber.sql' # 03 increment 3A
        'database/sql-projects/FabConFootball.refactorlog'                   # 03 increment 3B
        'database/sql-projects/deploy-report.xml'                            # 03 (gitignored)
        'database/sql-projects/deploy-report-increment-0.xml'                # 03 (gitignored)
    )

    # Directories a demo creates that should be gone (or empty) when reset. Empty dirs do not
    # show in `git status`, so this is cosmetic tidiness rather than a correctness check.
    CreatedDirectories = @(
        'database/sql-projects/Scripts/PreDeployment'                        # 03 region 19
    )

    # Content that must hold on a base checkout even though `git status` looks clean -- the
    # classic trap is a demo committing 75 to main (commit 33cf375) so the wrap-up plan reads
    # "0 to change". File path is relative to repo root.
    #   Pattern / Expect are regular expressions (Expect is whitespace-tolerant on purpose).
    ContentAssertions = @(
        @{
            Path        = 'infra/azure-sql/terraform/demo/variables.tf'
            Pattern     = 'database_auto_pause_delay'
            Expect      = 'default\s*=\s*60\b'
            Description = 'Azure SQL auto-pause default is 60 (not a leftover 75 from demo 05)'
        }
    )

    # Command-line tools every presenter machine needs before the demos run.
    RequiredCommands = @(
        @{ Name = 'git';        Demo = 'all' }
        @{ Name = 'gh';         Demo = '01, 04, 05' }
        @{ Name = 'az';         Demo = '02, 03, 05' }
        @{ Name = 'terraform';  Demo = '02' }
        @{ Name = 'dotnet';     Demo = '03' }
        @{ Name = 'sqlpackage'; Demo = '03' }
        @{ Name = 'code';       Demo = 'all (opens files on screen)' }
        @{ Name = 'pwsh';       Demo = 'all (the scripts are PowerShell)' }
    )

    # PowerShell modules the demos import.
    RequiredModules = @(
        @{ Name = 'dbatools'; Demo = '03, 05 (Invoke-DbaQuery)' }
    )

    # global.json pins the .NET SDK; demo 03 builds under it.
    DotnetMajorVersion = 8
}
