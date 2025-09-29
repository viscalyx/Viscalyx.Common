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
Describe 'New-GitTag' {
    Context 'When checking command structure' {
        It 'Should have the correct parameters in parameter set __AllParameterSets' -ForEach @(
            @{
                ExpectedParameterSetName = '__AllParameterSets'
                ExpectedParameters       = '[-Name] <string> [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]'
            }
        ) {
            $result = (Get-Command -Name 'New-GitTag').ParameterSets |
                Where-Object { $_.Name -eq $ExpectedParameterSetName } |
                Select-Object `
                    @{ Name = 'ParameterSetName';       Expression = { $_.Name } }, `
                    @{ Name = 'ParameterListAsString'; Expression = { $_.ToString() } }

            $result.ParameterSetName       | Should -Be $ExpectedParameterSetName
            $result.ParameterListAsString  | Should -Be $ExpectedParameters
        }
    }

    Context 'When creating a new tag' {
        BeforeAll {
            Mock -CommandName git -MockWith {
                if ($args[0] -eq 'tag')
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

        It 'Should create a new tag successfully' {
            $null = New-GitTag -Name 'v1.0.0' -Force

            Should -Invoke -CommandName git -ParameterFilter {
                $args[0] -eq 'tag' -and $args[1] -eq 'v1.0.0'
            }
        }

        Context 'When the operation fails' {
            BeforeAll {
                Mock -CommandName git -MockWith {
                    if ($args[0] -eq 'tag')
                    {
                        $global:LASTEXITCODE = 1
                    }
                    else
                    {
                        throw "Mock git unexpected args: $($args -join ' ')"
                    }
                }

                $mockErrorMessage = InModuleScope -ScriptBlock {
                    $script:localizedData.New_GitTag_FailedToCreateTag -f 'v1.0.0'
                }
            }

            AfterEach {
                $global:LASTEXITCODE = 0
            }

            It 'Should throw terminating error when git fails' {
                {
                    New-GitTag -Name 'v1.0.0' -Force
                } | Should -Throw -ExpectedMessage $mockErrorMessage
            }
        }
    }

    Context 'When ShouldProcess is used' {
        BeforeAll {
            Mock -CommandName git -MockWith {
                if ($args[0] -eq 'tag')
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

        It 'Should not create tag when WhatIf is specified' {
            $null = New-GitTag -Name 'v1.0.0' -WhatIf

            Should -Invoke -CommandName git -Times 0
        }
    }

    Context 'When Force parameter is used' {
        BeforeAll {
            Mock -CommandName git -MockWith {
                if ($args[0] -eq 'tag')
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
            $null = New-GitTag -Name 'v1.0.0' -Force

            Should -Invoke -CommandName git -ParameterFilter {
                $args[0] -eq 'tag' -and $args[1] -eq 'v1.0.0'
            }
        }
    }
}
