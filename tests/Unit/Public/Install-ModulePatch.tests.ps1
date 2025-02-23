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
{
  "ModuleName": "TestModule",
  "ModuleVersion": "1.1.1",
  "ModuleFiles": [
    {
      "ScriptFileName": "TestModule.psm1",
      "OriginalHashSHA": "4723258D788733FACED8BF20F60DFCBAD03E7AEB659D1B9C891DD9F86FEA2E73",
      "ValidationHashSHA": "4444D5073A54B838128FC53D61B87A40142E5181A38C593CC4BA728D6F1AD16B",
      "FilePatches": [
        {
          "StartOffset": 10,
          "EndOffset": 20,
          "PatchContent": "@{}"
        }
      ]
    }
  ]
}
'@

            Mock -CommandName Assert-PatchFile
            Mock -CommandName Assert-ScriptFileValidity
            Mock -CommandName Merge-Patch
            Mock -CommandName Get-ModuleByVersion -MockWith {
                return @{
                    ModuleBase = "$TestDrive/Modules/TestModule"
                }
            }

            Mock -CommandName Get-PatchFileContentFromPath -MockWith {
                $patchFileContent | ConvertFrom-Json -Depth 10
            }

            Mock -CommandName Get-PatchFileContentFromURI -MockWith {
                $patchFileContent | ConvertFrom-Json -Depth 10
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
