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

    # Initialize the test repository and create test commits
    Push-Location -Path $script:testRepoPath
    try {
        # Initialize git repository
        git init *> $null
        git config user.email "test@example.com" *> $null
        git config user.name "Test User" *> $null

        # Create initial commit
        "Initial content" | Out-File -FilePath 'test1.txt' -Encoding utf8
        git add test1.txt *> $null
        git commit -m "Initial commit" *> $null

        # Create more commits for testing
        "Second content" | Out-File -FilePath 'test2.txt' -Encoding utf8
        git add test2.txt *> $null
        git commit -m "Second commit" *> $null

        "Third content" | Out-File -FilePath 'test3.txt' -Encoding utf8
        git add test3.txt *> $null
        git commit -m "Third commit" *> $null

        "Fourth content" | Out-File -FilePath 'test4.txt' -Encoding utf8
        git add test4.txt *> $null
        git commit -m "Fourth commit" *> $null

        "Fifth content" | Out-File -FilePath 'test5.txt' -Encoding utf8
        git add test5.txt *> $null
        git commit -m "Fifth commit" *> $null

        # Create a feature branch for testing
        git checkout -b feature/test *> $null
        "Feature content" | Out-File -FilePath 'feature.txt' -Encoding utf8
        git add feature.txt *> $null
        git commit -m "Feature commit" *> $null

        # Switch back to main/master branch
        git checkout main *> $null 2> $null
        if ($LASTEXITCODE -ne 0) {
            git checkout master *> $null
        }

        # Store the current branch name for tests
        $script:currentBranch = git rev-parse --abbrev-ref HEAD
    }
    finally {
        Pop-Location
    }
}

AfterAll {
    # Clean up - remove the test repository
    if (Test-Path -Path $script:testRepoPath) {
        $previousProgressPreference = $ProgressPreference
        $ProgressPreference = 'SilentlyContinue' # Suppress progress output during deletion
        Remove-Item -Path $script:testRepoPath -Recurse -Force -ErrorAction SilentlyContinue
        $ProgressPreference = $previousProgressPreference
    }
}

Describe 'Get-GitBranchCommit Integration Tests' {
    BeforeEach {
        # Change to test repository for each test
        Push-Location -Path $script:testRepoPath
    }

    AfterEach {
        # Return to original location
        Pop-Location
    }

    Context 'When retrieving all commits from current branch' {
        It 'Should return all commit IDs from current branch' {
            $result = Get-GitBranchCommit -ErrorAction Stop

            $result | Should -Not -BeNullOrEmpty
            $result | Should -HaveCount 5  # We created 5 commits on main/master
            $result | ForEach-Object { $_ | Should -Match '^[a-f0-9]{40}$' }  # Should be valid SHA hashes
        }

        It 'Should return commits in chronological order (newest first)' {
            $result = Get-GitBranchCommit -ErrorAction Stop

            # Get the timestamps of the commits to verify order
            $timestamps = @()
            foreach ($commit in $result) {
                $timestamp = git log -1 --format="%ct" $commit
                $timestamps += [int]$timestamp
            }

            # Verify timestamps are in descending order (newest first)
            for ($i = 0; $i -lt ($timestamps.Count - 1); $i++) {
                $timestamps[$i] | Should -BeGreaterOrEqual $timestamps[$i + 1]
            }
        }
    }

    Context 'When retrieving commits from specific branch' {
        It 'Should return commits from the current branch when specified explicitly' {
            $result = Get-GitBranchCommit -BranchName $script:currentBranch -ErrorAction Stop

            $result | Should -Not -BeNullOrEmpty
            $result | Should -HaveCount 5
            $result | ForEach-Object { $_ | Should -Match '^[a-f0-9]{40}$' }
        }

        It 'Should return commits from feature branch' {
            $result = Get-GitBranchCommit -BranchName 'feature/test' -ErrorAction Stop

            $result | Should -Not -BeNullOrEmpty
            $result | Should -HaveCount 6  # 5 from main + 1 feature commit
            $result | ForEach-Object { $_ | Should -Match '^[a-f0-9]{40}$' }
        }

        It 'Should resolve dot (.) to current branch' {
            $resultDot = Get-GitBranchCommit -BranchName '.' -ErrorAction Stop
            $resultCurrent = Get-GitBranchCommit -ErrorAction Stop

            $resultDot | Should -Be $resultCurrent
        }
    }

    Context 'When using Latest parameter' {
        It 'Should return only the latest commit ID' {
            $result = Get-GitBranchCommit -Latest -ErrorAction Stop

            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [string]
            $result | Should -Match '^[a-f0-9]{40}$'

            # Verify it's actually the latest commit
            $headCommit = git rev-parse HEAD
            $result | Should -Be $headCommit
        }

        It 'Should return latest commit from specific branch' {
            $result = Get-GitBranchCommit -BranchName 'feature/test' -Latest -ErrorAction Stop

            $result | Should -Not -BeNullOrEmpty

            # If result is an array, take the first element for comparison
            if ($result -is [Array]) {
                $actualCommit = $result[0]
            } else {
                $actualCommit = $result
            }

            $actualCommit | Should -Match '^[a-f0-9]{40}$'

            # Verify it's the latest commit from the feature branch
            $featureHeadCommit = git rev-parse feature/test
            $actualCommit | Should -Be $featureHeadCommit
        }
    }

    Context 'When using Last parameter' {
        It 'Should return the last 3 commit IDs' {
            $result = Get-GitBranchCommit -Last 3 -ErrorAction Stop

            $result | Should -Not -BeNullOrEmpty
            $result | Should -HaveCount 3
            $result | ForEach-Object { $_ | Should -Match '^[a-f0-9]{40}$' }

            # Verify these are the 3 most recent commits
            $expectedCommits = git log -3 --pretty=format:"%H"
            $result | Should -Be $expectedCommits
        }

        It 'Should return last 2 commits from specific branch' {
            $result = Get-GitBranchCommit -BranchName 'feature/test' -Last 2 -ErrorAction Stop

            $result | Should -Not -BeNullOrEmpty
            $result | Should -HaveCount 2
            $result | ForEach-Object { $_ | Should -Match '^[a-f0-9]{40}$' }

            # Verify these are the 2 most recent commits from feature branch
            $expectedCommits = git log feature/test -2 --pretty=format:"%H"
            $result | Should -Be $expectedCommits
        }

        It 'Should handle requesting more commits than exist' {
            $result = Get-GitBranchCommit -Last 10 -ErrorAction Stop

            $result | Should -Not -BeNullOrEmpty
            $result | Should -HaveCount 5  # Should return all 5 commits that exist
            $result | ForEach-Object { $_ | Should -Match '^[a-f0-9]{40}$' }
        }
    }

    Context 'When using First parameter' {
        It 'Should return the first 2 commit IDs (oldest commits)' {
            $result = Get-GitBranchCommit -First 2 -ErrorAction Stop

            $result | Should -Not -BeNullOrEmpty
            $result | Should -HaveCount 2
            $result | ForEach-Object { $_ | Should -Match '^[a-f0-9]{40}$' }

            # Verify these are the oldest commits by checking their timestamps
            $timestamps = @()
            foreach ($commit in $result) {
                $timestamp = git log -1 --format="%ct" $commit
                $timestamps += [int]$timestamp
            }

            # Verify timestamps are in ascending order (oldest first)
            for ($i = 0; $i -lt ($timestamps.Count - 1); $i++) {
                $timestamps[$i] | Should -BeLessOrEqual $timestamps[$i + 1]
            }
        }

        It 'Should return first 3 commits from specific branch' {
            $result = Get-GitBranchCommit -BranchName 'feature/test' -First 3 -ErrorAction Stop

            $result | Should -Not -BeNullOrEmpty
            $result | Should -HaveCount 3
            $result | ForEach-Object { $_ | Should -Match '^[a-f0-9]{40}$' }

            # Verify order (oldest first for First parameter)
            $timestamps = @()
            foreach ($commit in $result) {
                $timestamp = git log -1 --format="%ct" $commit
                $timestamps += [int]$timestamp
            }

            for ($i = 0; $i -lt ($timestamps.Count - 1); $i++) {
                $timestamps[$i] | Should -BeLessOrEqual $timestamps[$i + 1]
            }
        }

        It 'Should handle requesting more commits than exist with First' {
            $result = Get-GitBranchCommit -First 10 -ErrorAction Stop

            $result | Should -Not -BeNullOrEmpty
            $result | Should -HaveCount 5  # Should return all 5 commits that exist
            $result | ForEach-Object { $_ | Should -Match '^[a-f0-9]{40}$' }
        }
    }

    Context 'When git operations fail' {
        It 'Should throw error for non-existent branch' {
            { Get-GitBranchCommit -BranchName 'nonexistent-branch' -ErrorAction Stop 2>$null } |
                Should -Throw -ErrorId 'GGBC0001,Get-GitBranchCommit'
        }

        It 'Should handle empty repository scenarios gracefully' {
            # Create a new empty repository
            $emptyRepoPath = Join-Path -Path $TestDrive -ChildPath 'EmptyGitRepo'
            New-Item -Path $emptyRepoPath -ItemType Directory -Force | Out-Null

            Push-Location -Path $emptyRepoPath
            try {
                git init *> $null
                git config user.email "test@example.com" *> $null
                git config user.name "Test User" *> $null

                # Should throw error from Get-GitLocalBranchName for empty repository
                { Get-GitBranchCommit -ErrorAction Stop 2>$null } |
                    Should -Throw -ErrorId 'GGLBN0001,Get-GitLocalBranchName'
            }
            finally {
                Pop-Location
                $previousProgressPreference = $ProgressPreference
                $ProgressPreference = 'SilentlyContinue' # Suppress progress output during deletion
                Remove-Item -Path $emptyRepoPath -Recurse -Force -ErrorAction SilentlyContinue
                $ProgressPreference = $previousProgressPreference
            }
        }
    }

    Context 'When testing in non-git directory' {
        It 'Should throw error when not in a git repository' {
            $nonGitPath = Join-Path -Path $TestDrive -ChildPath 'NonGitDirectory'
            New-Item -Path $nonGitPath -ItemType Directory -Force | Out-Null

            Push-Location -Path $nonGitPath
            try {
                # Should throw error from Get-GitLocalBranchName for non-git directory
                { Get-GitBranchCommit -ErrorAction Stop 2>$null } |
                    Should -Throw -ErrorId 'GGLBN0001,Get-GitLocalBranchName'
            }
            finally {
                Pop-Location
                $previousProgressPreference = $ProgressPreference
                $ProgressPreference = 'SilentlyContinue' # Suppress progress output during deletion
                Remove-Item -Path $nonGitPath -Recurse -Force -ErrorAction SilentlyContinue
                $ProgressPreference = $previousProgressPreference
            }
        }
    }

    Context 'When testing commit ID format validation' {
        It 'Should return valid 40-character SHA-1 hashes' {
            $result = Get-GitBranchCommit -ErrorAction Stop

            $result | ForEach-Object {
                $_ | Should -Match '^[a-f0-9]{40}$'
                $_.Length | Should -Be 40
            }
        }

        It 'Should return consistent results across multiple calls' {
            $result1 = Get-GitBranchCommit -ErrorAction Stop
            $result2 = Get-GitBranchCommit -ErrorAction Stop

            $result1 | Should -Be $result2
        }
    }

    Context 'When using Range parameter set' {
        It 'Should return commits between HEAD~3 and HEAD' {
            $result = Get-GitBranchCommit -From 'HEAD~3' -To 'HEAD' -ErrorAction Stop

            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -BeGreaterThan 0
            $result.Count | Should -BeLessOrEqual 3

            # Verify all results are valid commit IDs
            $result | ForEach-Object {
                $_ | Should -Match '^[a-f0-9]{40}$'
            }
        }

        It 'Should return commits between two specific commits' {
            # Get some commits to work with
            $allCommits = Get-GitBranchCommit -ErrorAction Stop

            if ($allCommits.Count -ge 3) {
                $fromCommit = $allCommits[2]  # Third commit (older)
                $toCommit = $allCommits[0]    # First commit (newer)

                $result = Get-GitBranchCommit -From $fromCommit -To $toCommit -ErrorAction Stop

                $result | Should -Not -BeNullOrEmpty
                $result.Count | Should -BeGreaterOrEqual 1

                # Verify all results are valid commit IDs
                $result | ForEach-Object {
                    $_ | Should -Match '^[a-f0-9]{40}$'
                }
            }
        }

        It 'Should return commits between branches' {
            # Create a feature branch to test with
            git checkout -b 'test-range-branch' *> $null

            try {
                # Make a commit on the feature branch
                "Test range content" | Out-File -FilePath 'test-range-file.txt' -Encoding UTF8
                git add . *> $null
                git commit -m "Test range commit" *> $null

                # Switch back to main and get range
                git checkout 'main' *> $null

                $result = Get-GitBranchCommit -From 'main' -To 'test-range-branch' -ErrorAction Stop

                $result | Should -Not -BeNullOrEmpty
                $result.Count | Should -BeGreaterOrEqual 1

                # Verify all results are valid commit IDs
                $result | ForEach-Object {
                    $_ | Should -Match '^[a-f0-9]{40}$'
                }
            }
            finally {
                # Clean up
                git checkout 'main' *> $null
                git branch -D 'test-range-branch' *> $null
                Remove-Item -Path 'test-range-file.txt' -ErrorAction SilentlyContinue
            }
        }

        It 'Should handle empty ranges gracefully' {
            # Test range where From and To are the same commit
            $latestCommit = Get-GitBranchCommit -Latest -ErrorAction Stop

            $result = Get-GitBranchCommit -From $latestCommit -To $latestCommit -ErrorAction Stop

            # Git range syntax commit..commit should return empty when they're the same
            $result | Should -BeNullOrEmpty
        }

        It 'Should throw error for invalid range references' {
            { Get-GitBranchCommit -From 'invalid-commit-123' -To 'HEAD' -ErrorAction Stop 2>$null } |
                Should -Throw -ErrorId 'GGBC0001,Get-GitBranchCommit'
        }

        It 'Should handle reversed range order' {
            # Get some commits to work with
            $allCommits = Get-GitBranchCommit -ErrorAction Stop

            if ($allCommits.Count -ge 2) {
                $olderCommit = $allCommits[1]   # Second commit (older)
                $newerCommit = $allCommits[0]   # First commit (newer)

                # Range from newer to older should return empty (git behavior)
                $result = Get-GitBranchCommit -From $newerCommit -To $olderCommit -ErrorAction Stop

                # This should return empty since we're going backwards in time
                $result | Should -BeNullOrEmpty
            }
        }
    }
}
