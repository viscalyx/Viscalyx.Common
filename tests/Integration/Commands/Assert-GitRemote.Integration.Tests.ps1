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

Describe 'Assert-GitRemote' -Tag 'Integration' {
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
            $null = git config user.email 'test@example.com' 2>&1
            $null = git config user.name 'Test User' 2>&1

            # Create an initial commit to establish a proper git repository
            'Initial content' | Out-File -FilePath 'README.md' -Encoding utf8
            $null = git add README.md 2>&1
            $null = git commit -m 'Initial commit' --quiet 2>&1

            # Add a test remote
            $null = git remote add origin 'https://github.com/test/repo.git' 2>&1
        }

        AfterEach {
            # Restore the original location
            Set-Location -Path $script:originalLocation
        }

        It 'Should not throw an exception when the remote exists' {
            $null = Assert-GitRemote -Name 'origin'
        }
    }

    Context 'When repository does not have the specified remote configured' {
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
            $null = git config user.email 'test@example.com' 2>&1
            $null = git config user.name 'Test User' 2>&1

            # Create an initial commit to establish a proper git repository
            'Initial content' | Out-File -FilePath 'README.md' -Encoding utf8
            $null = git add README.md 2>&1
            $null = git commit -m 'Initial commit' --quiet 2>&1

            # Note: No remote is added in this test scenario
        }

        AfterEach {
            # Restore the original location
            Set-Location -Path $script:originalLocation
        }

        It 'Should throw an exception when the remote does not exist' {
            { Assert-GitRemote -Name 'origin' -ErrorAction Stop } | Should -Throw
        }
    }

    Context 'When repository has multiple remotes configured' {
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
            $null = git config user.email 'test@example.com' 2>&1
            $null = git config user.name 'Test User' 2>&1

            # Create an initial commit to establish a proper git repository
            'Initial content' | Out-File -FilePath 'README.md' -Encoding utf8
            $null = git add README.md 2>&1
            $null = git commit -m 'Initial commit' --quiet 2>&1

            # Add multiple test remotes
            $null = git remote add origin 'https://github.com/test/repo.git' 2>&1
            $null = git remote add upstream 'https://github.com/upstream/repo.git' 2>&1
            $null = git remote add fork 'https://github.com/fork/repo.git' 2>&1
        }

        AfterEach {
            # Restore the original location
            Set-Location -Path $script:originalLocation
        }

        It 'Should not throw an exception when checking existing remote <RemoteName>' -ForEach @(
            @{ RemoteName = 'origin' }
            @{ RemoteName = 'upstream' }
            @{ RemoteName = 'fork' }
        ) {
            Assert-GitRemote -Name $RemoteName -ErrorAction Stop
        }

        It 'Should throw an exception when checking non-existing remote' {
            { Assert-GitRemote -Name 'nonexistent' -ErrorAction Stop } | Should -Throw
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
            # Restore the original location
            Set-Location -Path $script:originalLocation
        }

        It 'Should throw an exception when not in a git repository' {
            { Assert-GitRemote -Name 'origin' -ErrorAction Stop } | Should -Throw
        }
    }
}
