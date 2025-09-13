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

Describe 'Remove-PSReadLineHistory' {
    BeforeAll {
        Mock -CommandName Set-Content

        # Mock Get-Content to return the mocked history content
        Mock -CommandName Get-Content -MockWith {
            return @(
                'Get-Process',
                'Get-Service',
                'Get-Content .\file.txt',
                'Remove-Item .\file.txt',
                'Write-Output "Hello World"'
            )
        }
    }

    Context 'When removing entries with a regular expression pattern' {
        It 'Should remove entries matching the pattern' {
            # Arrange
            $pattern = '.*\.txt'

            $expectedContent = @(
                'Get-Process',
                'Get-Service',
                'Write-Output "Hello World"'
            )

            # Act
            $null = Viscalyx.Common\Remove-PSReadLineHistory -Pattern $pattern -Confirm:$false

            # Assert
            Should -Invoke -CommandName Set-Content -Exactly -Times 1 -Scope It -ParameterFilter {
                # Compare the arrays.
                $compareResult = Compare-Object -ReferenceObject $Value -DifferenceObject $expectedContent

                if ($compareResult)
                {
                    Out-Difference -Difference $Value -Reference $expectedContent | Write-Verbose -Verbose
                }

                # Compare-Object returns 0 when equal.
                -not $compareResult
            }
        }
    }

    Context 'When removing entries with a literal string pattern' {
        It 'Should remove entries matching the literal string' {
            # Arrange
            $pattern = 'Remove-Item .\file.txt'

            $expectedContent = @(
                'Get-Process',
                'Get-Service',
                'Get-Content .\file.txt',
                'Write-Output "Hello World"'
            )

            # Act
            $null = Viscalyx.Common\Remove-PSReadLineHistory -Pattern $pattern -EscapeRegularExpression -Confirm:$false

            # Assert
            Should -Invoke -CommandName Set-Content -Exactly -Times 1 -Scope It -ParameterFilter {
                # Compare the arrays.
                $compareResult = Compare-Object -ReferenceObject $Value -DifferenceObject $expectedContent

                if ($compareResult)
                {
                    Out-Difference -Difference $Value -Reference $expectedContent | Write-Verbose -Verbose
                }

                # Compare-Object returns 0 when equal.
                -not $compareResult
            }
        }
    }

    Context 'When no entries match the pattern' {
        It 'Should not modify the history file' {
            # Arrange
            $pattern = 'NonExistentPattern'

            $expectedContent = @(
                'Get-Process',
                'Get-Service',
                'Get-Content .\file.txt',
                'Remove-Item .\file.txt',
                'Write-Output "Hello World"'
            )

            # Act
            $null = Viscalyx.Common\Remove-PSReadLineHistory -Pattern $pattern -Confirm:$false

            # Assert
            Should -Invoke -CommandName Set-Content -Exactly -Times 0 -Scope It
        }
    }
}
