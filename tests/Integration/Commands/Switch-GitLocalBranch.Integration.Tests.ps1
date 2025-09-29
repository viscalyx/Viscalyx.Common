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

Describe 'Switch-GitLocalBranch' -Tag 'Integration' {
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

            # Create an initial commit
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

            # Switch back to main branch
            & git checkout main --quiet
        }
        catch
        {
            throw "Failed to setup test git repository: $($_.Exception.Message)"
        }
        finally
        {
            Pop-Location
        }
    }

    BeforeEach {
        # Change to the test repository directory for each test
        Push-Location -Path $script:testRepoPath

        # Ensure we're on the main branch before each test
        & git checkout main --quiet
    }

    AfterEach {
        # Return to original location after each test
        try
        {
            Pop-Location
        }
        catch
        {
            # Ignore if we're already at the original location
        }
    }

    AfterAll {
        # Clean up and return to original location
        try
        {
            if (Get-Location | Where-Object { $_.Path -eq $script:testRepoPath })
            {
                Pop-Location
            }
            Set-Location -Path $script:originalLocation
        }
        catch
        {
            # Ignore cleanup errors
        }
    }

    Context 'When switching to an existing branch' {
        It 'Should successfully switch to feature branch' {
            # Verify we're on the main branch first
            $currentBranch = & git branch --show-current
            $currentBranch | Should -Be 'main'

            # Switch to feature branch
            $null = Switch-GitLocalBranch -Name 'feature/test-branch' -Force -ErrorAction Stop

            # Verify we switched branches
            $newBranch = & git branch --show-current
            $newBranch | Should -Be 'feature/test-branch'
        }

        It 'Should successfully switch back to default branch' {
            # First switch to feature branch
            & git checkout 'feature/test-branch' --quiet
            $currentBranch = & git branch --show-current
            $currentBranch | Should -Be 'feature/test-branch'

            # Switch back to main branch (we know it's main since we set it explicitly)
            $null = Switch-GitLocalBranch -Name 'main' -Force -ErrorAction Stop

            # Verify we switched branches
            $newBranch = & git branch --show-current
            $newBranch | Should -Be 'main'
        }
    }

    Context 'When switching to a non-existent branch' {
        It 'Should throw an error when trying to switch to non-existent branch' {
            $nonExistentBranch = 'non-existent-branch'

            {
                Switch-GitLocalBranch -Name $nonExistentBranch -Force -ErrorAction Stop
            } | Should -Throw
        }
    }

    Context 'When there are uncommitted changes' {
        It 'Should throw an error when there are staged changes' {
            # Create and stage a change
            Set-Content -Path (Join-Path -Path $script:testRepoPath -ChildPath 'test.txt') -Value 'Test content'
            & git add test.txt

            {
                Switch-GitLocalBranch -Name 'feature/test-branch' -Force -ErrorAction Stop
            } | Should -Throw

            # Clean up
            & git reset --hard HEAD --quiet
            Remove-Item -Path (Join-Path -Path $script:testRepoPath -ChildPath 'test.txt') -Force -ErrorAction SilentlyContinue
        }

        It 'Should throw an error when there are unstaged changes' {
            # Create an unstaged change
            Set-Content -Path (Join-Path -Path $script:testRepoPath -ChildPath 'README.md') -Value '# Modified README'

            {
                Switch-GitLocalBranch -Name 'feature/test-branch' -Force -ErrorAction Stop
            } | Should -Throw

            # Clean up
            & git checkout -- README.md
        }
    }

    Context 'When using WhatIf parameter' {
        It 'Should not switch branches when WhatIf is used' {
            # Get current branch
            $originalBranch = & git branch --show-current

            # Run with WhatIf
            $null = Switch-GitLocalBranch -Name 'feature/test-branch' -WhatIf

            # Verify we're still on the original branch
            $currentBranch = & git branch --show-current
            $currentBranch | Should -Be $originalBranch
        }
    }

    Context 'When testing ShouldProcess with Confirm parameter' {
        It 'Should switch branches when Force is used to bypass confirmation' {
            # Get current branch
            $originalBranch = & git branch --show-current

            # Force bypasses confirmation and switches the branch
            $null = Switch-GitLocalBranch -Name 'feature/test-branch' -Force -ErrorAction Stop

            # Verify the branch was switched
            $currentBranch = & git branch --show-current
            $currentBranch | Should -Be 'feature/test-branch'

            # Switch back for cleanup
            & git checkout $originalBranch --quiet
        }
    }
}
