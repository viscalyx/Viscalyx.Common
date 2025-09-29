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

    # Initialize the test repository and create test structure
    Push-Location -Path $script:testRepoPath
    try
    {
        # Initialize git repository
        git init --initial-branch=main --quiet 2>$null
        git config user.email 'test@example.com' *> $null
        git config user.name 'Test User' *> $null

        # Create initial commit
        'Initial content' | Out-File -FilePath 'test.txt' -Encoding utf8
        git add test.txt *> $null
        git commit -m 'Initial commit' *> $null

        # Create feature branches for testing
        git checkout -b 'feature/branch1' --quiet 2>$null
        'Feature 1 content' | Out-File -FilePath 'feature1.txt' -Encoding utf8
        git add feature1.txt *> $null
        git commit -m 'Feature 1 commit' *> $null

        git checkout -b 'feature/branch2' --quiet 2>$null
        'Feature 2 content' | Out-File -FilePath 'feature2.txt' -Encoding utf8
        git add feature2.txt *> $null
        git commit -m 'Feature 2 commit' *> $null

        git checkout -b 'bugfix/issue123' --quiet 2>$null
        'Bug fix content' | Out-File -FilePath 'bugfix.txt' -Encoding utf8
        git add bugfix.txt *> $null
        git commit -m 'Bug fix commit' *> $null

        git checkout -b 'develop' --quiet 2>$null
        'Develop content' | Out-File -FilePath 'develop.txt' -Encoding utf8
        git add develop.txt *> $null
        git commit -m 'Develop commit' *> $null

        # Switch back to main branch
        git checkout main --quiet 2>$null

        # Store the current branch name for tests
        $script:defaultBranch = git rev-parse --abbrev-ref HEAD
    }
    finally
    {
        Pop-Location
    }
}

AfterAll {
    # Clean up - remove the test repository
    if (Test-Path -Path $script:testRepoPath)
    {
        $previousProgressPreference = $ProgressPreference
        $ProgressPreference = 'SilentlyContinue' # Suppress progress output during deletion
        Remove-Item -Path $script:testRepoPath -Recurse -Force -ErrorAction SilentlyContinue
        $ProgressPreference = $previousProgressPreference
    }
}

Describe 'Get-GitLocalBranchName' {
    BeforeEach {
        # Change to test repository for each test
        Push-Location -Path $script:testRepoPath
    }

    AfterEach {
        # Return to original location
        Pop-Location
    }

    Context 'When getting current branch name' {
        It 'Should return the current branch name' {
            $result = Get-GitLocalBranchName -Current -ErrorAction Stop

            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [string]
            $result | Should -Be $script:defaultBranch
        }

        It 'Should return correct branch name after switching branches' {
            # Switch to feature branch
            if ($PSVersionTable.PSEdition -eq 'Desktop')
            {
                # Windows PowerShell - use cmd.exe for reliable output suppression
                & cmd.exe /c 'git checkout feature/branch1 >nul 2>&1'
            }
            else
            {
                # PowerShell 7+ - use direct redirection
                git checkout feature/branch1 *>$null
            }

            $result = Get-GitLocalBranchName -Current -ErrorAction Stop

            $result | Should -Be 'feature/branch1'

            # Switch back to default branch
            if ($PSVersionTable.PSEdition -eq 'Desktop')
            {
                # Windows PowerShell - use cmd.exe for reliable output suppression
                & cmd.exe /c "git checkout $script:defaultBranch >nul 2>&1"
            }
            else
            {
                # PowerShell 7+ - use direct redirection
                git checkout $script:defaultBranch *>$null
            }
        }
    }

    Context 'When getting all branch names' {
        It 'Should return all local branch names' {
            $result = Get-GitLocalBranchName -ErrorAction Stop

            $result | Should -Not -BeNullOrEmpty
            $result | Should -Contain $script:defaultBranch
            $result | Should -Contain 'feature/branch1'
            $result | Should -Contain 'feature/branch2'
            $result | Should -Contain 'bugfix/issue123'
            $result | Should -Contain 'develop'
            $result | Should -HaveCount 5
        }

        It 'Should return branch names as strings' {
            $result = Get-GitLocalBranchName -ErrorAction Stop

            $result | ForEach-Object {
                $_ | Should -BeOfType [string]
                $_ | Should -Not -BeNullOrEmpty
            }
        }
    }

    Context 'When getting branch by exact name' {
        It 'Should return exact match for existing branch' {
            $result = Get-GitLocalBranchName -Name 'develop' -ErrorAction Stop

            $result | Should -Be 'develop'
        }

        It 'Should return exact match for default branch' {
            $result = Get-GitLocalBranchName -Name $script:defaultBranch -ErrorAction Stop

            $result | Should -Be $script:defaultBranch
        }

        It 'Should return nothing for non-existent branch' {
            $result = Get-GitLocalBranchName -Name 'nonexistent' -ErrorAction Stop

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'When using wildcard patterns' {
        It 'Should return all feature branches with feature/* pattern' {
            $result = Get-GitLocalBranchName -Name 'feature/*' -ErrorAction Stop

            $result | Should -Not -BeNullOrEmpty
            $result | Should -Contain 'feature/branch1'
            $result | Should -Contain 'feature/branch2'
            $result | Should -HaveCount 2
        }

        It 'Should return bugfix branch with bugfix/* pattern' {
            $result = Get-GitLocalBranchName -Name 'bugfix/*' -ErrorAction Stop

            $result | Should -Not -BeNullOrEmpty
            $result | Should -Contain 'bugfix/issue123'
            $result | Should -HaveCount 1
        }

        It 'Should return nothing for non-matching wildcard pattern' {
            $result = Get-GitLocalBranchName -Name 'hotfix/*' -ErrorAction Stop

            $result | Should -BeNullOrEmpty
        }

        It 'Should support single character wildcard pattern' {
            $result = Get-GitLocalBranchName -Name 'develo?' -ErrorAction Stop

            $result | Should -Contain 'develop'
            $result | Should -HaveCount 1
        }
    }

    Context 'When testing error handling' {
        It 'Should throw error when not in a git repository' {
            # Create a non-git directory
            $nonGitPath = Join-Path -Path $TestDrive -ChildPath 'NonGitRepo'
            New-Item -Path $nonGitPath -ItemType Directory -Force | Out-Null

            Push-Location -Path $nonGitPath
            try
            {
                { Get-GitLocalBranchName -Current -ErrorAction Stop 2> $null } | Should -Throw
            }
            finally
            {
                Pop-Location
            }
        }

        It 'Should write error when git command fails' {
            # Temporarily rename .git directory to induce git failure
            $gitPath = Join-Path -Path $script:testRepoPath -ChildPath '.git'
            $tempGitPath = Join-Path -Path $script:testRepoPath -ChildPath '.git.temp'

            try
            {
                Rename-Item -Path $gitPath -NewName '.git.temp' -ErrorAction Stop

                # Execute and capture all errors (git stderr + PowerShell error)
                $result = @(Get-GitLocalBranchName -Current 2>&1)

                # Verify both errors were captured
                $result | Should -HaveCount 2

                # First error is from git (stderr)
                $result[0] | Should -BeOfType [System.Management.Automation.ErrorRecord]
                $result[0].Exception.Message | Should -Match 'not a git repository'

                # Second error is from PowerShell Write-Error
                $result[1] | Should -BeOfType [System.Management.Automation.ErrorRecord]
                $result[1].Exception.Message | Should -Match 'Failed to get the name of the local branch'
                $result[1].FullyQualifiedErrorId | Should -Be 'GGLBN0001,Get-GitLocalBranchName'
            }
            finally
            {
                # Restore .git directory
                if (Test-Path -Path $tempGitPath)
                {
                    Rename-Item -Path $tempGitPath -NewName '.git' -ErrorAction SilentlyContinue
                }
            }
        }
    }

    Context 'When testing output consistency' {
        It 'Should return consistent results across multiple calls' {
            $result1 = Get-GitLocalBranchName -ErrorAction Stop
            $result2 = Get-GitLocalBranchName -ErrorAction Stop

            Compare-Object -ReferenceObject $result1 -DifferenceObject $result2 | Should -BeNullOrEmpty
        }

        It 'Should return same current branch across multiple calls' {
            $result1 = Get-GitLocalBranchName -Current -ErrorAction Stop
            $result2 = Get-GitLocalBranchName -Current -ErrorAction Stop

            $result1 | Should -Be $result2
        }
    }

    Context 'When testing specific branch name formats' {
        It 'Should handle branch names with special characters' {
            # Create a branch with numbers and special characters
            git checkout -b 'test-branch_123' --quiet 2>$null

            $result = Get-GitLocalBranchName -Name 'test-branch_123' -ErrorAction Stop

            $result | Should -Be 'test-branch_123'

            # Clean up
            if ($PSVersionTable.PSEdition -eq 'Desktop')
            {
                # Windows PowerShell - use cmd.exe for reliable output suppression
                & cmd.exe /c "git checkout $script:defaultBranch >nul 2>&1"
            }
            else
            {
                # PowerShell 7+ - use direct redirection
                git checkout $script:defaultBranch *>$null
            }
            git branch -D 'test-branch_123' *> $null
        }

        It 'Should handle branch names with forward slashes correctly' {
            $result = Get-GitLocalBranchName -Name 'feature/branch1' -ErrorAction Stop

            $result | Should -Be 'feature/branch1'
        }
    }

    Context 'When testing parameter combinations' {
        It 'Should ignore Name parameter when Current parameter is used' {
            # Both parameters provided, but Current should take precedence
            $result = Get-GitLocalBranchName -Name 'feature/branch1' -Current -ErrorAction Stop

            $result | Should -Be $script:defaultBranch
            $result | Should -Not -Be 'feature/branch1'
        }
    }
}
