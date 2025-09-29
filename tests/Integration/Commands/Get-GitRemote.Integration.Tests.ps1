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

Describe 'Get-GitRemote' -Tag 'Integration' {
    Context 'When repository has a remote configured' {
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

            # Add test remotes
            $null = git remote add origin 'https://github.com/test/repo.git' 2>&1
            $null = git remote add upstream 'https://github.com/upstream/repo.git' 2>&1
            $null = git remote set-url --push origin 'git@github.com:test/repo.git' 2>&1
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

        It 'Should return all remote names when no parameters specified' {
            $result = Get-GitRemote -ErrorAction Stop
            $result | Should -Contain 'origin'
            $result | Should -Contain 'upstream'
            $result.Count | Should -Be 2
        }

        It 'Should return specific remote name when Name parameter is provided and remote exists' {
            $result = Get-GitRemote -Name 'origin' -ErrorAction Stop
            $result | Should -Be 'origin'
        }

        It 'Should return empty when Name parameter is provided and remote does not exist' {
            $result = Get-GitRemote -Name 'nonexistent' -ErrorAction Stop
            $result | Should -BeNullOrEmpty
        }

        It 'Should return fetch URL when FetchUrl switch is specified' {
            $result = Get-GitRemote -Name 'origin' -FetchUrl -ErrorAction Stop
            $result | Should -Be 'https://github.com/test/repo.git'
        }

        It 'Should return push URL when PushUrl switch is specified' {
            $result = Get-GitRemote -Name 'origin' -PushUrl -ErrorAction Stop
            $result | Should -Be 'git@github.com:test/repo.git'
        }

        It 'Should return fetch URL when push URL is not specifically set' {
            $result = Get-GitRemote -Name 'upstream' -PushUrl -ErrorAction Stop
            $result | Should -Be 'https://github.com/upstream/repo.git'
        }

        It 'Should throw error when trying to get URL for non-existent remote' {
            { Get-GitRemote -Name 'nonexistent' -FetchUrl -ErrorAction Stop 2> $null } | Should -Throw
        }

        It 'Should throw error when trying to get push URL for non-existent remote' {
            { Get-GitRemote -Name 'nonexistent' -PushUrl -ErrorAction Stop 2> $null } | Should -Throw
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
            $null = git init --quiet --initial-branch=main 2>&1
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

        It 'Should return empty array when no remotes exist' {
            $result = Get-GitRemote -ErrorAction Stop
            $result | Should -BeNullOrEmpty
        }

        It 'Should return empty when searching for specific remote name' {
            $result = Get-GitRemote -Name 'origin' -ErrorAction Stop
            $result | Should -BeNullOrEmpty
        }

        It 'Should throw error when trying to get URL for any remote' {
            { Get-GitRemote -Name 'origin' -FetchUrl -ErrorAction Stop 2> $null } | Should -Throw
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

        It 'Should throw error when getting all remotes outside git repository' {
            { Get-GitRemote -ErrorAction Stop 2> $null } | Should -Throw
        }

        It 'Should throw error when getting specific remote outside git repository' {
            { Get-GitRemote -Name 'origin' -ErrorAction Stop 2> $null } | Should -Throw
        }

        It 'Should throw error when getting fetch URL outside git repository' {
            { Get-GitRemote -Name 'origin' -FetchUrl -ErrorAction Stop 2> $null } | Should -Throw
        }

        It 'Should throw error when getting push URL outside git repository' {
            { Get-GitRemote -Name 'origin' -PushUrl -ErrorAction Stop 2> $null } | Should -Throw
        }
    }
}
