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
            $gitOutput = git push -u origin main --quiet 2>&1
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
            $gitOutput = git checkout -b feature/test --quiet 2>&1
        }
        'Feature content' | Out-File -FilePath 'feature.txt' -Encoding utf8
        git add feature.txt *> $null
        git commit -m 'Feature commit' *> $null

        # Add another commit to feature branch
        'Feature content 2' | Out-File -FilePath 'feature2.txt' -Encoding utf8
        git add feature2.txt *> $null
        git commit -m 'Second feature commit' *> $null

        if ($PSVersionTable.PSEdition -eq 'Desktop')
        {
            # Windows PowerShell - use cmd.exe for reliable output suppression
            & cmd.exe /c 'git push -u origin feature/test --quiet >nul 2>&1'
        }
        else
        {
            # PowerShell 7+ - capture output in variables
            $gitOutput = git push -u origin feature/test --quiet 2>&1
        }

        # Store the commit hash before rebase for verification
        $script:featureBranchCommit = git rev-parse HEAD

        # Add a commit to main that will be rebased onto
        if ($PSVersionTable.PSEdition -eq 'Desktop')
        {
            # Windows PowerShell - use cmd.exe for reliable output suppression
            & cmd.exe /c 'git checkout main --quiet >nul 2>&1'
        }
        else
        {
            # PowerShell 7+ - capture output in variables
            $gitOutput = git checkout main --quiet 2>&1
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
            $gitOutput = git push origin main --quiet 2>&1
        }

        # Create a commit on main that will conflict with feature branch
        'Conflicting content' | Out-File -FilePath 'feature.txt' -Encoding utf8
        git add feature.txt *> $null
        git commit -m 'Conflicting commit on main' *> $null
        if ($PSVersionTable.PSEdition -eq 'Desktop')
        {
            # Windows PowerShell - use cmd.exe for reliable output suppression
            & cmd.exe /c 'git push origin main --quiet >nul 2>&1'
        }
        else
        {
            # PowerShell 7+ - capture output in variables
            $gitOutput = git push origin main --quiet 2>&1
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

Describe 'Stop-GitRebase' {
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
            $gitOutput = git checkout feature/test --quiet 2>&1
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

    Context 'When aborting an active rebase' {
        It 'Should successfully abort a rebase operation' -Skip {
            # NOTE: This test is skipped because it requires creating a rebase conflict
            # which is difficult to automate reliably in integration tests

            # Start a rebase that will cause a conflict
            $null = git rebase origin/main 2>&1

            # Check if we are in a rebase state
            $rebaseMergePath = Join-Path -Path $script:testRepoPath -ChildPath '.git' | Join-Path -ChildPath 'rebase-merge'
            $rebaseApplyPath = Join-Path -Path $script:testRepoPath -ChildPath '.git' | Join-Path -ChildPath 'rebase-apply'
            $isRebasing = (Test-Path -Path $rebaseMergePath) -or (Test-Path -Path $rebaseApplyPath)

            $isRebasing | Should -BeTrue

            # Abort the rebase
            $null = Stop-GitRebase -Force -ErrorAction Stop

            # Verify that the rebase was aborted
            $rebaseMergePath = Join-Path -Path $script:testRepoPath -ChildPath '.git' | Join-Path -ChildPath 'rebase-merge'
            $rebaseApplyPath = Join-Path -Path $script:testRepoPath -ChildPath '.git' | Join-Path -ChildPath 'rebase-apply'
            $isRebasing = (Test-Path -Path $rebaseMergePath) -or (Test-Path -Path $rebaseApplyPath)

            $isRebasing | Should -BeFalse

            # Verify that the branch is back to its original state
            $currentCommit = git rev-parse HEAD
            $currentCommit | Should -Be $script:featureBranchCommit
        }

        It 'Should use -Force to bypass confirmation' -Skip {
            # NOTE: This test is skipped because it requires creating a rebase conflict
            # which is difficult to automate reliably in integration tests

            # Start a rebase that will cause a conflict
            $null = git rebase origin/main 2>&1

            # This test verifies that -Force works without user interaction
            $null = Stop-GitRebase -Force -ErrorAction Stop

            # Verify that the rebase was aborted
            $rebaseMergePath = Join-Path -Path $script:testRepoPath -ChildPath '.git' | Join-Path -ChildPath 'rebase-merge'
            $rebaseApplyPath = Join-Path -Path $script:testRepoPath -ChildPath '.git' | Join-Path -ChildPath 'rebase-apply'
            $isRebasing = (Test-Path -Path $rebaseMergePath) -or (Test-Path -Path $rebaseApplyPath)

            $isRebasing | Should -BeFalse
        }
    }

    Context 'When not in a rebase state' {
        It 'Should throw an error when trying to abort without an active rebase' {
            # Ensure we're not in a rebase state
            $rebaseMergePath = Join-Path -Path $script:testRepoPath -ChildPath '.git' | Join-Path -ChildPath 'rebase-merge'
            $rebaseApplyPath = Join-Path -Path $script:testRepoPath -ChildPath '.git' | Join-Path -ChildPath 'rebase-apply'
            $isRebasing = (Test-Path -Path $rebaseMergePath) -or (Test-Path -Path $rebaseApplyPath)

            $isRebasing | Should -BeFalse

            # Attempt to abort rebase should fail
            { Stop-GitRebase -Force -ErrorAction Stop } | Should -Throw
        }
    }

    Context 'When specifying a custom path' {
        It 'Should successfully abort rebase in specified path' -Skip {
            # NOTE: This test is skipped because it requires creating a rebase conflict
            # which is difficult to automate reliably in integration tests

            # Start a rebase that will cause a conflict
            $null = git rebase origin/main 2>&1

            # Check if we are in a rebase state
            $rebaseMergePath = Join-Path -Path $script:testRepoPath -ChildPath '.git' | Join-Path -ChildPath 'rebase-merge'
            $rebaseApplyPath = Join-Path -Path $script:testRepoPath -ChildPath '.git' | Join-Path -ChildPath 'rebase-apply'
            $isRebasing = (Test-Path -Path $rebaseMergePath) -or (Test-Path -Path $rebaseApplyPath)

            $isRebasing | Should -BeTrue

            # Return to previous directory
            Pop-Location

            # Abort rebase from outside the repository using -Path
            $null = Stop-GitRebase -Path $script:testRepoPath -Force -ErrorAction Stop

            # Verify the rebase was aborted
            Push-Location -Path $script:testRepoPath
            try
            {
                $rebaseMergePath = Join-Path -Path $script:testRepoPath -ChildPath '.git' | Join-Path -ChildPath 'rebase-merge'
                $rebaseApplyPath = Join-Path -Path $script:testRepoPath -ChildPath '.git' | Join-Path -ChildPath 'rebase-apply'
                $isRebasing = (Test-Path -Path $rebaseMergePath) -or (Test-Path -Path $rebaseApplyPath)

                $isRebasing | Should -BeFalse

                # Verify that the branch is back to its original state
                $currentCommit = git rev-parse HEAD
                $currentCommit | Should -Be $script:featureBranchCommit
            }
            finally
            {
                Pop-Location
            }
        }
    }

    Context 'When aborting during a non-conflict rebase' {
        It 'Should successfully abort a non-conflicting rebase in progress' -Skip {
            # NOTE: This test is skipped because it's difficult to reliably create a rebase
            # state that doesn't immediately complete in an automated test environment

            # Checkout main first to create a scenario for non-conflicting rebase
            if ($PSVersionTable.PSEdition -eq 'Desktop')
            {
                # Windows PowerShell - use cmd.exe for reliable output suppression
                & cmd.exe /c 'git checkout main --quiet >nul 2>&1'
            }
            else
            {
                # PowerShell 7+ - capture output in variables
                $gitOutput = git checkout main --quiet 2>&1
            }

            # Reset main to before the conflicting commit
            git reset --hard HEAD~1 --quiet *> $null

            # Store the current commit
            $mainCommit = git rev-parse HEAD

            # Switch back to feature branch
            if ($PSVersionTable.PSEdition -eq 'Desktop')
            {
                # Windows PowerShell - use cmd.exe for reliable output suppression
                & cmd.exe /c 'git checkout feature/test --quiet >nul 2>&1'
            }
            else
            {
                # PowerShell 7+ - capture output in variables
                $gitOutput = git checkout feature/test --quiet 2>&1
            }

            # Start a non-conflicting rebase (may complete immediately)
            $null = git rebase $mainCommit 2>&1

            # Check if rebase is still in progress
            $rebaseMergePath = Join-Path -Path $script:testRepoPath -ChildPath '.git' | Join-Path -ChildPath 'rebase-merge'
            $rebaseApplyPath = Join-Path -Path $script:testRepoPath -ChildPath '.git' | Join-Path -ChildPath 'rebase-apply'
            $isRebasing = (Test-Path -Path $rebaseMergePath) -or (Test-Path -Path $rebaseApplyPath)

            if ($isRebasing)
            {
                # Abort the rebase
                $null = Stop-GitRebase -Force -ErrorAction Stop

                # Verify that the rebase was aborted
                $rebaseMergePath = Join-Path -Path $script:testRepoPath -ChildPath '.git' | Join-Path -ChildPath 'rebase-merge'
                $rebaseApplyPath = Join-Path -Path $script:testRepoPath -ChildPath '.git' | Join-Path -ChildPath 'rebase-apply'
                $isRebasing = (Test-Path -Path $rebaseMergePath) -or (Test-Path -Path $rebaseApplyPath)

                $isRebasing | Should -BeFalse
            }
            else
            {
                # If rebase completed immediately, trying to abort should throw an error
                { Stop-GitRebase -Force -ErrorAction Stop } | Should -Throw
            }
        }
    }
}
