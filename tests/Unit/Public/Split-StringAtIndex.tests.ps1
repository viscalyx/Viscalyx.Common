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

Describe 'Split-StringAtIndex' {
    Context 'Using StartIndex and EndIndex parameters' {
        It 'should split the string correctly with valid indices' {
            $result = Split-StringAtIndex -InputString "Hello, World!" -StartIndex 0 -EndIndex 4

            $result | Should-BeEquivalent @('Hello', ', World!')
        }

        It 'should handle indices at the end of the string' {
            $result = Split-StringAtIndex -InputString "Hello, World!" -StartIndex 7 -EndIndex 11

            $result | Should-BeEquivalent @('Hello, ', 'World', '!')
        }

        It 'should return the whole string if indices cover the entire string' {
            $result = Split-StringAtIndex -InputString "Hello, World!" -StartIndex 0 -EndIndex 12

            $result | Should-BeEquivalent @('Hello, World!')
        }
    }

    Context 'Using pipeline input with IndexObject' {
        It 'should split the string correctly with valid index objects' {
            $indexObjects = @(@{Start = 0; End = 4}, @{Start = 7; End = 11})

            $result = $indexObjects | Split-StringAtIndex -InputString "Hello, World!"

            $result | Should-BeEquivalent @('Hello', ', ', 'World', '!')
        }

        It 'should handle multiple index objects' {
            $indexObjects = @(@{Start = 0; End = 2}, @{Start = 4; End = $null}, @{Start = 8; End = 10})

            # cSpell:ignore abcdefghijk
            $result = $indexObjects | Split-StringAtIndex -InputString "abcdefghijk"

            $result | Should-BeEquivalent @('abc', 'd', 'e', 'fgh', 'ijk')
        }
    }

    Context 'Edge cases' {
        It 'should return the whole string if no indices are provided' {
            $result = Split-StringAtIndex -InputString "Hello, World!" -StartIndex 0 -EndIndex 12

            $result | Should-BeEquivalent @('Hello, World!')
        }

        It 'should handle empty input string' {
            {  Split-StringAtIndex -InputString "" } | Should -Throw
        }

        It 'should throw an error if indices are out of bounds' {
            { Split-StringAtIndex -InputString "Hello" -StartIndex 10 -EndIndex 15 } | Should -Throw
        }
    }
}
