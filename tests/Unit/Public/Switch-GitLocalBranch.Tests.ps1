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
    $script:dscModuleName = 'Viscalyx.Common'

    Import-Module -Name $script:dscModuleName -Force -ErrorAction Stop

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:dscModuleName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:dscModuleName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:dscModuleName
}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    # Unload the module being tested so that it doesn't impact any other tests.
    Get-Module -Name $script:dscModuleName -All | Remove-Module -Force
}

# cSpell: ignore LASTEXITCODE
Describe 'Switch-GitLocalBranch' {
    Context 'When checking parameter sets' {
        It 'Should have the correct parameters in parameter set <ExpectedParameterSetName>' -ForEach @(
        @{
            ExpectedParameterSetName = '__AllParameterSets'
            ExpectedParameters = '[-Name] <string> [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]'
        }
    ) {
            $result = (Get-Command -Name 'Switch-GitLocalBranch').ParameterSets |
                Where-Object -FilterScript { $_.Name -eq $ExpectedParameterSetName } |
                Select-Object -Property @(
                    @{ Name = 'ParameterSetName'; Expression = { $_.Name } },
                    @{ Name = 'ParameterListAsString'; Expression = { $_.ToString() } }
                )

            $result.ParameterSetName | Should -Be $ExpectedParameterSetName
            $result.ParameterListAsString | Should -Be $ExpectedParameters
        }
    }

    Context 'When checking parameter properties' {
        It 'Should have Name as a mandatory parameter' {
            $parameterInfo = (Get-Command -Name 'Switch-GitLocalBranch').Parameters['Name']
            $parameterSet = $parameterInfo.ParameterSets['__AllParameterSets']
            $parameterSet.IsMandatory | Should -BeTrue
        }

        It 'Should have Force as a non-mandatory parameter' {
            $parameterInfo = (Get-Command -Name 'Switch-GitLocalBranch').Parameters['Force']
            $parameterSet = $parameterInfo.ParameterSets['__AllParameterSets']
            $parameterSet.IsMandatory | Should -BeFalse
        }

        It 'Should have Name parameter at position 0' {
            $parameterInfo = (Get-Command -Name 'Switch-GitLocalBranch').Parameters['Name']
            $parameterSet = $parameterInfo.ParameterSets['__AllParameterSets']
            $parameterSet.Position | Should -Be 0
        }

        It 'Should have Force parameter with no specific position' {
            $parameterInfo = (Get-Command -Name 'Switch-GitLocalBranch').Parameters['Force']
            $parameterSet = $parameterInfo.ParameterSets['__AllParameterSets']
            $parameterSet.Position | Should -Be -2147483648
        }
    }

    Context 'When switching to a local branch successfully' {
        BeforeAll {
            Mock -CommandName Assert-GitLocalChange

            Mock -CommandName git -MockWith {
                if ($args[0] -eq 'checkout')
                {
                    $global:LASTEXITCODE = 0
                }
                else
                {
                    throw "Mock git unexpected args: $($args -join ' ')"
                }
            }
        }

        AfterEach {
            $global:LASTEXITCODE = 0
        }

        It 'Should switch to the branch successfully' {
            Switch-GitLocalBranch -Name 'feature/test-branch' -Force

            Should -Invoke -CommandName Assert-GitLocalChange -Times 1
            Should -Invoke -CommandName git -ParameterFilter {
                $args[0] -eq 'checkout' -and $args[1] -eq 'feature/test-branch'
            }
        }

        It 'Should call Assert-GitLocalChange to check for uncommitted changes' {
            Switch-GitLocalBranch -Name 'main' -Force

            Should -Invoke -CommandName Assert-GitLocalChange -Times 1
        }
    }

    Context 'When the checkout operation fails' {
        BeforeAll {
            Mock -CommandName Assert-GitLocalChange

            Mock -CommandName git -MockWith {
                if ($args[0] -eq 'checkout')
                {
                    $global:LASTEXITCODE = 1
                }
                else
                {
                    throw "Mock git unexpected args: $($args -join ' ')"
                }
            }

            $mockErrorMessage = InModuleScope -ScriptBlock {
                $script:localizedData.Switch_GitLocalBranch_FailedCheckoutLocalBranch -f 'feature/test-branch'
            }
        }

        AfterEach {
            $global:LASTEXITCODE = 0
        }

        It 'Should throw terminating error when git checkout fails' {
            {
                Switch-GitLocalBranch -Name 'feature/test-branch' -Force
            } | Should -Throw -ExpectedMessage $mockErrorMessage
        }
    }

    Context 'When ShouldProcess is used' {
        BeforeAll {
            Mock -CommandName Assert-GitLocalChange

            Mock -CommandName git -MockWith {
                if ($args[0] -eq 'checkout')
                {
                    $global:LASTEXITCODE = 0
                }
                else
                {
                    throw "Mock git unexpected args: $($args -join ' ')"
                }
            }
        }

        AfterEach {
            $global:LASTEXITCODE = 0
        }

        It 'Should not switch branch when WhatIf is specified' {
            Switch-GitLocalBranch -Name 'feature/test-branch' -WhatIf

            Should -Invoke -CommandName git -Times 0
        }

        It 'Should not call Assert-GitLocalChange when WhatIf is specified' {
            Switch-GitLocalBranch -Name 'feature/test-branch' -WhatIf

            Should -Invoke -CommandName Assert-GitLocalChange -Times 0
        }
    }

    Context 'When Force parameter is used' {
        BeforeAll {
            Mock -CommandName Assert-GitLocalChange

            Mock -CommandName git -MockWith {
                if ($args[0] -eq 'checkout')
                {
                    $global:LASTEXITCODE = 0
                }
                else
                {
                    throw "Mock git unexpected args: $($args -join ' ')"
                }
            }
        }

        AfterEach {
            $global:LASTEXITCODE = 0
        }

        It 'Should bypass confirmation when Force is used' {
            Switch-GitLocalBranch -Name 'feature/test-branch' -Force

            Should -Invoke -CommandName git -ParameterFilter {
                $args[0] -eq 'checkout' -and $args[1] -eq 'feature/test-branch'
            }
        }
    }

    Context 'When Assert-GitLocalChange throws an error' {
        BeforeAll {
            Mock -CommandName Assert-GitLocalChange -MockWith {
                throw 'There are unstaged or staged changes. Please commit or stash your changes before proceeding.'
            }

            Mock -CommandName git -MockWith {
                if ($args[0] -eq 'checkout')
                {
                    $global:LASTEXITCODE = 0
                }
                else
                {
                    throw "Mock git unexpected args: $($args -join ' ')"
                }
            }
        }

        AfterEach {
            $global:LASTEXITCODE = 0
        }

        It 'Should not proceed with checkout when there are local changes' {
            {
                Switch-GitLocalBranch -Name 'feature/test-branch' -Force
            } | Should -Throw -ExpectedMessage 'There are unstaged or staged changes. Please commit or stash your changes before proceeding.'

            Should -Invoke -CommandName git -Times 0
        }
    }

    Context 'When testing parameter validation' {
        It 'Should require the Name parameter' {
            # Test that Name parameter is mandatory by checking the parameter attributes
            $commandInfo = Get-Command -Name 'Switch-GitLocalBranch'
            $nameParameter = $commandInfo.Parameters['Name']

            $nameParameter.Attributes | Where-Object { $_ -is [System.Management.Automation.ParameterAttribute] } |
                Select-Object -First 1 | ForEach-Object {
                    $_.Mandatory | Should -BeTrue -Because 'Name parameter should be mandatory'
                }
        }

        It 'Should accept valid branch names with Force parameter' {
            Mock -CommandName Assert-GitLocalChange
            Mock -CommandName git -MockWith {
                if ($args[0] -eq 'checkout')
                {
                    $global:LASTEXITCODE = 0
                }
            }

            Switch-GitLocalBranch -Name 'main' -Force
            Switch-GitLocalBranch -Name 'feature/branch-name' -Force
            Switch-GitLocalBranch -Name 'hotfix/fix-123' -Force

            Should -Invoke -CommandName Assert-GitLocalChange -Times 3 -Exactly
            Should -Invoke -CommandName git -ParameterFilter { $args[0] -eq 'checkout' -and $args[1] -eq 'main' } -Times 1 -Exactly
            Should -Invoke -CommandName git -ParameterFilter { $args[0] -eq 'checkout' -and $args[1] -eq 'feature/branch-name' } -Times 1 -Exactly
            Should -Invoke -CommandName git -ParameterFilter { $args[0] -eq 'checkout' -and $args[1] -eq 'hotfix/fix-123' } -Times 1 -Exactly
        }

        It 'Should accept valid branch names without Force parameter' {
            Mock -CommandName Assert-GitLocalChange
            Mock -CommandName git -MockWith {
                if ($args[0] -eq 'checkout')
                {
                    $global:LASTEXITCODE = 0
                }
            }

            Switch-GitLocalBranch -Name 'main' -Confirm:$false
            Switch-GitLocalBranch -Name 'feature/branch-name' -Confirm:$false

            Should -Invoke -CommandName Assert-GitLocalChange -Times 2 -Exactly
            Should -Invoke -CommandName git -ParameterFilter { $args[0] -eq 'checkout' -and $args[1] -eq 'main' } -Times 1 -Exactly
            Should -Invoke -CommandName git -ParameterFilter { $args[0] -eq 'checkout' -and $args[1] -eq 'feature/branch-name' } -Times 1 -Exactly
        }

        It 'Should accept positional parameter for Name' {
            Mock -CommandName Assert-GitLocalChange
            Mock -CommandName git -MockWith {
                if ($args[0] -eq 'checkout')
                {
                    $global:LASTEXITCODE = 0
                }
            }

            Switch-GitLocalBranch 'main' -Force

            Should -Invoke -CommandName Assert-GitLocalChange -Times 1 -Exactly
            Should -Invoke -CommandName git -ParameterFilter { $args[0] -eq 'checkout' -and $args[1] -eq 'main' } -Times 1 -Exactly
        }
    }
}
