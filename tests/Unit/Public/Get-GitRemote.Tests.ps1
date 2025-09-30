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
            ExpectedParameters       = '[[-Name] <string>] [<CommonParameters>]'
        },
        @{
            ExpectedParameterSetName = 'FetchUrl'
            ExpectedParameters       = '-Name <string> -FetchUrl [<CommonParameters>]'
        },
        @{
            ExpectedParameterSetName = 'PushUrl'
            ExpectedParameters       = '-Name <string> -PushUrl [<CommonParameters>]'
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

Describe 'Get-GitRemote' {
    Context 'When checking parameter sets' {
        It 'Should have the correct parameters in parameter set <ExpectedParameterSetName>' -ForEach $script:parameterSetTestCases {
            $result = (Get-Command -Name 'Get-GitRemote').ParameterSets |
                Where-Object -FilterScript { $_.Name -eq $ExpectedParameterSetName } |
                Select-Object -Property @(
                    @{ Name = 'ParameterSetName'; Expression = { $_.Name } },
                    @{ Name = 'ParameterListAsString'; Expression = { $_.ToString() } }
                )

            $result.ParameterSetName | Should -Be $ExpectedParameterSetName
            $result.ParameterListAsString | Should -Be $ExpectedParameters
        }

        It 'Should have Default as the default parameter set' {
            $defaultParameterSet = (Get-Command -Name 'Get-GitRemote').DefaultParameterSet
            $defaultParameterSet | Should -Be 'Default'
        }
    }

    Context 'When checking parameter properties' {
        It 'Should have Name as a non-mandatory parameter in Default parameter set' {
            $parameterInfo = (Get-Command -Name 'Get-GitRemote').Parameters['Name']
            $defaultParameterSet = $parameterInfo.ParameterSets['Default']
            $defaultParameterSet.IsMandatory | Should -BeFalse
        }

        It 'Should have Name as a mandatory parameter in FetchUrl parameter set' {
            $parameterInfo = (Get-Command -Name 'Get-GitRemote').Parameters['Name']
            $fetchUrlParameterSet = $parameterInfo.ParameterSets['FetchUrl']
            $fetchUrlParameterSet.IsMandatory | Should -BeTrue
        }

        It 'Should have Name as a mandatory parameter in PushUrl parameter set' {
            $parameterInfo = (Get-Command -Name 'Get-GitRemote').Parameters['Name']
            $pushUrlParameterSet = $parameterInfo.ParameterSets['PushUrl']
            $pushUrlParameterSet.IsMandatory | Should -BeTrue
        }

        It 'Should have FetchUrl as a mandatory parameter in FetchUrl parameter set' {
            $parameterInfo = (Get-Command -Name 'Get-GitRemote').Parameters['FetchUrl']
            $fetchUrlParameterSet = $parameterInfo.ParameterSets['FetchUrl']
            $fetchUrlParameterSet.IsMandatory | Should -BeTrue
        }

        It 'Should have PushUrl as a mandatory parameter in PushUrl parameter set' {
            $parameterInfo = (Get-Command -Name 'Get-GitRemote').Parameters['PushUrl']
            $pushUrlParameterSet = $parameterInfo.ParameterSets['PushUrl']
            $pushUrlParameterSet.IsMandatory | Should -BeTrue
        }

        It 'Should have correct parameter types' {
            $command = Get-Command -Name 'Get-GitRemote'

            $command.Parameters['Name'].ParameterType | Should -Be ([System.String])
            $command.Parameters['FetchUrl'].ParameterType | Should -Be ([System.Management.Automation.SwitchParameter])
            $command.Parameters['PushUrl'].ParameterType | Should -Be ([System.Management.Automation.SwitchParameter])
        }
    }

    Context 'When testing localized strings' {
        It 'Should have proper localized error messages' {
            InModuleScope -ScriptBlock {
                $script:localizedData.Get_GitRemote_Failed | Should -Match 'Failed to get the remote.*Make sure the remote exists and is accessible'
            }
        }
    }

    Context 'When getting all remotes' {
        It 'Should call git remote without arguments when no Name specified' {
            Mock -CommandName 'git' -MockWith {
                return @('origin', 'upstream')
            }

            InModuleScope -ScriptBlock {
                $global:LASTEXITCODE = 0
                $result = Get-GitRemote
                $result | Should -Be @('origin', 'upstream')
                Should -Invoke -CommandName 'git' -Times 1 -Exactly -ParameterFilter {
                    $args[0] -eq 'remote' -and $args.Count -eq 1
                }
            }
        }

        It 'Should return empty array when no remotes exist' {
            Mock -CommandName 'git' -MockWith {
                return @()
            }

            InModuleScope -ScriptBlock {
                $global:LASTEXITCODE = 0
                $result = Get-GitRemote
                $result | Should -BeNullOrEmpty
            }
        }
    }

    Context 'When getting specific remote by name' {
        It 'Should return remote name when remote exists' {
            Mock -CommandName 'git' -MockWith {
                return @('origin', 'upstream')
            }

            InModuleScope -ScriptBlock {
                $global:LASTEXITCODE = 0
                $result = Get-GitRemote -Name 'origin'
                $result | Should -Be 'origin'
            }
        }

        It 'Should return null when remote does not exist' {
            Mock -CommandName 'git' -MockWith {
                return @('origin', 'upstream')
            }

            InModuleScope -ScriptBlock {
                $global:LASTEXITCODE = 0
                $result = Get-GitRemote -Name 'nonexistent'
                $result | Should -BeNullOrEmpty
            }
        }
    }

    Context 'When getting fetch URL' {
        It 'Should call git remote get-url for fetch URL' {
            Mock -CommandName 'git' -MockWith {
                return 'https://github.com/user/repo.git'
            }

            InModuleScope -ScriptBlock {
                $global:LASTEXITCODE = 0
                $result = Get-GitRemote -Name 'origin' -FetchUrl
                $result | Should -Be 'https://github.com/user/repo.git'
                Should -Invoke -CommandName 'git' -Times 1 -Exactly -ParameterFilter {
                    $args[0] -eq 'remote' -and $args[1] -eq 'get-url' -and $args[2] -eq 'origin' -and $args.Count -eq 3
                }
            }
        }
    }

    Context 'When getting push URL' {
        It 'Should call git remote get-url --push for push URL' {
            Mock -CommandName 'git' -MockWith {
                return 'git@github.com:user/repo.git'
            }

            InModuleScope -ScriptBlock {
                $global:LASTEXITCODE = 0
                $result = Get-GitRemote -Name 'origin' -PushUrl
                $result | Should -Be 'git@github.com:user/repo.git'
                Should -Invoke -CommandName 'git' -Times 1 -Exactly -ParameterFilter {
                    $args[0] -eq 'remote' -and $args[1] -eq 'get-url' -and $args[2] -eq '--push' -and $args[3] -eq 'origin' -and $args.Count -eq 4
                }
            }
        }
    }

    Context 'When git command fails' {
        It 'Should write error and not throw when git remote fails' {
            Mock -CommandName 'git' -MockWith {
                $global:LASTEXITCODE = 1
                return $null
            }
            Mock -CommandName 'Write-Error' -MockWith { }

            InModuleScope -ScriptBlock {
                $result = Get-GitRemote -Name 'nonexistent' -FetchUrl -ErrorAction SilentlyContinue
                $result | Should -BeNullOrEmpty
                Should -Invoke -CommandName 'Write-Error' -Times 1 -Exactly
            }
        }

        It 'Should write error with correct parameters when git fails' {
            Mock -CommandName 'git' -MockWith {
                $global:LASTEXITCODE = 1
                return $null
            }
            Mock -CommandName 'Write-Error' -MockWith { }

            InModuleScope -ScriptBlock {
                Get-GitRemote -Name 'test' -FetchUrl -ErrorAction SilentlyContinue
                Should -Invoke -CommandName 'Write-Error' -Times 1 -Exactly -ParameterFilter {
                    $Message -match 'Failed to get the remote.*test' -and
                    $Category -eq 'ObjectNotFound' -and
                    $ErrorId -eq 'GGR0001' -and
                    $TargetObject -eq 'test'
                }
            }
        }
    }
}
