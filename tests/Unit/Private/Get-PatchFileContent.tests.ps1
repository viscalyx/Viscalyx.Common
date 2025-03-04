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

Describe 'Get-PatchFileContent' {
    Context 'When JSON content is valid' {
        It 'Should convert JSON content to PowerShell object' {
            $result = InModuleScope -ScriptBlock {
                $jsonContent = @'
[
    {
        "ModuleName": "TestModule",
        "ModuleVersion": "1.0.0",
        "ScriptFileName": "TestScript.ps1",
        "OriginalHashSHA": "1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef",
        "StartOffset": 0,
        "EndOffset": 10,
        "PatchContent": "PatchedContent"
    }
]
'@

                Get-PatchFileContent -JsonContent $jsonContent
            }

            $result | Should -BeOfType ([PSCustomObject])
            $result.ModuleName | Should -Be 'TestModule'
            $result.ModuleVersion | Should -Be '1.0.0'
            $result.ScriptFileName | Should -Be 'TestScript.ps1'
            $result.OriginalHashSHA | Should -Be '1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef'
            $result.StartOffset | Should -Be 0
            $result.EndOffset | Should -Be 10
            $result.PatchContent | Should -Be 'PatchedContent'
        }
    }

    Context 'When JSON content is invalid' {
        It 'Should throw error for invalid JSON content' {
            InModuleScope -ScriptBlock {
                { Get-PatchFileContent -JsonContent 'Invalid JSON Content' -ErrorAction 'Stop' } |
                    Should -Throw -ErrorId 'GPFC0001,Get-PatchFileContent' # cSpell: disable-line
            }
        }
    }
}
