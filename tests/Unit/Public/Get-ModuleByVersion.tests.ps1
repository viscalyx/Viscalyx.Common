[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
param ()

BeforeDiscovery {
    try
    {
        if (-not (Get-Module -Name 'DscResource.Test'))
        {
            # Assumes dependencies has been resolved, so if this module is not available, run 'noop' task.
            if (-not (Get-Module -Name 'DscResource.Test' -ListAvailable))
            {
                # Redirect all streams to $null, except the error stream (stream 2)
                & "$PSScriptRoot/../../../build.ps1" -Tasks 'noop' 3>&1 4>&1 5>&1 6>&1 > $null
            }

            # If the dependencies has not been resolved, this will throw an error.
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
    It 'Should have the expected parameter set <Name>' -ForEach @(
        @{
            Name = '__AllParameterSets'
            ExpectedParameterSetString = '[-Name] <string> [-Version] <string> [<CommonParameters>]'
        }
    ) {
        $parameterSet = (Get-Command -Name 'Get-ModuleByVersion').ParameterSets |
            Where-Object -FilterScript { $_.Name -eq $Name }

        $parameterSet | Should -Not -BeNullOrEmpty
        $parameterSet.Name | Should -Be $Name
        $parameterSet.ToString() | Should -Be $ExpectedParameterSetString
    }

    Context 'When the module exists with the specified version' {
        BeforeAll {
            Mock -CommandName Get-Module -MockWith {
                'ExistingModule'
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
