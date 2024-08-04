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
                & "$PSScriptRoot/../../../build.ps1" -Tasks 'noop' 2>&1 4>&1 5>&1 6>&1 > $null
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

Describe 'Remove-History' {
    BeforeAll {
        Mock -CommandName Remove-PSReadLineHistory
        Mock -CommandName Remove-PSHistory
    }

    It 'Should removes entries matching a pattern' {
        # Arrange
        $pattern = ".*\.txt"

        # Act
        Viscalyx.Common\Remove-History -Pattern $pattern

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
        Viscalyx.Common\Remove-History -Pattern $pattern -EscapeRegularExpression

        # Assert
        Should -Invoke -CommandName Remove-PSReadLineHistory -Exactly -Times 1 -Scope It -ParameterFilter {
            $Pattern -eq $pattern -and $EscapeRegularExpression.IsPresent
        }

        Should -Invoke -CommandName Remove-PSHistory -Exactly -Times 1 -Scope It -ParameterFilter {
            $Pattern -eq $pattern -and $EscapeRegularExpression.IsPresent
        }
    }
}
