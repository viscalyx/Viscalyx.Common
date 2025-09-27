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

    New-Item -Path $script:testRepoPath -ItemType Directory -Force | Out-Null
    New-Item -Path $script:bareRepoPath -ItemType Directory -Force | Out-Null

    # Initialize the bare repository (simulates a remote)
    Push-Location -Path $script:bareRepoPath
    try {
        git init --bare *> $null
    }
    finally {
        Pop-Location
    }

    # Initialize the test repository and create test commits
    Push-Location -Path $script:testRepoPath
    try {
        # Initialize git repository
        git init *> $null
        git config user.email "test@example.com" *> $null
        git config user.name "Test User" *> $null

        # Add remote pointing to bare repository
        git remote add origin $script:bareRepoPath *> $null

        # Create initial commit
        "Initial content" | Out-File -FilePath 'test1.txt' -Encoding utf8
        git add test1.txt *> $null
        git commit -m "Initial commit" *> $null

        # Push to remote
        git push -u origin main --quiet 2>$null
        if ($LASTEXITCODE -ne 0) {
            git push -u origin master --quiet 2>$null
        }

        # Create test tags locally and push them
        git tag 'test-tag-1' *> $null
        git tag 'test-tag-2' *> $null
        git tag 'test-tag-3' *> $null

        # Push tags to remote
        git push origin --tags *> $null
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
}

Describe 'Remove-GitTag Integration Tests' {
    Context 'When removing tags from local repository' {
        BeforeEach {
            Push-Location -Path $script:testRepoPath

            # Clean slate for each test
            git tag -l | ForEach-Object { git tag -d $_ *> $null 2>&1 }
            git ls-remote --tags origin 2>$null | ForEach-Object {
                if ($_ -match 'refs/tags/(.+?)(\^{})?$') {
                    git push origin ":refs/tags/$($matches[1])" *> $null 2>&1
                }
            }
            Start-Sleep -Milliseconds 100

            # Create fresh test tags
            git tag 'test-tag-1' *> $null
            git tag 'test-tag-2' *> $null
            git tag 'test-tag-3' *> $null
            git push origin 'test-tag-1' *> $null 2>&1
            git push origin 'test-tag-2' *> $null 2>&1
            git push origin 'test-tag-3' *> $null 2>&1
            Start-Sleep -Milliseconds 100
        }

        AfterEach {
            Pop-Location
        }

        It 'Should remove a single tag from local repository' {
            # Verify tag exists
            $tagsBefore = git tag -l 'test-tag-1'
            $tagsBefore | Should -Be 'test-tag-1'

            # Remove the tag
            Remove-GitTag -Tag 'test-tag-1' -Force

            # Verify tag is removed
            $tagsAfter = git tag -l 'test-tag-1'
            $tagsAfter | Should -BeNullOrEmpty
        }

        It 'Should remove multiple tags from local repository' {
            # Verify tags exist
            $tagsBefore = git tag -l
            $tagsBefore | Should -Contain 'test-tag-1'
            $tagsBefore | Should -Contain 'test-tag-2'

            # Remove multiple tags
            Remove-GitTag -Tag @('test-tag-1', 'test-tag-2') -Force

            # Verify tags are removed
            $tagsAfter = git tag -l
            $tagsAfter | Should -Not -Contain 'test-tag-1'
            $tagsAfter | Should -Not -Contain 'test-tag-2'
            $tagsAfter | Should -Contain 'test-tag-3'
        }

        It 'Should remove tag using Local switch explicitly' {
            # Verify tag exists
            $tagsBefore = git tag -l 'test-tag-1'
            $tagsBefore | Should -Be 'test-tag-1'

            # Remove the tag with Local switch
            Remove-GitTag -Tag 'test-tag-1' -Local -Force

            # Verify tag is removed
            $tagsAfter = git tag -l 'test-tag-1'
            $tagsAfter | Should -BeNullOrEmpty
        }
    }

    Context 'When removing tags from remote repository' {
        BeforeEach {
            Push-Location -Path $script:testRepoPath

            # Clean slate for each test
            git tag -l | ForEach-Object { git tag -d $_ *> $null 2>&1 }
            git ls-remote --tags origin 2>$null | ForEach-Object {
                if ($_ -match 'refs/tags/(.+?)(\^{})?$') {
                    git push origin ":refs/tags/$($matches[1])" *> $null 2>&1
                }
            }
            Start-Sleep -Milliseconds 100
        }

        AfterEach {
            Pop-Location
        }

        It 'Should remove a single tag from remote repository' {
            # Create a tag for this specific test
            git tag 'remote-test-tag' *> $null
            git push origin 'remote-test-tag' *> $null
            Start-Sleep -Milliseconds 200

            # Verify tag exists on remote
            $remoteTagsBefore = git ls-remote --tags origin 2>$null
            $remoteTagsBefore | Should -Match 'refs/tags/remote-test-tag'

            # Remove the tag from remote only
            Remove-GitTag -Tag 'remote-test-tag' -Remote 'origin' -Force
            Start-Sleep -Milliseconds 200

            # Verify tag is removed from remote
            $remoteTagsAfter = git ls-remote --tags origin 2>$null
            $remoteTagsAfter | Should -Not -Match 'refs/tags/remote-test-tag'

            # Verify tag still exists locally
            $localTags = git tag -l 'remote-test-tag'
            $localTags | Should -Be 'remote-test-tag'
        }

        It 'Should remove multiple tags from remote repository' {
            # Create tags for this specific test
            git tag 'remote-test-tag-1' *> $null
            git tag 'remote-test-tag-2' *> $null

            # Push tags individually with error checking
            $result1 = git push origin 'remote-test-tag-1' 2>&1
            Start-Sleep -Milliseconds 100
            $result2 = git push origin 'remote-test-tag-2' 2>&1
            Start-Sleep -Milliseconds 300  # Increased wait time

            # Verify tags exist on remote
            $remoteTagsBefore = git ls-remote --tags origin 2>$null

            ($remoteTagsBefore -join ' ') | Should -Match 'refs/tags/remote-test-tag-1'
            ($remoteTagsBefore -join ' ') | Should -Match 'refs/tags/remote-test-tag-2'

            # Remove multiple tags from remote
            Remove-GitTag -Tag @('remote-test-tag-1', 'remote-test-tag-2') -Remote 'origin' -Force
            Start-Sleep -Milliseconds 300  # Increased wait time

            # Verify tags are removed from remote
            $remoteTagsAfter = git ls-remote --tags origin 2>$null
            ($remoteTagsAfter -join ' ') | Should -Not -Match 'refs/tags/remote-test-tag-1'
            ($remoteTagsAfter -join ' ') | Should -Not -Match 'refs/tags/remote-test-tag-2'

            # Verify tags still exist locally
            $localTags = git tag -l
            $localTags | Should -Contain 'remote-test-tag-1'
            $localTags | Should -Contain 'remote-test-tag-2'
        }
    }

    Context 'When removing tags from both local and remote repositories' {
        BeforeEach {
            Push-Location -Path $script:testRepoPath

            # Clean slate for each test
            git tag -l | ForEach-Object { git tag -d $_ *> $null 2>&1 }
            git ls-remote --tags origin 2>$null | ForEach-Object {
                if ($_ -match 'refs/tags/(.+?)(\^{})?$') {
                    git push origin ":refs/tags/$($matches[1])" *> $null 2>&1
                }
            }
            Start-Sleep -Milliseconds 100
        }

        AfterEach {
            Pop-Location
        }

        It 'Should remove tag from both local and remote when both are specified' {
            # Create a tag for this specific test
            git tag 'both-test-tag' *> $null
            git push origin 'both-test-tag' *> $null
            Start-Sleep -Milliseconds 200

            # Verify tag exists both locally and remotely
            $localTagsBefore = git tag -l 'both-test-tag'
            $remoteTagsBefore = git ls-remote --tags origin 2>$null
            $localTagsBefore | Should -Be 'both-test-tag'
            $remoteTagsBefore | Should -Match 'refs/tags/both-test-tag'

            # Remove the tag from both
            Remove-GitTag -Tag 'both-test-tag' -Local -Remote 'origin' -Force
            Start-Sleep -Milliseconds 200

            # Verify tag is removed from both
            $localTagsAfter = git tag -l 'both-test-tag'
            $remoteTagsAfter = git ls-remote --tags origin 2>$null
            $localTagsAfter | Should -BeNullOrEmpty
            $remoteTagsAfter | Should -Not -Match 'refs/tags/both-test-tag'
        }
    }

    Context 'When handling errors' {
        BeforeEach {
            Push-Location -Path $script:testRepoPath

            # Setup clean environment with base tags
            git tag -l | ForEach-Object { git tag -d $_ *> $null 2>&1 }
            git tag 'test-tag-1' *> $null
            git push origin 'test-tag-1' *> $null 2>&1
        }

        AfterEach {
            Pop-Location
        }

        It 'Should throw error when trying to remove non-existent local tag' {
            {
                Remove-GitTag -Tag 'non-existent-tag' -Force 2>$null
            } | Should -Throw
        }

        It 'Should throw error when trying to remove from non-existent remote' {
            {
                Remove-GitTag -Tag 'test-tag-1' -Remote 'non-existent-remote' -Force 2>$null
            } | Should -Throw
        }

        It 'Should handle non-existent remote tag removal gracefully' {
            # Git doesn't actually throw an error when trying to remove a non-existent remote tag
            # It just reports a warning, so this test ensures the command completes without throwing
            { Remove-GitTag -Tag 'non-existent-tag' -Remote 'origin' -Force } | Should -Not -Throw
        }
    }

    Context 'When using WhatIf' {
        BeforeEach {
            Push-Location -Path $script:testRepoPath

            # Setup clean environment with test tag
            git tag -l | ForEach-Object { git tag -d $_ *> $null 2>&1 }
            git tag 'test-tag-1' *> $null
        }

        AfterEach {
            Pop-Location
        }

        It 'Should not remove tag when WhatIf is specified' {
            # Verify tag exists
            $tagsBefore = git tag -l 'test-tag-1'
            $tagsBefore | Should -Be 'test-tag-1'

            # Use WhatIf
            Remove-GitTag -Tag 'test-tag-1' -WhatIf

            # Verify tag still exists
            $tagsAfter = git tag -l 'test-tag-1'
            $tagsAfter | Should -Be 'test-tag-1'
        }
    }
}
