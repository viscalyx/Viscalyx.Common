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
        It 'Should apply patches from local file' {
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

            Mock -CommandName Get-Content -MockWith { $patchFileContent }
            Mock -CommandName Get-Module -MockWith {
                return [PSCustomObject] @{
                    Name        = 'TestModule'
                    Version     = [System.Version] '1.0.0'
                    ModuleBase  = 'C:\Modules\TestModule'
                }
            }
            Mock -CommandName Get-FileHash -MockWith {
                return [PSCustomObject] @{
                    Hash = '1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef'
                }
            }
            Mock -CommandName Set-Content

            Install-ModulePatch -Path 'C:\patches\TestModule_1.0.0_patch.json' -Force

            Assert-MockCalled -CommandName Get-Content -Exactly 1 -Scope It
            Assert-MockCalled -CommandName Get-Module -Exactly 1 -Scope It
            Assert-MockCalled -CommandName Get-FileHash -Exactly 1 -Scope It
            Assert-MockCalled -CommandName Set-Content -Exactly 1 -Scope It
        }

        It 'Should apply patches from URL' {
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

            Mock -CommandName Invoke-RestMethod -MockWith { $patchFileContent }
            Mock -CommandName Get-Module -MockWith {
                return [PSCustomObject] @{
                    Name        = 'TestModule'
                    Version     = [System.Version] '1.0.0'
                    ModuleBase  = 'C:\Modules\TestModule'
                }
            }
            Mock -CommandName Get-FileHash -MockWith {
                return [PSCustomObject] @{
                    Hash = '1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef'
                }
            }
            Mock -CommandName Set-Content

            Install-ModulePatch -URI 'https://gist.githubusercontent.com/user/gistid/raw/TestModule_1.0.0_patch.json' -Force

            Assert-MockCalled -CommandName Invoke-RestMethod -Exactly 1 -Scope It
            Assert-MockCalled -CommandName Get-Module -Exactly 1 -Scope It
            Assert-MockCalled -CommandName Get-FileHash -Exactly 1 -Scope It
            Assert-MockCalled -CommandName Set-Content -Exactly 1 -Scope It
        }
    }

    Context 'When patch file is invalid' {
        It 'Should throw error for missing ModuleName' {
            $patchFileContent = @'
[
    {
        "ModuleVersion": "1.0.0",
        "ScriptFileName": "TestScript.ps1",
        "HashSHA": "1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef",
        "StartOffset": 0,
        "EndOffset": 10,
        "PatchContent": "PatchedContent"
    }
]
'@

            Mock -CommandName Get-Content -MockWith { $patchFileContent }

            { Install-ModulePatch -Path 'C:\patches\TestModule_1.0.0_patch.json' -Force } | Should -Throw -ExpectedMessage "Patch entry is missing 'ModuleName'."
        }

        It 'Should throw error for missing ModuleVersion' {
            $patchFileContent = @'
[
    {
        "ModuleName": "TestModule",
        "ScriptFileName": "TestScript.ps1",
        "HashSHA": "1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef",
        "StartOffset": 0,
        "EndOffset": 10,
        "PatchContent": "PatchedContent"
    }
]
'@

            Mock -CommandName Get-Content -MockWith { $patchFileContent }

            { Install-ModulePatch -Path 'C:\patches\TestModule_1.0.0_patch.json' -Force } | Should -Throw -ExpectedMessage "Patch entry is missing 'ModuleVersion'."
        }

        It 'Should throw error for missing ScriptFileName' {
            $patchFileContent = @'
[
    {
        "ModuleName": "TestModule",
        "ModuleVersion": "1.0.0",
        "HashSHA": "1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef",
        "StartOffset": 0,
        "EndOffset": 10,
        "PatchContent": "PatchedContent"
    }
]
'@

            Mock -CommandName Get-Content -MockWith { $patchFileContent }

            { Install-ModulePatch -Path 'C:\patches\TestModule_1.0.0_patch.json' -Force } | Should -Throw -ExpectedMessage "Patch entry is missing 'ScriptFileName'."
        }

        It 'Should throw error for missing HashSHA' {
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

            Mock -CommandName Get-Content -MockWith { $patchFileContent }

            { Install-ModulePatch -Path 'C:\patches\TestModule_1.0.0_patch.json' -Force } | Should -Throw -ExpectedMessage "Patch entry is missing 'HashSHA'."
        }

        It 'Should throw error for missing StartOffset or EndOffset' {
            $patchFileContent = @'
[
    {
        "ModuleName": "TestModule",
        "ModuleVersion": "1.0.0",
        "ScriptFileName": "TestScript.ps1",
        "HashSHA": "1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef",
        "PatchContent": "PatchedContent"
    }
]
'@

            Mock -CommandName Get-Content -MockWith { $patchFileContent }

            { Install-ModulePatch -Path 'C:\patches\TestModule_1.0.0_patch.json' -Force } | Should -Throw -ExpectedMessage "Patch entry is missing 'StartOffset' or 'EndOffset'."
        }

        It 'Should throw error for missing PatchContent' {
            $patchFileContent = @'
[
    {
        "ModuleName": "TestModule",
        "ModuleVersion": "1.0.0",
        "ScriptFileName": "TestScript.ps1",
        "HashSHA": "1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef",
        "StartOffset": 0,
        "EndOffset": 10
    }
]
'@

            Mock -CommandName Get-Content -MockWith { $patchFileContent }

            { Install-ModulePatch -Path 'C:\patches\TestModule_1.0.0_patch.json' -Force } | Should -Throw -ExpectedMessage "Patch entry is missing 'PatchContent'."
        }
    }

    Context 'When Force parameter is used' {
        It 'Should apply patches without confirmation' {
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

            Mock -CommandName Get-Content -MockWith { $patchFileContent }
            Mock -CommandName Get-Module -MockWith {
                return [PSCustomObject] @{
                    Name        = 'TestModule'
                    Version     = [System.Version] '1.0.0'
                    ModuleBase  = 'C:\Modules\TestModule'
                }
            }
            Mock -CommandName Get-FileHash -MockWith {
                return [PSCustomObject] @{
                    Hash = '1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef'
                }
            }
            Mock -CommandName Set-Content

            Install-ModulePatch -Path 'C:\patches\TestModule_1.0.0_patch.json' -Force

            Assert-MockCalled -CommandName Get-Content -Exactly 1 -Scope It
            Assert-MockCalled -CommandName Get-Module -Exactly 1 -Scope It
            Assert-MockCalled -CommandName Get-FileHash -Exactly 1 -Scope It
            Assert-MockCalled -CommandName Set-Content -Exactly 1 -Scope It
        }
    }
}
