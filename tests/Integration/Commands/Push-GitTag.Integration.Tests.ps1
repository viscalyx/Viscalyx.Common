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

Describe 'Push-GitTag' -Tag 'Integration' {
    BeforeAll {
        # Store original location
        $script:originalLocation = Get-Location

        # Create a temporary directory for our test repositories
        $script:testRepoPath = Join-Path -Path $TestDrive -ChildPath 'TestRepo'
        $script:remoteRepoPath = Join-Path -Path $TestDrive -ChildPath 'RemoteRepo'

        $null = New-Item -Path $script:testRepoPath -ItemType Directory -Force
        $null = New-Item -Path $script:remoteRepoPath -ItemType Directory -Force

        # Initialize a bare remote repository (simulates GitHub/GitLab etc.)
        Push-Location -Path $script:remoteRepoPath
        try {
            & git init --bare --quiet --initial-branch=main
        }
        catch {
            throw "Failed to setup test remote git repository: $($_.Exception.Message)"
        }
        finally {
            Pop-Location
        }

        # Initialize a local git repository and set up remote
        Push-Location -Path $script:testRepoPath
        try {
            & git init --quiet --initial-branch=main
            & git config user.name "Test User"
            & git config user.email "test@example.com"

            # Add the test remote repository
            & git remote add origin $script:remoteRepoPath
            & git remote add upstream $script:remoteRepoPath

            # Create an initial commit
            $null = New-Item -Path (Join-Path -Path $script:testRepoPath -ChildPath 'README.md') -ItemType File -Force
            Set-Content -Path (Join-Path -Path $script:testRepoPath -ChildPath 'README.md') -Value '# Test Repository'
            & git add README.md
            & git commit -m "Initial commit" --quiet

            # Push initial commit to remote
            if ($PSVersionTable.PSEdition -eq 'Desktop') {
                # Windows PowerShell - use cmd.exe for reliable output suppression
                & cmd.exe /c "git push origin main --quiet >nul 2>&1"
            } else {
                # PowerShell 7+ - capture output in variables
                $gitOutput = & git push origin main --quiet 2>&1
            }
        }
        catch {
            throw "Failed to setup test local git repository: $($_.Exception.Message)"
        }
        finally {
            Pop-Location
        }
    }

    BeforeEach {
        # Change to the test repository directory for each test
        Push-Location -Path $script:testRepoPath

        # Clean up any existing tags before each test
        try {
            $localTags = & git tag 2>$null
            if ($localTags) {
                foreach ($tag in $localTags) {
                    & git tag -d $tag 2>$null | Out-Null
                }
            }

            # Clean up remote tags
            $remoteTags = & git ls-remote --tags origin 2>$null
            if ($remoteTags) {
                foreach ($tagLine in $remoteTags) {
                    if ($tagLine -match 'refs/tags/(.+)$') {
                        $tagName = $matches[1]
                        if ($PSVersionTable.PSEdition -eq 'Desktop') {
                            # Windows PowerShell - use cmd.exe for reliable output suppression
                            & cmd.exe /c "git push origin --delete refs/tags/$tagName >nul 2>&1"
                        } else {
                            # PowerShell 7+ - capture output in variables
                            $gitOutput = & git push origin --delete "refs/tags/$tagName" 2>&1
                        }
                    }
                }
            }
        }
        catch {
            # Ignore cleanup errors
        }
    }

    AfterEach {
        # Clean up any tags created during testing
        try {
            $localTags = & git tag 2>$null
            if ($localTags) {
                foreach ($tag in $localTags) {
                    & git tag -d $tag 2>$null | Out-Null
                }
            }

            # Clean up remote tags
            $remoteTags = & git ls-remote --tags origin 2>$null
            if ($remoteTags) {
                foreach ($tagLine in $remoteTags) {
                    if ($tagLine -match 'refs/tags/(.+)$') {
                        $tagName = $matches[1]
                        if ($PSVersionTable.PSEdition -eq 'Desktop') {
                            # Windows PowerShell - use cmd.exe for reliable output suppression
                            & cmd.exe /c "git push origin --delete refs/tags/$tagName >nul 2>&1"
                        } else {
                            # PowerShell 7+ - capture output in variables
                            $gitOutput = & git push origin --delete "refs/tags/$tagName" 2>&1
                        }
                    }
                }
            }
        }
        catch {
            # Ignore cleanup errors
        }

        # Return to original location
        try {
            Pop-Location
        }
        catch {
            # Ignore location errors
        }
    }

    Context 'When pushing a specific tag successfully' {
        BeforeEach {
            # Create a local tag for testing
            & git tag 'v1.0.0' 2>$null
        }

        It 'Should push a specific tag to the default remote' {
            { Push-GitTag -Name 'v1.0.0' -Force -ErrorAction Stop } | Should -Not -Throw

            # Verify the tag was pushed to the remote
            $remoteTags = & git ls-remote --tags origin
            ($remoteTags | Where-Object { $_ -match 'refs/tags/v1.0.0' }) | Should -Not -BeNullOrEmpty
        }

        It 'Should push a specific tag to a custom remote' {
            { Push-GitTag -RemoteName 'upstream' -Name 'v1.0.0' -Force -ErrorAction Stop } | Should -Not -Throw

            # Verify the tag was pushed to the upstream remote
            $remoteTags = & git ls-remote --tags upstream
            ($remoteTags | Where-Object { $_ -match 'refs/tags/v1.0.0' }) | Should -Not -BeNullOrEmpty
        }

        It 'Should work with different tag naming patterns' {
            $tagNames = @('v2.0.0', 'release-2023', 'feature-tag')

            foreach ($tagName in $tagNames) {
                # Create local tag
                & git tag $tagName 2>$null

                # Push the tag
                { Push-GitTag -Name $tagName -Force -ErrorAction Stop } | Should -Not -Throw
            }

            # Verify all tags were pushed
            $remoteTags = & git ls-remote --tags origin
            foreach ($tagName in $tagNames) {
                ($remoteTags | Where-Object { $_ -match "refs/tags/$tagName" }) | Should -Not -BeNullOrEmpty -Because "Tag $tagName should be pushed to remote"
            }
        }
    }

    Context 'When pushing all tags successfully' {
        BeforeEach {
            # Create multiple local tags for testing
            & git tag 'v1.0.0' 2>$null
            & git tag 'v1.1.0' 2>$null
            & git tag 'v2.0.0' 2>$null
        }

        It 'Should push all tags to the default remote' {
            { Push-GitTag -Force -ErrorAction Stop } | Should -Not -Throw

            # Verify all tags were pushed to the remote
            $remoteTags = & git ls-remote --tags origin
            ($remoteTags | Where-Object { $_ -match 'refs/tags/v1.0.0' }) | Should -Not -BeNullOrEmpty
            ($remoteTags | Where-Object { $_ -match 'refs/tags/v1.1.0' }) | Should -Not -BeNullOrEmpty
            ($remoteTags | Where-Object { $_ -match 'refs/tags/v2.0.0' }) | Should -Not -BeNullOrEmpty
        }

        It 'Should push all tags to a custom remote' {
            { Push-GitTag -RemoteName 'upstream' -Force -ErrorAction Stop } | Should -Not -Throw

            # Verify all tags were pushed to the upstream remote
            $remoteTags = & git ls-remote --tags upstream
            ($remoteTags | Where-Object { $_ -match 'refs/tags/v1.0.0' }) | Should -Not -BeNullOrEmpty
            ($remoteTags | Where-Object { $_ -match 'refs/tags/v1.1.0' }) | Should -Not -BeNullOrEmpty
            ($remoteTags | Where-Object { $_ -match 'refs/tags/v2.0.0' }) | Should -Not -BeNullOrEmpty
        }
    }

    Context 'When using ShouldProcess functionality' {
        BeforeEach {
            # Create a local tag for testing
            & git tag 'v1.0.0' 2>$null
        }

        It 'Should not push tag when WhatIf is specified' {
            { Push-GitTag -Name 'v1.0.0' -WhatIf } | Should -Not -Throw

            # Verify the tag was NOT pushed to the remote
            $remoteTags = & git ls-remote --tags origin 2>$null
            ($remoteTags | Where-Object { $_ -match 'refs/tags/v1.0.0' }) | Should -BeNullOrEmpty
        }

        It 'Should not push all tags when WhatIf is specified' {
            { Push-GitTag -WhatIf } | Should -Not -Throw

            # Verify no tags were pushed to the remote
            $remoteTags = & git ls-remote --tags origin 2>$null
            ($remoteTags | Where-Object { $_ -match 'refs/tags/v1.0.0' }) | Should -BeNullOrEmpty
        }
    }

    Context 'When handling error conditions' {
        It 'Should throw an error when trying to push non-existent tag' {
            { Push-GitTag -Name 'non-existent-tag' -Force -ErrorAction Stop 2>$null } | Should -Throw
        }

        It 'Should throw an error when remote does not exist' {
            # Create a local tag
            & git tag 'v1.0.0' 2>$null

            { Push-GitTag -RemoteName 'non-existent-remote' -Name 'v1.0.0' -Force -ErrorAction Stop 2>$null } | Should -Throw
        }

        It 'Should succeed when trying to push all tags with no local tags (no-op)' {
            # This should succeed but be a no-op since there are no tags to push
            { Push-GitTag -Force -ErrorAction Stop 2>$null } | Should -Not -Throw
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
            { Push-GitTag -Name 'test-tag' -Force -ErrorAction Stop 2>$null } | Should -Throw
        }

        It 'Should throw an error when trying to push all tags outside git repository' {
            { Push-GitTag -Force -ErrorAction Stop 2>$null } | Should -Throw
        }
    }

    Context 'When tag already exists on remote' {
        BeforeEach {
            # Create a local tag and push it first
            if ($PSVersionTable.PSEdition -eq 'Desktop') {
                # Windows PowerShell - use cmd.exe for reliable output suppression
                & cmd.exe /c "git tag v1.0.0 >nul 2>&1"
                & cmd.exe /c "git push origin refs/tags/v1.0.0 >nul 2>&1"
            } else {
                # PowerShell 7+ - capture output in variables
                $gitOutput = & git tag 'v1.0.0' 2>&1
                $gitOutput = & git push origin 'refs/tags/v1.0.0' 2>&1
            }
        }

        It 'Should succeed when pushing the same tag again (idempotent operation)' {
            { Push-GitTag -Name 'v1.0.0' -Force -ErrorAction Stop } | Should -Not -Throw

            # Verify the tag still exists on the remote
            $remoteTags = & git ls-remote --tags origin
            ($remoteTags | Where-Object { $_ -match 'refs/tags/v1.0.0' }) | Should -Not -BeNullOrEmpty
        }
    }
}
