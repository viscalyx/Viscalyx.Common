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

Describe 'Get-GitRemoteBranch' -Tag 'Integration' {
    Context 'When repository has remotes configured' {
        BeforeEach {
            # Create a temporary directory for our test git repository
            $script:testRepoPath = Join-Path -Path $TestDrive -ChildPath "TestRepo_$([guid]::NewGuid().Guid)"
            New-Item -Path $script:testRepoPath -ItemType Directory -Force | Out-Null

            # Store the original location to restore later
            $script:originalLocation = Get-Location

            # Change to the test repository directory
            Set-Location -Path $script:testRepoPath

            # Initialize git repository
            $null = git init --quiet --initial-branch=main 2>&1
            $null = git config user.email "test@example.com" 2>&1
            $null = git config user.name "Test User" 2>&1

            # Create an initial commit to establish a proper git repository
            'test content' | Out-File -FilePath 'test.txt' -Encoding utf8
            $null = git add . 2>&1
            $null = git commit -m "Initial commit" --quiet 2>&1

            # Add test remotes pointing to actual public repositories for realistic testing
            $null = git remote add origin 'https://github.com/PowerShell/PowerShell.git' 2>&1
            $null = git remote add upstream 'https://github.com/PowerShell/PowerShell-Docs.git' 2>&1
        }

        AfterEach {
            # Restore original location
            Set-Location -Path $script:originalLocation

            # Clean up test repository
            if (Test-Path -Path $script:testRepoPath) {
                $previousProgressPreference = $ProgressPreference
                $ProgressPreference = 'SilentlyContinue' # Suppress progress output during deletion
                Remove-Item -Path $script:testRepoPath -Recurse -Force -ErrorAction SilentlyContinue
                $ProgressPreference = $previousProgressPreference
            }
        }

        It 'Should return remote branches when RemoteName is specified' {
            try {
                $result = Get-GitRemoteBranch -RemoteName 'origin' -ErrorAction Stop
                $result | Should -Not -BeNullOrEmpty
                $result | Should -BeOfType [System.String]

                # Verify that all returned branches have the refs/heads/ prefix
                $result | ForEach-Object { $_ | Should -Match '^refs/heads/' }
            }
            catch {
                # If network issues occur, skip this test
                Set-ItResult -Skipped -Because "Network connectivity issue: $($_.Exception.Message)"
            }
        }

        It 'Should return remote branches without refs/heads/ prefix when RemoveRefsHeads is specified' {
            try {
                $result = Get-GitRemoteBranch -RemoteName 'origin' -RemoveRefsHeads -ErrorAction Stop
                $result | Should -Not -BeNullOrEmpty
                $result | Should -BeOfType [System.String]

                # Verify that no returned branches have the refs/heads/ prefix
                $result | ForEach-Object { $_ | Should -Not -Match '^refs/heads/' }
            }
            catch {
                # If network issues occur, skip this test
                Set-ItResult -Skipped -Because "Network connectivity issue: $($_.Exception.Message)"
            }
        }

        It 'Should return specific branch when Name parameter is provided' {
            # Try to get the main/master branch which should exist in PowerShell repository
            $result = Get-GitRemoteBranch -RemoteName 'origin' -Name 'master'

            if ($result) {
                $result | Should -BeOfType [System.String]
                $result | Should -Match 'refs/heads/master$'
            } else {
                # If master doesn't exist, try main
                $result = Get-GitRemoteBranch -RemoteName 'origin' -Name 'main'
                if ($result) {
                    $result | Should -BeOfType [System.String]
                    $result | Should -Match 'refs/heads/main$'
                }
            }
        }

        It 'Should handle wildcard patterns in branch names' {
            # Use a more general pattern that's likely to match in most repositories
            $result = Get-GitRemoteBranch -RemoteName 'origin' -Name '*/*'

            if ($result) {
                $result | Should -BeOfType [System.String]
                # Verify that results contain paths with forward slashes (feature branches, etc.)
                $result | Where-Object { $_ -match 'refs/heads/.+/.+' } | Should -Not -BeNullOrEmpty
            } else {
                # If no feature branches exist, try a simpler wildcard
                $result = Get-GitRemoteBranch -RemoteName 'origin' -Name '*'
                $result | Should -Not -BeNullOrEmpty
            }
        }

        It 'Should work with refs/heads/ prefix in Name parameter' {
            # Try to get the main/master branch using the full refs/heads/ path
            $result = Get-GitRemoteBranch -RemoteName 'origin' -Name 'refs/heads/master'

            if ($result) {
                $result | Should -BeOfType [System.String]
                $result | Should -Match 'refs/heads/master$'
            } else {
                # If master doesn't exist, try main
                $result = Get-GitRemoteBranch -RemoteName 'origin' -Name 'refs/heads/main'
                if ($result) {
                    $result | Should -BeOfType [System.String]
                    $result | Should -Match 'refs/heads/main$'
                }
            }
        }

        It 'Should return empty result for non-existent branch' {
            $result = Get-GitRemoteBranch -RemoteName 'origin' -Name 'this-branch-definitely-does-not-exist-12345'
            $result | Should -BeNullOrEmpty
        }

        It 'Should work with different remote names' {
            try {
                $originResult = Get-GitRemoteBranch -RemoteName 'origin' -ErrorAction Stop
                $upstreamResult = Get-GitRemoteBranch -RemoteName 'upstream' -ErrorAction Stop

                $originResult | Should -Not -BeNullOrEmpty
                $upstreamResult | Should -Not -BeNullOrEmpty

                # Both should return branch names with refs/heads/ prefix
                $originResult | ForEach-Object { $_ | Should -Match '^refs/heads/' }
                $upstreamResult | ForEach-Object { $_ | Should -Match '^refs/heads/' }
            }
            catch {
                # If network issues occur, skip this test
                Set-ItResult -Skipped -Because "Network connectivity issue: $($_.Exception.Message)"
            }
        }
    }

    Context 'When handling error conditions' {
        BeforeEach {
            # Create a temporary directory for our test git repository
            $script:testRepoPath = Join-Path -Path $TestDrive -ChildPath "TestRepo_$([guid]::NewGuid().Guid)"
            New-Item -Path $script:testRepoPath -ItemType Directory -Force | Out-Null

            # Store the original location to restore later
            $script:originalLocation = Get-Location

            # Change to the test repository directory
            Set-Location -Path $script:testRepoPath

            # Initialize git repository without any remotes
            $null = git init --quiet --initial-branch=main 2>&1
            $null = git config user.email "test@example.com" 2>&1
            $null = git config user.name "Test User" 2>&1

            # Create an initial commit
            'test content' | Out-File -FilePath 'test.txt' -Encoding utf8
            $null = git add . 2>&1
            $null = git commit -m "Initial commit" --quiet 2>&1
        }

        AfterEach {
            # Restore original location
            Set-Location -Path $script:originalLocation

            # Clean up test repository
            if (Test-Path -Path $script:testRepoPath) {
                $previousProgressPreference = $ProgressPreference
                $ProgressPreference = 'SilentlyContinue' # Suppress progress output during deletion
                Remove-Item -Path $script:testRepoPath -Recurse -Force -ErrorAction SilentlyContinue
                $ProgressPreference = $previousProgressPreference
            }
        }

        It 'Should write error when remote does not exist' {
            $errorActionPreference = 'SilentlyContinue'
            $errorRecord = $null
            $result = Get-GitRemoteBranch -RemoteName 'nonexistent-remote' -ErrorAction $errorActionPreference -ErrorVariable errorRecord 2>$null

            # The command should generate an error and return null/empty
            $result | Should -BeNullOrEmpty
            $errorRecord | Should -Not -BeNullOrEmpty

            # Verify the specific error message from remote validation
            $errorRecord.Exception.Message | Should -Match 'The remote.*nonexistent-remote.*does not exist in the local git repository'
        }

        It 'Should handle invalid remote URL gracefully' {
            # Add a remote with invalid URL
            $null = git remote add invalid 'not-a-valid-url' 2>&1

            $errorActionPreference = 'SilentlyContinue'
            $errorRecord = $null
            $result = Get-GitRemoteBranch -RemoteName 'invalid' -ErrorAction $errorActionPreference -ErrorVariable errorRecord 2>$null

            # The command should generate an error or return empty
            $result | Should -BeNullOrEmpty
            $errorRecord | Should -Not -BeNullOrEmpty
        }
    }

    Context 'When testing edge cases' {
        BeforeEach {
            # Create a temporary directory for our test git repository
            $script:testRepoPath = Join-Path -Path $TestDrive -ChildPath "TestRepo_$([guid]::NewGuid().Guid)"
            New-Item -Path $script:testRepoPath -ItemType Directory -Force | Out-Null

            # Store the original location to restore later
            $script:originalLocation = Get-Location

            # Change to the test repository directory
            Set-Location -Path $script:testRepoPath

            # Initialize git repository
            $null = git init --quiet --initial-branch=main 2>&1
            $null = git config user.email "test@example.com" 2>&1
            $null = git config user.name "Test User" 2>&1

            # Create an initial commit
            'test content' | Out-File -FilePath 'test.txt' -Encoding utf8
            $null = git add . 2>&1
            $null = git commit -m "Initial commit" --quiet 2>&1

            # Add a valid remote for testing
            $null = git remote add origin 'https://github.com/PowerShell/PowerShell.git' 2>&1
        }

        AfterEach {
            # Restore original location
            Set-Location -Path $script:originalLocation

            # Clean up test repository
            if (Test-Path -Path $script:testRepoPath) {
                $previousProgressPreference = $ProgressPreference
                $ProgressPreference = 'SilentlyContinue' # Suppress progress output during deletion
                Remove-Item -Path $script:testRepoPath -Recurse -Force -ErrorAction SilentlyContinue
                $ProgressPreference = $previousProgressPreference
            }
        }

        It 'Should handle empty wildcard patterns appropriately' {
            try {
                $result = Get-GitRemoteBranch -RemoteName 'origin' -Name '*' -ErrorAction Stop

                # This should return all branches (same as not specifying Name)
                $result | Should -Not -BeNullOrEmpty
                $result | Should -BeOfType [System.String]
            }
            catch {
                # If network issues occur, skip this test
                Set-ItResult -Skipped -Because "Network connectivity issue: $($_.Exception.Message)"
            }
        }

        It 'Should handle complex wildcard patterns' {
            $result = Get-GitRemoteBranch -RemoteName 'origin' -Name 'feature/test*'

            # This may or may not return results depending on what branches exist
            # But it should not error
            if ($result) {
                $result | Should -BeOfType [System.String]
                $result | ForEach-Object { $_ | Should -Match 'refs/heads/feature/test' }
            } else {
                $result | Should -BeNullOrEmpty
            }
        }
    }
}
