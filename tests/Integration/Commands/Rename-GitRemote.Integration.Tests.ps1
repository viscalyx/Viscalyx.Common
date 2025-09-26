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
    $script:bareRepoPath = Join-Path -Path $TestDrive -ChildPath 'BareRepo'
    $script:upstreamRepoPath = Join-Path -Path $TestDrive -ChildPath 'UpstreamRepo'

    New-Item -Path $script:testRepoPath -ItemType Directory -Force | Out-Null
    New-Item -Path $script:bareRepoPath -ItemType Directory -Force | Out-Null
    New-Item -Path $script:upstreamRepoPath -ItemType Directory -Force | Out-Null

    # Initialize the bare repositories (simulates remotes)
    Push-Location -Path $script:bareRepoPath
    try {
        git init --bare *> $null
    }
    finally {
        Pop-Location
    }

    Push-Location -Path $script:upstreamRepoPath
    try {
        git init --bare *> $null
    }
    finally {
        Pop-Location
    }

    # Initialize the test repository and create initial content
    Push-Location -Path $script:testRepoPath
    try {
        # Initialize git repository
        git init *> $null
        git config user.email "test@example.com" *> $null
        git config user.name "Test User" *> $null

        # Create initial commit
        "Initial content" | Out-File -FilePath 'test.txt' -Encoding utf8
        git add test.txt *> $null
        git commit -m "Initial commit" *> $null

        # Add multiple remotes for testing
        git remote add myremote $script:bareRepoPath *> $null
        git remote add upstream $script:upstreamRepoPath *> $null

        # Push to remotes to establish them
        git push -u myremote main *> $null 2> $null
        if ($LASTEXITCODE -ne 0) {
            git push -u myremote master *> $null
        }

        git push upstream main *> $null 2> $null
        if ($LASTEXITCODE -ne 0) {
            git push upstream master *> $null
        }
    }
    finally {
        Pop-Location
    }
}

AfterAll {
    # Clean up - remove the test repositories
    if (Test-Path -Path $script:testRepoPath) {
        $previousProgressPreference = $ProgressPreference
        $ProgressPreference = 'SilentlyContinue' # Suppress progress output during deletion
        Remove-Item -Path $script:testRepoPath -Recurse -Force -ErrorAction SilentlyContinue
        $ProgressPreference = $previousProgressPreference
    }
    if (Test-Path -Path $script:bareRepoPath) {
        $previousProgressPreference = $ProgressPreference
        $ProgressPreference = 'SilentlyContinue' # Suppress progress output during deletion
        Remove-Item -Path $script:bareRepoPath -Recurse -Force -ErrorAction SilentlyContinue
        $ProgressPreference = $previousProgressPreference
    }
    if (Test-Path -Path $script:upstreamRepoPath) {
        $previousProgressPreference = $ProgressPreference
        $ProgressPreference = 'SilentlyContinue' # Suppress progress output during deletion
        Remove-Item -Path $script:upstreamRepoPath -Recurse -Force -ErrorAction SilentlyContinue
        $ProgressPreference = $previousProgressPreference
    }
}

Describe 'Rename-GitRemote Integration Tests' {
    BeforeEach {
        # Change to test repository for each test
        Push-Location -Path $script:testRepoPath

        # Reset remotes to initial state for each test
        $currentRemotes = git remote
        foreach ($remote in $currentRemotes) {
            git remote remove $remote *> $null
        }

        # Re-add the test remotes
        git remote add myremote $script:bareRepoPath *> $null
        git remote add upstream $script:upstreamRepoPath *> $null
    }

    AfterEach {
        # Return to original location
        Pop-Location
    }

    Context 'When renaming an existing Git remote' {
        It 'Should rename "myremote" to "origin"' {
            # Verify initial state
            $remotesBefore = git remote
            $remotesBefore | Should -Contain 'myremote'
            $remotesBefore | Should -Not -Contain 'origin'

            # Rename the remote using the command
            Rename-GitRemote -Name 'myremote' -NewName 'origin' -ErrorAction Stop

            # Verify the remote was renamed
            $remotesAfter = git remote
            $remotesAfter | Should -Not -Contain 'myremote'
            $remotesAfter | Should -Contain 'origin'
            $remotesAfter | Should -Contain 'upstream'

            # Verify the URL was preserved
            $originUrl = git remote get-url origin
            $originUrl | Should -Be $script:bareRepoPath
        }

        It 'Should rename "upstream" to "fork"' {
            # Verify initial state
            $remotesBefore = git remote
            $remotesBefore | Should -Contain 'upstream'
            $remotesBefore | Should -Not -Contain 'fork'

            # Rename the remote using the command
            Rename-GitRemote -Name 'upstream' -NewName 'fork' -ErrorAction Stop

            # Verify the remote was renamed
            $remotesAfter = git remote
            $remotesAfter | Should -Not -Contain 'upstream'
            $remotesAfter | Should -Contain 'fork'
            $remotesAfter | Should -Contain 'myremote'

            # Verify the URL was preserved
            $forkUrl = git remote get-url fork
            $forkUrl | Should -Be $script:upstreamRepoPath
        }

        It 'Should preserve tracking branches after renaming remote' {
            # Rename the remote
            Rename-GitRemote -Name 'myremote' -NewName 'origin' -ErrorAction Stop

            # Verify that branches can still be pushed and tracked
            "Modified content" | Out-File -FilePath 'test2.txt' -Encoding utf8
            git add test2.txt *> $null
            git commit -m "Test commit after rename" *> $null

            # Set up upstream tracking for the current branch and push
            $currentBranch = git branch --show-current
            git push --set-upstream origin $currentBranch *> $null

            # Now a regular push should work without errors
            { git push origin } | Should -Not -Throw
        }
    }

    Context 'When attempting to rename a non-existent remote' {
        It 'Should throw an error when trying to rename a non-existent remote' {
            # Verify the remote doesn't exist
            $remotes = git remote
            $remotes | Should -Not -Contain 'nonexistent'

            # Attempt to rename non-existent remote should throw an error
            { Rename-GitRemote -Name 'nonexistent' -NewName 'origin' -ErrorAction Stop 2>$null } | Should -Throw
        }
    }

    Context 'When attempting to rename to an existing remote name' {
        It 'Should throw an error when trying to rename to an existing remote name' {
            # Verify both remotes exist
            $remotes = git remote
            $remotes | Should -Contain 'myremote'
            $remotes | Should -Contain 'upstream'

            # Attempt to rename to existing name should throw an error
            { Rename-GitRemote -Name 'myremote' -NewName 'upstream' -ErrorAction Stop 2>$null } | Should -Throw
        }
    }

    Context 'When renaming with verbose output' {
        It 'Should display verbose message when renaming successfully' {
            # Capture verbose output
            $verboseOutput = Rename-GitRemote -Name 'myremote' -NewName 'origin' -Verbose -ErrorAction Stop 4>&1

            # Should contain success message
            $verboseOutput | Should -Match "Successfully renamed remote 'myremote' to 'origin'"
        }
    }
}
