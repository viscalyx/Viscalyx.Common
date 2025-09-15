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

Describe 'Remove-PSHistory' {
    Context 'When checking command structure' {
        It 'Should have the correct parameters in parameter set <ExpectedParameterSetName>' -ForEach @(
            @{
                ExpectedParameterSetName = '__AllParameterSets'
                ExpectedParameters       = '[-Pattern] <string> [-EscapeRegularExpression] [-WhatIf] [-Confirm] [<CommonParameters>]'
            }
        ) {
            $result = (Get-Command -Name 'Remove-PSHistory').ParameterSets |
                Where-Object -FilterScript { $_.Name -eq $ExpectedParameterSetName } |
                Select-Object -Property @(
                    @{ Name = 'ParameterSetName'; Expression = { $_.Name } },
                    @{ Name = 'ParameterListAsString'; Expression = { $_.ToString() } }
                )
            $result.ParameterSetName | Should -Be $ExpectedParameterSetName
            $result.ParameterListAsString | Should -Be $ExpectedParameters
        }

        It 'Should have Pattern as a mandatory parameter' {
            $result = (Get-Command -Name 'Remove-PSHistory').Parameters['Pattern'].Attributes.Mandatory
            $result | Should -Contain $true
        }
    }

    BeforeEach {
        # Mock Get-History to return a predefined set of history entries
        Mock -CommandName Get-History -MockWith {
            @(
                [PSCustomObject] @{
                    Id          = 1
                    CommandLine = 'Get-Process'
                }
                [PSCustomObject] @{
                    Id          = 2
                    CommandLine = 'Get-Content file1.txt'
                }
                [PSCustomObject] @{
                    Id          = 3
                    CommandLine = 'Remove-Item file2.txt'
                }
            )
        }

        # Mock Clear-History to verify it is called with the correct parameters
        Mock -CommandName Clear-History
    }

    It 'Should remove history entries matching the pattern' {
        # Act
        $null = Viscalyx.Common\Remove-PSHistory -Pattern 'file.*\.txt' -Confirm:$false

        # Assert
        Should -Invoke -CommandName Clear-History -Exactly -Times 2 -Scope It
        Should -Invoke -CommandName Clear-History -ParameterFilter { $Id -eq 2 } -Exactly -Times 1 -Scope It
        Should -Invoke -CommandName Clear-History -ParameterFilter { $Id -eq 3 } -Exactly -Times 1 -Scope It
    }

    It 'Should not remove history entries if no match is found' {
        # Act
        $null = Viscalyx.Common\Remove-PSHistory -Pattern 'NonExistentPattern' -Confirm:$false

        # Assert
        Should -Invoke -CommandName Clear-History -Times 0 -Scope It
    }

    It 'Should treat pattern as a literal string when EscapeRegularExpression is specified' {
        # Act
        $null = Viscalyx.Common\Remove-PSHistory -Pattern 'file1.txt' -EscapeRegularExpression -Confirm:$false

        # Assert
        Should -Invoke -CommandName Clear-History -Exactly 1 -Scope It
        Should -Invoke -CommandName Clear-History -ParameterFilter { $Id -eq 2 } -Exactly -Times 1 -Scope It
    }
}
