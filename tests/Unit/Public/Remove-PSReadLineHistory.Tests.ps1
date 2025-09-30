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

Describe 'Remove-PSReadLineHistory' {
    Context 'When checking command structure' {
        It 'Should have the correct parameters in parameter set <ExpectedParameterSetName>' -ForEach @(
            @{
                ExpectedParameterSetName = '__AllParameterSets'
                ExpectedParameters       = '[-Pattern] <string> [-EscapeRegularExpression] [-WhatIf] [-Confirm] [<CommonParameters>]'
            }
        ) {
            $result = (Get-Command -Name 'Remove-PSReadLineHistory').ParameterSets |
                Where-Object -FilterScript { $_.Name -eq $ExpectedParameterSetName } |
                Select-Object -Property @(
                    @{ Name = 'ParameterSetName'; Expression = { $_.Name } },
                    @{ Name = 'ParameterListAsString'; Expression = { $_.ToString() } }
                )
            $result.ParameterSetName | Should -Be $ExpectedParameterSetName
            $result.ParameterListAsString | Should -Be $ExpectedParameters
        }

        It 'Should have Pattern as a mandatory parameter' {
            $result = (Get-Command -Name 'Remove-PSReadLineHistory').Parameters['Pattern'].Attributes.Mandatory
            $result | Should -Contain $true
        }
    }

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
                    $null = Out-Difference -Difference $Value -Reference $expectedContent
                }

                # Compare-Object returns $null (no output) when equal.
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
                    $null = Out-Difference -Difference $Value -Reference $expectedContent
                }

                # Compare-Object returns $null (no output) when equal.
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
