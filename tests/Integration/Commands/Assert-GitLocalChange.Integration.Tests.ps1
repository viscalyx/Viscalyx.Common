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

Describe 'Assert-GitLocalChange' -Tag 'Integration' {
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
            $null = git init --quiet 2>&1
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
        }

        It 'Should not throw when repository is clean' {
            { Assert-GitLocalChange -ErrorAction Stop } | Should -Not -Throw
        }

        It 'Should not throw when all changes are committed' {
            # Make a change and commit it
            'New content' | Add-Content -Path 'README.md' -Encoding utf8
            $null = git add README.md 2>&1
            $null = git commit -m "Add new content" --quiet 2>&1

            { Assert-GitLocalChange -ErrorAction Stop } | Should -Not -Throw
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
            $null = git init --quiet 2>&1
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
        }

        It 'Should throw when there are unstaged changes to tracked files' {
            # Modify an existing file without staging
            'Modified content' | Add-Content -Path 'README.md' -Encoding utf8

            { Assert-GitLocalChange -ErrorAction Stop } | Should -Throw
        }

        It 'Should throw when there are untracked files' {
            # Create a new untracked file
            'New file content' | Out-File -FilePath 'newfile.txt' -Encoding utf8

            { Assert-GitLocalChange -ErrorAction Stop } | Should -Throw
        }

        It 'Should throw when there are deleted files' {
            # Delete an existing file
            Remove-Item -Path 'README.md' -Force

            { Assert-GitLocalChange -ErrorAction Stop } | Should -Throw
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
            $null = git init --quiet 2>&1
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
        }

        It 'Should throw when there are staged changes' {
            # Modify a file and stage it
            'Staged content' | Add-Content -Path 'README.md' -Encoding utf8
            $null = git add README.md 2>&1

            { Assert-GitLocalChange -ErrorAction Stop } | Should -Throw
        }

        It 'Should throw when there are new files staged for commit' {
            # Create and stage a new file
            'New staged file' | Out-File -FilePath 'staged.txt' -Encoding utf8
            $null = git add staged.txt 2>&1

            { Assert-GitLocalChange -ErrorAction Stop } | Should -Throw
        }

        It 'Should throw when there are staged deletions' {
            # Stage deletion of an existing file
            $null = git rm README.md --quiet 2>&1

            { Assert-GitLocalChange -ErrorAction Stop } | Should -Throw
        }
    }

    Context 'When repository has mixed staged and unstaged changes' {
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
            'Initial content' | Out-File -FilePath 'README.md' -Encoding utf8
            $null = git add README.md 2>&1
            $null = git commit -m "Initial commit" --quiet 2>&1
        }

        AfterEach {
            # Restore the original location
            Set-Location -Path $script:originalLocation
        }

        It 'Should throw when there are both staged and unstaged changes' {
            # Create a new file and stage it
            'Staged file' | Out-File -FilePath 'staged.txt' -Encoding utf8
            $null = git add staged.txt 2>&1

            # Create another unstaged file
            'Unstaged file' | Out-File -FilePath 'unstaged.txt' -Encoding utf8

            { Assert-GitLocalChange -ErrorAction Stop } | Should -Throw
        }

        It 'Should throw when a file has both staged and unstaged changes' {
            # Modify README.md and stage it
            'Staged modification' | Add-Content -Path 'README.md' -Encoding utf8
            $null = git add README.md 2>&1

            # Make another modification to the same file (unstaged)
            'Unstaged modification' | Add-Content -Path 'README.md' -Encoding utf8

            { Assert-GitLocalChange -ErrorAction Stop } | Should -Throw
        }
    }
}