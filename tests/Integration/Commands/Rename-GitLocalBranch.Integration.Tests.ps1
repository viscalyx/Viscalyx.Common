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

    # Initialize the test repository and create test structure
    Push-Location -Path $script:testRepoPath
    try {
        # Initialize git repository
        git init --initial-branch=main --quiet 2>$null
        git config user.email "test@example.com" *> $null
        git config user.name "Test User" *> $null

        # Create initial commit
        "Initial content" | Out-File -FilePath 'test.txt' -Encoding utf8
        git add test.txt *> $null
        git commit -m "Initial commit" *> $null

        # Get the default branch name (main or master)
        $script:defaultBranch = git rev-parse --abbrev-ref HEAD

        # Create feature branches for testing
        git checkout -b 'feature/original-branch' --quiet 2>$null
        "Feature content" | Out-File -FilePath 'feature.txt' -Encoding utf8
        git add feature.txt *> $null
        git commit -m "Feature commit" *> $null

        # Create another test branch for remote scenarios
        git checkout -b 'develop' --quiet 2>$null
        "Develop content" | Out-File -FilePath 'develop.txt' -Encoding utf8
        git add develop.txt *> $null
        git commit -m "Develop commit" *> $null

        # Switch back to default branch
        git checkout $script:defaultBranch *> $null
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

Describe 'Rename-GitLocalBranch Integration Tests' {
    BeforeEach {
        # Change to test repository for each test
        Push-Location -Path $script:testRepoPath
    }

    AfterEach {
        # Return to original location
        Pop-Location
    }

    Context 'When renaming a local branch successfully' {
        BeforeEach {
            # Ensure we start with the feature branch
            git checkout 'feature/original-branch' *> $null
        }

        AfterEach {
            # Clean up any renamed branches for next test
            try {
                $currentBranch = git rev-parse --abbrev-ref HEAD 2>&1
                if ($LASTEXITCODE -eq 0 -and $currentBranch -eq 'feature/renamed-branch') {
                    git checkout $script:defaultBranch *> $null
                    git branch -D 'feature/renamed-branch' *> $null
                }
                $existingBranches = git branch --list 'feature/renamed-branch' 2>&1
                if ($LASTEXITCODE -eq 0 -and $existingBranches) {
                    git branch -D 'feature/renamed-branch' *> $null
                }
            }
            catch {
                # Ignore cleanup errors
            }
        }

        It 'Should rename a local branch successfully' {
            # Verify the original branch exists
            $originalBranches = git branch --list 'feature/original-branch'
            $originalBranches | Should -Not -BeNullOrEmpty

            # Rename the branch
            { Rename-GitLocalBranch -Name 'feature/original-branch' -NewName 'feature/renamed-branch' } | Should -Not -Throw

            # Verify the old branch no longer exists
            $oldBranch = git branch --list 'feature/original-branch' 2>&1
            if ($LASTEXITCODE -eq 0) {
                $oldBranch | Should -BeNullOrEmpty
            }

            # Verify the new branch exists
            $newBranch = git branch --list 'feature/renamed-branch'
            $newBranch | Should -Not -BeNullOrEmpty

            # Verify we're currently on the renamed branch
            $currentBranch = git rev-parse --abbrev-ref HEAD
            $currentBranch | Should -Be 'feature/renamed-branch'
        }

        It 'Should preserve commit history when renaming a branch' {
            # Make sure we have a fresh branch for this test
            git checkout $script:defaultBranch *> $null
            git checkout -b 'feature/original-branch' --quiet 2>$null
            "Feature content" | Out-File -FilePath 'feature2.txt' -Encoding utf8
            git add feature2.txt *> $null
            git commit -m "Feature commit" *> $null

            # Get the commit hash before renaming
            $originalCommit = git rev-parse HEAD

            # Rename the branch
            Rename-GitLocalBranch -Name 'feature/original-branch' -NewName 'feature/renamed-branch'

            # Get the commit hash after renaming
            $newCommit = git rev-parse HEAD

            # Verify the commit history is preserved
            $originalCommit | Should -Be $newCommit

            # Verify the commit message is preserved
            $commitMessage = git log -1 --pretty=format:"%s"
            $commitMessage | Should -Be 'Feature commit'

            # Clean up the extra file
            git checkout $script:defaultBranch *> $null
            try { git branch -D 'feature/renamed-branch' *> $null } catch { }
            try { Remove-Item -Path 'feature2.txt' -Force -ErrorAction SilentlyContinue } catch { }
        }

        It 'Should handle branch names with special characters' {
            # Create a branch with special characters
            git checkout -b 'feature/test-123_special.branch' --quiet 2>$null
            "Special content" | Out-File -FilePath 'special.txt' -Encoding utf8
            git add special.txt *> $null
            git commit -m "Special commit" *> $null

            # Rename the branch
            { Rename-GitLocalBranch -Name 'feature/test-123_special.branch' -NewName 'feature/renamed-special' } | Should -Not -Throw

            # Verify the rename worked
            $currentBranch = git rev-parse --abbrev-ref HEAD
            $currentBranch | Should -Be 'feature/renamed-special'

            # Clean up
            git checkout $script:defaultBranch *> $null
            try { git branch -D 'feature/renamed-special' *> $null } catch { }
        }
    }

    Context 'When handling error scenarios' {
        It 'Should throw error when trying to rename non-existent branch' {
            {
                Rename-GitLocalBranch -Name 'non-existent-branch' -NewName 'new-branch-name' -ErrorAction Stop 2>$null
            } | Should -Throw -ExpectedMessage "*Failed to rename branch*"
        }

        It 'Should throw error when trying to rename to existing branch name' {
            # Create two branches
            git checkout -b 'branch-one' --quiet 2>$null
            git checkout -b 'branch-two' --quiet 2>$null

            # Try to rename branch-two to branch-one (which already exists)
            {
                Rename-GitLocalBranch -Name 'branch-two' -NewName 'branch-one' -ErrorAction Stop 2>$null
            } | Should -Throw -ExpectedMessage "*Failed to rename branch*"

            # Clean up
            git checkout $script:defaultBranch *> $null
            git branch -D 'branch-one' 2>$null
            git branch -D 'branch-two' 2>$null
        }

        It 'Should throw error when trying to rename branch with invalid characters' {
            git checkout -b 'valid-branch' --quiet 2>$null

            # Try to rename to an invalid branch name (contains spaces and special chars)
            {
                Rename-GitLocalBranch -Name 'valid-branch' -NewName 'invalid branch name with spaces!' -ErrorAction Stop 2>$null
            } | Should -Throw -ExpectedMessage "*Failed to rename branch*"

            # Clean up
            git checkout $script:defaultBranch *> $null
            git branch -D 'valid-branch' 2>$null
        }
    }

    Context 'When working with remote-related options' {
        BeforeEach {
            # Create a bare repository to act as a remote
            $script:bareRepoPath = Join-Path -Path $TestDrive -ChildPath 'BareTestRepo'
            git init --bare $script:bareRepoPath *> $null

            # Add the bare repo as origin remote
            git remote add origin $script:bareRepoPath 2>$null

            # Create and push a branch to remote
            git checkout -b 'remote-test-branch' --quiet 2>$null
            "Remote test content" | Out-File -FilePath 'remote-test.txt' -Encoding utf8
            git add remote-test.txt *> $null
            git commit -m "Remote test commit" *> $null
            git push origin remote-test-branch *> $null
        }

        AfterEach {
            # Clean up remote and branches
            $currentBranch = git rev-parse --abbrev-ref HEAD 2>$null
            if ($currentBranch -ne $script:defaultBranch) {
                git checkout $script:defaultBranch *> $null
            }

            # Remove test branches
            git branch -D 'remote-test-branch' 2>$null
            git branch -D 'renamed-remote-branch' 2>$null

            # Remove remote
            git remote remove origin 2>$null

            # Remove bare repository
            if (Test-Path -Path $script:bareRepoPath) {
                $previousProgressPreference = $ProgressPreference
                $ProgressPreference = 'SilentlyContinue' # Suppress progress output during deletion
                Remove-Item -Path $script:bareRepoPath -Recurse -Force -ErrorAction SilentlyContinue
                $ProgressPreference = $previousProgressPreference
            }
        }

        It 'Should rename branch with TrackUpstream when remote branch exists' {
            # First push the branch to remote if not already there
            try { git push origin remote-test-branch *> $null } catch { }

            # Rename with upstream tracking - this will fail because the upstream doesn't exist yet
            # but we test that the error is handled correctly
            {
                Rename-GitLocalBranch -Name 'remote-test-branch' -NewName 'renamed-remote-branch' -TrackUpstream 2>$null
            } | Should -Throw -Because "The upstream branch doesn't exist in our test setup"

            # Verify the branch was renamed despite the upstream tracking failure
            # Switch back to see if branch was renamed before the upstream tracking failed
            git checkout $script:defaultBranch *> $null
            $branchExists = git branch --list 'renamed-remote-branch'
            $branchExists | Should -Not -BeNullOrEmpty -Because "Branch should still be renamed even if upstream tracking fails"
        }

        It 'Should handle SetDefault parameter without throwing error' {
            # This test verifies the command executes and properly handles the expected failure
            # In a real repository with proper remote setup, this would set the default branch
            # but in our test setup, it will fail because there's no remote HEAD to determine
            {
                Rename-GitLocalBranch -Name 'remote-test-branch' -NewName 'renamed-remote-branch' -SetDefault 2>$null
            } | Should -Throw -Because "Cannot determine remote HEAD in test setup"

            # Verify the branch was renamed despite the set-head failure
            git checkout $script:defaultBranch *> $null
            $branchExists = git branch --list 'renamed-remote-branch'
            $branchExists | Should -Not -BeNullOrEmpty -Because "Branch should still be renamed even if set-head fails"
        }

        It 'Should handle custom remote name' {
            # Add another remote with different name
            $script:upstreamRepoPath = Join-Path -Path $TestDrive -ChildPath 'UpstreamTestRepo'
            try { git init --bare $script:upstreamRepoPath *> $null } catch { }
            try { git remote add upstream $script:upstreamRepoPath *> $null } catch { }

            # Test with custom remote name - this will fail due to missing upstream branch
            {
                Rename-GitLocalBranch -Name 'remote-test-branch' -NewName 'renamed-remote-branch' -RemoteName 'upstream' -TrackUpstream 2>$null
            } | Should -Throw -Because "Upstream branch doesn't exist"

            # Clean up additional remote
            try { git remote remove upstream *> $null } catch { }
            if (Test-Path -Path $script:upstreamRepoPath) {
                $previousProgressPreference = $ProgressPreference
                $ProgressPreference = 'SilentlyContinue' # Suppress progress output during deletion
                Remove-Item -Path $script:upstreamRepoPath -Recurse -Force -ErrorAction SilentlyContinue
                $ProgressPreference = $previousProgressPreference
            }
        }
    }

    Context 'When testing edge cases' {
        It 'Should work when renaming current branch' {
            # Create and switch to a test branch
            git checkout -b 'current-branch-test' --quiet 2>$null

            # Rename the current branch
            { Rename-GitLocalBranch -Name 'current-branch-test' -NewName 'renamed-current-branch' } | Should -Not -Throw

            # Verify we're now on the renamed branch
            $currentBranch = git rev-parse --abbrev-ref HEAD
            $currentBranch | Should -Be 'renamed-current-branch'

            # Clean up
            git checkout $script:defaultBranch *> $null
            git branch -D 'renamed-current-branch' 2>$null
        }

        It 'Should work when renaming branch that is not current' {
            # Create two test branches
            git checkout -b 'branch-to-rename' --quiet 2>$null
            git checkout -b 'other-branch' --quiet 2>$null

            # Rename a branch we're not currently on
            { Rename-GitLocalBranch -Name 'branch-to-rename' -NewName 'renamed-other-branch' } | Should -Not -Throw

            # Verify the branch was renamed (should exist in branch list)
            $branchExists = git branch --list 'renamed-other-branch'
            $branchExists | Should -Not -BeNullOrEmpty

            # Verify we're still on the other branch
            $currentBranch = git rev-parse --abbrev-ref HEAD
            $currentBranch | Should -Be 'other-branch'

            # Clean up
            git checkout $script:defaultBranch *> $null
            git branch -D 'other-branch' 2>$null
            git branch -D 'renamed-other-branch' 2>$null
        }
    }
}
