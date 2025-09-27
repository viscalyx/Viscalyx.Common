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
        git init --bare *> $null
        if ($LASTEXITCODE -ne 0)
        {
            throw 'Failed to initialize bare repository'
        }
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
        git init *> $null
        if ($LASTEXITCODE -ne 0)
        {
            throw 'Failed to initialize test repository'
        }

        # Configure git user for testing
        git config user.name 'Test User' *> $null
        git config user.email 'test@example.com' *> $null

        # Create initial commit
        'Initial content' | Out-File -FilePath 'test.txt' -Encoding utf8
        git add . *> $null
        git commit -m 'Initial commit' *> $null
        if ($LASTEXITCODE -ne 0)
        {
            throw 'Failed to create initial commit'
        }

        # Add the bare repository as origin remote
        git remote add origin $script:bareRepoPath *> $null
        if ($LASTEXITCODE -ne 0)
        {
            throw 'Failed to add origin remote'
        }

        # Get the current branch name (don't assume 'main' or 'master')
        $currentBranch = git branch --show-current 2>$null
        if (-not $currentBranch)
        {
            throw 'Failed to determine current branch name'
        }

        # Push to origin
        git push --set-upstream origin $currentBranch --quiet 2>$null
        if ($LASTEXITCODE -ne 0)
        {
            throw 'Failed to push to origin'
        }

        # Create and push tags
        git tag 'v1.0.0' *> $null
        git tag 'v1.1.0' *> $null
        git tag 'v2.0.0' *> $null

        git push origin --tags *> $null
        if ($LASTEXITCODE -ne 0)
        {
            throw 'Failed to push tags to origin'
        }
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
        git clone $script:bareRepoPath . *> $null
        if ($LASTEXITCODE -ne 0)
        {
            throw 'Failed to clone repository'
        }

        # Configure git user for testing
        git config user.name 'Test User' *> $null
        git config user.email 'test@example.com' *> $null

        # Remove all local tags to test fetching
        $tags = git tag
        if ($tags)
        {
            git tag -d $tags *> $null
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
        try
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
        catch
        {
            # Ignore cleanup errors - TestDrive will handle remaining cleanup
        }
    }

    if ($script:secondRepoPath -and (Test-Path -Path $script:secondRepoPath))
    {
        try
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
        catch
        {
            # Ignore cleanup errors - TestDrive will handle remaining cleanup
        }
    }

    if ($script:bareRepoPath -and (Test-Path -Path $script:bareRepoPath))
    {
        try
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
        catch
        {
            # Ignore cleanup errors - TestDrive will handle remaining cleanup
        }
    }
}

Describe 'Request-GitTag Integration Tests' {
    Context 'When fetching a specific tag from origin remote' {
        BeforeEach {
            Push-Location -Path $script:secondRepoPath
        }

        AfterEach {
            Pop-Location
        }

        It 'Should successfully fetch a specific tag' {
            # Verify tag doesn't exist locally
            $existingTags = git tag 2>$null
            $existingTags | Should -Not -Contain 'v1.0.0'

            # Debug output to understand what's happening
            Write-Host "DEBUG: About to call Request-GitTag with RemoteName 'origin' and Name 'v1.0.0'"

            # Fetch the specific tag
            { Request-GitTag -RemoteName 'origin' -Name 'v1.0.0' -Force -Verbose } | Should -Not -Throw

            # Verify the tag now exists locally
            $tagsAfterFetch = git tag 2>$null
            $tagsAfterFetch | Should -Contain 'v1.0.0'
        }

        It 'Should successfully fetch multiple specific tags' {
            # Remove any existing tags
            $existingTags = git tag 2>$null
            if ($existingTags)
            {
                git tag -d $existingTags 2>$null
            }

            # Verify tags don't exist locally
            $existingTags = git tag 2>$null
            $existingTags | Should -Not -Contain 'v1.1.0'
            $existingTags | Should -Not -Contain 'v2.0.0'

            # Fetch specific tags
            Request-GitTag -RemoteName 'origin' -Name 'v1.1.0' -Force
            Request-GitTag -RemoteName 'origin' -Name 'v2.0.0' -Force

            # Verify the tags now exist locally
            $tagsAfterFetch = git tag 2>$null
            $tagsAfterFetch | Should -Contain 'v1.1.0'
            $tagsAfterFetch | Should -Contain 'v2.0.0'
        }

        It 'Should handle non-existent tag gracefully' {
            # Attempt to fetch a non-existent tag (redirect errors to suppress console noise)
            { Request-GitTag -RemoteName 'origin' -Name 'non-existent-tag' -Force 2>$null } |
                Should -Throw -ErrorId 'RGT0001,Request-GitTag'
        }
    }

    Context 'When fetching all tags from origin remote' {
        BeforeEach {
            Push-Location -Path $script:secondRepoPath

            # Remove all local tags to test fetching all
            $existingTags = git tag 2>$null
            if ($existingTags)
            {
                git tag -d $existingTags 2>$null
            }
        }

        AfterEach {
            Pop-Location
        }

        It 'Should successfully fetch all tags' {
            # Verify no tags exist locally
            $existingTags = git tag 2>$null
            $existingTags | Should -BeNullOrEmpty

            # Fetch all tags
            { Request-GitTag -RemoteName 'origin' -Force } | Should -Not -Throw

            # Verify all tags now exist locally
            $tagsAfterFetch = git tag 2>$null
            $tagsAfterFetch | Should -Contain 'v1.0.0'
            $tagsAfterFetch | Should -Contain 'v1.1.0'
            $tagsAfterFetch | Should -Contain 'v2.0.0'
        }

        It 'Should work when tags already exist locally' {
            # First fetch all tags
            Request-GitTag -RemoteName 'origin' -Force

            # Verify tags exist
            $tagsBeforeSecondFetch = git tag 2>$null
            $tagsBeforeSecondFetch | Should -Contain 'v1.0.0'

            # Fetch again - should not fail
            { Request-GitTag -RemoteName 'origin' -Force } | Should -Not -Throw

            # Verify tags still exist
            $tagsAfterSecondFetch = git tag 2>$null
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
            { Request-GitTag -RemoteName 'nonexistent' -Force 2>$null } |
                Should -Throw -ErrorId 'RGT0001,Request-GitTag'
        }

        It 'Should throw error when trying to fetch specific tag from invalid remote' {
            { Request-GitTag -RemoteName 'invalid-remote' -Name 'v1.0.0' -Force 2>$null } |
                Should -Throw -ErrorId 'RGT0001,Request-GitTag'
        }
    }

    Context 'ShouldProcess integration with real git commands' {
        BeforeEach {
            Push-Location -Path $script:secondRepoPath

            # Remove test tag if it exists
            $existingTags = git tag 2>$null
            if ($existingTags -contains 'v1.0.0')
            {
                git tag -d 'v1.0.0' 2>$null
            }
        }

        AfterEach {
            Pop-Location
        }

        It 'Should not fetch tags when using WhatIf for specific tag' {
            # Ensure no tags exist initially
            $tagsBeforeWhatIf = git tag 2>$null

            # WhatIf should not perform the actual operation
            Request-GitTag -RemoteName 'origin' -Name 'v1.0.0' -WhatIf 2>$null

            # Verify that no tags were actually fetched
            $tagsAfterWhatIf = git tag 2>$null
            $tagsAfterWhatIf | Should -Be $tagsBeforeWhatIf
        }

        It 'Should not fetch tags when using WhatIf for all tags' {
            # Ensure no tags exist initially
            $tagsBeforeWhatIf = git tag 2>$null

            # WhatIf should not perform the actual operation
            Request-GitTag -RemoteName 'origin' -WhatIf 2>$null

            # Verify that no tags were actually fetched
            $tagsAfterWhatIf = git tag 2>$null
            $tagsAfterWhatIf | Should -Be $tagsBeforeWhatIf
        }

        It 'Should respect -Confirm:$false with -Force' {
            # This should execute without prompting
            { Request-GitTag -RemoteName 'origin' -Name 'v1.0.0' -Force -Confirm:$false } | Should -Not -Throw

            # Verify the tag was actually fetched
            $tagsAfterFetch = git tag 2>$null
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
                git init --bare *> $null
                if ($LASTEXITCODE -ne 0)
                {
                    throw 'Failed to initialize upstream repository'
                }
            }
            finally
            {
                Pop-Location
            }

            # Add upstream remote to the second repo and create a different tag
            Push-Location -Path $script:testRepoPath
            try
            {
                git remote add upstream $script:upstreamRepoPath *> $null
                git tag 'upstream-v1.0.0' *> $null

                # Get the current branch name (don't assume 'main' or 'master')
                $currentBranch = git branch --show-current 2>$null
                if (-not $currentBranch)
                {
                    throw 'Failed to determine current branch name'
                }

                git push upstream $currentBranch --quiet 2>$null
                git push upstream --tags --quiet 2>$null
            }
            finally
            {
                Pop-Location
            }

            # Add upstream remote to second repo for testing
            Push-Location -Path $script:secondRepoPath
            try
            {
                git remote add upstream $script:upstreamRepoPath *> $null
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
            $existingTags = git tag
            if ($existingTags)
            {
                git tag -d $existingTags *> $null
            }

            # Fetch from origin
            Request-GitTag -RemoteName 'origin' -Force
            $originTags = git tag 2>$null
            $originTags | Should -Contain 'v1.0.0'

            # Remove all tags again
            if ($originTags)
            {
                git tag -d $originTags 2>$null
            }

            # Fetch from upstream
            Request-GitTag -RemoteName 'upstream' -Force
            $upstreamTags = git tag 2>$null
            $upstreamTags | Should -Contain 'upstream-v1.0.0'
        }

        It 'Should fetch specific tag from upstream remote' {
            # Remove the upstream tag if it exists locally
            $existingTags = git tag 2>$null
            if ($existingTags -contains 'upstream-v1.0.0')
            {
                git tag -d 'upstream-v1.0.0' 2>$null
            }

            # Fetch specific upstream tag
            Request-GitTag -RemoteName 'upstream' -Name 'upstream-v1.0.0' -Force

            # Verify the tag was fetched
            $tagsAfterFetch = git tag 2>$null
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
            $originalUrl = git config --get remote.origin.url
            git remote set-url origin 'invalid-url' *> $null

            try
            {
                $errorRecord = { Request-GitTag -RemoteName 'origin' -Name 'v1.0.0' -Force 2>$null } |
                    Should -Throw -PassThru

                $errorRecord.Exception.Message | Should -Match "Failed to fetch tag 'v1.0.0' from remote 'origin'"
                $errorRecord.FullyQualifiedErrorId | Should -Be 'RGT0001,Request-GitTag'
            }
            finally
            {
                # Restore the original URL
                git remote set-url origin $originalUrl *> $null
            }
        }

        It 'Should provide meaningful error when fetching all tags fails' {
            # Test with a malformed remote URL
            $originalUrl = git config --get remote.origin.url
            git remote set-url origin 'invalid-url' *> $null

            try
            {
                $errorRecord = { Request-GitTag -RemoteName 'origin' -Force 2>$null } |
                    Should -Throw -PassThru

                $errorRecord.Exception.Message | Should -Match "Failed to fetch all tags from remote 'origin'"
                $errorRecord.FullyQualifiedErrorId | Should -Be 'RGT0001,Request-GitTag'
            }
            finally
            {
                # Restore the original URL
                git remote set-url origin $originalUrl *> $null
            }
        }
    }
}
