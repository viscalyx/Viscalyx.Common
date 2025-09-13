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
    $script:dscModuleName = 'Viscalyx.Common'

    Import-Module -Name $script:dscModuleName

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

Describe 'Remove-PSHistory' {
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

    It 'Should removes history entries matching the pattern' {
        # Act
        Viscalyx.Common\Remove-PSHistory -Pattern 'file.*\.txt' -Confirm:$false

        # Assert
        Should -Invoke -CommandName Clear-History -Exactly -Times 2 -Scope It
        Should -Invoke -CommandName Clear-History -ParameterFilter { $Id -eq 2 } -Exactly -Times 1 -Scope It
        Should -Invoke -CommandName Clear-History -ParameterFilter { $Id -eq 3 } -Exactly -Times 1 -Scope It
    }

    It 'Should not remove history entries if no match is found' {
        # Act
        Viscalyx.Common\Remove-PSHistory -Pattern 'NonExistentPattern' -Confirm:$false

        # Assert
        Should -Invoke -CommandName Clear-History -Times 0 -Scope It
    }

    It 'Should treat pattern as a literal string when EscapeRegularExpression is specified' {
        # Act
        Viscalyx.Common\Remove-PSHistory -Pattern 'file1.txt' -EscapeRegularExpression -Confirm:$false

        # Assert
        Should -Invoke -CommandName Clear-History -Exactly 1 -Scope It
        Should -Invoke -CommandName Clear-History -ParameterFilter { $Id -eq 2 } -Exactly 1 -Scope It
    }
}
