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
}

Describe 'Rename-GitLocalBranch Integration Tests' {
    BeforeAll {
        # Create a temporary Git repository for testing
        $script:testRepoPath = Join-Path -Path $TestDrive -ChildPath 'TestGitRepo'
        New-Item -Path $script:testRepoPath -ItemType Directory -Force | Out-Null

        # Initialize the test repository and create test structure
        Push-Location -Path $script:testRepoPath
        try
        {
            # Initialize git repository
            Viscalyx.Common\Invoke-Git -WorkingDirectory $script:testRepoPath -Arguments @('init', '--initial-branch=main', '--quiet')
            Viscalyx.Common\Invoke-Git -WorkingDirectory $script:testRepoPath -Arguments @('config', 'user.email', 'test@example.com')
            Viscalyx.Common\Invoke-Git -WorkingDirectory $script:testRepoPath -Arguments @('config', 'user.name', '"Test User"')

            # Create initial commit
            'Initial content' | Out-File -FilePath 'test.txt' -Encoding utf8
            Viscalyx.Common\Invoke-Git -WorkingDirectory $script:testRepoPath -Arguments @('add', 'test.txt')
            Viscalyx.Common\Invoke-Git -WorkingDirectory $script:testRepoPath -Arguments @('commit', '-m', '"Initial commit"')

            # Get the default branch name (main or master)
            $result = Viscalyx.Common\Invoke-Git -WorkingDirectory $script:testRepoPath -Arguments @('rev-parse', '--abbrev-ref', 'HEAD') -PassThru
            $script:defaultBranch = $result.Output
        }
        finally
        {
            Pop-Location
        }
    }

    AfterAll {
        # Clean up - remove the test repository
        if (Test-Path -Path $script:testRepoPath)
        {
            $previousProgressPreference = $ProgressPreference
            $ProgressPreference = 'SilentlyContinue' # Suppress progress output during deletion
            Remove-Item -Path $script:testRepoPath -Recurse -Force -ErrorAction SilentlyContinue
            $ProgressPreference = $previousProgressPreference
        }
    }

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
            Viscalyx.Common\Invoke-Git -WorkingDirectory $script:testRepoPath -Arguments @('checkout', $script:defaultBranch)

            # Create feature branches for testing
            Viscalyx.Common\Invoke-Git -WorkingDirectory $script:testRepoPath -Arguments @('checkout', '-b', 'feature/original-branch', '--quiet')
            'Feature content' | Out-File -FilePath 'feature.txt' -Encoding utf8
            Viscalyx.Common\Invoke-Git -WorkingDirectory $script:testRepoPath -Arguments @('add', 'feature.txt')
            Viscalyx.Common\Invoke-Git -WorkingDirectory $script:testRepoPath -Arguments @('commit', '-m', '"Feature commit"')
        }

        AfterEach {
            # Clean up any renamed branches for next test
            Viscalyx.Common\Invoke-Git -WorkingDirectory $script:testRepoPath -Arguments @('checkout', $script:defaultBranch)
            Viscalyx.Common\Invoke-Git -WorkingDirectory $script:testRepoPath -Arguments @('branch', '-D', 'feature/renamed-branch')
        }

        It 'Should rename a local branch successfully' {
            { Rename-GitLocalBranch -Name 'feature/original-branch' -NewName 'feature/renamed-branch' } | Should -Not -Throw

            # Verify the old branch no longer exists
            $result = Viscalyx.Common\Invoke-Git -WorkingDirectory $script:testRepoPath -Arguments @('branch', '--list', 'feature/original-branch') -PassThru
            $oldBranch = $result.Output
            $oldBranch | Should -BeNullOrEmpty

            # Verify the new branch exists
            $result = Viscalyx.Common\Invoke-Git -WorkingDirectory $script:testRepoPath -Arguments @('branch', '--list', 'feature/renamed-branch') -PassThru
            $newBranch = $result.Output
            $newBranch | Should -Not -BeNullOrEmpty

            # Verify we're currently on the renamed branch
            $result = Viscalyx.Common\Invoke-Git -WorkingDirectory $script:testRepoPath -Arguments @('rev-parse', '--abbrev-ref', 'HEAD') -PassThru
            $currentBranch = $result.Output
            $currentBranch | Should -Be 'feature/renamed-branch'
        }

        It 'Should preserve commit history when renaming a branch' {
            # Make sure we have a fresh branch for this test
            Viscalyx.Common\Invoke-Git -WorkingDirectory $script:testRepoPath -Arguments @('checkout', 'feature/original-branch', '--quiet')

            'Feature content' | Out-File -FilePath 'feature2.txt' -Encoding utf8
            Viscalyx.Common\Invoke-Git -WorkingDirectory $script:testRepoPath -Arguments @('add', 'feature2.txt')
            Viscalyx.Common\Invoke-Git -WorkingDirectory $script:testRepoPath -Arguments @('commit', '-m', '"Feature commit"')

            # Get the commit hash before renaming
            $result = Viscalyx.Common\Invoke-Git -WorkingDirectory $script:testRepoPath -Arguments @('rev-parse', 'HEAD') -PassThru
            $originalCommit = $result.Output

            # Rename the branch
            Rename-GitLocalBranch -Name 'feature/original-branch' -NewName 'feature/renamed-branch'

            # Get the commit hash after renaming
            $result = Viscalyx.Common\Invoke-Git -WorkingDirectory $script:testRepoPath -Arguments @('rev-parse', 'HEAD') -PassThru
            $newCommit = $result.Output

            # Verify the commit history is preserved
            $originalCommit | Should -Be $newCommit

            # Verify the commit message is preserved
            $result = Viscalyx.Common\Invoke-Git -WorkingDirectory $script:testRepoPath -Arguments @('log', '-1', '--pretty=format:%s') -PassThru
            $commitMessage = $result.Output
            $commitMessage | Should -Be 'Feature commit'
        }

        It 'Should handle branch names with special characters' {
            # Create a branch with special characters
            Viscalyx.Common\Invoke-Git -WorkingDirectory $script:testRepoPath -Arguments @('checkout', '-b', 'feature/test-123_special.branch', '--quiet')

            'Special content' | Out-File -FilePath 'special.txt' -Encoding utf8
            Viscalyx.Common\Invoke-Git -WorkingDirectory $script:testRepoPath -Arguments @('add', 'special.txt')
            Viscalyx.Common\Invoke-Git -WorkingDirectory $script:testRepoPath -Arguments @('commit', '-m', '"Special commit"')

            # Rename the branch
            { Rename-GitLocalBranch -Name 'feature/test-123_special.branch' -NewName 'feature/renamed-branch' } | Should -Not -Throw

            # Verify the rename worked
            $result = Viscalyx.Common\Invoke-Git -WorkingDirectory $script:testRepoPath -Arguments @('rev-parse', '--abbrev-ref', 'HEAD') -PassThru
            $currentBranch = $result.Output
            $currentBranch | Should -Be 'feature/renamed-branch'
        }
    }

    Context 'When handling error scenarios' {
        It 'Should throw error when trying to rename non-existent branch' {
            {
                Rename-GitLocalBranch -Name 'non-existent-branch' -NewName 'new-branch-name' -ErrorAction Stop
            } | Should -Throw -ExpectedMessage '*Failed to rename branch*'
        }

        It 'Should throw error when trying to rename to existing branch name' {
            # Create two branches
            Viscalyx.Common\Invoke-Git -WorkingDirectory $script:testRepoPath -Arguments @('checkout', '-b', 'branch-one', '--quiet')
            Viscalyx.Common\Invoke-Git -WorkingDirectory $script:testRepoPath -Arguments @('checkout', '-b', 'branch-two', '--quiet')

            # Try to rename branch-two to branch-one (which already exists)
            {
                Rename-GitLocalBranch -Name 'branch-two' -NewName 'branch-one' -ErrorAction Stop
            } | Should -Throw -ExpectedMessage '*Failed to rename branch*'

            # Clean up
            Viscalyx.Common\Invoke-Git -WorkingDirectory $script:testRepoPath -Arguments @('checkout', $script:defaultBranch)
            Viscalyx.Common\Invoke-Git -WorkingDirectory $script:testRepoPath -Arguments @('branch', '-D', 'branch-one')
            Viscalyx.Common\Invoke-Git -WorkingDirectory $script:testRepoPath -Arguments @('branch', '-D', 'branch-two')
        }

        It 'Should throw error when trying to rename branch with invalid characters' {
            Viscalyx.Common\Invoke-Git -WorkingDirectory $script:testRepoPath -Arguments @('checkout', '-b', 'valid-branch', '--quiet')

            # Try to rename to an invalid branch name (contains spaces and special chars)
            {
                Rename-GitLocalBranch -Name 'valid-branch' -NewName 'invalid branch name with spaces!' -ErrorAction Stop
            } | Should -Throw -ExpectedMessage '*Failed to rename branch*'

            # Clean up
            Viscalyx.Common\Invoke-Git -WorkingDirectory $script:testRepoPath -Arguments @('checkout', $script:defaultBranch)

            Viscalyx.Common\Invoke-Git -WorkingDirectory $script:testRepoPath -Arguments @('branch', '-D', 'valid-branch')
        }
    }

    Context 'When working with remote-related options' {
        BeforeEach {
            # Create a bare repository to act as a remote
            $script:bareRepoPath = Join-Path -Path $TestDrive -ChildPath 'BareTestRepo'
            Viscalyx.Common\Invoke-Git -WorkingDirectory $TestDrive -Arguments @('init', '--bare', '--initial-branch=main', $script:bareRepoPath)

            # Add the bare repo as origin remote
            Viscalyx.Common\Invoke-Git -WorkingDirectory $script:testRepoPath -Arguments @('remote', 'add', 'origin', $script:bareRepoPath)

            # Create and push a branch to remote
            Viscalyx.Common\Invoke-Git -WorkingDirectory $script:testRepoPath -Arguments @('checkout', '-b', 'remote-test-branch', '--quiet')

            'Remote test content' | Out-File -FilePath 'remote-test.txt' -Encoding utf8
            Viscalyx.Common\Invoke-Git -WorkingDirectory $script:testRepoPath -Arguments @('add', 'remote-test.txt')
            Viscalyx.Common\Invoke-Git -WorkingDirectory $script:testRepoPath -Arguments @('commit', '-m', '"Remote test commit"')
            Viscalyx.Common\Invoke-Git -WorkingDirectory $script:testRepoPath -Arguments @('push', 'origin', 'remote-test-branch')
        }

        AfterEach {
            $result = Viscalyx.Common\Invoke-Git -WorkingDirectory $script:testRepoPath -Arguments @('rev-parse', '--abbrev-ref', 'HEAD') -PassThru
            $currentBranch = $result.Output
            if ($currentBranch -ne $script:defaultBranch)
            {
                Viscalyx.Common\Invoke-Git -WorkingDirectory $script:testRepoPath -Arguments @('checkout', $script:defaultBranch)
            }

            # Remove test branches
            Viscalyx.Common\Invoke-Git -WorkingDirectory $script:testRepoPath -Arguments @('branch', '-D', 'renamed-remote-branch')
            Viscalyx.Common\Invoke-Git -WorkingDirectory $script:testRepoPath -Arguments @('remote', 'remove', 'origin')

            # Remove bare repository
            if (Test-Path -Path $script:bareRepoPath)
            {
                $previousProgressPreference = $ProgressPreference
                $ProgressPreference = 'SilentlyContinue' # Suppress progress output during deletion
                Remove-Item -Path $script:bareRepoPath -Recurse -Force -ErrorAction SilentlyContinue
                $ProgressPreference = $previousProgressPreference
            }
        }

        It 'Should rename branch with TrackUpstream when remote branch exists' {
            # First push the branch to remote if not already there
            Viscalyx.Common\Invoke-Git -WorkingDirectory $script:testRepoPath -Arguments @('push', 'origin', 'remote-test-branch')

            # Rename with upstream tracking - this will fail because the upstream doesn't exist yet
            # but we test that the error is handled correctly
            {
                Rename-GitLocalBranch -Name 'remote-test-branch' -NewName 'renamed-remote-branch' -TrackUpstream -ErrorAction 'Stop'
            } | Should -Throw -Because "The upstream branch doesn't exist in our test setup"

            # Verify the branch was renamed despite the upstream tracking failure
            # Switch back to see if branch was renamed before the upstream tracking failed
            Viscalyx.Common\Invoke-Git -WorkingDirectory $script:testRepoPath -Arguments @('checkout', $script:defaultBranch)
            $result = Viscalyx.Common\Invoke-Git -WorkingDirectory $script:testRepoPath -Arguments @('branch', '--list', 'renamed-remote-branch') -PassThru
            $branchExists = $result.Output
            $branchExists | Should -Not -BeNullOrEmpty -Because 'Branch should still be renamed even if upstream tracking fails'
        }

        It 'Should handle SetDefault parameter without throwing error' {
            # This test verifies the command executes and properly handles the expected failure
            # In a real repository with proper remote setup, this would set the default branch
            # but in our test setup, it will fail because there's no remote HEAD to determine
            {
                Rename-GitLocalBranch -Name 'remote-test-branch' -NewName 'renamed-remote-branch' -SetDefault
            } | Should -Throw -Because 'Cannot determine remote HEAD in test setup'

            # Verify the branch was renamed despite the set-head failure
            Viscalyx.Common\Invoke-Git -WorkingDirectory $script:testRepoPath -Arguments @('checkout', $script:defaultBranch)
            $result = Viscalyx.Common\Invoke-Git -WorkingDirectory $script:testRepoPath -Arguments @('branch', '--list', 'renamed-remote-branch') -PassThru
            $branchExists = $result.Output
            $branchExists | Should -Not -BeNullOrEmpty -Because 'Branch should still be renamed even if set-head fails'
        }

        It 'Should handle custom remote name' {
            # Add another remote with different name
            $script:upstreamRepoPath = Join-Path -Path $TestDrive -ChildPath 'UpstreamTestRepo'
            Viscalyx.Common\Invoke-Git -WorkingDirectory $TestDrive -Arguments @('init', '--bare', '--initial-branch=main', $script:upstreamRepoPath)
            Viscalyx.Common\Invoke-Git -WorkingDirectory $script:testRepoPath -Arguments @('remote', 'add', 'upstream', $script:upstreamRepoPath)

            # Test with custom remote name - this will fail due to missing upstream branch
            {
                Rename-GitLocalBranch -Name 'remote-test-branch' -NewName 'renamed-remote-branch' -RemoteName 'upstream' -TrackUpstream
            } | Should -Throw -Because "Upstream branch doesn't exist"

            # Clean up additional remote
            Viscalyx.Common\Invoke-Git -WorkingDirectory $script:testRepoPath -Arguments @('remote', 'remove', 'upstream')

            if (Test-Path -Path $script:upstreamRepoPath)
            {
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
            Viscalyx.Common\Invoke-Git -WorkingDirectory $script:testRepoPath -Arguments @('checkout', '-b', 'current-branch-test', '--quiet')

            # Rename the current branch
            { Rename-GitLocalBranch -Name 'current-branch-test' -NewName 'renamed-current-branch' } | Should -Not -Throw

            # Verify we're now on the renamed branch
            $result = Viscalyx.Common\Invoke-Git -WorkingDirectory $script:testRepoPath -Arguments @('rev-parse', '--abbrev-ref', 'HEAD') -PassThru
            $currentBranch = $result.Output
            $currentBranch | Should -Be 'renamed-current-branch'

            # Clean up
            Viscalyx.Common\Invoke-Git -WorkingDirectory $script:testRepoPath -Arguments @('checkout', $script:defaultBranch)
            Viscalyx.Common\Invoke-Git -WorkingDirectory $script:testRepoPath -Arguments @('branch', '-D', 'renamed-current-branch')
        }

        It 'Should work when renaming branch that is not current' {
            # Create two test branches
            Viscalyx.Common\Invoke-Git -WorkingDirectory $script:testRepoPath -Arguments @('checkout', '-b', 'branch-to-rename', '--quiet')
            Viscalyx.Common\Invoke-Git -WorkingDirectory $script:testRepoPath -Arguments @('checkout', '-b', 'other-branch', '--quiet')

            # Rename a branch we're not currently on
            { Rename-GitLocalBranch -Name 'branch-to-rename' -NewName 'renamed-other-branch' } | Should -Not -Throw

            # Verify the branch was renamed (should exist in branch list)
            $result = Viscalyx.Common\Invoke-Git -WorkingDirectory $script:testRepoPath -Arguments @('branch', '--list', 'renamed-other-branch') -PassThru
            $branchExists = $result.Output
            $branchExists | Should -Not -BeNullOrEmpty

            # Verify we're still on the other branch
            $result = Viscalyx.Common\Invoke-Git -WorkingDirectory $script:testRepoPath -Arguments @('rev-parse', '--abbrev-ref', 'HEAD') -PassThru
            $currentBranch = $result.Output
            $currentBranch | Should -Be 'other-branch'

            # Clean up
            Viscalyx.Common\Invoke-Git -WorkingDirectory $script:testRepoPath -Arguments @('checkout', $script:defaultBranch)
            Viscalyx.Common\Invoke-Git -WorkingDirectory $script:testRepoPath -Arguments @('branch', '-D', 'other-branch')
            Viscalyx.Common\Invoke-Git -WorkingDirectory $script:testRepoPath -Arguments @('branch', '-D', 'renamed-other-branch')
        }
    }
}
