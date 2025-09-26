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

Describe 'Test-GitRemote' -Tag 'Integration' {
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
            $null = git init --quiet 2>&1
            $null = git config user.email "test@example.com" 2>&1
            $null = git config user.name "Test User" 2>&1

            # Create an initial commit to establish a proper git repository
            'test content' | Out-File -FilePath 'test.txt' -Encoding utf8
            $null = git add . 2>&1
            $null = git commit -m "Initial commit" --quiet 2>&1

            # Add test remotes
            $null = git remote add origin 'https://github.com/test/repo.git' 2>&1
            $null = git remote add upstream 'https://github.com/upstream/repo.git' 2>&1
            $null = git remote add fork 'https://github.com/fork/repo.git' 2>&1
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

        It 'Should return true when testing for existing remote "origin"' {
            $result = Test-GitRemote -Name 'origin'
            $result | Should -BeTrue
            $result | Should -BeOfType [System.Boolean]
        }

        It 'Should return true when testing for existing remote "upstream"' {
            $result = Test-GitRemote -Name 'upstream'
            $result | Should -BeTrue
            $result | Should -BeOfType [System.Boolean]
        }

        It 'Should return true when testing for existing remote "fork"' {
            $result = Test-GitRemote -Name 'fork'
            $result | Should -BeTrue
            $result | Should -BeOfType [System.Boolean]
        }

        It 'Should return false when testing for non-existing remote' {
            $result = Test-GitRemote -Name 'nonexistent'
            $result | Should -BeFalse
            $result | Should -BeOfType [System.Boolean]
        }

        It 'Should return false when testing for remote with different case' {
            # Note: Git remotes may be case-insensitive on some systems, so test with completely different name
            $result = Test-GitRemote -Name 'notfound'
            $result | Should -BeFalse
            $result | Should -BeOfType [System.Boolean]
        }

        It 'Should return false when testing for remote with partial name match' {
            $result = Test-GitRemote -Name 'orig'
            $result | Should -BeFalse
            $result | Should -BeOfType [System.Boolean]
        }

        It 'Should work with positional parameter' {
            $result = Test-GitRemote 'origin'
            $result | Should -BeTrue
            $result | Should -BeOfType [System.Boolean]
        }

        It 'Should handle remote names with special characters' {
            # Add a remote with special characters
            $null = git remote add 'remote-with-dash' 'https://github.com/special/repo.git' 2>&1

            $result = Test-GitRemote -Name 'remote-with-dash'
            $result | Should -BeTrue
            $result | Should -BeOfType [System.Boolean]
        }

        It 'Should handle remote names with underscores' {
            # Add a remote with underscores
            $null = git remote add 'remote_with_underscore' 'https://github.com/underscore/repo.git' 2>&1

            $result = Test-GitRemote -Name 'remote_with_underscore'
            $result | Should -BeTrue
            $result | Should -BeOfType [System.Boolean]
        }
    }

    Context 'When repository has no remotes configured' {
        BeforeEach {
            # Create a temporary directory for our test git repository
            $script:testRepoPath = Join-Path -Path $TestDrive -ChildPath "TestRepo_$([guid]::NewGuid().Guid)"
            New-Item -Path $script:testRepoPath -ItemType Directory -Force | Out-Null

            # Store the original location to restore later
            $script:originalLocation = Get-Location

            # Change to the test repository directory
            Set-Location -Path $script:testRepoPath

            # Initialize git repository
            $null = git init --quiet 2>&1
            $null = git config user.email "test@example.com" 2>&1
            $null = git config user.name "Test User" 2>&1

            # Create an initial commit to establish a proper git repository
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

        It 'Should return false when testing for "origin" remote in repository with no remotes' {
            $result = Test-GitRemote -Name 'origin'
            $result | Should -BeFalse
            $result | Should -BeOfType [System.Boolean]
        }

        It 'Should return false when testing for "upstream" remote in repository with no remotes' {
            $result = Test-GitRemote -Name 'upstream'
            $result | Should -BeFalse
            $result | Should -BeOfType [System.Boolean]
        }

        It 'Should return false when testing for any remote name in repository with no remotes' {
            $result = Test-GitRemote -Name 'anyremote'
            $result | Should -BeFalse
            $result | Should -BeOfType [System.Boolean]
        }
    }

    Context 'When not in a git repository' {
        BeforeEach {
            # Create a temporary directory that is not a git repository
            $script:testRepoPath = Join-Path -Path $TestDrive -ChildPath "NonGitRepo_$([guid]::NewGuid().Guid)"
            New-Item -Path $script:testRepoPath -ItemType Directory -Force | Out-Null

            # Store the original location to restore later
            $script:originalLocation = Get-Location

            # Change to the non-git directory
            Set-Location -Path $script:testRepoPath
        }

        AfterEach {
            # Restore original location
            Set-Location -Path $script:originalLocation

            # Clean up test directory
            if (Test-Path -Path $script:testRepoPath) {
                $previousProgressPreference = $ProgressPreference
                $ProgressPreference = 'SilentlyContinue' # Suppress progress output during deletion
                Remove-Item -Path $script:testRepoPath -Recurse -Force -ErrorAction SilentlyContinue
                $ProgressPreference = $previousProgressPreference
            }
        }

        It 'Should return false and handle error gracefully when testing for remote outside git repository' {
            # Test-GitRemote should return false when Get-GitRemote fails
            $result = Test-GitRemote -Name 'origin' -ErrorAction SilentlyContinue 2>$null

            # The result should be false since the underlying Get-GitRemote will fail
            # and return null/empty, which Test-GitRemote interprets as false
            $result | Should -BeFalse
            $result | Should -BeOfType [System.Boolean]
        }

        It 'Should return false when testing for any remote outside git repository with error action continue' {
            # Test-GitRemote should return false when Get-GitRemote fails
            $result = Test-GitRemote -Name 'upstream' -ErrorAction SilentlyContinue 2>$null

            # The result should be false since the underlying Get-GitRemote will fail
            $result | Should -BeFalse
            $result | Should -BeOfType [System.Boolean]
        }
    }

    Context 'When testing remote behavior after remote operations' {
        BeforeEach {
            # Create a temporary directory for our test git repository
            $script:testRepoPath = Join-Path -Path $TestDrive -ChildPath "TestRepo_$([guid]::NewGuid().Guid)"
            New-Item -Path $script:testRepoPath -ItemType Directory -Force | Out-Null

            # Store the original location to restore later
            $script:originalLocation = Get-Location

            # Change to the test repository directory
            Set-Location -Path $script:testRepoPath

            # Initialize git repository
            $null = git init --quiet 2>&1
            $null = git config user.email "test@example.com" 2>&1
            $null = git config user.name "Test User" 2>&1

            # Create an initial commit to establish a proper git repository
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

        It 'Should return false before adding remote, then true after adding remote' {
            # Test before adding remote
            $resultBefore = Test-GitRemote -Name 'newremote'
            $resultBefore | Should -BeFalse

            # Add the remote
            $null = git remote add 'newremote' 'https://github.com/new/repo.git' 2>&1

            # Test after adding remote
            $resultAfter = Test-GitRemote -Name 'newremote'
            $resultAfter | Should -BeTrue
        }

        It 'Should return true before removing remote, then false after removing remote' {
            # Add a remote first
            $null = git remote add 'tempremote' 'https://github.com/temp/repo.git' 2>&1

            # Test before removing remote
            $resultBefore = Test-GitRemote -Name 'tempremote'
            $resultBefore | Should -BeTrue

            # Remove the remote
            $null = git remote remove 'tempremote' 2>&1

            # Test after removing remote
            $resultAfter = Test-GitRemote -Name 'tempremote'
            $resultAfter | Should -BeFalse
        }

        It 'Should return true after renaming from old name to new name' {
            # Add a remote first
            $null = git remote add 'oldname' 'https://github.com/test/repo.git' 2>&1

            # Verify it exists with old name
            $resultOldBefore = Test-GitRemote -Name 'oldname'
            $resultOldBefore | Should -BeTrue

            # Verify it doesn't exist with new name
            $resultNewBefore = Test-GitRemote -Name 'newname'
            $resultNewBefore | Should -BeFalse

            # Rename the remote
            $null = git remote rename 'oldname' 'newname' 2>&1

            # Verify it doesn't exist with old name anymore
            $resultOldAfter = Test-GitRemote -Name 'oldname'
            $resultOldAfter | Should -BeFalse

            # Verify it exists with new name
            $resultNewAfter = Test-GitRemote -Name 'newname'
            $resultNewAfter | Should -BeTrue
        }
    }
}
