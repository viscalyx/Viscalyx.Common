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

Describe 'ConvertTo-AnsiSequence' {
    BeforeAll {
        $esc = [System.Char] 0x1b
    }

    It 'Should have the expected parameter set <Name>' -ForEach @(
        @{
            Name = '__AllParameterSets'
            ExpectedParameterSetString = '[-Value] <string> [<CommonParameters>]'
        }
    ) {
        $parameterSet = (Get-Command -Name 'ConvertTo-AnsiSequence').ParameterSets |
            Where-Object -FilterScript { $_.Name -eq $Name }

        $parameterSet | Should -Not -BeNullOrEmpty
        $parameterSet.Name | Should -Be $Name
        $parameterSet.ToString() | Should -Be $ExpectedParameterSetString
    }

    It 'Should return the same value if no ANSI sequence is present' {
        $result = ConvertTo-AnsiSequence -Value 'Hello'
        $result | Should-BeString 'Hello'
    }

    It 'Should convert partial ANSI sequence to full ANSI sequence' {
        $result = ConvertTo-AnsiSequence -Value '[31'
        $result | Should-BeString "$($esc)[31m"
    }

    It 'Should convert complete ANSI sequence correctly' {
        $result = ConvertTo-AnsiSequence -Value "$($esc)[32m"
        $result | Should-BeString "$($esc)[32m"
    }

    It 'Should handle multiple ANSI codes' {
        $result = ConvertTo-AnsiSequence -Value '[31;1'
        $result | Should-BeString "$($esc)[31;1m"
    }

    It 'Should handle number only' {
        $result = ConvertTo-AnsiSequence -Value '31'
        $result | Should-BeString "$($esc)[31m"
    }

    It 'Should handle numbers separated by semicolon' {
        $result = ConvertTo-AnsiSequence -Value '31;1'
        $result | Should-BeString "$($esc)[31;1m"
    }

    It 'Should handle number suffixed with m-character' {
        $result = ConvertTo-AnsiSequence -Value '31m'
        $result | Should-BeString "$($esc)[31m"
    }

    It 'Should handle numbers separated by semicolon and suffixed with m-character' {
        $result = ConvertTo-AnsiSequence -Value '31;3;5m'
        $result | Should-BeString "$($esc)[31;3;5m"
    }
}
