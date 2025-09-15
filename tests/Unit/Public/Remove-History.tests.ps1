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

Describe 'Remove-History' {
    Context 'When checking command structure' {
        It 'Should have the correct parameters in parameter set <ExpectedParameterSetName>' -ForEach @(
            @{
                ExpectedParameterSetName = '__AllParameterSets'
                ExpectedParameters       = '[-Pattern] <string> [-EscapeRegularExpression] [-WhatIf] [-Confirm] [<CommonParameters>]'
            }
        ) {
            $result = (Get-Command -Name 'Remove-History').ParameterSets |
                Where-Object -FilterScript { $_.Name -eq $ExpectedParameterSetName } |
                Select-Object -Property @(
                    @{ Name = 'ParameterSetName'; Expression = { $_.Name } },
                    @{ Name = 'ParameterListAsString'; Expression = { $_.ToString() } }
                )
            $result.ParameterSetName | Should -Be $ExpectedParameterSetName
            $result.ParameterListAsString | Should -Be $ExpectedParameters
        }

        It 'Should have Pattern as a mandatory parameter' {
            $result = (Get-Command -Name 'Remove-History').Parameters['Pattern'].Attributes.Mandatory
            $result | Should -Contain $true
        }
    }

    BeforeAll {
        Mock -CommandName Remove-PSReadLineHistory
        Mock -CommandName Remove-PSHistory
    }

    It 'Should remove entries matching a pattern' {
        # Arrange
        $pattern = ".*\.txt"

        # Act
        $null = Viscalyx.Common\Remove-History -Pattern $pattern

        # Assert
        Should -Invoke -CommandName Remove-PSReadLineHistory -Exactly -Times 1 -Scope It -ParameterFilter {
            $Pattern -eq $pattern -and -not $EscapeRegularExpression.IsPresent
        }

        Should -Invoke -CommandName Remove-PSHistory -Exactly -Times 1 -Scope It -ParameterFilter {
            $Pattern -eq $pattern -and -not $EscapeRegularExpression.IsPresent
        }
    }

    It 'Should treat the pattern as a literal string when EscapeRegularExpression is specified' {
        # Arrange
        $pattern = './build.ps1'

        # Act
        $null = Viscalyx.Common\Remove-History -Pattern $pattern -EscapeRegularExpression

        # Assert
        Should -Invoke -CommandName Remove-PSReadLineHistory -Exactly -Times 1 -Scope It -ParameterFilter {
            $Pattern -eq $pattern -and $EscapeRegularExpression.IsPresent
        }

        Should -Invoke -CommandName Remove-PSHistory -Exactly -Times 1 -Scope It -ParameterFilter {
            $Pattern -eq $pattern -and $EscapeRegularExpression.IsPresent
        }
    }
}
