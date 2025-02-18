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

Describe 'Merge-Patch' {
    Context 'When patch file is valid' {
        It 'Should apply a patch' -ForEach @(
            @{
                PatchEntry = @{
                    ModuleName = 'TestModule'
                    ModuleVersion = '1.0.0'
                    ScriptFileName = 'TestScript.ps1'
                    HashSHA = '1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef'
                    StartOffset = 20
                    EndOffset = 30
                    PatchContent = 'PatchedContent1'
                }
            }
         ) {
            Mock -CommandName Get-Module -MockWith {
                @{
                    ModuleBase = $TestDrive
                }
            }

            Mock -CommandName Test-Path -MockWith {
                $true
            }

            Mock -CommandName Get-Content -MockWith {
                'This is the script file content'
            }

            Mock -CommandName Set-Content

            InModuleScope -Parameters $_ -ScriptBlock {
                Merge-Patch -PatchEntry $PatchEntry
            }

            Should -Invoke -CommandName Get-Content -Exactly 1 -Scope It
            Should -Invoke -CommandName Set-Content -Exactly 1 -Scope It
        }
    }
}
