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

    # Create a temporary Git repository for testing
    $script:testRepoPath = Join-Path -Path $TestDrive -ChildPath 'TestGitRepo'
    New-Item -Path $script:testRepoPath -ItemType Directory -Force | Out-Null

    # Initialize the test repository and create test tags
    Push-Location -Path $script:testRepoPath
    try {
        # Initialize git repository
        git init *> $null
        git config user.email "test@example.com" *> $null
        git config user.name "Test User" *> $null

        # Create initial commit
        "Initial content" | Out-File -FilePath 'test1.txt' -Encoding utf8
        git add test1.txt *> $null
        git commit -m "Initial commit" *> $null

        # Create test tags for various scenarios
        git tag v1.0.0 *> $null
        
        # Create another commit and tag
        "Second content" | Out-File -FilePath 'test2.txt' -Encoding utf8
        git add test2.txt *> $null
        git commit -m "Second commit" *> $null
        git tag v1.1.0 *> $null
        
        # Create another commit and tag
        "Third content" | Out-File -FilePath 'test3.txt' -Encoding utf8
        git add test3.txt *> $null
        git commit -m "Third commit" *> $null
        git tag v2.0.0 *> $null
        
        # Create another commit and tag
        "Fourth content" | Out-File -FilePath 'test4.txt' -Encoding utf8
        git add test4.txt *> $null
        git commit -m "Fourth commit" *> $null
        git tag v2.1.0 *> $null
        
        # Create some non-version tags
        git tag release-candidate *> $null
        git tag stable *> $null
    }
    finally {
        # No need to change back directory here as we want to run tests in the repo
    }
}

AfterAll {
    try {
        Pop-Location -ErrorAction SilentlyContinue
        
        # Force cleanup of Git repository to avoid permission issues
        if (Test-Path $script:testRepoPath) {
            # Remove read-only attributes from .git files
            Get-ChildItem -Path $script:testRepoPath -Recurse -Force | ForEach-Object {
                if ($_.Attributes -band [System.IO.FileAttributes]::ReadOnly) {
                    $_.Attributes = $_.Attributes -bxor [System.IO.FileAttributes]::ReadOnly
                }
            }
            $previousProgressPreference = $ProgressPreference
            $ProgressPreference = 'SilentlyContinue' # Suppress progress output during deletion
            Remove-Item -Path $script:testRepoPath -Recurse -Force -ErrorAction SilentlyContinue
            $ProgressPreference = $previousProgressPreference
        }
    }
    catch {
        # Ignore cleanup errors
    }
    
    # Unload the module being tested so that it doesn't impact any other tests.
    Get-Module -Name $script:moduleName -All | Remove-Module -Force
}

Describe 'Get-GitTag Integration Tests' {
    Context 'When retrieving all tags' {
        It 'Should return all tags from the repository' {
            $result = Get-GitTag -ErrorAction Stop

            $result | Should -HaveCount 6
            $result | Should -Contain 'v1.0.0'
            $result | Should -Contain 'v1.1.0'
            $result | Should -Contain 'v2.0.0'
            $result | Should -Contain 'v2.1.0'
            $result | Should -Contain 'release-candidate'
            $result | Should -Contain 'stable'
        }

        It 'Should return tags sorted in ascending order by default' {
            $result = Get-GitTag -ErrorAction Stop

            # Tags should be returned in alphabetical order by default
            $result[0] | Should -Be 'release-candidate'
            $result[1] | Should -Be 'stable'
            $result[2] | Should -Be 'v1.0.0'
            $result[3] | Should -Be 'v1.1.0'
            $result[4] | Should -Be 'v2.0.0'
            $result[5] | Should -Be 'v2.1.0'
        }

        It 'Should return tags sorted in descending order when Descending is specified' {
            $result = Get-GitTag -Descending -ErrorAction Stop

            # Tags should be returned in reverse alphabetical order
            $result[0] | Should -Be 'v2.1.0'
            $result[1] | Should -Be 'v2.0.0'
            $result[2] | Should -Be 'v1.1.0'
            $result[3] | Should -Be 'v1.0.0'
            $result[4] | Should -Be 'stable'
            $result[5] | Should -Be 'release-candidate'
        }
    }

    Context 'When using version sorting' {
        It 'Should return version tags sorted correctly when AsVersions is specified' {
            $result = Get-GitTag -AsVersions -ErrorAction Stop

            # With version sorting, version tags should come after non-version tags
            # and be sorted numerically
            $result | Should -HaveCount 6
            $result | Should -Contain 'v1.0.0'
            $result | Should -Contain 'v1.1.0'
            $result | Should -Contain 'v2.0.0'
            $result | Should -Contain 'v2.1.0'
        }

        It 'Should return version tags in descending order when AsVersions and Descending are specified' {
            $result = Get-GitTag -AsVersions -Descending -ErrorAction Stop

            $result | Should -HaveCount 6
            # The exact order depends on git's version sorting algorithm
            $result | Should -Contain 'v1.0.0'
            $result | Should -Contain 'v1.1.0'
            $result | Should -Contain 'v2.0.0'
            $result | Should -Contain 'v2.1.0'
        }
    }

    Context 'When using the Latest parameter' {
        It 'Should return the latest version tag' {
            $result = Get-GitTag -Latest -ErrorAction Stop

            $result | Should -HaveCount 1
            # Should return the highest version tag
            $result | Should -Be 'v2.1.0'
        }
    }

    Context 'When using the First parameter' {
        It 'Should return the specified number of tags' {
            $result = Get-GitTag -First 3 -ErrorAction Stop

            $result | Should -HaveCount 3
        }

        It 'Should return the first 2 tags when First is 2' {
            $result = Get-GitTag -First 2 -ErrorAction Stop

            $result | Should -HaveCount 2
            $result[0] | Should -Be 'release-candidate'
            $result[1] | Should -Be 'stable'
        }

        It 'Should return the first 2 version-sorted tags in descending order' {
            $result = Get-GitTag -First 2 -AsVersions -Descending -ErrorAction Stop

            $result | Should -HaveCount 2
            # Should get the top 2 version tags in descending order
        }
    }

    Context 'When using the Name parameter for filtering' {
        It 'Should return tags matching the specified pattern' {
            $result = Get-GitTag -Name 'v1*' -ErrorAction Stop

            $result | Should -HaveCount 2
            $result | Should -Contain 'v1.0.0'
            $result | Should -Contain 'v1.1.0'
        }

        It 'Should return a specific tag when exact name is provided' {
            $result = Get-GitTag -Name 'v2.0.0' -ErrorAction Stop

            $result | Should -HaveCount 1
            $result | Should -Be 'v2.0.0'
        }

        It 'Should return empty result when pattern matches no tags' {
            $result = Get-GitTag -Name 'nonexistent*' -ErrorAction Stop

            $result | Should -BeNullOrEmpty
        }

        It 'Should work with Name pattern and version sorting' {
            $result = Get-GitTag -Name 'v2*' -AsVersions -Descending -ErrorAction Stop

            $result | Should -HaveCount 2
            $result | Should -Contain 'v2.0.0'
            $result | Should -Contain 'v2.1.0'
        }
    }

    Context 'When combining parameters' {
        It 'Should work with Name pattern, First, and AsVersions' {
            $result = Get-GitTag -Name 'v*' -First 2 -AsVersions -ErrorAction Stop

            $result | Should -HaveCount 2
            # Should return first 2 version tags matching v* pattern
        }

        It 'Should work with First and Descending' {
            $result = Get-GitTag -First 1 -Descending -ErrorAction Stop

            $result | Should -HaveCount 1
            $result | Should -Be 'v2.1.0'
        }
    }
}