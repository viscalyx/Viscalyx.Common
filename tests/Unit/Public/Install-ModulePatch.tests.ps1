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

Describe 'Install-ModulePatch' {
    Context 'When patch file is valid' {
        BeforeAll {
            $patchFileContent = @'
[
    {
        "ModuleName": "TestModule",
        "ModuleVersion": "1.0.0",
        "ScriptFileName": "TestScript.ps1",
        "HashSHA": "1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef",
        "StartOffset": 0,
        "EndOffset": 10,
        "PatchContent": "PatchedContent"
    }
]
'@

            Mock -CommandName Assert-PatchFile
            Mock -CommandName Merge-Patch

            Mock -CommandName Get-PatchFileContentFromPath -MockWith {
                $patchFileContent
            }

            Mock -CommandName Get-PatchFileContentFromURI -MockWith {
                $patchFileContent
            }
        }

        It 'Should apply patches from local file' {
            Install-ModulePatch -Force -Path "$TestDrive/patches/TestModule_1.0.0_patch.json" -ErrorAction 'Stop'

            Should -Invoke -CommandName Get-PatchFileContentFromURI -Exactly 0 -Scope It
            Should -Invoke -CommandName Get-PatchFileContentFromPath -Exactly 1 -Scope It
            Should -Invoke -CommandName Merge-Patch -Exactly 1 -Scope It
        }

        It 'Should apply patches from URL' {
            Install-ModulePatch -Force -URI 'https://gist.githubusercontent.com/user/gistid/raw/TestModule_1.0.0_patch.json' -ErrorAction 'Stop'

            Should -Invoke -CommandName Get-PatchFileContentFromPath -Exactly 0 -Scope It
            Should -Invoke -CommandName Get-PatchFileContentFromURI -Exactly 1 -Scope It
            Should -Invoke -CommandName Merge-Patch -Exactly 1 -Scope It
        }
    }
}
