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

    # Test data for parameter set validation
    $script:parameterSetTestCases = @(
        @{
            ExpectedParameterSetName = 'NoParameter'
            ExpectedParameters = '[-BranchName <string>] [<CommonParameters>]'
        }
        @{
            ExpectedParameterSetName = 'Latest'
            ExpectedParameters = '[-BranchName <string>] [-Latest] [<CommonParameters>]'
        }
        @{
            ExpectedParameterSetName = 'Last'
            ExpectedParameters = '[-BranchName <string>] [-Last <uint>] [<CommonParameters>]'
        }
        @{
            ExpectedParameterSetName = 'First'
            ExpectedParameters = '[-BranchName <string>] [-First <uint>] [<CommonParameters>]'
        }
        @{
            ExpectedParameterSetName = 'Range'
            ExpectedParameters = '-From <string> -To <string> [<CommonParameters>]'
        }
    )
}

BeforeAll {
    $script:moduleName = 'Viscalyx.Common'

    Import-Module -Name $script:moduleName -Force -ErrorAction 'Stop'

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:moduleName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:moduleName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:moduleName
}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    # Unload the module being tested so that it doesn't impact any other tests.
    Get-Module -Name $script:moduleName -All | Remove-Module -Force
}

Describe 'Get-GitBranchCommit' {
    Context 'When command has correct parameter sets' {
        It 'Should have the correct parameters in parameter set <ExpectedParameterSetName>' -ForEach $script:parameterSetTestCases {
            $result = (Get-Command -Name 'Get-GitBranchCommit').ParameterSets |
                Where-Object -FilterScript { $_.Name -eq $ExpectedParameterSetName } |
                Select-Object -Property @(
                    @{ Name = 'ParameterSetName'; Expression = { $_.Name } },
                    @{ Name = 'ParameterListAsString'; Expression = { $_.ToString() } }
                )

            $result.ParameterSetName | Should -Be $ExpectedParameterSetName

            if ($PSVersionTable.PSVersion.Major -eq 5) {
                # Windows PowerShell 5.1 shows <uint32> for System.UInt32 type
                $ExpectedParameters = $ExpectedParameters -replace '<uint>', '<uint32>'
            }

            $result.ParameterListAsString | Should -Be $ExpectedParameters
        }

        It 'Should have NoParameter as the default parameter set' {
            $defaultParameterSet = (Get-Command -Name 'Get-GitBranchCommit').DefaultParameterSet
            $defaultParameterSet | Should -Be 'NoParameter'
        }
    }

    Context 'When command has correct parameter properties' {
        It 'Should have BranchName as a non-mandatory parameter' {
            $parameterInfo = (Get-Command -Name 'Get-GitBranchCommit').Parameters['BranchName']
            $parameterInfo.Attributes.Mandatory | Should -BeFalse
        }

        It 'Should have Latest as a non-mandatory parameter' {
            $parameterInfo = (Get-Command -Name 'Get-GitBranchCommit').Parameters['Latest']
            $parameterInfo.Attributes.Mandatory | Should -BeFalse
        }

        It 'Should have Last as a non-mandatory parameter' {
            $parameterInfo = (Get-Command -Name 'Get-GitBranchCommit').Parameters['Last']
            $parameterInfo.Attributes.Mandatory | Should -BeFalse
        }

        It 'Should have First as a non-mandatory parameter' {
            $parameterInfo = (Get-Command -Name 'Get-GitBranchCommit').Parameters['First']
            $parameterInfo.Attributes.Mandatory | Should -BeFalse
        }

        It 'Should have From as a mandatory parameter in Range parameter set' {
            $parameterInfo = (Get-Command -Name 'Get-GitBranchCommit').Parameters['From']
            $parameterInfo.Attributes.Where({$_.ParameterSetName -eq 'Range'}).Mandatory | Should -BeTrue
        }

        It 'Should have To as a mandatory parameter in Range parameter set' {
            $parameterInfo = (Get-Command -Name 'Get-GitBranchCommit').Parameters['To']
            $parameterInfo.Attributes.Where({$_.ParameterSetName -eq 'Range'}).Mandatory | Should -BeTrue
        }

        It 'Should have correct parameter types' {
            $command = Get-Command -Name 'Get-GitBranchCommit'

            $command.Parameters['BranchName'].ParameterType | Should -Be ([System.String])
            $command.Parameters['Latest'].ParameterType | Should -Be ([System.Management.Automation.SwitchParameter])
            $command.Parameters['Last'].ParameterType | Should -Be ([System.UInt32])
            $command.Parameters['First'].ParameterType | Should -Be ([System.UInt32])
            $command.Parameters['From'].ParameterType | Should -Be ([System.String])
            $command.Parameters['To'].ParameterType | Should -Be ([System.String])
        }
    }

    Context 'When testing parameter validation' {
        It 'Should accept positive values for Last parameter' {
            { Get-Command -Name 'Get-GitBranchCommit' | ForEach-Object { $_.Parameters['Last'].Attributes.Where({$_.TypeId.Name -eq 'ValidateRangeAttribute'}) } } | Should -Not -Throw
        }

        It 'Should accept positive values for First parameter' {
            { Get-Command -Name 'Get-GitBranchCommit' | ForEach-Object { $_.Parameters['First'].Attributes.Where({$_.TypeId.Name -eq 'ValidateRangeAttribute'}) } } | Should -Not -Throw
        }
    }

    Context 'When testing successful execution paths' {
        Context 'When testing NoParameter parameter set' {
            It 'Should return all commit IDs when no parameters provided' {
                InModuleScope -ScriptBlock {
                    # Mock git command success
                    Mock -CommandName 'git' -MockWith {
                        $global:LASTEXITCODE = 0
                        return @('abc123', 'def456', 'ghi789')
                    }

                    Mock -CommandName 'Get-GitLocalBranchName' -MockWith {
                        return 'main'
                    }

                    $result = Get-GitBranchCommit

                    Should -Invoke -CommandName 'Get-GitLocalBranchName' -Times 1 -Exactly -ParameterFilter { $Current -eq $true }
                    Should -Invoke -CommandName 'git' -Times 1 -Exactly -ParameterFilter { $args[0] -eq 'log' -and $args[1] -eq '--pretty=format:%H' -and $args[2] -eq 'main' }
                    $result | Should -Be @('abc123', 'def456', 'ghi789')
                }
            }

            It 'Should return all commit IDs when BranchName is provided' {
                InModuleScope -ScriptBlock {
                    Mock -CommandName 'git' -MockWith {
                        $global:LASTEXITCODE = 0
                        return @('abc123', 'def456')
                    }

                    $result = Get-GitBranchCommit -BranchName 'feature/test'

                    Should -Invoke -CommandName 'git' -Times 1 -Exactly -ParameterFilter { $args[0] -eq 'log' -and $args[1] -eq '--pretty=format:%H' -and $args[2] -eq 'feature/test' }
                    $result | Should -Be @('abc123', 'def456')
                }
            }

            It 'Should use current branch when BranchName is dot' {
                InModuleScope -ScriptBlock {
                    Mock -CommandName 'git' -MockWith {
                        $global:LASTEXITCODE = 0
                        return @('abc123')
                    }

                    Mock -CommandName 'Get-GitLocalBranchName' -MockWith {
                        return 'current-branch'
                    }

                    $result = Get-GitBranchCommit -BranchName '.'

                    Should -Invoke -CommandName 'Get-GitLocalBranchName' -Times 1 -Exactly -ParameterFilter { $Current -eq $true }
                    Should -Invoke -CommandName 'git' -Times 1 -Exactly -ParameterFilter { $args[0] -eq 'log' -and $args[1] -eq '--pretty=format:%H' -and $args[2] -eq 'current-branch' }
                    $result | Should -Be @('abc123')
                }
            }
        }

        Context 'When testing Latest parameter set' {
            It 'Should return only the latest commit ID' {
                InModuleScope -ScriptBlock {
                    Mock -CommandName 'git' -MockWith {
                        $global:LASTEXITCODE = 0
                        return 'abc123'
                    }

                    Mock -CommandName 'Get-GitLocalBranchName' -MockWith {
                        return 'main'
                    }

                    $result = Get-GitBranchCommit -Latest

                    Should -Invoke -CommandName 'git' -Times 1 -Exactly -ParameterFilter { $args[0] -eq 'rev-parse' -and $args[1] -eq 'main' }
                    $result | Should -Be 'abc123'
                }
            }

            It 'Should return latest commit ID for specified branch' {
                InModuleScope -ScriptBlock {
                    Mock -CommandName 'git' -MockWith {
                        $global:LASTEXITCODE = 0
                        return 'def456'
                    }

                    $result = Get-GitBranchCommit -BranchName 'feature/test' -Latest

                    Should -Invoke -CommandName 'git' -Times 1 -Exactly -ParameterFilter { $args[0] -eq 'rev-parse' -and $args[1] -eq 'feature/test' }
                    $result | Should -Be 'def456'
                }
            }
        }

        Context 'When testing Last parameter set' {
            It 'Should return specified number of latest commits' {
                InModuleScope -ScriptBlock {
                    Mock -CommandName 'git' -MockWith {
                        $global:LASTEXITCODE = 0
                        return @('abc123', 'def456', 'ghi789')
                    }

                    Mock -CommandName 'Get-GitLocalBranchName' -MockWith {
                        return 'main'
                    }

                    $result = Get-GitBranchCommit -Last 3

                    Should -Invoke -CommandName 'git' -Times 1 -Exactly -ParameterFilter { $args[0] -eq 'log' -and $args[1] -eq '-n' -and $args[2] -eq 3 -and $args[3] -eq '--pretty=format:%H' -and $args[4] -eq 'main' }
                    $result | Should -Be @('abc123', 'def456', 'ghi789')
                }
            }

            It 'Should return last commits for specified branch' {
                InModuleScope -ScriptBlock {
                    Mock -CommandName 'git' -MockWith {
                        $global:LASTEXITCODE = 0
                        return @('xyz789', 'uvw456')
                    }

                    $result = Get-GitBranchCommit -BranchName 'develop' -Last 2

                    Should -Invoke -CommandName 'git' -Times 1 -Exactly -ParameterFilter { $args[0] -eq 'log' -and $args[1] -eq '-n' -and $args[2] -eq 2 -and $args[3] -eq '--pretty=format:%H' -and $args[4] -eq 'develop' }
                    $result | Should -Be @('xyz789', 'uvw456')
                }
            }
        }

        Context 'When testing First parameter set' {
            It 'Should return specified number of first commits' {
                InModuleScope -ScriptBlock {
                    Mock -CommandName 'Get-GitLocalBranchName' -MockWith {
                        return 'main'
                    }

                    # Mock git commands
                    Mock -CommandName 'git' -MockWith {
                        $global:LASTEXITCODE = 0
                        if ($args[0] -eq 'rev-list' -and $args[1] -eq '--count') {
                            return '10'
                        }
                        elseif ($args[0] -eq 'log' -and $args[1] -eq '--skip') {
                            return @('abc123', 'def456', 'ghi789')
                        }
                    }

                    $result = Get-GitBranchCommit -First 3

                    Should -Invoke -CommandName 'git' -Times 1 -Exactly -ParameterFilter { $args[0] -eq 'rev-list' -and $args[1] -eq '--count' -and $args[2] -eq 'main' }
                    Should -Invoke -CommandName 'git' -Times 1 -Exactly -ParameterFilter { $args[0] -eq 'log' -and $args[1] -eq '--skip' -and $args[2] -eq 7 -and $args[3] -eq '--reverse' -and $args[4] -eq '-n' -and $args[5] -eq 3 -and $args[6] -eq '--pretty=format:%H' -and $args[7] -eq 'main' }
                    $result | Should -Be @('abc123', 'def456', 'ghi789')
                }
            }

            It 'Should handle branch name resolution in First parameter set when not provided' {
                InModuleScope -ScriptBlock {
                    Mock -CommandName 'Get-GitLocalBranchName' -MockWith {
                        return 'feature-branch'
                    }

                    Mock -CommandName 'git' -MockWith {
                        $global:LASTEXITCODE = 0
                        if ($args[0] -eq 'rev-list' -and $args[1] -eq '--count') {
                            return '5'
                        }
                        elseif ($args[0] -eq 'log' -and $args[1] -eq '--skip') {
                            return @('first123', 'second456')
                        }
                    }

                    $result = Get-GitBranchCommit -First 2

                    Should -Invoke -CommandName 'Get-GitLocalBranchName' -Times 2 -Exactly -ParameterFilter { $Current -eq $true }
                    Should -Invoke -CommandName 'git' -Times 1 -Exactly -ParameterFilter { $args[0] -eq 'rev-list' -and $args[1] -eq '--count' -and $args[2] -eq 'feature-branch' }
                    Should -Invoke -CommandName 'git' -Times 1 -Exactly -ParameterFilter { $args[0] -eq 'log' -and $args[1] -eq '--skip' -and $args[2] -eq 3 -and $args[7] -eq 'feature-branch' }
                }
            }

            It 'Should handle First parameter set with specified branch' {
                InModuleScope -ScriptBlock {
                    Mock -CommandName 'git' -MockWith {
                        $global:LASTEXITCODE = 0
                        if ($args[0] -eq 'rev-list' -and $args[1] -eq '--count') {
                            return '8'
                        }
                        elseif ($args[0] -eq 'log' -and $args[1] -eq '--skip') {
                            return @('oldest123')
                        }
                    }

                    $result = Get-GitBranchCommit -BranchName 'release/v1.0' -First 1

                    Should -Invoke -CommandName 'git' -Times 1 -Exactly -ParameterFilter { $args[0] -eq 'rev-list' -and $args[1] -eq '--count' -and $args[2] -eq 'release/v1.0' }
                    Should -Invoke -CommandName 'git' -Times 1 -Exactly -ParameterFilter { $args[0] -eq 'log' -and $args[1] -eq '--skip' -and $args[2] -eq 7 -and $args[7] -eq 'release/v1.0' }
                    $result | Should -Be @('oldest123')
                }
            }

            It 'Should handle First parameter set when First is greater than total commits' {
                InModuleScope -ScriptBlock {
                    Mock -CommandName 'Get-GitLocalBranchName' -MockWith {
                        return 'main'
                    }

                    # Mock git commands - simulate branch with only 2 commits but First=5
                    Mock -CommandName 'git' -MockWith {
                        $global:LASTEXITCODE = 0
                        if ($args[0] -eq 'rev-list' -and $args[1] -eq '--count') {
                            return '2'  # Only 2 commits in branch
                        }
                        elseif ($args[0] -eq 'log' -and $args[1] -eq '--skip') {
                            # With current bug, --skip would be -3 (2-5=-3), which should fail
                            # With fix, --skip should be 0 (max(0, 2-5)=0)
                            return @('commit1', 'commit2')
                        }
                    }

                    $result = Get-GitBranchCommit -First 5

                    Should -Invoke -CommandName 'git' -Times 1 -Exactly -ParameterFilter { $args[0] -eq 'rev-list' -and $args[1] -eq '--count' -and $args[2] -eq 'main' }
                    # This should verify --skip is 0, not -3
                    Should -Invoke -CommandName 'git' -Times 1 -Exactly -ParameterFilter { $args[0] -eq 'log' -and $args[1] -eq '--skip' -and $args[2] -eq 0 -and $args[3] -eq '--reverse' -and $args[4] -eq '-n' -and $args[5] -eq 5 -and $args[6] -eq '--pretty=format:%H' -and $args[7] -eq 'main' }
                    $result | Should -Be @('commit1', 'commit2')
                }
            }
        }

        Context 'When testing Range parameter set' {
            It 'Should return commits between two references' {
                InModuleScope -ScriptBlock {
                    Mock -CommandName 'git' -MockWith {
                        $global:LASTEXITCODE = 0
                        return @('commit1', 'commit2', 'commit3')
                    }

                    $result = Get-GitBranchCommit -From 'main' -To 'HEAD'

                    Should -Invoke -CommandName 'git' -Times 1 -Exactly -ParameterFilter { $args[0] -eq 'log' -and $args[1] -eq '--pretty=format:%H' -and $args[2] -eq 'main..HEAD' }
                    $result | Should -Be @('commit1', 'commit2', 'commit3')
                }
            }

            It 'Should return commits between tag references' {
                InModuleScope -ScriptBlock {
                    Mock -CommandName 'git' -MockWith {
                        $global:LASTEXITCODE = 0
                        return @('tag-commit1', 'tag-commit2')
                    }

                    $result = Get-GitBranchCommit -From 'v1.0.0' -To 'v2.0.0'

                    Should -Invoke -CommandName 'git' -Times 1 -Exactly -ParameterFilter { $args[0] -eq 'log' -and $args[1] -eq '--pretty=format:%H' -and $args[2] -eq 'v1.0.0..v2.0.0' }
                    $result | Should -Be @('tag-commit1', 'tag-commit2')
                }
            }
        }
    }

    Context 'When testing error handling' {
        Context 'When testing NoParameter parameter set errors' {
            It 'Should throw error when git log fails for current branch' {
                InModuleScope -ScriptBlock {
                    Mock -CommandName 'git' -MockWith {
                        $global:LASTEXITCODE = 128
                        return $null
                    }

                    Mock -CommandName 'Get-GitLocalBranchName' -MockWith {
                        return 'main'
                    }

                    Mock -CommandName 'Write-Error' -MockWith {}

                    $result = Get-GitBranchCommit -ErrorAction SilentlyContinue

                    Should -Invoke -CommandName 'Write-Error' -Times 1 -Exactly -ParameterFilter {
                        $Message -match 'Failed to retrieve commits from current branch' -and
                        $Category -eq 'ObjectNotFound' -and
                        $ErrorId -eq 'GGBC0001' -and
                        $TargetObject -eq 'main'
                    }
                }
            }

            It 'Should throw error when git log fails for specified branch' {
                InModuleScope -ScriptBlock {
                    Mock -CommandName 'git' -MockWith {
                        $global:LASTEXITCODE = 128
                        return $null
                    }

                    Mock -CommandName 'Write-Error' -MockWith {}

                    $result = Get-GitBranchCommit -BranchName 'nonexistent-branch' -ErrorAction SilentlyContinue

                    Should -Invoke -CommandName 'Write-Error' -Times 1 -Exactly -ParameterFilter {
                        $Message -match "Failed to retrieve commits.*Make sure the branch 'nonexistent-branch' exists" -and
                        $Category -eq 'ObjectNotFound' -and
                        $ErrorId -eq 'GGBC0001' -and
                        $TargetObject -eq 'nonexistent-branch'
                    }
                }
            }
        }

        Context 'When testing Latest parameter set errors' {
            It 'Should throw error when git rev-parse fails' {
                InModuleScope -ScriptBlock {
                    Mock -CommandName 'git' -MockWith {
                        $global:LASTEXITCODE = 128
                        return $null
                    }

                    Mock -CommandName 'Get-GitLocalBranchName' -MockWith {
                        return 'main'
                    }

                    Mock -CommandName 'Write-Error' -MockWith {}

                    $result = Get-GitBranchCommit -Latest -ErrorAction SilentlyContinue

                    Should -Invoke -CommandName 'Write-Error' -Times 1 -Exactly -ParameterFilter {
                        $Message -match 'Failed to retrieve commits from current branch' -and
                        $TargetObject -eq 'main'
                    }
                }
            }
        }

        Context 'When testing Last parameter set errors' {
            It 'Should throw error when git log with -n fails' {
                InModuleScope -ScriptBlock {
                    Mock -CommandName 'git' -MockWith {
                        $global:LASTEXITCODE = 128
                        return $null
                    }

                    Mock -CommandName 'Get-GitLocalBranchName' -MockWith {
                        return 'main'
                    }

                    Mock -CommandName 'Write-Error' -MockWith {}

                    $result = Get-GitBranchCommit -Last 5 -ErrorAction SilentlyContinue

                    Should -Invoke -CommandName 'Write-Error' -Times 1 -Exactly -ParameterFilter {
                        $Message -match 'Failed to retrieve commits from current branch' -and
                        $TargetObject -eq 'main'
                    }
                }
            }
        }

        Context 'When testing First parameter set errors' {
            It 'Should throw error when git rev-list --count fails' {
                InModuleScope -ScriptBlock {
                    Mock -CommandName 'Get-GitLocalBranchName' -MockWith {
                        return 'main'
                    }

                    Mock -CommandName 'git' -MockWith {
                        $global:LASTEXITCODE = 128
                        return $null
                    }

                    Mock -CommandName 'Write-Error' -MockWith {}

                    $result = Get-GitBranchCommit -First 3 -ErrorAction SilentlyContinue

                    Should -Invoke -CommandName 'Write-Error' -Times 1 -Exactly -ParameterFilter {
                        $Message -match 'Failed to retrieve commits from current branch' -and
                        $TargetObject -eq 'main'
                    }
                }
            }

            It 'Should throw error when second git command fails in First parameter set' {
                InModuleScope -ScriptBlock {
                    Mock -CommandName 'Get-GitLocalBranchName' -MockWith {
                        return 'main'
                    }

                    Mock -CommandName 'git' -MockWith {
                        if ($args[0] -eq 'rev-list' -and $args[1] -eq '--count') {
                            $global:LASTEXITCODE = 0
                            return '10'
                        }
                        elseif ($args[0] -eq 'log' -and $args[1] -eq '--skip') {
                            $global:LASTEXITCODE = 128
                            return $null
                        }
                    }

                    Mock -CommandName 'Write-Error' -MockWith {}

                    $result = Get-GitBranchCommit -First 3 -ErrorAction SilentlyContinue

                    Should -Invoke -CommandName 'Write-Error' -Times 1 -Exactly -ParameterFilter {
                        $Message -match 'Failed to retrieve commits from current branch'
                    }
                }
            }
        }

        Context 'When testing Range parameter set errors' {
            It 'Should throw error when git log with range fails' {
                InModuleScope -ScriptBlock {
                    Mock -CommandName 'git' -MockWith {
                        $global:LASTEXITCODE = 128
                        return $null
                    }

                    Mock -CommandName 'Write-Error' -MockWith {}

                    $result = Get-GitBranchCommit -From 'main' -To 'HEAD' -ErrorAction SilentlyContinue

                    Should -Invoke -CommandName 'Write-Error' -Times 1 -Exactly -ParameterFilter {
                        $Message -match "Failed to retrieve commits from range 'main..HEAD'" -and
                        $Category -eq 'ObjectNotFound' -and
                        $ErrorId -eq 'GGBC0001' -and
                        $TargetObject -eq 'main..HEAD'
                    }
                }
            }
        }
    }
}
