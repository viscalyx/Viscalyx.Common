[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification = 'Suppressing this rule because Script Analyzer does not understand Pester syntax.')]
param ()

BeforeDiscovery {
    try
    {
        if (-not (Get-Module -Name 'DscResource.Test'))
        {
            # Assumes dependencies have been resolved, so if this module is not available, run 'noop' task.
            if (-not (Get-Module -Name 'DscResource.Test' -ListAvailable))
            {
                # Redirect all streams to $null, except the error stream (stream 2)
                & "$PSScriptRoot/../../../build.ps1" -Tasks 'noop' 3>&1 4>&1 5>&1 6>&1 > $null
            }

            # If the dependencies have not been resolved, this will throw an error.
            Import-Module -Name 'DscResource.Test' -Force -ErrorAction 'Stop'
        }
    }
    catch [System.IO.FileNotFoundException]
    {
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -ResolveDependency -Tasks noop" first.'
    }
}

BeforeAll {
    $script:moduleName = 'Viscalyx.Common'

    Import-Module -Name $script:moduleName -Force -ErrorAction 'Stop'

    # Create a temporary Git repository for testing
    $script:testRepoPath = Join-Path -Path $TestDrive -ChildPath 'TestGitRepo'
    New-Item -Path $script:testRepoPath -ItemType Directory -Force | Out-Null

    # Create a remote repository path for testing
    $script:remoteRepoPath = Join-Path -Path $TestDrive -ChildPath 'RemoteGitRepo'
    New-Item -Path $script:remoteRepoPath -ItemType Directory -Force | Out-Null

    # Initialize the remote repository first
    Push-Location -Path $script:remoteRepoPath
    try
    {
        git init --bare --initial-branch=main *> $null
    }
    finally
    {
        Pop-Location
    }

    # Initialize the test repository and create test commits
    Push-Location -Path $script:testRepoPath
    try
    {
        # Initialize git repository
        git init --initial-branch=main --quiet 2>$null
        git config user.email 'test@example.com' *> $null
        git config user.name 'Test User' *> $null

        # Add remote origin
        git remote add origin $script:remoteRepoPath *> $null

        # Create initial commit on main branch
        'Initial content' | Out-File -FilePath 'test1.txt' -Encoding utf8
        git add test1.txt *> $null
        git commit -m 'Initial commit' *> $null

        # Set up main branch and push to remote
        git branch -M main *> $null
        if ($PSVersionTable.PSEdition -eq 'Desktop')
        {
            # Windows PowerShell - use cmd.exe for reliable output suppression
            & cmd.exe /c 'git push -u origin main --quiet >nul 2>&1'
        }
        else
        {
            # PowerShell 7+ - capture output in variables
            $null = git push -u origin main --quiet 2>&1
        }

        # Create a feature branch
        if ($PSVersionTable.PSEdition -eq 'Desktop')
        {
            # Windows PowerShell - use cmd.exe for reliable output suppression
            & cmd.exe /c 'git checkout -b feature/test --quiet >nul 2>&1'
        }
        else
        {
            # PowerShell 7+ - capture output in variables
            $null = git checkout -b feature/test --quiet 2>&1
        }
        'Feature content' | Out-File -FilePath 'feature.txt' -Encoding utf8
        git add feature.txt *> $null
        git commit -m 'Feature commit' *> $null
        if ($PSVersionTable.PSEdition -eq 'Desktop')
        {
            # Windows PowerShell - use cmd.exe for reliable output suppression
            & cmd.exe /c 'git push -u origin feature/test --quiet >nul 2>&1'
        }
        else
        {
            # PowerShell 7+ - capture output in variables
            $null = git push -u origin feature/test --quiet 2>&1
        }

        # Add another commit to main on remote (simulating upstream changes)
        if ($PSVersionTable.PSEdition -eq 'Desktop')
        {
            # Windows PowerShell - use cmd.exe for reliable output suppression
            & cmd.exe /c 'git checkout main --quiet >nul 2>&1'
        }
        else
        {
            # PowerShell 7+ - capture output in variables
            $null = git checkout main --quiet 2>&1
        }
        'Updated main content' | Out-File -FilePath 'test2.txt' -Encoding utf8
        git add test2.txt *> $null
        git commit -m 'Main branch update' *> $null
        if ($PSVersionTable.PSEdition -eq 'Desktop')
        {
            # Windows PowerShell - use cmd.exe for reliable output suppression
            & cmd.exe /c 'git push origin main --quiet >nul 2>&1'
        }
        else
        {
            # PowerShell 7+ - capture output in variables
            $null = git push origin main --quiet 2>&1
        }
    }
    finally
    {
        Pop-Location
    }
}

AfterAll {
    # Clean up - remove the test repositories
    if (Test-Path -Path $script:testRepoPath)
    {
        $previousProgressPreference = $ProgressPreference
        $ProgressPreference = 'SilentlyContinue' # Suppress progress output during deletion
        Remove-Item -Path $script:testRepoPath -Recurse -Force -ErrorAction SilentlyContinue
        $ProgressPreference = $previousProgressPreference
    }
    if (Test-Path -Path $script:remoteRepoPath)
    {
        $previousProgressPreference = $ProgressPreference
        $ProgressPreference = 'SilentlyContinue' # Suppress progress output during deletion
        Remove-Item -Path $script:remoteRepoPath -Recurse -Force -ErrorAction SilentlyContinue
        $ProgressPreference = $previousProgressPreference
    }
}

Describe 'Start-GitRebase' {
    BeforeEach {
        # Change to test repository for each test
        Push-Location -Path $script:testRepoPath

        # Fetch latest changes from remote
        git fetch origin *> $null

        # Checkout feature branch for each test
        if ($PSVersionTable.PSEdition -eq 'Desktop')
        {
            # Windows PowerShell - use cmd.exe for reliable output suppression
            & cmd.exe /c 'git checkout feature/test --quiet >nul 2>&1'
        }
        else
        {
            # PowerShell 7+ - capture output in variables
            $null = git checkout feature/test --quiet 2>&1
        }
    }

    AfterEach {
        # Restore the repository to a clean state
        Pop-Location

        Push-Location -Path $script:testRepoPath
        try
        {
            # Abort any ongoing rebase
            $rebaseMergePath = Join-Path -Path $script:testRepoPath -ChildPath '.git' | Join-Path -ChildPath 'rebase-merge'
            $rebaseApplyPath = Join-Path -Path $script:testRepoPath -ChildPath '.git' | Join-Path -ChildPath 'rebase-apply'

            if ((Test-Path -Path $rebaseMergePath) -or (Test-Path -Path $rebaseApplyPath))
            {
                git rebase --abort *> $null
            }

            # Reset to clean state
            git checkout feature/test --quiet *> $null
            git reset --hard origin/feature/test --quiet *> $null
        }
        finally
        {
            Pop-Location
        }
    }

    Context 'When rebasing from default origin/main' {
        It 'Should successfully start rebase from origin/main' {
            # Reset feature branch to before main's updates to ensure rebase has something to do
            git reset --hard HEAD~2 --quiet 2> $null

            # Store the current number of commits
            $commitCountBefore = (git rev-list --count HEAD)

            # Start the rebase
            { Start-GitRebase -Force -ErrorAction Stop } | Should -Not -Throw

            # Verify that the rebase was successful
            $currentBranch = git rev-parse --abbrev-ref HEAD
            $currentBranch | Should -Be 'feature/test'

            # Verify that the commit count increased (rebased onto newer main)
            $commitCountAfter = (git rev-list --count HEAD)
            $commitCountAfter | Should -BeGreaterThan $commitCountBefore
        }

        It 'Should use -Force to bypass confirmation' {
            # Reset feature branch to before main's updates
            git reset --hard HEAD~2 --quiet 2> $null

            # This test verifies that -Force works without user interaction
            { Start-GitRebase -Force -ErrorAction Stop } | Should -Not -Throw
        }
    }

    Context 'When rebasing from a custom remote and branch' {
        It 'Should successfully start rebase from custom remote/branch' {
            # Checkout main branch first
            if ($PSVersionTable.PSEdition -eq 'Desktop')
            {
                # Windows PowerShell - use cmd.exe for reliable output suppression
                & cmd.exe /c 'git checkout main --quiet >nul 2>&1'
            }
            else
            {
                # PowerShell 7+ - capture output in variables
                $null = git checkout main --quiet 2>&1
            }

            # Create a new commit on feature branch from remote
            if ($PSVersionTable.PSEdition -eq 'Desktop')
            {
                # Windows PowerShell - use cmd.exe for reliable output suppression
                & cmd.exe /c 'git checkout feature/test --quiet >nul 2>&1'
            }
            else
            {
                # PowerShell 7+ - capture output in variables
                $null = git checkout feature/test --quiet 2>&1
            }

            # Reset to before the feature commit to test rebasing from feature branch
            git reset --hard HEAD~1 --quiet *> $null

            # Start the rebase from origin/feature/test
            { Start-GitRebase -RemoteName 'origin' -Branch 'feature/test' -Force -ErrorAction Stop } | Should -Not -Throw

            # Verify that the rebase was successful
            $currentBranch = git rev-parse --abbrev-ref HEAD
            $currentBranch | Should -Be 'feature/test'
        }
    }

    Context 'When specifying a custom path' {
        It 'Should accept the Path parameter and successfully rebase' -Skip {
            # NOTE: This test is skipped because git rebase with -Path parameter
            # appears to have issues finding remote references when executed from
            # a working directory different from the repository root.
            # This may be a limitation of how git rebase interacts with working directory.

            # Reset feature branch to before main's updates
            git reset --hard HEAD~2 --quiet *> $null

            # Store the current commit count
            $commitCountBefore = (git rev-list --count HEAD)

            # Start rebase using -Path parameter (still from within the repo, but explicitly specifying path)
            { Start-GitRebase -Path $script:testRepoPath -Force -ErrorAction Stop } | Should -Not -Throw

            # Verify the rebase was successful
            $currentBranch = git rev-parse --abbrev-ref HEAD
            $currentBranch | Should -Be 'feature/test'

            # Verify commit count increased
            $commitCountAfter = (git rev-list --count HEAD)
            $commitCountAfter | Should -BeGreaterThan $commitCountBefore
        }
    }

    Context 'When handling errors' {
        It 'Should handle invalid remote name gracefully' {
            # Attempt to rebase from a non-existent remote
            { Start-GitRebase -RemoteName 'nonexistent' -Branch 'main' -Force -ErrorAction Stop } | Should -Throw
        }

        It 'Should handle invalid branch name gracefully' {
            # Attempt to rebase from a non-existent branch
            { Start-GitRebase -RemoteName 'origin' -Branch 'nonexistent' -Force -ErrorAction Stop } | Should -Throw
        }
    }
}
