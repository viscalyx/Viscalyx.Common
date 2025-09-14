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

Describe 'Split-StringAtIndex' {
    Context 'When checking command structure' {
        It 'Should have the correct parameters in parameter set <ExpectedParameterSetName>' -ForEach @(
            @{
                ExpectedParameterSetName = 'PipelineInput'
                ExpectedParameters = '-IndexObject <psobject> -InputString <string> [<CommonParameters>]'
            }
            @{
                ExpectedParameterSetName = 'StartEndInput'
                # Windows PowerShell shows uint32, PowerShell 7+ shows uint
                ExpectedParameters = if ($PSVersionTable.PSVersion.Major -le 5) {
                    '-InputString <string> -StartIndex <uint32> -EndIndex <uint32> [<CommonParameters>]'
                } else {
                    '-InputString <string> -StartIndex <uint> -EndIndex <uint> [<CommonParameters>]'
                }
            }
        ) {
            $result = (Get-Command -Name 'Split-StringAtIndex').ParameterSets |
                Where-Object -FilterScript { $_.Name -eq $ExpectedParameterSetName } |
                Select-Object -Property @(
                    @{ Name = 'ParameterSetName'; Expression = { $_.Name } },
                    @{ Name = 'ParameterListAsString'; Expression = { $_.ToString() } }
                )
            $result.ParameterSetName | Should -Be $ExpectedParameterSetName
            $result.ParameterListAsString | Should -Be $ExpectedParameters
        }

        It 'Should have IndexObject as a mandatory parameter in PipelineInput parameter set' {
            $parameterInfo = (Get-Command -Name 'Split-StringAtIndex').Parameters['IndexObject']
            $mandatoryAttribute = $parameterInfo.Attributes | Where-Object { $_.TypeId.Name -eq 'ParameterAttribute' -and $_.ParameterSetName -eq 'PipelineInput' }
            $mandatoryAttribute.Mandatory | Should -BeTrue
        }

        It 'Should have InputString as a mandatory parameter in all parameter sets' {
            $parameterInfo = (Get-Command -Name 'Split-StringAtIndex').Parameters['InputString']
            $mandatoryAttributes = $parameterInfo.Attributes | Where-Object { $_.TypeId.Name -eq 'ParameterAttribute' }
            $mandatoryAttributes | ForEach-Object { $_.Mandatory | Should -BeTrue }
        }

        It 'Should have StartIndex as a mandatory parameter in StartEndInput parameter set' {
            $parameterInfo = (Get-Command -Name 'Split-StringAtIndex').Parameters['StartIndex']
            $mandatoryAttribute = $parameterInfo.Attributes | Where-Object { $_.TypeId.Name -eq 'ParameterAttribute' -and $_.ParameterSetName -eq 'StartEndInput' }
            $mandatoryAttribute.Mandatory | Should -BeTrue
        }

        It 'Should have EndIndex as a mandatory parameter in StartEndInput parameter set' {
            $parameterInfo = (Get-Command -Name 'Split-StringAtIndex').Parameters['EndIndex']
            $mandatoryAttribute = $parameterInfo.Attributes | Where-Object { $_.TypeId.Name -eq 'ParameterAttribute' -and $_.ParameterSetName -eq 'StartEndInput' }
            $mandatoryAttribute.Mandatory | Should -BeTrue
        }
    }

    Context 'Using StartIndex and EndIndex parameters' {
        It 'Should split the string correctly with valid indices' {
            $result = Split-StringAtIndex -InputString "Hello, World!" -StartIndex 0 -EndIndex 4

            $result | Should-BeEquivalent @('Hello', ', World!')
        }

        It 'Should handle indices at the end of the string' {
            $result = Split-StringAtIndex -InputString "Hello, World!" -StartIndex 7 -EndIndex 11

            $result | Should-BeEquivalent @('Hello, ', 'World', '!')
        }

        It 'Should return the whole string if indices cover the entire string' {
            $result = Split-StringAtIndex -InputString "Hello, World!" -StartIndex 0 -EndIndex 12

            $result | Should-BeEquivalent @('Hello, World!')
        }
    }

    Context 'Using pipeline input with IndexObject' {
        It 'Should split the string correctly with valid index objects' {
            $indexObjects = @(@{Start = 0; End = 4}, @{Start = 7; End = 11})

            $result = $indexObjects | Split-StringAtIndex -InputString "Hello, World!"

            $result | Should-BeEquivalent @('Hello', ', ', 'World', '!')
        }

        It 'Should handle multiple index objects' {
            $indexObjects = @(@{Start = 0; End = 2}, @{Start = 4; End = $null}, @{Start = 8; End = 10})

            # cSpell:ignore abcdefghijk
            $result = $indexObjects | Split-StringAtIndex -InputString "abcdefghijk"

            $result | Should-BeEquivalent @('abc', 'd', 'e', 'fgh', 'ijk')
        }
    }

    Context 'Edge cases' {
        It 'Should return the whole string if no indices are provided' {
            $result = Split-StringAtIndex -InputString "Hello, World!" -StartIndex 0 -EndIndex 12

            $result | Should-BeEquivalent @('Hello, World!')
        }

        It 'Should handle empty input string' {
            {  Split-StringAtIndex -InputString "" } | Should -Throw
        }

        It 'Should throw an error if indices are out of bounds' {
            { Split-StringAtIndex -InputString "Hello" -StartIndex 10 -EndIndex 15 } | Should -Throw
        }
    }
}
