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

Describe "Get-NumericalSequence" {
    It 'Should have the expected parameter set <Name>' -ForEach @(
        @{
            Name = '__AllParameterSets'
            ExpectedParameterSetString = '[-Number] <int> [<CommonParameters>]'
        }
    ) {
        $parameterSet = (Get-Command -Name 'Get-NumericalSequence').ParameterSets |
            Where-Object -FilterScript { $_.Name -eq $Name }

        $parameterSet | Should -Not -BeNullOrEmpty
        $parameterSet.Name | Should -Be $Name
        $parameterSet.ToString() | Should -Be $ExpectedParameterSetString
    }

    It "should return a single range for consecutive numbers" {
        $numbers = 1, 2, 3

        $result = $numbers | Get-NumericalSequence

        $expected = [PSCustomObject]@{ Start = 1; End = 3 }

        $result | Should-BeEquivalent $expected
    }

    It "should return multiple ranges for numbers with gaps" {
        $numbers = 1, 2, 3, 5, 6, 7, 10

        $result = $numbers | Get-NumericalSequence

        $expected = @(
            [PSCustomObject]@{ Start = 1; End = 3 },
            [PSCustomObject]@{ Start = 5; End = 7 },
            [PSCustomObject]@{ Start = 10; End = $null }
        )

        $result |  Should-BeEquivalent $expected
    }

    It "should return a single range for a single number" {
        $numbers = 1

        $result = $numbers | Get-NumericalSequence

        $expected = [PSCustomObject]@{ Start = 1; End = $null }

        $result | Should-BeEquivalent $expected
    }

    It "should return an empty array for no input" {
        $numbers = @()

        $result = $numbers | Get-NumericalSequence

        $expected = @()

        $result | Should-BeEquivalent $expected
    }
}
