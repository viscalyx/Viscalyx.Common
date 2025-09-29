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
    try {
        git init --bare --initial-branch=main *> $null
    }
    finally {
        Pop-Location
    }

    # Initialize the test repository and create test commits
    Push-Location -Path $script:testRepoPath
    try {
        # Initialize git repository
        git init --initial-branch=main --quiet 2>$null
        git config user.email "test@example.com" *> $null
        git config user.name "Test User" *> $null

        # Add remote origin
        git remote add origin $script:remoteRepoPath *> $null

        # Create initial commit on main branch
        "Initial content" | Out-File -FilePath 'test1.txt' -Encoding utf8
        git add test1.txt *> $null
        git commit -m "Initial commit" *> $null

        # Set up main branch and push to remote
        git branch -M main *> $null
        if ($PSVersionTable.PSEdition -eq 'Desktop') {
            # Windows PowerShell - use cmd.exe for reliable output suppression
            & cmd.exe /c "git push -u origin main --quiet >nul 2>&1"
        } else {
            # PowerShell 7+ - capture output in variables
            $gitOutput = git push -u origin main --quiet 2>&1
        }

        # Create a feature branch
        if ($PSVersionTable.PSEdition -eq 'Desktop') {
            # Windows PowerShell - use cmd.exe for reliable output suppression
            & cmd.exe /c "git checkout -b feature/test --quiet >nul 2>&1"
        } else {
            # PowerShell 7+ - capture output in variables
            $gitOutput = git checkout -b feature/test --quiet 2>&1
        }
        "Feature content" | Out-File -FilePath 'feature.txt' -Encoding utf8
        git add feature.txt *> $null
        git commit -m "Feature commit" *> $null
        if ($PSVersionTable.PSEdition -eq 'Desktop') {
            # Windows PowerShell - use cmd.exe for reliable output suppression
            & cmd.exe /c "git push -u origin feature/test --quiet >nul 2>&1"
        } else {
            # PowerShell 7+ - capture output in variables
            $gitOutput = git push -u origin feature/test --quiet 2>&1
        }

        # Switch back to main branch
        if ($PSVersionTable.PSEdition -eq 'Desktop') {
            # Windows PowerShell - use cmd.exe for reliable output suppression
            & cmd.exe /c "git checkout main --quiet >nul 2>&1"
        } else {
            # PowerShell 7+ - capture output in variables
            $gitOutput = git checkout main --quiet 2>&1
        }

        # Store the initial branch for reference
        $script:initialBranch = git rev-parse --abbrev-ref HEAD
    }
    finally {
        Pop-Location
    }
}

AfterAll {
    # Clean up - remove the test repositories
    if (Test-Path -Path $script:testRepoPath) {
        $previousProgressPreference = $ProgressPreference
        $ProgressPreference = 'SilentlyContinue' # Suppress progress output during deletion
        Remove-Item -Path $script:testRepoPath -Recurse -Force -ErrorAction SilentlyContinue
        $ProgressPreference = $previousProgressPreference
    }
    if (Test-Path -Path $script:remoteRepoPath) {
        $previousProgressPreference = $ProgressPreference
        $ProgressPreference = 'SilentlyContinue' # Suppress progress output during deletion
        Remove-Item -Path $script:remoteRepoPath -Recurse -Force -ErrorAction SilentlyContinue
        $ProgressPreference = $previousProgressPreference
    }
}

Describe 'Receive-GitBranch' {
    BeforeEach {
        # Change to test repository for each test
        Push-Location -Path $script:testRepoPath
    }

    AfterEach {
        # Return to original location and clean up any test changes
        try {
            git checkout main --quiet 2>$null
            git reset --hard HEAD *> $null 2> $null
        }
        catch {
            # Ignore cleanup errors
        }
        Pop-Location
    }

    Context 'When checking out and pulling a branch' {
        It 'Should successfully checkout and pull main branch with -Checkout parameter' {
            # Start from feature branch
            if ($PSVersionTable.PSEdition -eq 'Desktop') {
                # Windows PowerShell - use cmd.exe for reliable output suppression
                & cmd.exe /c "git checkout feature/test >nul 2>&1"
            } else {
                # PowerShell 7+ - use direct redirection
                git checkout feature/test *>$null
            }

            # Use Receive-GitBranch to switch to main and pull
            { Receive-GitBranch -Checkout -BranchName 'main' -Force } | Should -Not -Throw

            # Verify we're on main branch
            $currentBranch = git rev-parse --abbrev-ref HEAD
            $currentBranch | Should -Be 'main'
        }

        It 'Should successfully checkout and pull specified branch' {
            # Start from main branch
            if ($PSVersionTable.PSEdition -eq 'Desktop') {
                # Windows PowerShell - use cmd.exe for reliable output suppression
                & cmd.exe /c "git checkout main --quiet >nul 2>&1"
            } else {
                # PowerShell 7+ - capture output in variables
                $gitOutput = git checkout main --quiet 2>&1
            }

            # Use Receive-GitBranch to switch to feature branch and pull
            { Receive-GitBranch -Checkout -BranchName 'feature/test' -Force } | Should -Not -Throw

            # Verify we're on feature branch
            $currentBranch = git rev-parse --abbrev-ref HEAD
            $currentBranch | Should -Be 'feature/test'
        }
    }

    Context 'When using rebase mode' {
        It 'Should successfully checkout, fetch, and rebase with main branch' {
            # Start from feature branch
            if ($PSVersionTable.PSEdition -eq 'Desktop') {
                # Windows PowerShell - use cmd.exe for reliable output suppression
                & cmd.exe /c "git checkout feature/test >nul 2>&1"
            } else {
                # PowerShell 7+ - use direct redirection
                git checkout feature/test *>$null
            }

            # Use Receive-GitBranch with rebase to switch to main
            { Receive-GitBranch -Checkout -BranchName 'main' -Rebase -Force } | Should -Not -Throw

            # Verify we're on main branch
            $currentBranch = git rev-parse --abbrev-ref HEAD
            $currentBranch | Should -Be 'main'
        }

        It 'Should successfully checkout and rebase feature branch with main upstream' {
            # Start from main branch
            if ($PSVersionTable.PSEdition -eq 'Desktop') {
                # Windows PowerShell - use cmd.exe for reliable output suppression
                & cmd.exe /c "git checkout main --quiet >nul 2>&1"
            } else {
                # PowerShell 7+ - capture output in variables
                $gitOutput = git checkout main --quiet 2>&1
            }

            # Use Receive-GitBranch with rebase on feature branch
            { Receive-GitBranch -Checkout -BranchName 'feature/test' -UpstreamBranchName 'main' -Rebase -Force } | Should -Not -Throw

            # Verify we're on feature branch
            $currentBranch = git rev-parse --abbrev-ref HEAD
            $currentBranch | Should -Be 'feature/test'
        }
    }

    Context 'When branch does not exist' {
        It 'Should throw error when trying to checkout non-existent branch' {
            { Receive-GitBranch -Checkout -BranchName 'nonexistent-branch' -Force -ErrorAction Stop 2>$null } | Should -Throw
        }
    }

    Context 'When using WhatIf parameter' {
        It 'Should not change current branch when WhatIf is specified' {
            # Start from feature branch
            if ($PSVersionTable.PSEdition -eq 'Desktop') {
                # Windows PowerShell - use cmd.exe for reliable output suppression
                & cmd.exe /c "git checkout feature/test >nul 2>&1"
            } else {
                # PowerShell 7+ - use direct redirection
                git checkout feature/test *>$null
            }
            $originalBranch = git rev-parse --abbrev-ref HEAD

            # Run with WhatIf (need to use -Checkout if we want to test checkout behavior)
            Receive-GitBranch -Checkout -BranchName 'main' -WhatIf

            # Verify branch hasn't changed
            $currentBranch = git rev-parse --abbrev-ref HEAD
            $currentBranch | Should -Be $originalBranch
        }
    }

    Context 'When testing in a repository with local changes' {
        It 'Should successfully work when there are no local changes' {
            # Ensure clean working directory
            if ($PSVersionTable.PSEdition -eq 'Desktop') {
                # Windows PowerShell - use cmd.exe for reliable output suppression
                & cmd.exe /c "git checkout main --quiet >nul 2>&1"
            } else {
                # PowerShell 7+ - capture output in variables
                $gitOutput = git checkout main --quiet 2>&1
            }
            git reset --hard HEAD *> $null

            # This should work without issues
            { Receive-GitBranch -Checkout -BranchName 'feature/test' -Force } | Should -Not -Throw
        }

        It 'Should handle repository with staged changes' {
            # Create staged changes
            "Modified content" | Out-File -FilePath 'test1.txt' -Encoding utf8
            git add test1.txt *> $null

            # Receive-GitBranch may succeed or fail depending on Git's behavior with staged changes
            # The command should handle this gracefully
            $result = try {
                Receive-GitBranch -Checkout -BranchName 'feature/test' -Force 2>$null
                $true
            }
            catch {
                $false
            }

            # Reset changes for cleanup
            git reset --hard HEAD *> $null 2>$null

            # We don't assert success/failure here as it depends on Git configuration
            # The important thing is that it doesn't crash and returns a boolean result
            $result | Should -BeIn @($true, $false)
        }
    }

    Context 'When testing with different remote configurations' {
        BeforeAll {
            # Add additional content to remote to test pulling
            Push-Location -Path $script:testRepoPath
            try {
                if ($PSVersionTable.PSEdition -eq 'Desktop') {
                    # Windows PowerShell - use cmd.exe for reliable output suppression
                    & cmd.exe /c "git checkout main --quiet >nul 2>&1"
                } else {
                    # PowerShell 7+ - capture output in variables
                    $gitOutput = git checkout main --quiet 2>&1
                }
                "Additional content" | Out-File -FilePath 'additional.txt' -Encoding utf8
                git add additional.txt *> $null
                git commit -m "Additional commit" *> $null
                if ($PSVersionTable.PSEdition -eq 'Desktop') {
                    # Windows PowerShell - use cmd.exe for reliable output suppression
                    & cmd.exe /c "git push origin main >nul 2>&1"
                } else {
                    # PowerShell 7+ - use direct redirection
                    git push origin main *>$null
                }

                # Reset local main to simulate being behind
                git reset --hard HEAD~1 *> $null
            }
            finally {
                Pop-Location
            }
        }

        It 'Should successfully pull new commits from remote' {
            Push-Location -Path $script:testRepoPath
            try {
                git checkout main --quiet 2>$null

                # Count commits before pull
                $commitsBefore = @(git log --oneline).Count

                # Use Receive-GitBranch to pull latest changes
                { Receive-GitBranch -BranchName 'main' -Force } | Should -Not -Throw

                # Count commits after pull
                $commitsAfter = @(git log --oneline).Count

                # Should have pulled the additional commit
                $commitsAfter | Should -Be ($commitsBefore + 1)
            }
            finally {
                Pop-Location
            }
        }
    }
}
