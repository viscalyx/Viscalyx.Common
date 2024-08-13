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

Describe 'ConvertTo-DiffString' {
    It 'should convert the entire string when only InputString is provided' {
        $result = ConvertTo-DiffString -InputString "Hello, world!"

        $result | Should -BeExactly "`e[30;43mHello, world!`e[0m"
    }

    It 'should convert the specified portion of the string using StartEndInput' {
        $result = ConvertTo-DiffString -InputString "Hello, world!" -StartIndex 7 -EndIndex 11

        $result | Should -BeExactly "Hello, `e[30;43mworld`e[0m!"
    }

    It 'should convert the specified portion of the string using PipelineInput' {
        $indexObject = [PSCustomObject]@{ Start = 7; End = 11 }
        $result = $indexObject | ConvertTo-DiffString -InputString "Hello, world!"

        $result | Should -BeExactly "Hello, `e[30;43mworld`e[0m!"
    }

    It 'should use default ANSI color codes' {
        $result = ConvertTo-DiffString -InputString "Hello, world!" -StartIndex 7 -EndIndex 11

        $result | Should -BeExactly "Hello, `e[30;43mworld`e[0m!"
    }

    It 'should use custom ANSI color codes' {
        $result = ConvertTo-DiffString -InputString "Hello, world!" -StartIndex 7 -EndIndex 11 -Ansi '31;42m' -AnsiReset '0m'

        $result | Should -BeExactly "Hello, `e[31;42mworld`e[0m!"
    }
}
