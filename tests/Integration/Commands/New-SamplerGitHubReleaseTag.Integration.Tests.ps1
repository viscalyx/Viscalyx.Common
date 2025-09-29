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

Describe 'New-SamplerGitHubReleaseTag' -Tag 'Integration' {
    BeforeAll {
        # Store original location
        $script:originalLocation = Get-Location

        # Create a temporary directory for our test repository
        $script:testRepoPath = Join-Path -Path $TestDrive -ChildPath 'TestSamplerRepo'
        $null = New-Item -Path $script:testRepoPath -ItemType Directory -Force

        # Initialize a git repository with proper setup
        Push-Location -Path $script:testRepoPath
        try
        {
            & git init --quiet --initial-branch=main 2>$null
            if ($LASTEXITCODE -ne 0)
            {
                # Fallback for older git versions
                & git init --quiet --initial-branch=main
                & git checkout -b main --quiet 2>$null
            }
            & git config user.name 'Test User'
            & git config user.email 'test@example.com'

            # Create an initial commit
            $null = New-Item -Path (Join-Path -Path $script:testRepoPath -ChildPath 'README.md') -ItemType File -Force
            Set-Content -Path (Join-Path -Path $script:testRepoPath -ChildPath 'README.md') -Value '# Test Sampler Repository'
            & git add README.md
            & git commit -m 'Initial commit' --quiet

            # Create a preview tag to simulate a Sampler project state
            & git tag 'v1.0.0-preview0001'
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

        # Clean up any release tags before each test (but keep preview tags)
        try
        {
            $tags = & git tag 2>$null | Where-Object { $_ -match '^v\d+\.\d+\.\d+$' }
            if ($tags)
            {
                foreach ($tag in $tags)
                {
                    & git tag -d $tag 2>$null | Out-Null
                }
            }
        }
        catch
        {
            # Ignore cleanup errors
        }
    }

    AfterEach {
        # Clean up any release tags created during testing
        try
        {
            $tags = & git tag 2>$null | Where-Object { $_ -match '^v\d+\.\d+\.\d+$' }
            if ($tags)
            {
                foreach ($tag in $tags)
                {
                    & git tag -d $tag 2>$null | Out-Null
                }
            }
        }
        catch
        {
            # Ignore cleanup errors
        }

        # Return to original location
        try
        {
            Pop-Location
        }
        catch
        {
            # Ignore location errors
        }
    }

    Context 'When creating a release tag with existing preview tag' {
        BeforeEach {
            # Add a remote origin for this specific test
            if ($PSVersionTable.PSEdition -eq 'Desktop')
            {
                # Windows PowerShell - use cmd.exe for reliable output suppression
                & cmd.exe /c "git remote add origin file://$script:testRepoPath/.git >nul 2>&1"
            }
            else
            {
                # PowerShell 7+ - capture output in variables
                $gitOutput = & git remote add origin "file://$script:testRepoPath/.git" 2>&1
            }
        }

        AfterEach {
            # Remove remote after test
            if ($PSVersionTable.PSEdition -eq 'Desktop')
            {
                # Windows PowerShell - use cmd.exe for reliable output suppression
                & cmd.exe /c 'git remote remove origin >nul 2>&1'
            }
            else
            {
                # PowerShell 7+ - capture output in variables
                $gitOutput = & git remote remove origin 2>&1
            }
        }

        It 'Should create a release tag from preview tag automatically' {
            # This should extract version from v1.0.0-preview0001 and create v1.0.0
            $null = New-SamplerGitHubReleaseTag -Force -ErrorAction Stop

            # Verify the release tag was created
            $tags = & git tag
            $tags | Should -Contain 'v1.0.0'
        }

        It 'Should create a specified release tag' {
            $null = New-SamplerGitHubReleaseTag -ReleaseTag 'v1.1.0' -Force -ErrorAction Stop

            # Verify the specified tag was created
            $tags = & git tag
            $tags | Should -Contain 'v1.1.0'
        }
    }

    Context 'When using ShouldProcess functionality' {
        BeforeEach {
            # Add a local remote for this specific test
            if ($PSVersionTable.PSEdition -eq 'Desktop')
            {
                # Windows PowerShell - use cmd.exe for reliable output suppression
                & cmd.exe /c "git remote add origin file://$script:testRepoPath/.git >nul 2>&1"
            }
            else
            {
                # PowerShell 7+ - capture output in variables
                $gitOutput = & git remote add origin "file://$script:testRepoPath/.git" 2>&1
            }
        }

        AfterEach {
            # Remove remote after test
            if ($PSVersionTable.PSEdition -eq 'Desktop')
            {
                # Windows PowerShell - use cmd.exe for reliable output suppression
                & cmd.exe /c 'git remote remove origin >nul 2>&1'
            }
            else
            {
                # PowerShell 7+ - capture output in variables
                $gitOutput = & git remote remove origin 2>&1
            }
        }

        It 'Should not create tag when WhatIf is specified' {
            $null = New-SamplerGitHubReleaseTag -ReleaseTag 'v2.0.0' -WhatIf

            # Verify the tag was NOT created
            $tags = & git tag
            $tags | Should -Not -Contain 'v2.0.0'
        }
    }

    Context 'When repository setup is invalid' {
        BeforeAll {
            # Create a repository without proper setup
            $script:invalidRepoPath = Join-Path -Path $TestDrive -ChildPath 'InvalidRepo'
            $null = New-Item -Path $script:invalidRepoPath -ItemType Directory -Force

            Push-Location -Path $script:invalidRepoPath
            try
            {
                & git init --quiet --initial-branch=main
                & git config user.name 'Test User'
                & git config user.email 'test@example.com'

                # Create initial commit but no remote or tags
                $null = New-Item -Path (Join-Path -Path $script:invalidRepoPath -ChildPath 'README.md') -ItemType File -Force
                Set-Content -Path (Join-Path -Path $script:invalidRepoPath -ChildPath 'README.md') -Value '# Invalid Repository'
                & git add README.md
                & git commit -m 'Initial commit' --quiet
            }
            finally
            {
                Pop-Location
            }
        }

        BeforeEach {
            Push-Location -Path $script:invalidRepoPath
        }

        AfterEach {
            Pop-Location
        }

        It 'Should throw an error when no remote exists' {
            { New-SamplerGitHubReleaseTag -ReleaseTag 'v1.0.0' -Force -ErrorAction Stop } | Should -Throw
        }

        It 'Should throw an error when no preview tags exist and no release tag specified' {
            # Create a separate remote repository without any tags
            $emptyRemotePath = Join-Path -Path $TestDrive -ChildPath 'EmptyRemote'
            $null = New-Item -Path $emptyRemotePath -ItemType Directory -Force

            Push-Location -Path $emptyRemotePath
            try
            {
                # Initialize empty remote repository
                & git init --bare --quiet --initial-branch=main 2>$null
            }
            finally
            {
                Pop-Location
            }

            # Remove local preview tag and add remote pointing to empty repository
            if ($PSVersionTable.PSEdition -eq 'Desktop')
            {
                # Windows PowerShell - use cmd.exe for reliable output suppression
                & cmd.exe /c 'git tag -d v1.0.0-preview0001 >nul 2>&1'
                & cmd.exe /c "git remote add origin file://$emptyRemotePath/.git >nul 2>&1"
            }
            else
            {
                # PowerShell 7+ - capture output in variables
                $gitOutput = & git tag -d 'v1.0.0-preview0001' 2>&1
                $gitOutput = & git remote add origin "file://$emptyRemotePath/.git" 2>&1
            }

            { New-SamplerGitHubReleaseTag -Force -ErrorAction Stop } | Should -Throw

            # Restore the preview tag and remove the remote for other tests
            & git tag 'v1.0.0-preview0001'
            if ($PSVersionTable.PSEdition -eq 'Desktop')
            {
                # Windows PowerShell - use cmd.exe for reliable output suppression
                & cmd.exe /c 'git remote remove origin >nul 2>&1'
            }
            else
            {
                # PowerShell 7+ - capture output in variables
                $gitOutput = & git remote remove origin 2>&1
            }
        }
    }

    Context 'When working with different branch names' {
        BeforeEach {
            # Add a local remote for this specific test
            if ($PSVersionTable.PSEdition -eq 'Desktop')
            {
                # Windows PowerShell - use cmd.exe for reliable output suppression
                & cmd.exe /c "git remote add origin file://$script:testRepoPath/.git >nul 2>&1"
            }
            else
            {
                # PowerShell 7+ - capture output in variables
                $gitOutput = & git remote add origin "file://$script:testRepoPath/.git" 2>&1
            }
        }

        AfterEach {
            # Remove remote after test
            if ($PSVersionTable.PSEdition -eq 'Desktop')
            {
                # Windows PowerShell - use cmd.exe for reliable output suppression
                & cmd.exe /c 'git remote remove origin >nul 2>&1'
            }
            else
            {
                # PowerShell 7+ - capture output in variables
                $gitOutput = & git remote remove origin 2>&1
            }
        }

        It 'Should work with non-default branch name' {
            # Create a develop branch and switch to it
            if ($PSVersionTable.PSEdition -eq 'Desktop')
            {
                # Windows PowerShell - use cmd.exe for reliable output suppression
                & cmd.exe /c 'git checkout -b develop --quiet >nul 2>&1'
                & cmd.exe /c 'git checkout main --quiet >nul 2>&1'
            }
            else
            {
                # PowerShell 7+ - use direct redirection
                & git checkout -b develop --quiet *>$null
                & git checkout main --quiet *>$null
            }

            $null = New-SamplerGitHubReleaseTag -DefaultBranchName 'main' -ReleaseTag 'v1.2.0' -Force -ErrorAction Stop

            # Verify the tag was created
            $tags = & git tag
            $tags | Should -Contain 'v1.2.0'
        }
    }

    Context 'When using ReturnToCurrentBranch functionality' {
        BeforeEach {
            # Add a local remote for this specific test
            if ($PSVersionTable.PSEdition -eq 'Desktop')
            {
                # Windows PowerShell - use cmd.exe for reliable output suppression
                & cmd.exe /c "git remote add origin file://$script:testRepoPath/.git >nul 2>&1"
            }
            else
            {
                # PowerShell 7+ - capture output in variables
                $gitOutput = & git remote add origin "file://$script:testRepoPath/.git" 2>&1
            }
        }

        AfterEach {
            # Remove remote after test
            if ($PSVersionTable.PSEdition -eq 'Desktop')
            {
                # Windows PowerShell - use cmd.exe for reliable output suppression
                & cmd.exe /c 'git remote remove origin >nul 2>&1'
            }
            else
            {
                # PowerShell 7+ - capture output in variables
                $gitOutput = & git remote remove origin 2>&1
            }
        }

        It 'Should return to the current branch after tagging' {
            # Create and switch to a feature branch
            if ($PSVersionTable.PSEdition -eq 'Desktop')
            {
                # Windows PowerShell - use cmd.exe for reliable output suppression
                & cmd.exe /c 'git checkout -b feature-branch --quiet >nul 2>&1'
            }
            else
            {
                # PowerShell 7+ - use direct redirection
                & git checkout -b feature-branch --quiet *>$null
            }
            $originalBranch = & git branch --show-current 2>$null

            $null = New-SamplerGitHubReleaseTag -ReleaseTag 'v1.3.0' -ReturnToCurrentBranch -Force -ErrorAction Stop

            # Verify we're back on the original branch
            $currentBranch = & git branch --show-current 2>$null
            $currentBranch | Should -Be $originalBranch

            # Verify the tag was still created
            $tags = & git tag
            $tags | Should -Contain 'v1.3.0'
        }
    }

    AfterAll {
        # Restore original location
        try
        {
            Set-Location -Path $script:originalLocation
        }
        catch
        {
            # Ignore location restore errors
        }
    }
}
