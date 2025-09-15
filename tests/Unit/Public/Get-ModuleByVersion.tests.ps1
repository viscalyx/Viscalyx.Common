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
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -ResolveDependency -Tasks build" first.'
    }
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

Describe 'Get-ModuleByVersion' {
    Context 'When checking command structure' {
        It 'Should have the correct parameters in parameter set <ExpectedParameterSetName>' -ForEach @(
            @{
                ExpectedParameterSetName = '__AllParameterSets'
                ExpectedParameters = '[-Name] <string> [-Version] <string> [<CommonParameters>]'
            }
        ) {
            $result = (Get-Command -Name 'Get-ModuleByVersion').ParameterSets |
                Where-Object -FilterScript { $_.Name -eq $ExpectedParameterSetName } |
                Select-Object -Property @(
                    @{ Name = 'ParameterSetName'; Expression = { $_.Name } },
                    @{ Name = 'ParameterListAsString'; Expression = { $_.ToString() } }
                )
            $result.ParameterSetName | Should -Be $ExpectedParameterSetName
            $result.ParameterListAsString | Should -Be $ExpectedParameters
        }

        It 'Should have Name as a mandatory parameter' {
            $parameterInfo = (Get-Command -Name 'Get-ModuleByVersion').Parameters['Name']
            $parameterInfo.Attributes.Mandatory | Should -BeTrue
        }

        It 'Should have Version as a mandatory parameter' {
            $parameterInfo = (Get-Command -Name 'Get-ModuleByVersion').Parameters['Version']
            $parameterInfo.Attributes.Mandatory | Should -BeTrue
        }
    }

    Context 'When the module exists with the specified version' {
        BeforeAll {
            Mock -CommandName Get-Module -MockWith {
                [pscustomobject]@{
                    Name = 'ExistingModule'
                    Version = [version]'1.0.0'
                }
            }

            Mock -CommandName Get-ModuleVersion -RemoveParameterType 'Module' -MockWith {
                '1.0.0'
            }
        }

        It 'Should return the module object' {
            $result = Get-ModuleByVersion -Name 'ExistingModule' -Version '1.0.0'
            $result | Should-BeTruthy
        }
    }

    Context 'When the module does not exist with the specified version' {
        BeforeAll {
            Mock -CommandName Get-Module -MockWith {
                'ExistingModule'
            }

            Mock -CommandName Get-ModuleVersion -RemoveParameterType 'Module' -MockWith {
                '1.0.0'
            }
        }

        It 'Should return $null when the specified version is not found' {
            $result = Get-ModuleByVersion -Name 'ExistingModule' -Version '2.0.0'

            $result | Should-BeNull
        }
    }

    Context 'When the module does not exist' {
        BeforeAll {
            Mock -CommandName Get-Module
            Mock -CommandName Get-ModuleVersion -RemoveParameterType 'Module' -MockWith {
                '1.0.0'
            }
        }

        It 'Should return $null when the module does not exist' {
            $result = Get-ModuleByVersion -Name 'ExistingModule' -Version '1.0.0'

            $result | Should-BeNull
        }
    }
}
