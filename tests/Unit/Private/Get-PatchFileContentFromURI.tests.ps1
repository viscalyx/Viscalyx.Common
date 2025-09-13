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
                & "$PSScriptRoot/../../../build.ps1" -Tasks 'noop' 3>&1 4>&1 5>&1 6>&1 > $null
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

Describe 'Get-PatchFileContentFromURI' {
    Context 'When patch file exists at URI' {
        It 'Should read patch file content from URI' {
            $patchFileContent = @'
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

            Mock -CommandName Invoke-WebRequest -MockWith {
                [PSCustomObject] @{
                    Content = $patchFileContent
                }
            }

            Mock -CommandName Get-PatchFileContent -MockWith {
                $patchFileContent | ConvertFrom-Json
            }

            $result = InModuleScope -ScriptBlock {
                Get-PatchFileContentFromURI -URI 'https://gist.githubusercontent.com/user/gistid/raw/TestModule_1.0.0_patch.json'
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

    Context 'When patch file does not exist at URI' {
        It 'Should throw error for missing patch file' {
            Mock -CommandName Invoke-WebRequest -MockWith {
                throw '404 Not Found'
            }

            InModuleScope -ScriptBlock {
                { Get-PatchFileContentFromURI -URI 'https://gist.githubusercontent.com/user/gistid/raw/TestModule_1.0.0_patch.json' -ErrorAction 'Stop' } |
                    Should -Throw -ExpectedMessage 'System.Management.Automation.RuntimeException: 404 Not Found'
            }
        }

        It 'Should return $null if error is caught and ErrorAction is "SilentlyContinue"' {
            Mock -CommandName Invoke-WebRequest -MockWith {
                throw '404 Not Found'
            }

            InModuleScope -ScriptBlock {
                $result = Get-PatchFileContentFromURI -URI 'https://gist.githubusercontent.com/user/gistid/raw/TestModule_1.0.0_patch.json' -ErrorAction 'SilentlyContinue'
                $result | Should-BeNull
            }
        }
    }
}
