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

Describe 'New-GitTag' -Tag 'Integration' {
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

        # Clean up any existing tags before each test
        try
        {
            $tags = & git tag 2>$null
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
        # Clean up any tags created during testing
        try
        {
            $tags = & git tag 2>$null
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

    Context 'When creating a new tag successfully' {
        It 'Should create a simple tag' {
            { New-GitTag -Name 'v1.0.0' -Force -ErrorAction Stop } | Should -Not -Throw

            # Verify the tag was created
            $tags = & git tag
            $tags | Should -Contain 'v1.0.0'
        }

        It 'Should create multiple tags' {
            { New-GitTag -Name 'v1.0.0' -Force -ErrorAction Stop } | Should -Not -Throw
            { New-GitTag -Name 'v1.1.0' -Force -ErrorAction Stop } | Should -Not -Throw

            # Verify both tags were created
            $tags = & git tag
            $tags | Should -Contain 'v1.0.0'
            $tags | Should -Contain 'v1.1.0'
        }

        It 'Should work with different tag naming patterns' {
            $tagNames = @('v1.0.0', 'release-2023', 'feature-tag', '1.0.0-beta')

            foreach ($tagName in $tagNames)
            {
                { New-GitTag -Name $tagName -Force -ErrorAction Stop } | Should -Not -Throw
            }

            # Verify all tags were created
            $tags = & git tag
            foreach ($tagName in $tagNames)
            {
                $tags | Should -Contain $tagName
            }
        }
    }

    Context 'When creating a tag that already exists' {
        BeforeEach {
            # Create a tag that already exists
            & git tag 'existing-tag' 2>$null
        }

        It 'Should throw an error when trying to create duplicate tag' {
            { New-GitTag -Name 'existing-tag' -Force -ErrorAction Stop 2>$null } | Should -Throw
        }
    }

    Context 'When using ShouldProcess functionality' {
        It 'Should not create tag when WhatIf is specified' {
            { New-GitTag -Name 'whatif-tag' -WhatIf } | Should -Not -Throw

            # Verify the tag was NOT created
            $tags = & git tag
            $tags | Should -Not -Contain 'whatif-tag'
        }
    }

    Context 'When git repository is not accessible' {
        BeforeAll {
            # Change to a directory that is not a git repository
            $script:nonGitPath = Join-Path -Path $TestDrive -ChildPath 'NonGitRepo'
            $null = New-Item -Path $script:nonGitPath -ItemType Directory -Force
        }

        BeforeEach {
            Push-Location -Path $script:nonGitPath
        }

        AfterEach {
            Pop-Location
        }

        It 'Should throw an error when not in a git repository' {
            { New-GitTag -Name 'test-tag' -Force -ErrorAction Stop 2>$null } | Should -Throw
        }
    }
}
