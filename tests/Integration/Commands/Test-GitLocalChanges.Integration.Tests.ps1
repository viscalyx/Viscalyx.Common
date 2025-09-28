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

Describe 'Test-GitLocalChanges' -Tag 'Integration' {
    Context 'When repository has no local changes' {
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
            'Initial content' | Out-File -FilePath 'README.md' -Encoding utf8
            $null = git add README.md 2>&1
            $null = git commit -m "Initial commit" --quiet 2>&1
        }

        AfterEach {
            # Restore the original location
            Set-Location -Path $script:originalLocation

            # Clean up the test repository
            if (Test-Path -Path $script:testRepoPath)
            {
                $previousProgressPreference = $ProgressPreference
                $ProgressPreference = 'SilentlyContinue' # Suppress progress output during deletion
                Remove-Item -Path $script:testRepoPath -Recurse -Force
                $ProgressPreference = $previousProgressPreference
            }
        }

        It 'Should return false when repository has no changes' {
            $result = Test-GitLocalChanges -ErrorAction Stop

            $result | Should -Be $false
        }
    }

    Context 'When repository has unstaged changes' {
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
            'Initial content' | Out-File -FilePath 'README.md' -Encoding utf8
            $null = git add README.md 2>&1
            $null = git commit -m "Initial commit" --quiet 2>&1

            # Make changes to the file to create unstaged changes
            'Modified content' | Out-File -FilePath 'README.md' -Encoding utf8
        }

        AfterEach {
            # Restore the original location
            Set-Location -Path $script:originalLocation

            # Clean up the test repository
            if (Test-Path -Path $script:testRepoPath)
            {
                $previousProgressPreference = $ProgressPreference
                $ProgressPreference = 'SilentlyContinue' # Suppress progress output during deletion
                Remove-Item -Path $script:testRepoPath -Recurse -Force
                $ProgressPreference = $previousProgressPreference
            }
        }

        It 'Should return true when repository has unstaged changes' {
            $result = Test-GitLocalChanges -ErrorAction Stop

            $result | Should -Be $true
        }
    }

    Context 'When repository has staged changes' {
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
            'Initial content' | Out-File -FilePath 'README.md' -Encoding utf8
            $null = git add README.md 2>&1
            $null = git commit -m "Initial commit" --quiet 2>&1

            # Create a new file and stage it
            'New file content' | Out-File -FilePath 'newfile.txt' -Encoding utf8
            $null = git add newfile.txt 2>&1
        }

        AfterEach {
            # Restore the original location
            Set-Location -Path $script:originalLocation

            # Clean up the test repository
            if (Test-Path -Path $script:testRepoPath)
            {
                $previousProgressPreference = $ProgressPreference
                $ProgressPreference = 'SilentlyContinue' # Suppress progress output during deletion
                Remove-Item -Path $script:testRepoPath -Recurse -Force
                $ProgressPreference = $previousProgressPreference
            }
        }

        It 'Should return true when repository has staged changes' {
            $result = Test-GitLocalChanges -ErrorAction Stop

            $result | Should -Be $true
        }
    }

    Context 'When repository has both staged and unstaged changes' {
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
            'Initial content' | Out-File -FilePath 'README.md' -Encoding utf8
            $null = git add README.md 2>&1
            $null = git commit -m "Initial commit" --quiet 2>&1

            # Create staged changes
            'Staged file content' | Out-File -FilePath 'staged.txt' -Encoding utf8
            $null = git add staged.txt 2>&1

            # Create unstaged changes
            'Modified content' | Out-File -FilePath 'README.md' -Encoding utf8
        }

        AfterEach {
            # Restore the original location
            Set-Location -Path $script:originalLocation

            # Clean up the test repository
            if (Test-Path -Path $script:testRepoPath)
            {
                $previousProgressPreference = $ProgressPreference
                $ProgressPreference = 'SilentlyContinue' # Suppress progress output during deletion
                Remove-Item -Path $script:testRepoPath -Recurse -Force
                $ProgressPreference = $previousProgressPreference
            }
        }

        It 'Should return true when repository has both staged and unstaged changes' {
            $result = Test-GitLocalChanges -ErrorAction Stop

            $result | Should -Be $true
        }
    }

    Context 'When not in a git repository' {
        BeforeEach {
            # Create a temporary directory that is not a git repository
            $script:testPath = Join-Path -Path $TestDrive -ChildPath "NonGitDir_$([guid]::NewGuid().Guid)"
            New-Item -Path $script:testPath -ItemType Directory -Force | Out-Null

            # Store the original location to restore later
            $script:originalLocation = Get-Location

            # Change to the non-git directory
            Set-Location -Path $script:testPath
        }

        AfterEach {
            # Restore the original location
            Set-Location -Path $script:originalLocation

            # Clean up the test directory
            if (Test-Path -Path $script:testPath)
            {
                $previousProgressPreference = $ProgressPreference
                $ProgressPreference = 'SilentlyContinue' # Suppress progress output during deletion
                Remove-Item -Path $script:testPath -Recurse -Force
                $ProgressPreference = $previousProgressPreference
            }
        }

        It 'Should handle non-git directories gracefully' {
            # This test verifies the command handles git errors properly
            # The actual behavior depends on how git responds to --porcelain in non-git directories
            { Test-GitLocalChanges -ErrorAction Stop 2>$null } | Should -Not -Throw
        }
    }
}
