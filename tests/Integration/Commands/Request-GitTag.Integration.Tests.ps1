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
    # Save the original location before any operations
    $script:originalLocation = Get-Location

    $script:moduleName = 'Viscalyx.Common'

    # Initialize all script-level path variables to prevent null reference errors in AfterAll
    $script:testRepoPath = $null
    $script:bareRepoPath = $null
    $script:secondRepoPath = $null

    Import-Module -Name $script:moduleName -Force -ErrorAction 'Stop'

    # Create temporary Git repositories for testing
    $script:testRepoPath = Join-Path -Path $TestDrive -ChildPath 'TestGitRepo'
    $script:bareRepoPath = Join-Path -Path $TestDrive -ChildPath 'BareRepo'

    New-Item -Path $script:testRepoPath -ItemType Directory -Force | Out-Null
    New-Item -Path $script:bareRepoPath -ItemType Directory -Force | Out-Null

    # Initialize the bare repository (simulates a remote)
    Push-Location -Path $script:bareRepoPath
    try
    {
        Viscalyx.Common\Invoke-Git -WorkingDirectory $script:bareRepoPath -Arguments @('init', '--bare', '--initial-branch=main')
    }
    finally
    {
        Pop-Location
    }

    # Initialize the test repository and create test commits
    Push-Location -Path $script:testRepoPath
    try
    {
        # Initialize git repository
        Viscalyx.Common\Invoke-Git -WorkingDirectory $script:testRepoPath -Arguments @('init', '--initial-branch=main', '--quiet')

        # Configure git user for testing
        Viscalyx.Common\Invoke-Git -WorkingDirectory $script:testRepoPath -Arguments @('config', 'user.name', 'Test User')
        Viscalyx.Common\Invoke-Git -WorkingDirectory $script:testRepoPath -Arguments @('config', 'user.email', 'test@example.com')

        # Create initial commit
        'Initial content' | Out-File -FilePath 'test.txt' -Encoding utf8
        Viscalyx.Common\Invoke-Git -WorkingDirectory $script:testRepoPath -Arguments @('add', '.')
        Viscalyx.Common\Invoke-Git -WorkingDirectory $script:testRepoPath -Arguments @('commit', '-m', 'Initial commit')

        # Add the bare repository as origin remote
        Viscalyx.Common\Invoke-Git -WorkingDirectory $script:testRepoPath -Arguments @('remote', 'add', 'origin', $script:bareRepoPath)

        # Get the current branch name (don't assume 'main' or 'master')
        $result = Viscalyx.Common\Invoke-Git -WorkingDirectory $script:testRepoPath -Arguments @('branch', '--show-current') -PassThru
        $currentBranch = $result.Output
        if (-not $currentBranch)
        {
            throw 'Failed to determine current branch name'
        }

        # Push to origin
        Viscalyx.Common\Invoke-Git -WorkingDirectory $script:testRepoPath -Arguments @('push', '--set-upstream', 'origin', $currentBranch, '--quiet')

        # Create and push tags
        Viscalyx.Common\Invoke-Git -WorkingDirectory $script:testRepoPath -Arguments @('tag', 'v1.0.0')
        Viscalyx.Common\Invoke-Git -WorkingDirectory $script:testRepoPath -Arguments @('tag', 'v1.1.0')
        Viscalyx.Common\Invoke-Git -WorkingDirectory $script:testRepoPath -Arguments @('tag', 'v2.0.0')

        Viscalyx.Common\Invoke-Git -WorkingDirectory $script:testRepoPath -Arguments @('push', 'origin', '--tags')
    }
    finally
    {
        Pop-Location
    }

    # Create a second working repository to test fetching tags from
    $script:secondRepoPath = Join-Path -Path $TestDrive -ChildPath 'SecondGitRepo'
    New-Item -Path $script:secondRepoPath -ItemType Directory -Force | Out-Null

    Push-Location -Path $script:secondRepoPath
    try
    {
        # Clone the bare repository
        Viscalyx.Common\Invoke-Git -WorkingDirectory $script:secondRepoPath -Arguments @('clone', $script:bareRepoPath, '.')

        # Configure git user for testing
        Viscalyx.Common\Invoke-Git -WorkingDirectory $script:secondRepoPath -Arguments @('config', 'user.name', 'Test User')
        Viscalyx.Common\Invoke-Git -WorkingDirectory $script:secondRepoPath -Arguments @('config', 'user.email', 'test@example.com')

        # Remove all local tags to test fetching
        $result = Viscalyx.Common\Invoke-Git -WorkingDirectory $script:secondRepoPath -Arguments @('tag') -PassThru
        $tags = $result.Output
        if ($tags)
        {
            Viscalyx.Common\Invoke-Git -WorkingDirectory $script:secondRepoPath -Arguments (@('tag', '-d') + ($tags -split("`n"))) -Verbose
        }
    }
    finally
    {
        Pop-Location
    }
}

AfterAll {
    # Clean up - return to original location if we're still in test directories
    $currentLocation = Get-Location
    if ($currentLocation.Path.StartsWith($TestDrive))
    {
        Set-Location -Path $script:originalLocation
    }

    # Force cleanup of git repositories to prevent TestDrive deletion issues
    if ($script:testRepoPath -and (Test-Path -Path $script:testRepoPath))
    {
        # Remove read-only attributes from .git directory recursively
        Get-ChildItem -Path $script:testRepoPath -Recurse -Force | ForEach-Object {
            if ($_.Attributes -band [System.IO.FileAttributes]::ReadOnly)
            {
                $_.Attributes = $_.Attributes -band (-bnot [System.IO.FileAttributes]::ReadOnly)
            }
        }
        Remove-Item -Path $script:testRepoPath -Recurse -Force -ErrorAction SilentlyContinue
    }

    if ($script:secondRepoPath -and (Test-Path -Path $script:secondRepoPath))
    {
        # Remove read-only attributes from .git directory recursively
        Get-ChildItem -Path $script:secondRepoPath -Recurse -Force | ForEach-Object {
            if ($_.Attributes -band [System.IO.FileAttributes]::ReadOnly)
            {
                $_.Attributes = $_.Attributes -band (-bnot [System.IO.FileAttributes]::ReadOnly)
            }
        }
        Remove-Item -Path $script:secondRepoPath -Recurse -Force -ErrorAction SilentlyContinue
    }

    if ($script:bareRepoPath -and (Test-Path -Path $script:bareRepoPath))
    {
        # Remove read-only attributes from .git directory recursively
        Get-ChildItem -Path $script:bareRepoPath -Recurse -Force | ForEach-Object {
            if ($_.Attributes -band [System.IO.FileAttributes]::ReadOnly)
            {
                $_.Attributes = $_.Attributes -band (-bnot [System.IO.FileAttributes]::ReadOnly)
            }
        }
        Remove-Item -Path $script:bareRepoPath -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'Request-GitTag' {
    Context 'When fetching a specific tag from origin remote' {
        BeforeEach {
            Push-Location -Path $script:secondRepoPath
        }

        AfterEach {
            Pop-Location
        }

        It 'Should successfully fetch a specific tag' {
            # Verify tag doesn't exist locally
            $result = Viscalyx.Common\Invoke-Git -WorkingDirectory $script:secondRepoPath -Arguments @('tag') -PassThru
            $existingTags = $result.Output
            # $existingTags = if ($result.Output) { $result.Output -split "`n" | Where-Object { $_.Trim() } } else { @() }
            $existingTags | Should -Not -Contain 'v1.0.0'

            # Fetch the specific tag
            { Request-GitTag -RemoteName 'origin' -Name 'v1.0.0' -Force -Verbose } | Should -Not -Throw

            # Verify the tag now exists locally
            $result = Viscalyx.Common\Invoke-Git -WorkingDirectory $script:secondRepoPath -Arguments @('tag') -PassThru
            $tagsAfterFetch = $result.Output
            $tagsAfterFetch | Should -Contain 'v1.0.0'
        }

        It 'Should successfully fetch multiple specific tags' {
            # Remove any existing tags
            $result = Viscalyx.Common\Invoke-Git -WorkingDirectory $script:secondRepoPath -Arguments @('tag') -PassThru
            $existingTags = $result.Output
            if ($existingTags)
            {
                Viscalyx.Common\Invoke-Git -WorkingDirectory $script:secondRepoPath -Arguments (@('tag', '-d') + $existingTags -split("`n"))
            }

            # Verify tags don't exist locally
            $result = Viscalyx.Common\Invoke-Git -WorkingDirectory $script:secondRepoPath -Arguments @('tag') -PassThru
            $existingTags = $result.Output
            $existingTags | Should -Not -Contain 'v1.1.0'
            $existingTags | Should -Not -Contain 'v2.0.0'

            # Fetch specific tags
            $null = Request-GitTag -RemoteName 'origin' -Name 'v1.1.0' -Force -ErrorAction Stop
            $null = Request-GitTag -RemoteName 'origin' -Name 'v2.0.0' -Force -ErrorAction Stop

            # Verify the tags now exist locally
            $result = Viscalyx.Common\Invoke-Git -WorkingDirectory $script:secondRepoPath -Arguments @('tag') -PassThru
            $tagsAfterFetch = $result.Output
            $tagsAfterFetch | Should -Contain 'v1.1.0'
            $tagsAfterFetch | Should -Contain 'v2.0.0'
        }

        It 'Should handle non-existent tag gracefully' {
            # Attempt to fetch a non-existent tag (redirect errors to suppress console noise)
            { Request-GitTag -RemoteName 'origin' -Name 'non-existent-tag' -Force -ErrorAction Stop } |
                Should -Throw -ErrorId 'RGT0001,Request-GitTag'
        }
    }

    Context 'When fetching all tags from origin remote' {
        BeforeEach {
            Push-Location -Path $script:secondRepoPath

            # Remove all local tags to test fetching all
            $result = Viscalyx.Common\Invoke-Git -WorkingDirectory $script:secondRepoPath -Arguments @('tag') -PassThru
            $existingTags = $result.Output
            if ($existingTags)
            {
                Viscalyx.Common\Invoke-Git -WorkingDirectory $script:secondRepoPath -Arguments (@('tag', '-d') + ($existingTags -split("`n"))) -Verbose
            }
        }

        AfterEach {
            Pop-Location
        }

        It 'Should successfully fetch all tags' {
            # Verify no tags exist locally
            $result = Viscalyx.Common\Invoke-Git -WorkingDirectory $script:secondRepoPath -Arguments @('tag') -PassThru
            $existingTags = $result.Output
            $existingTags | Should -BeNullOrEmpty

            # Fetch all tags
            { Request-GitTag -RemoteName 'origin' -Force -ErrorAction Stop } | Should -Not -Throw

            # Verify all tags now exist locally
            $result = Viscalyx.Common\Invoke-Git -WorkingDirectory $script:secondRepoPath -Arguments @('tag') -PassThru
            $tagsAfterFetch = $result.Output
            $tagsAfterFetch | Should -Contain 'v1.0.0'
            $tagsAfterFetch | Should -Contain 'v1.1.0'
            $tagsAfterFetch | Should -Contain 'v2.0.0'
        }

        It 'Should work when tags already exist locally' {
            # First fetch all tags
            $null = Request-GitTag -RemoteName 'origin' -Force

            # Verify tags exist
            $result = Viscalyx.Common\Invoke-Git -WorkingDirectory $script:secondRepoPath -Arguments @('tag') -PassThru
            $tagsBeforeSecondFetch = $result.Output
            $tagsBeforeSecondFetch | Should -Contain 'v1.0.0'

            # Fetch again - should not fail
            { Request-GitTag -RemoteName 'origin' -Force } | Should -Not -Throw

            # Verify tags still exist
            $result = Viscalyx.Common\Invoke-Git -WorkingDirectory $script:secondRepoPath -Arguments @('tag') -PassThru
            $tagsAfterSecondFetch = $result.Output
            $tagsAfterSecondFetch | Should -Contain 'v1.0.0'
            $tagsAfterSecondFetch | Should -Contain 'v1.1.0'
            $tagsAfterSecondFetch | Should -Contain 'v2.0.0'
        }
    }

    Context 'When using invalid remote name' {
        BeforeEach {
            Push-Location -Path $script:secondRepoPath
        }

        AfterEach {
            Pop-Location
        }

        It 'Should throw error when remote does not exist' {
            { Request-GitTag -RemoteName 'nonexistent' -Force } |
                Should -Throw -ErrorId 'RGT0001,Request-GitTag'
        }

        It 'Should throw error when trying to fetch specific tag from invalid remote' {
            { Request-GitTag -RemoteName 'invalid-remote' -Name 'v1.0.0' -Force } |
                Should -Throw -ErrorId 'RGT0001,Request-GitTag'
        }
    }

    Context 'ShouldProcess integration with real git commands' {
        BeforeEach {
            Push-Location -Path $script:secondRepoPath

            # Remove test tag if it exists
            $result = Viscalyx.Common\Invoke-Git -WorkingDirectory $script:secondRepoPath -Arguments @('tag') -PassThru
            $existingTags = $result.Output
            if ($existingTags -contains 'v1.0.0')
            {
                Viscalyx.Common\Invoke-Git -WorkingDirectory $script:secondRepoPath -Arguments @('tag', '-d', 'v1.0.0')
            }
        }

        AfterEach {
            Pop-Location
        }

        It 'Should not fetch tags when using WhatIf for specific tag' {
            # Ensure no tags exist initially
            $result = Viscalyx.Common\Invoke-Git -WorkingDirectory $script:secondRepoPath -Arguments @('tag') -PassThru
            $tagsBeforeWhatIf = $result.Output

            # WhatIf should not perform the actual operation
            $null = Request-GitTag -RemoteName 'origin' -Name 'v1.0.0' -WhatIf 2>$null

            # Verify that no tags were actually fetched
            $result = Viscalyx.Common\Invoke-Git -WorkingDirectory $script:secondRepoPath -Arguments @('tag') -PassThru
            $tagsAfterWhatIf = $result.Output
            $tagsAfterWhatIf | Should -Be $tagsBeforeWhatIf
        }

        It 'Should not fetch tags when using WhatIf for all tags' {
            # Ensure no tags exist initially
            $result = Viscalyx.Common\Invoke-Git -WorkingDirectory $script:secondRepoPath -Arguments @('tag') -PassThru
            $tagsBeforeWhatIf = $result.Output

            # WhatIf should not perform the actual operation
            $null = Request-GitTag -RemoteName 'origin' -WhatIf 2>$null

            # Verify that no tags were actually fetched
            $result = Viscalyx.Common\Invoke-Git -WorkingDirectory $script:secondRepoPath -Arguments @('tag') -PassThru
            $tagsAfterWhatIf = $result.Output
            $tagsAfterWhatIf | Should -Be $tagsBeforeWhatIf
        }

        It 'Should respect -Confirm:$false with -Force' {
            # This should execute without prompting
            { Request-GitTag -RemoteName 'origin' -Name 'v1.0.0' -Force -Confirm:$false } | Should -Not -Throw

            # Verify the tag was actually fetched
            $result = Viscalyx.Common\Invoke-Git -WorkingDirectory $script:secondRepoPath -Arguments @('tag') -PassThru
            $tagsAfterFetch = $result.Output
            $tagsAfterFetch | Should -Contain 'v1.0.0'
        }
    }

    Context 'When working with multiple remotes' {
        BeforeAll {
            # Create a third repository to act as upstream
            $script:upstreamRepoPath = Join-Path -Path $TestDrive -ChildPath 'UpstreamRepo'
            New-Item -Path $script:upstreamRepoPath -ItemType Directory -Force | Out-Null

            Push-Location -Path $script:upstreamRepoPath
            try
            {
                Viscalyx.Common\Invoke-Git -WorkingDirectory $script:upstreamRepoPath -Arguments @('init', '--bare', '--initial-branch=main')
            }
            finally
            {
                Pop-Location
            }

            # Add upstream remote to the second repo and create a different tag
            Push-Location -Path $script:testRepoPath
            try
            {
                Viscalyx.Common\Invoke-Git -WorkingDirectory $script:testRepoPath -Arguments @('remote', 'add', 'upstream', $script:upstreamRepoPath)
                Viscalyx.Common\Invoke-Git -WorkingDirectory $script:testRepoPath -Arguments @('tag', 'upstream-v1.0.0')

                # Get the current branch name (don't assume 'main' or 'master')
                $result = Viscalyx.Common\Invoke-Git -WorkingDirectory $script:testRepoPath -Arguments @('branch', '--show-current') -PassThru
                $currentBranch = $result.Output
                if (-not $currentBranch)
                {
                    throw 'Failed to determine current branch name'
                }

                Viscalyx.Common\Invoke-Git -WorkingDirectory $script:testRepoPath -Arguments @('push', 'upstream', $currentBranch, '--quiet')
                Viscalyx.Common\Invoke-Git -WorkingDirectory $script:testRepoPath -Arguments @('push', 'upstream', '--tags', '--quiet')
            }
            finally
            {
                Pop-Location
            }

            # Add upstream remote to second repo for testing
            Push-Location -Path $script:secondRepoPath
            try
            {
                Viscalyx.Common\Invoke-Git -WorkingDirectory $script:secondRepoPath -Arguments @('remote', 'add', 'upstream', $script:upstreamRepoPath)
            }
            finally
            {
                Pop-Location
            }
        }

        BeforeEach {
            Push-Location -Path $script:secondRepoPath
        }

        AfterEach {
            Pop-Location
        }

        It 'Should fetch tags from different remotes' {
            # Remove all local tags
            $result = Viscalyx.Common\Invoke-Git -WorkingDirectory $script:secondRepoPath -Arguments @('tag') -PassThru
            $existingTags = $result.Output
            if ($existingTags)
            {
                Viscalyx.Common\Invoke-Git -WorkingDirectory $script:secondRepoPath -Arguments (@('tag', '-d') + $existingTags)
            }

            # Fetch from origin
            $null = Request-GitTag -RemoteName 'origin' -Force -ErrorAction Stop
            $result = Viscalyx.Common\Invoke-Git -WorkingDirectory $script:secondRepoPath -Arguments @('tag') -PassThru
            $originTags = $result.Output
            $originTags | Should -Contain 'v1.0.0'

            # Remove all tags again
            if ($originTags)
            {
                Viscalyx.Common\Invoke-Git -WorkingDirectory $script:secondRepoPath -Arguments (@('tag', '-d') + $originTags)
            }

            # Fetch from upstream
            $null = Request-GitTag -RemoteName 'upstream' -Force -ErrorAction Stop
            $result = Viscalyx.Common\Invoke-Git -WorkingDirectory $script:secondRepoPath -Arguments @('tag') -PassThru
            $upstreamTags = $result.Output
            $upstreamTags | Should -Contain 'upstream-v1.0.0'
        }

        It 'Should fetch specific tag from upstream remote' {
            # Remove the upstream tag if it exists locally
            $result = Viscalyx.Common\Invoke-Git -WorkingDirectory $script:secondRepoPath -Arguments @('tag') -PassThru
            $existingTags = $result.Output
            if ($existingTags -contains 'upstream-v1.0.0')
            {
                Viscalyx.Common\Invoke-Git -WorkingDirectory $script:secondRepoPath -Arguments @('tag', '-d', 'upstream-v1.0.0')
            }

            # Fetch specific upstream tag
            $null = Request-GitTag -RemoteName 'upstream' -Name 'upstream-v1.0.0' -Force -ErrorAction Stop

            # Verify the tag was fetched
            $result = Viscalyx.Common\Invoke-Git -WorkingDirectory $script:secondRepoPath -Arguments @('tag') -PassThru
            $tagsAfterFetch = $result.Output
            $tagsAfterFetch | Should -Contain 'upstream-v1.0.0'
        }
    }

    Context 'Error handling with real git failures' {
        BeforeEach {
            Push-Location -Path $script:secondRepoPath
        }

        AfterEach {
            Pop-Location
        }

        It 'Should provide meaningful error when git fetch fails' {
            # Test with a malformed remote URL by temporarily changing the origin URL
            $result = Viscalyx.Common\Invoke-Git -WorkingDirectory $script:secondRepoPath -Arguments @('config', '--get', 'remote.origin.url') -PassThru
            $originalUrl = $result.Output
            Viscalyx.Common\Invoke-Git -WorkingDirectory $script:secondRepoPath -Arguments @('remote', 'set-url', 'origin', 'invalid-url')

            try
            {
                $errorRecord = { Request-GitTag -RemoteName 'origin' -Name 'v1.0.0' -Force } |
                    Should -Throw -PassThru

                $errorRecord.Exception.Message | Should -Match "Failed to fetch tag 'v1.0.0' from remote 'origin'"
                $errorRecord.FullyQualifiedErrorId | Should -Be 'RGT0001,Request-GitTag'
            }
            finally
            {
                # Restore the original URL
                Viscalyx.Common\Invoke-Git -WorkingDirectory $script:secondRepoPath -Arguments @('remote', 'set-url', 'origin', $originalUrl)
            }
        }

        It 'Should provide meaningful error when fetching all tags fails' {
            # Test with a malformed remote URL
            $result = Viscalyx.Common\Invoke-Git -WorkingDirectory $script:secondRepoPath -Arguments @('config', '--get', 'remote.origin.url') -PassThru
            $originalUrl = $result.Output
            Viscalyx.Common\Invoke-Git -WorkingDirectory $script:secondRepoPath -Arguments @('remote', 'set-url', 'origin', 'invalid-url')

            try
            {
                $errorRecord = { Request-GitTag -RemoteName 'origin' -Force } |
                    Should -Throw -PassThru

                $errorRecord.Exception.Message | Should -Match "Failed to fetch all tags from remote 'origin'"
                $errorRecord.FullyQualifiedErrorId | Should -Be 'RGT0001,Request-GitTag'
            }
            finally
            {
                # Restore the original URL
                Viscalyx.Common\Invoke-Git -WorkingDirectory $script:secondRepoPath -Arguments @('remote', 'set-url', 'origin', $originalUrl)
            }
        }
    }
}
