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

    # Set the parameter set test cases at discovery time
    $script:parameterSetTestCases = @(
        @{
            ExpectedParameterSetName = 'Default'
            ExpectedParameters = '[[-RemoteName] <string>] [-RemoveRefsHeads] [<CommonParameters>]'
        },
        @{
            ExpectedParameterSetName = 'Name'
            ExpectedParameters = '[-RemoteName] <string> [[-Name] <string>] [-RemoveRefsHeads] [<CommonParameters>]'
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

Describe 'Get-GitRemoteBranch' {
    Context 'When checking parameter sets' {
        It 'Should have the correct parameters in parameter set <ExpectedParameterSetName>' -ForEach $script:parameterSetTestCases {
            $result = (Get-Command -Name 'Get-GitRemoteBranch').ParameterSets |
                Where-Object -FilterScript { $_.Name -eq $ExpectedParameterSetName } |
                Select-Object -Property @(
                    @{ Name = 'ParameterSetName'; Expression = { $_.Name } },
                    @{ Name = 'ParameterListAsString'; Expression = { $_.ToString() } }
                )

            $result.ParameterSetName | Should -Be $ExpectedParameterSetName
            $result.ParameterListAsString | Should -Be $ExpectedParameters
        }

        It 'Should have Default as the default parameter set' {
            $defaultParameterSet = (Get-Command -Name 'Get-GitRemoteBranch').DefaultParameterSet
            $defaultParameterSet | Should -Be 'Default'
        }
    }

    Context 'When checking parameter properties' {
        It 'Should have RemoteName as a non-mandatory parameter in Default parameter set' {
            $parameterInfo = (Get-Command -Name 'Get-GitRemoteBranch').Parameters['RemoteName']
            $defaultParameterSet = $parameterInfo.ParameterSets['Default']
            $defaultParameterSet.IsMandatory | Should -BeFalse
        }

        It 'Should have RemoteName as a mandatory parameter in Name parameter set' {
            $parameterInfo = (Get-Command -Name 'Get-GitRemoteBranch').Parameters['RemoteName']
            $nameParameterSet = $parameterInfo.ParameterSets['Name']
            $nameParameterSet.IsMandatory | Should -BeTrue
        }

        It 'Should have Name as a non-mandatory parameter in Name parameter set' {
            $parameterInfo = (Get-Command -Name 'Get-GitRemoteBranch').Parameters['Name']
            $nameParameterSet = $parameterInfo.ParameterSets['Name']
            $nameParameterSet.IsMandatory | Should -BeFalse
        }

        It 'Should have correct parameter types' {
            $command = Get-Command -Name 'Get-GitRemoteBranch'

            $command.Parameters['RemoteName'].ParameterType | Should -Be ([System.String])
            $command.Parameters['Name'].ParameterType | Should -Be ([System.String])
            $command.Parameters['RemoveRefsHeads'].ParameterType | Should -Be ([System.Management.Automation.SwitchParameter])
        }
    }

    Context 'When testing localized strings' {
        It 'Should have proper localized error messages' {
            InModuleScope -ScriptBlock {
                $script:localizedData.Get_GitRemoteBranch_Failed | Should -Match 'Failed to get the remote branches.*Make sure the remote branch exists and is accessible'
                $script:localizedData.Get_GitRemoteBranch_FromRemote_Failed | Should -Match 'Failed to get the remote branches from remote.*Make sure the remote branch exists and is accessible'
                $script:localizedData.Get_GitRemoteBranch_ByName_Failed | Should -Match 'Failed to get the remote branch.*using the remote.*Make sure the remote branch exists and is accessible'
            }
        }
    }

    Context 'When getting remote branches without specific remote' {
        It 'Should call git ls-remote --branches with --quiet only' {
            Mock -CommandName 'git' -MockWith {
                return @(
                    "a1b2c3d4e5f6	refs/heads/main",
                    "f6e5d4c3b2a1	refs/heads/feature/test"
                )
            }

            InModuleScope -ScriptBlock {
                $global:LASTEXITCODE = 0
                $result = Get-GitRemoteBranch
                $result | Should -Be @('refs/heads/main', 'refs/heads/feature/test')
                Should -Invoke -CommandName 'git' -Times 1 -Exactly -ParameterFilter {
                    $args[0] -eq 'ls-remote' -and
                    $args[1] -eq '--branches' -and
                    $args[2] -eq '--quiet' -and
                    $args.Count -eq 3
                }
            }
        }

        It 'Should return empty array when no branches exist' {
            Mock -CommandName 'git' -MockWith {
                return @()
            }

            InModuleScope -ScriptBlock {
                $global:LASTEXITCODE = 0
                $result = Get-GitRemoteBranch
                $result | Should -BeNullOrEmpty
            }
        }
    }

    Context 'When getting remote branches from specific remote' {
        It 'Should call git ls-remote --branches with remote name' {
            Mock -CommandName 'Get-GitRemote' -MockWith {
                return 'origin'
            }
            
            Mock -CommandName 'git' -MockWith {
                return @(
                    "a1b2c3d4e5f6	refs/heads/main",
                    "f6e5d4c3b2a1	refs/heads/develop"
                )
            }

            InModuleScope -ScriptBlock {
                $global:LASTEXITCODE = 0
                $result = Get-GitRemoteBranch -RemoteName 'origin'
                $result | Should -Be @('refs/heads/main', 'refs/heads/develop')
                Should -Invoke -CommandName 'git' -Times 1 -Exactly -ParameterFilter {
                    $args[0] -eq 'ls-remote' -and
                    $args[1] -eq '--branches' -and
                    $args[2] -eq '--quiet' -and
                    $args[3] -eq 'origin' -and
                    $args.Count -eq 4
                }
            }
        }
    }

    Context 'When getting specific branch by name' {
        It 'Should call git ls-remote --branches with remote and branch name' {
            Mock -CommandName 'Get-GitRemote' -MockWith {
                return 'origin'
            }
            
            Mock -CommandName 'git' -MockWith {
                return @("a1b2c3d4e5f6	refs/heads/main")
            }

            InModuleScope -ScriptBlock {
                $global:LASTEXITCODE = 0
                $result = Get-GitRemoteBranch -RemoteName 'origin' -Name 'main'
                $result | Should -Be 'refs/heads/main'
                Should -Invoke -CommandName 'git' -Times 1 -Exactly -ParameterFilter {
                    $args[0] -eq 'ls-remote' -and
                    $args[1] -eq '--branches' -and
                    $args[2] -eq '--quiet' -and
                    $args[3] -eq 'origin' -and
                    $args[4] -eq 'main' -and
                    $args.Count -eq 5
                }
            }
        }

        It 'Should handle wildcard patterns in branch names' {
            Mock -CommandName 'Get-GitRemote' -MockWith {
                return 'origin'
            }
            
            Mock -CommandName 'git' -MockWith {
                return @(
                    "a1b2c3d4e5f6	refs/heads/feature/test1",
                    "f6e5d4c3b2a1	refs/heads/feature/test2"
                )
            }

            InModuleScope -ScriptBlock {
                $global:LASTEXITCODE = 0
                $result = Get-GitRemoteBranch -RemoteName 'origin' -Name 'feature/*'
                $result | Should -Be @('refs/heads/feature/test1', 'refs/heads/feature/test2')
                Should -Invoke -CommandName 'git' -Times 1 -Exactly -ParameterFilter {
                    $args[0] -eq 'ls-remote' -and
                    $args[1] -eq '--branches' -and
                    $args[2] -eq '--quiet' -and
                    $args[3] -eq 'origin' -and
                    $args[4] -eq '*feature/*' -and
                    $args.Count -eq 5
                }
            }
        }

        It 'Should strip refs/heads/ from Name parameter if present' {
            Mock -CommandName 'Get-GitRemote' -MockWith {
                return 'origin'
            }
            
            Mock -CommandName 'git' -MockWith {
                return @("a1b2c3d4e5f6	refs/heads/main")
            }

            InModuleScope -ScriptBlock {
                $global:LASTEXITCODE = 0
                $result = Get-GitRemoteBranch -RemoteName 'origin' -Name 'refs/heads/main'
                $result | Should -Be 'refs/heads/main'
                Should -Invoke -CommandName 'git' -Times 1 -Exactly -ParameterFilter {
                    $args[0] -eq 'ls-remote' -and
                    $args[1] -eq '--branches' -and
                    $args[2] -eq '--quiet' -and
                    $args[3] -eq 'origin' -and
                    $args[4] -eq 'main' -and
                    $args.Count -eq 5
                }
            }
        }

        It 'Should treat Name parameter with single asterisk same as no Name parameter' {
            Mock -CommandName 'Get-GitRemote' -MockWith {
                return 'origin'
            }
            
            Mock -CommandName 'git' -MockWith {
                return @(
                    "a1b2c3d4e5f6	refs/heads/main",
                    "f6e5d4c3b2a1	refs/heads/develop"
                )
            }

            InModuleScope -ScriptBlock {
                $global:LASTEXITCODE = 0
                $result = Get-GitRemoteBranch -RemoteName 'origin' -Name '*'
                $result | Should -Be @('refs/heads/main', 'refs/heads/develop')
                # Should not pass the asterisk to git - should behave same as no Name parameter
                Should -Invoke -CommandName 'git' -Times 1 -Exactly -ParameterFilter {
                    $args[0] -eq 'ls-remote' -and
                    $args[1] -eq '--branches' -and
                    $args[2] -eq '--quiet' -and
                    $args[3] -eq 'origin' -and
                    $args.Count -eq 4  # No Name parameter should be passed
                }
            }
        }
    }

    Context 'When using RemoveRefsHeads switch' {
        It 'Should remove refs/heads/ prefix from branch names' {
            Mock -CommandName 'Get-GitRemote' -MockWith {
                return 'origin'
            }
            
            Mock -CommandName 'git' -MockWith {
                return @(
                    "a1b2c3d4e5f6	refs/heads/main",
                    "f6e5d4c3b2a1	refs/heads/develop"
                )
            }

            InModuleScope -ScriptBlock {
                $global:LASTEXITCODE = 0
                $result = Get-GitRemoteBranch -RemoteName 'origin' -RemoveRefsHeads
                $result | Should -Be @('main', 'develop')
            }
        }

        It 'Should work with Name parameter and RemoveRefsHeads' {
            Mock -CommandName 'Get-GitRemote' -MockWith {
                return 'origin'
            }
            
            Mock -CommandName 'git' -MockWith {
                return @("a1b2c3d4e5f6	refs/heads/main")
            }

            InModuleScope -ScriptBlock {
                $global:LASTEXITCODE = 0
                $result = Get-GitRemoteBranch -RemoteName 'origin' -Name 'main' -RemoveRefsHeads
                $result | Should -Be 'main'
            }
        }
    }

    Context 'When git command fails' {
        It 'Should write error when git ls-remote fails without parameters' {
            Mock -CommandName 'git' -MockWith {
                $global:LASTEXITCODE = 1
                return $null
            }
            Mock -CommandName 'Write-Error' -MockWith { }

            InModuleScope -ScriptBlock {
                $result = Get-GitRemoteBranch -ErrorAction SilentlyContinue
                $result | Should -BeNullOrEmpty
                Should -Invoke -CommandName 'Write-Error' -Times 1 -Exactly
            }
        }

        It 'Should write error with correct parameters when remote name fails' {
            Mock -CommandName 'Get-GitRemote' -MockWith {
                return 'nonexistent'  # Remote exists but git command fails
            }
            
            Mock -CommandName 'git' -MockWith {
                $global:LASTEXITCODE = 1
                return $null
            }
            Mock -CommandName 'Write-Error' -MockWith { }

            InModuleScope -ScriptBlock {
                Get-GitRemoteBranch -RemoteName 'nonexistent' -ErrorAction SilentlyContinue
                Should -Invoke -CommandName 'Write-Error' -Times 1 -Exactly -ParameterFilter {
                    $Message -match 'Failed to get the remote branches from remote.*nonexistent' -and
                    $Category -eq 'ObjectNotFound' -and
                    $ErrorId -eq 'GGRB0001' -and
                    $TargetObject -eq 'RemoteName'
                }
            }
        }

        It 'Should write error with correct parameters when branch name fails' {
            Mock -CommandName 'Get-GitRemote' -MockWith {
                return 'origin'  # Remote exists but git command fails
            }
            
            Mock -CommandName 'git' -MockWith {
                $global:LASTEXITCODE = 1
                return $null
            }
            Mock -CommandName 'Write-Error' -MockWith { }

            InModuleScope -ScriptBlock {
                Get-GitRemoteBranch -RemoteName 'origin' -Name 'nonexistent' -ErrorAction SilentlyContinue
                Should -Invoke -CommandName 'Write-Error' -Times 1 -Exactly -ParameterFilter {
                    $Message -match 'Failed to get the remote branch.*nonexistent.*using the remote.*origin' -and
                    $Category -eq 'ObjectNotFound' -and
                    $ErrorId -eq 'GGRB0001' -and
                    $TargetObject -eq 'Name'
                }
            }
        }

        It 'Should write error with correct message when no parameters specified and git fails' {
            Mock -CommandName 'git' -MockWith {
                $global:LASTEXITCODE = 1
                return $null
            }
            Mock -CommandName 'Write-Error' -MockWith { }

            InModuleScope -ScriptBlock {
                Get-GitRemoteBranch -ErrorAction SilentlyContinue
                Should -Invoke -CommandName 'Write-Error' -Times 1 -Exactly -ParameterFilter {
                    $Message -match 'Failed to get the remote branches' -and
                    $Category -eq 'ObjectNotFound' -and
                    $ErrorId -eq 'GGRB0001' -and
                    $TargetObject -eq $null
                }
            }
        }
    }

    Context 'When remote validation fails' {
        It 'Should write error when remote does not exist' {
            Mock -CommandName 'Get-GitRemote' -MockWith {
                return $null
            }
            Mock -CommandName 'Write-Error' -MockWith { }

            InModuleScope -ScriptBlock {
                $result = Get-GitRemoteBranch -RemoteName 'nonexistent' -ErrorAction SilentlyContinue
                $result | Should -BeNullOrEmpty
                Should -Invoke -CommandName 'Get-GitRemote' -Times 1 -Exactly -ParameterFilter {
                    $Name -eq 'nonexistent'
                }
                Should -Invoke -CommandName 'Write-Error' -Times 1 -Exactly -ParameterFilter {
                    $Message -match 'The remote.*nonexistent.*does not exist in the local git repository' -and
                    $Category -eq 'ObjectNotFound' -and
                    $ErrorId -eq 'GGRB0002' -and
                    $TargetObject -eq 'nonexistent'
                }
            }
        }
        
        It 'Should not call git ls-remote when remote does not exist' {
            Mock -CommandName 'Get-GitRemote' -MockWith {
                return $null
            }
            Mock -CommandName 'git' -MockWith {
                throw 'git should not be called when remote does not exist'
            }
            Mock -CommandName 'Write-Error' -MockWith { }

            InModuleScope -ScriptBlock {
                Get-GitRemoteBranch -RemoteName 'nonexistent' -ErrorAction SilentlyContinue
                Should -Invoke -CommandName 'git' -Times 0 -Exactly
            }
        }
    }
}
