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

    # Set a fallback default branch name for contexts that don't have git repositories
    $script:fallbackBranch = 'main'
}

Describe 'Test-GitRemoteBranch' -Tag 'Integration' {
    Context 'When repository has remotes configured' {
        BeforeEach {
            # Set the branch name for consistent reference throughout the test
            $script:defaultBranch = 'main'

            # Create a temporary directory for our test git repository
            $script:testRepoPath = Join-Path -Path $TestDrive -ChildPath "TestRepo_$([guid]::NewGuid().Guid)"
            New-Item -Path $script:testRepoPath -ItemType Directory -Force | Out-Null

            # Store the original location to restore later
            $script:originalLocation = Get-Location

            # Change to the test repository directory
            Set-Location -Path $script:testRepoPath

            # Initialize git repository with the specified default branch
            $null = git init --initial-branch $script:defaultBranch --quiet 2>&1
            $null = git config user.email "test@example.com" 2>&1
            $null = git config user.name "Test User" 2>&1

            # Create an initial commit to establish a proper git repository
            "Initial content" | Out-File -FilePath "README.md" -Encoding utf8
            $null = git add . 2>&1
            $null = git commit -m "Initial commit" --quiet 2>&1

            # Create a bare repository to act as our "remote"
            $script:bareRepoPath = Join-Path -Path $TestDrive -ChildPath "BareRepo_$([guid]::NewGuid().Guid)"
            $null = git init --bare $script:bareRepoPath --quiet 2>&1

            # Add the bare repository as a remote
            $null = git remote add origin $script:bareRepoPath 2>&1

            # Push initial branch to create remote branch - capture output for debugging
            $pushOutput = git push origin $script:defaultBranch --quiet 2>&1
            if ($LASTEXITCODE -ne 0) {
                Write-Warning "Push failed with exit code $LASTEXITCODE. Output: $pushOutput"
            }
        }

        AfterEach {
            # Return to original location
            if ($script:originalLocation) {
                Set-Location -Path $script:originalLocation
            }

            # Clean up test directories
            $previousProgressPreference = $ProgressPreference
            $ProgressPreference = 'SilentlyContinue' # Suppress progress output during deletion
            if ($script:testRepoPath -and (Test-Path -Path $script:testRepoPath)) {
                Remove-Item -Path $script:testRepoPath -Recurse -Force -ErrorAction SilentlyContinue
            }
            if ($script:bareRepoPath -and (Test-Path -Path $script:bareRepoPath)) {
                Remove-Item -Path $script:bareRepoPath -Recurse -Force -ErrorAction SilentlyContinue
            }
            $ProgressPreference = $previousProgressPreference
        }

        It 'Should return true when testing existing remote branch' {
            $result = Test-GitRemoteBranch -RemoteName 'origin' -Name $script:defaultBranch
            $result | Should -BeTrue
        }

        It 'Should return false when testing non-existent remote branch' {
            $result = Test-GitRemoteBranch -RemoteName 'origin' -Name 'nonexistent-branch' 2>$null
            $result | Should -BeFalse
        }

        It 'Should return true when testing remote without specifying branch name and branches exist' {
            $result = Test-GitRemoteBranch -RemoteName 'origin'
            $result | Should -BeTrue
        }

        It 'Should throw an exception when testing non-existent remote' {
            { Test-GitRemoteBranch -RemoteName 'nonexistent-remote' -Name $script:defaultBranch -ErrorAction 'Stop' } | Should -Throw
        }

        Context 'When multiple branches exist' {
            BeforeEach {
                # Create additional branches and push them
                $null = git checkout -b develop --quiet 2>&1
                "Develop content" | Out-File -FilePath "develop.md" -Encoding utf8
                $null = git add . 2>&1
                $null = git commit -m "Develop commit" --quiet 2>&1
                $null = git push origin develop --quiet 2>&1

                $null = git checkout -b feature/test --quiet 2>&1
                "Feature content" | Out-File -FilePath "feature.md" -Encoding utf8
                $null = git add . 2>&1
                $null = git commit -m "Feature commit" --quiet 2>&1
                $null = git push origin feature/test --quiet 2>&1

                # Return to default branch
                $null = git checkout $script:defaultBranch --quiet 2>&1
            }

            It 'Should return true when testing specific existing branches' {
                Test-GitRemoteBranch -RemoteName 'origin' -Name $script:defaultBranch | Should -BeTrue
                Test-GitRemoteBranch -RemoteName 'origin' -Name 'develop' | Should -BeTrue
                Test-GitRemoteBranch -RemoteName 'origin' -Name 'feature/test' | Should -BeTrue
            }

            It 'Should return true when testing with wildcard patterns' {
                Test-GitRemoteBranch -RemoteName 'origin' -Name 'feature/*' | Should -BeTrue
            }

            It 'Should return false for non-matching wildcard patterns' {
                Test-GitRemoteBranch -RemoteName 'origin' -Name 'hotfix/*' 2>$null | Should -BeFalse
            }

            It 'Should return true when checking any branches exist for remote' {
                Test-GitRemoteBranch -RemoteName 'origin' | Should -BeTrue
            }
        }

        Context 'When testing edge cases' {
            It 'Should handle branch names with special characters' {
                # Create branch with special characters
                $null = git checkout -b "feature/test-branch_v1.0" --quiet 2>&1
                "Special content" | Out-File -FilePath "special.md" -Encoding utf8
                $null = git add . 2>&1
                $null = git commit -m "Special commit" --quiet 2>&1
                $null = git push origin "feature/test-branch_v1.0" --quiet 2>&1

                Test-GitRemoteBranch -RemoteName 'origin' -Name 'feature/test-branch_v1.0' | Should -BeTrue
            }

            It 'Should handle branch names with case sensitivity' {
                # Create branch with specific case
                $null = git checkout -b "FeatureBranch" --quiet 2>&1
                "Feature content" | Out-File -FilePath "feature.md" -Encoding utf8
                $null = git add . 2>&1
                $null = git commit -m "Feature commit" --quiet 2>&1
                $null = git push origin "FeatureBranch" --quiet 2>&1

                Test-GitRemoteBranch -RemoteName 'origin' -Name 'FeatureBranch' | Should -BeTrue
                Test-GitRemoteBranch -RemoteName 'origin' -Name 'featurebranch' 2>$null | Should -BeFalse
            }
        }
    }

    Context 'When no remotes are configured' {
        BeforeEach {
            # Set the branch name for consistent reference throughout the test
            $script:defaultBranch = 'main'

            # Create a temporary directory for our test git repository
            $script:testRepoPath = Join-Path -Path $TestDrive -ChildPath "NoRemoteRepo_$([guid]::NewGuid().Guid)"
            New-Item -Path $script:testRepoPath -ItemType Directory -Force | Out-Null

            # Store the original location to restore later
            $script:originalLocation = Get-Location

            # Change to the test repository directory
            Set-Location -Path $script:testRepoPath

            # Initialize git repository with the specified default branch (no remotes)
            $null = git init --initial-branch $script:defaultBranch --quiet 2>&1
            $null = git config user.email "test@example.com" 2>&1
            $null = git config user.name "Test User" 2>&1

            # Create an initial commit
            "Initial content" | Out-File -FilePath "README.md" -Encoding utf8
            $null = git add . 2>&1
            $null = git commit -m "Initial commit" --quiet 2>&1
        }

        AfterEach {
            # Return to original location
            if ($script:originalLocation) {
                Set-Location -Path $script:originalLocation
            }

            # Clean up test directory
            $previousProgressPreference = $ProgressPreference
            $ProgressPreference = 'SilentlyContinue' # Suppress progress output during deletion
            if ($script:testRepoPath -and (Test-Path -Path $script:testRepoPath)) {
                Remove-Item -Path $script:testRepoPath -Recurse -Force -ErrorAction SilentlyContinue
            }
            $ProgressPreference = $previousProgressPreference
        }

        It 'Should return false when testing remote branch without configured remotes' {
            $result = Test-GitRemoteBranch -RemoteName 'origin' -Name $script:defaultBranch 2>$null
            $result | Should -BeFalse
        }

        It 'Should return false when testing any remote branches without configured remotes' {
            $result = Test-GitRemoteBranch -RemoteName 'origin' 2>$null
            $result | Should -BeFalse
        }

        It 'Should return false when testing without specifying remote' {
            $result = Test-GitRemoteBranch 2>$null
            $result | Should -BeFalse
        }
    }

    Context 'When not in a git repository' {
        BeforeEach {
            # Create a temporary directory that is not a git repository
            $script:nonGitPath = Join-Path -Path $TestDrive -ChildPath "NonGitRepo_$([guid]::NewGuid().Guid)"
            New-Item -Path $script:nonGitPath -ItemType Directory -Force | Out-Null

            # Store the original location to restore later
            $script:originalLocation = Get-Location

            # Change to the non-git directory
            Set-Location -Path $script:nonGitPath
        }

        AfterEach {
            # Return to original location
            if ($script:originalLocation) {
                Set-Location -Path $script:originalLocation
            }

            # Clean up test directory
            $previousProgressPreference = $ProgressPreference
            $ProgressPreference = 'SilentlyContinue' # Suppress progress output during deletion
            if ($script:nonGitPath -and (Test-Path -Path $script:nonGitPath)) {
                Remove-Item -Path $script:nonGitPath -Recurse -Force -ErrorAction SilentlyContinue
            }
            $ProgressPreference = $previousProgressPreference
        }

        It 'Should return false when not in a git repository' {
            $result = Test-GitRemoteBranch -RemoteName 'origin' -Name $script:fallbackBranch 2>$null
            $result | Should -BeFalse
        }

        It 'Should return false when testing any remote branches outside git repository' {
            $result = Test-GitRemoteBranch -RemoteName 'origin' 2>$null
            $result | Should -BeFalse
        }

        It 'Should return false when testing without specifying remote outside git repository' {
            $result = Test-GitRemoteBranch 2>$null
            $result | Should -BeFalse
        }
    }

    Context 'When testing with unreachable remote' {
        BeforeEach {
            # Set the branch name for consistent reference throughout the test
            $script:defaultBranch = 'main'

            # Create a temporary directory for our test git repository
            $script:testRepoPath = Join-Path -Path $TestDrive -ChildPath "UnreachableRemoteRepo_$([guid]::NewGuid().Guid)"
            New-Item -Path $script:testRepoPath -ItemType Directory -Force | Out-Null

            # Store the original location to restore later
            $script:originalLocation = Get-Location

            # Change to the test repository directory
            Set-Location -Path $script:testRepoPath

            # Initialize git repository with the specified default branch
            $null = git init --initial-branch $script:defaultBranch --quiet 2>&1
            $null = git config user.email "test@example.com" 2>&1
            $null = git config user.name "Test User" 2>&1

            # Create an initial commit
            "Initial content" | Out-File -FilePath "README.md" -Encoding utf8
            $null = git add . 2>&1
            $null = git commit -m "Initial commit" --quiet 2>&1

            # Add an unreachable remote (non-existent path)
            $unreachablePath = "/nonexistent/path/to/repo.git"
            $null = git remote add origin $unreachablePath 2>&1
        }

        AfterEach {
            # Return to original location
            if ($script:originalLocation) {
                Set-Location -Path $script:originalLocation
            }

            # Clean up test directory
            $previousProgressPreference = $ProgressPreference
            $ProgressPreference = 'SilentlyContinue' # Suppress progress output during deletion
            if ($script:testRepoPath -and (Test-Path -Path $script:testRepoPath)) {
                Remove-Item -Path $script:testRepoPath -Recurse -Force -ErrorAction SilentlyContinue
            }
            $ProgressPreference = $previousProgressPreference
        }

        It 'Should return false when remote is unreachable' {
            $result = Test-GitRemoteBranch -RemoteName 'origin' -Name $script:defaultBranch 2>$null
            $result | Should -BeFalse
        }

        It 'Should return false when testing any branches from unreachable remote' {
            $result = Test-GitRemoteBranch -RemoteName 'origin' 2>$null
            $result | Should -BeFalse
        }
    }
}
