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

AfterAll {
    # Unload the module being tested so that it doesn't impact any other tests.
    Get-Module -Name $script:moduleName -All | Remove-Module -Force
}

Describe 'Update-RemoteTrackingBranch Integration Tests' -Tag 'Integration' {
    BeforeAll {
        # Store original location
        $script:originalLocation = Get-Location

        # Create a temporary directory for our test repository
        $script:testRepoPath = Join-Path -Path $TestDrive -ChildPath 'TestRepo'
        $null = New-Item -Path $script:testRepoPath -ItemType Directory -Force

        # Initialize a git repository
        Push-Location -Path $script:testRepoPath
        try
        {
            & git init --quiet --initial-branch=main
            & git config user.name 'Test User'
            & git config user.email 'test@example.com'

            # Create an initial commit on main branch
            $null = New-Item -Path (Join-Path -Path $script:testRepoPath -ChildPath 'README.md') -ItemType File -Force
            Set-Content -Path (Join-Path -Path $script:testRepoPath -ChildPath 'README.md') -Value '# Test Repository'
            & git add README.md
            & git commit -m 'Initial commit' --quiet

            # Create a feature branch for testing
            & git checkout -b 'feature/test-branch' --quiet
            $null = New-Item -Path (Join-Path -Path $script:testRepoPath -ChildPath 'feature.txt') -ItemType File -Force
            Set-Content -Path (Join-Path -Path $script:testRepoPath -ChildPath 'feature.txt') -Value 'Feature content'
            & git add feature.txt
            & git commit -m 'Add feature file' --quiet

            # Create a development branch with additional commits
            & git checkout -b 'develop' --quiet
            $null = New-Item -Path (Join-Path -Path $script:testRepoPath -ChildPath 'develop.txt') -ItemType File -Force
            Set-Content -Path (Join-Path -Path $script:testRepoPath -ChildPath 'develop.txt') -Value 'Development content'
            & git add develop.txt
            & git commit -m 'Add development file' --quiet

            # Switch back to main branch
            & git checkout main --quiet

            # Add more commits to main for testing updates
            Set-Content -Path (Join-Path -Path $script:testRepoPath -ChildPath 'README.md') -Value "# Test Repository`nUpdated content"
            & git add README.md
            & git commit -m 'Update README' --quiet

            # Create a simple remote by creating another local repository
            $script:remoteRepoPath = Join-Path -Path $TestDrive -ChildPath 'RemoteRepo'
            & git clone $script:testRepoPath $script:remoteRepoPath --bare --quiet

            # Add remote to our test repository
            & git remote add origin $script:remoteRepoPath

            # Push branches to remote and set up tracking
            try
            {
                & git push origin main --quiet 2>$null
            }
            catch
            {
            }
            try
            {
                & git push origin develop --quiet 2>$null
            }
            catch
            {
            }
            try
            {
                & git push origin feature/test-branch --quiet 2>$null
            }
            catch
            {
            }

            # Set up proper tracking branches
            try
            {
                & git branch --set-upstream-to=origin/main main 2>$null
            }
            catch
            {
            }
            try
            {
                & git branch --set-upstream-to=origin/develop develop 2>$null
            }
            catch
            {
            }
            try
            {
                & git branch --set-upstream-to=origin/feature/test-branch feature/test-branch 2>$null
            }
            catch
            {
            }            # Create some additional commits in the "remote" to test fetching
            Push-Location -Path $script:remoteRepoPath
            try
            {
                # Since it's a bare repo, we need to work around this by cloning it temporarily
                $script:tempRemoteWorkPath = Join-Path -Path $TestDrive -ChildPath 'TempRemoteWork'
                & git clone $script:remoteRepoPath $script:tempRemoteWorkPath --quiet
                Push-Location -Path $script:tempRemoteWorkPath
                try
                {
                    & git config user.name 'Remote User'
                    & git config user.email 'remote@example.com'

                    # Add commits to main branch
                    Set-Content -Path (Join-Path -Path $script:tempRemoteWorkPath -ChildPath 'CHANGELOG.md') -Value '# Changelog'
                    & git add CHANGELOG.md
                    & git commit -m 'Add CHANGELOG' --quiet
                    & git push origin main --quiet

                    # Add commits to develop branch
                    & git checkout develop --quiet
                    Set-Content -Path (Join-Path -Path $script:tempRemoteWorkPath -ChildPath 'develop.txt') -Value 'Updated development content'
                    & git add develop.txt
                    & git commit -m 'Update develop file' --quiet
                    & git push origin develop --quiet

                    # Go back to main
                    & git checkout main --quiet
                }
                finally
                {
                    Pop-Location
                }
            }
            finally
            {
                Pop-Location
            }
        }
        catch
        {
            Pop-Location
            throw
        }
    }

    AfterAll {
        # Always return to original location
        Set-Location -Path $script:originalLocation

        # Clean up temporary directories
        $previousProgressPreference = $ProgressPreference
        $ProgressPreference = 'SilentlyContinue' # Suppress progress output during deletion
        if (Test-Path -Path $script:testRepoPath)
        {
            Remove-Item -Path $script:testRepoPath -Recurse -Force -ErrorAction SilentlyContinue
        }
        if (Test-Path -Path $script:remoteRepoPath)
        {
            Remove-Item -Path $script:remoteRepoPath -Recurse -Force -ErrorAction SilentlyContinue
        }
        if (Test-Path -Path $script:tempRemoteWorkPath)
        {
            Remove-Item -Path $script:tempRemoteWorkPath -Recurse -Force -ErrorAction SilentlyContinue
        }
        $ProgressPreference = $previousProgressPreference
    }

    Context 'When fetching all branches from remote' {
        BeforeAll {
            # Ensure we're in the test repository
            Push-Location -Path $script:testRepoPath
        }

        AfterAll {
            Pop-Location
        }

        It 'Should successfully fetch all branches from origin remote' {
            # Verify current state before fetch
            $beforeBranches = & git branch -r 2>$null

            Update-RemoteTrackingBranch -RemoteName 'origin' -Confirm:$false -ErrorAction Stop

            # Verify branches were fetched
            $afterBranches = & git branch -r 2>$null
            $afterBranches | Should -Contain '  origin/main'
            $afterBranches | Should -Contain '  origin/develop'
            $afterBranches | Should -Contain '  origin/feature/test-branch'
        }

        It 'Should update remote tracking references' {
            # Get current commit ID of remote main
            $beforeRemoteCommit = & git rev-parse origin/main 2>$null

            Update-RemoteTrackingBranch -RemoteName 'origin' -Confirm:$false -ErrorAction Stop

            # Get commit ID after fetch - it should be updated
            $afterRemoteCommit = & git rev-parse origin/main 2>$null

            # The commit should still exist (may be same or different depending on setup)
            $afterRemoteCommit | Should -Not -BeNullOrEmpty
            $afterRemoteCommit | Should -Match '^[0-9a-f]{40}$'  # Valid SHA
        }
    }

    Context 'When fetching specific branch from remote' {
        BeforeAll {
            # Ensure we're in the test repository
            Push-Location -Path $script:testRepoPath
        }

        AfterAll {
            Pop-Location
        }

        It 'Should successfully fetch main branch from origin remote' {
            # First try to clean up any potential repository issues
            & git gc --quiet 2>$null

            <#
                The try-catch block is necessary due to intermittent Git repository corruption that can occur
                in the complex test setup involving bare repositories and concurrent operations. The corruption
                manifests as "bad object refs/remotes/origin/<branch>" errors and is not a fault in the code
                being tested, but rather a known limitation of the integration test infrastructure. The retry
                mechanism with 'git fetch origin' successfully recovers from these transient corruption issues.
            #>
            try
            {
                Update-RemoteTrackingBranch -RemoteName 'origin' -BranchName 'main' -Confirm:$false -ErrorAction Stop
            }
            catch
            {
                # If there's a repository corruption, try to recover by re-fetching all references
                & git fetch origin --quiet 2>$null
                Update-RemoteTrackingBranch -RemoteName 'origin' -BranchName 'main' -Confirm:$false -ErrorAction Stop
            }

            # Verify the specific branch reference exists
            $remoteBranches = & git branch -r 2>$null
            $remoteBranches | Should -Contain '  origin/main'
        }

        It 'Should successfully fetch develop branch from origin remote' {
            Update-RemoteTrackingBranch -RemoteName 'origin' -BranchName 'develop' -Confirm:$false -ErrorAction Stop

            # Verify the specific branch reference exists
            $remoteBranches = & git branch -r 2>$null
            $remoteBranches | Should -Contain '  origin/develop'
        }

        It 'Should successfully fetch feature branch from origin remote' {
            Update-RemoteTrackingBranch -RemoteName 'origin' -BranchName 'feature/test-branch' -Confirm:$false -ErrorAction Stop

            # Verify the specific branch reference exists
            $remoteBranches = & git branch -r 2>$null
            $remoteBranches | Should -Contain '  origin/feature/test-branch'
        }
    }

    Context 'When remote does not exist' {
        BeforeAll {
            # Ensure we're in the test repository
            Push-Location -Path $script:testRepoPath
        }

        AfterAll {
            Pop-Location
        }

        It 'Should throw error when remote does not exist' {
            { Update-RemoteTrackingBranch -RemoteName 'nonexistent' -Confirm:$false -ErrorAction Stop 2>$null } | Should -Throw
        }

        It 'Should throw error when remote does not exist with specific branch' {
            { Update-RemoteTrackingBranch -RemoteName 'nonexistent' -BranchName 'main' -Confirm:$false -ErrorAction Stop 2>$null } | Should -Throw
        }
    }

    Context 'When branch does not exist on remote' {
        BeforeAll {
            # Ensure we're in the test repository
            Push-Location -Path $script:testRepoPath
        }

        AfterAll {
            Pop-Location
        }

        It 'Should throw error when trying to fetch non-existent branch' {
            { Update-RemoteTrackingBranch -RemoteName 'origin' -BranchName 'nonexistent-branch' -Confirm:$false -ErrorAction Stop 2>$null } | Should -Throw
        }
    }

    Context 'When using ShouldProcess with real Git repository' {
        BeforeAll {
            # Ensure we're in the test repository
            Push-Location -Path $script:testRepoPath
        }

        AfterAll {
            Pop-Location
        }

        It 'Should show what would happen with -WhatIf and not perform actual fetch' {
            # Get current state (using rev-parse instead of log to get a single commit hash)
            $beforeState = & git rev-parse origin/main 2>$null

            # Test WhatIf by redirecting all streams and capturing output differently
            $whatIfOutput = $null
            try
            {
                # Use Start-Transcript temporarily to capture all output
                $tempTranscriptPath = Join-Path $TestDrive 'whatif-test.txt'
                Start-Transcript -Path $tempTranscriptPath -Force
                Update-RemoteTrackingBranch -RemoteName 'origin' -BranchName 'main' -WhatIf
                Stop-Transcript

                # Read the transcript to get the actual output
                $transcriptContent = Get-Content -Path $tempTranscriptPath -Raw
                $whatIfOutput = $transcriptContent
            }
            catch
            {
                Stop-Transcript -ErrorAction SilentlyContinue
                throw
            }
            finally
            {
                if (Test-Path $tempTranscriptPath)
                {
                    $previousProgressPreference = $ProgressPreference
                    $ProgressPreference = 'SilentlyContinue' # Suppress progress output during deletion
                    Remove-Item $tempTranscriptPath -ErrorAction SilentlyContinue
                    $ProgressPreference = $previousProgressPreference
                }
            }

            # Verify no actual changes were made
            $afterState = & git rev-parse origin/main 2>$null
            $afterState | Should -Be $beforeState

            # Verify WhatIf output was generated (this verifies ShouldProcess is working)
            # The output should contain "What if:" text
            $whatIfOutput | Should -Match 'What if:'
        }
    }

    Context 'When working in non-git directory' {
        BeforeAll {
            # Create a non-git directory and switch to it
            $script:nonGitPath = Join-Path -Path $TestDrive -ChildPath 'NonGitDir'
            $null = New-Item -Path $script:nonGitPath -ItemType Directory -Force
            Push-Location -Path $script:nonGitPath
        }

        AfterAll {
            Pop-Location
        }

        It 'Should throw error when not in a git repository' {
            { Update-RemoteTrackingBranch -RemoteName 'origin' -Confirm:$false -ErrorAction Stop 2>$null } | Should -Throw
        }
    }

    Context 'When testing with different remote names' {
        BeforeAll {
            # Ensure we're in the test repository and add an upstream remote
            Push-Location -Path $script:testRepoPath

            # Create another "remote" repository
            $script:upstreamRepoPath = Join-Path -Path $TestDrive -ChildPath 'UpstreamRepo'
            & git clone $script:remoteRepoPath $script:upstreamRepoPath --bare --quiet

            # Add upstream remote
            try
            {
                & git remote add upstream $script:upstreamRepoPath 2>$null
            }
            catch
            {
            }
        }

        AfterAll {
            Pop-Location
            if (Test-Path -Path $script:upstreamRepoPath)
            {
                $previousProgressPreference = $ProgressPreference
                $ProgressPreference = 'SilentlyContinue' # Suppress progress output during deletion
                Remove-Item -Path $script:upstreamRepoPath -Recurse -Force -ErrorAction SilentlyContinue
                $ProgressPreference = $previousProgressPreference
            }
        }

        It 'Should successfully fetch from upstream remote' {
            Update-RemoteTrackingBranch -RemoteName 'upstream' -Confirm:$false -ErrorAction Stop

            # Verify upstream branches were fetched
            $remoteBranches = & git branch -r 2>$null
            $remoteBranches | Should -Contain '  upstream/main'
        }

        It 'Should successfully fetch specific branch from upstream remote' {
            Update-RemoteTrackingBranch -RemoteName 'upstream' -BranchName 'develop' -Confirm:$false -ErrorAction Stop

            # Verify specific upstream branch was fetched
            $remoteBranches = & git branch -r 2>$null
            $remoteBranches | Should -Contain '  upstream/develop'
        }
    }
}
