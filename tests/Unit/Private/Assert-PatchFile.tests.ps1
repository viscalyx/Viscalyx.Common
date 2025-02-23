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

Describe 'Assert-PatchFile' {
    Context 'When patch file is valid' {
        It 'Should validate patch file structure and data' {
            Mock -CommandName Assert-PatchValidity

            Mock -CommandName Get-Module -MockWith {
                return [PSCustomObject] @{
                    Name       = 'TestModule'
                    Version    = [System.Version] '1.0.0'
                    ModuleBase = "$TestDrive/Modules/TestModule"
                }
            }

            Mock -CommandName Get-FileHash -MockWith {
                return [PSCustomObject] @{
                    Hash = '1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef'
                }
            }

            InModuleScope -ScriptBlock {
                $patchFileContent = @'
[
    {
        "ModuleName": "TestModule",
        "ModuleVersion": "1.0.0",
        "ScriptFileName": "TestScript.ps1",
        "OriginalHashSHA": "1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef",
        "PatchedHashSHA": "abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890",
        "StartOffset": 0,
        "EndOffset": 10,
        "PatchContent": "PatchedContent"
    }
]
'@

                Assert-PatchFile -PatchFileContent ($patchFileContent | ConvertFrom-Json) -ErrorAction 'Stop'
            }
        }
    }

    Context 'When patch file is invalid' {
        It 'Should throw error for missing ModuleName' {
            InModuleScope -ScriptBlock {
                $patchFileContent = @'
[
    {
        "ModuleVersion": "1.0.0",
        "ScriptFileName": "TestScript.ps1",
        "OriginalHashSHA": "1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef",
        "StartOffset": 0,
        "EndOffset": 10,
        "PatchContent": "PatchedContent"
    }
]
'@
                { Assert-PatchFile -PatchFileContent ($patchFileContent | ConvertFrom-Json) -ErrorAction 'Stop' } |
                    Should -Throw -ExpectedMessage "Patch entry is missing 'ModuleName'."
            }
        }

        It 'Should throw correct error for missing ModuleVersion' {
            InModuleScope -ScriptBlock {
                $patchFileContent = @'
[
    {
        "ModuleName": "TestModule",
        "ScriptFileName": "TestScript.ps1",
        "OriginalHashSHA": "1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef",
        "StartOffset": 0,
        "EndOffset": 10,
        "PatchContent": "PatchedContent"
    }
]
'@

                { Assert-PatchFile -PatchFileContent ($patchFileContent | ConvertFrom-Json) -ErrorAction 'Stop' } |
                    Should -Throw -ExpectedMessage "Patch entry is missing 'ModuleVersion'."
            }
        }

        It 'Should throw correct error for missing ScriptFileName' {
            InModuleScope -ScriptBlock {
                $patchFileContent = @'
[
    {
        "ModuleName": "TestModule",
        "ModuleVersion": "1.0.0",
        "OriginalHashSHA": "1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef",
        "StartOffset": 0,
        "EndOffset": 10,
        "PatchContent": "PatchedContent"
    }
]
'@

                { Assert-PatchFile -PatchFileContent ($patchFileContent | ConvertFrom-Json) -ErrorAction 'Stop' } |
                    Should -Throw -ExpectedMessage "Patch entry is missing 'ScriptFileName'."
            }
        }

        It 'Should throw correct error for missing OriginalHashSHA' {
            InModuleScope -ScriptBlock {
                $patchFileContent = @'
[
    {
        "ModuleName": "TestModule",
        "ModuleVersion": "1.0.0",
        "ScriptFileName": "TestScript.ps1",
        "StartOffset": 0,
        "EndOffset": 10,
        "PatchContent": "PatchedContent"
    }
]
'@

                { Assert-PatchFile -PatchFileContent ($patchFileContent | ConvertFrom-Json) -ErrorAction 'Stop' } |
                    Should -Throw -ExpectedMessage "Patch entry is missing 'OriginalHashSHA'."
            }
        }

        It 'Should throw correct error for missing StartOffset or EndOffset' {
            InModuleScope -ScriptBlock {
                $patchFileContent = @'
[
    {
        "ModuleName": "TestModule",
        "ModuleVersion": "1.0.0",
        "ScriptFileName": "TestScript.ps1",
        "OriginalHashSHA": "1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef",
        "PatchContent": "PatchedContent"
    }
]
'@
                { Assert-PatchFile -PatchFileContent ($patchFileContent | ConvertFrom-Json) -ErrorAction 'Stop' } |
                    Should -Throw -ExpectedMessage "Patch entry is missing 'StartOffset' or 'EndOffset'."
            }
        }

        It 'Should throw correct error for missing PatchContent' {
            InModuleScope -ScriptBlock {
                $patchFileContent = @'
[
    {
        "ModuleName": "TestModule",
        "ModuleVersion": "1.0.0",
        "ScriptFileName": "TestScript.ps1",
        "OriginalHashSHA": "1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef",
        "StartOffset": 0,
        "EndOffset": 10
    }
]
'@

                { Assert-PatchFile -PatchFileContent ($patchFileContent | ConvertFrom-Json) -ErrorAction 'Stop' } |
                    Should -Throw -ExpectedMessage "Patch entry is missing 'PatchContent'."
            }
        }
    }

    Context 'Additional Edge Cases' {
        It 'Should throw error for empty patch file' {
            InModuleScope -ScriptBlock {
                $patchFileContent = ' [] '
                { Assert-PatchFile -PatchFileContent ($patchFileContent | ConvertFrom-Json) -ErrorAction 'Stop' } |
                    Should -Throw
            }
        }

        It 'Should throw error for invalid JSON format' {
            InModuleScope -ScriptBlock {
                $patchFileContent = 'Invalid JSON'
                { Assert-PatchFile -PatchFileContent ($patchFileContent | ConvertFrom-Json) -ErrorAction 'Stop' } |
                    Should -Throw
            }
        }
    }
}
