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

Describe 'ConvertTo-AnsiSequence' {
    BeforeAll {
        $esc = [System.Char] 0x1b
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
