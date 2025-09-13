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
            InModuleScope -ScriptBlock {
                $patchFileContent = @'
{
  "ModuleName": "TestModule",
  "ModuleVersion": "1.1.1",
  "ModuleFiles": [
    {
      "ScriptFileName": "TestModule.psm1",
      "OriginalHashSHA": "4723258D788733FACED8BF20F60DFCBAD03E7AEB659D1B9C891DD9F86FEA2E73",
      "ValidationHashSHA": ["4444D5073A54B838128FC53D61B87A40142E5181A38C593CC4BA728D6F1AD16B"],
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

                Assert-PatchFile -PatchFileObject ($patchFileContent | ConvertFrom-Json) -ErrorAction 'Stop'
            }
        }
    }

    Context 'When patch file is invalid' {
        It 'Should throw error for missing ModuleName' {
            InModuleScope -ScriptBlock {
                $patchFileContent = @'
{
  "ModuleVersion": "1.1.1",
  "ModuleFiles": [
    {
      "ScriptFileName": "TestModule.psm1",
      "OriginalHashSHA": "4723258D788733FACED8BF20F60DFCBAD03E7AEB659D1B9C891DD9F86FEA2E73",
      "ValidationHashSHA": ["4444D5073A54B838128FC53D61B87A40142E5181A38C593CC4BA728D6F1AD16B"],
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
                { Assert-PatchFile -PatchFileObject ($patchFileContent | ConvertFrom-Json) -ErrorAction 'Stop' } |
                    Should -Throw -ExpectedMessage "Patch entry is missing 'ModuleName'."
            }
        }

        It 'Should throw correct error for missing ModuleVersion' {
            InModuleScope -ScriptBlock {
                $patchFileContent = @'
{
  "ModuleName": "TestModule",
  "ModuleFiles": [
    {
      "ScriptFileName": "TestModule.psm1",
      "OriginalHashSHA": "4723258D788733FACED8BF20F60DFCBAD03E7AEB659D1B9C891DD9F86FEA2E73",
      "ValidationHashSHA": ["4444D5073A54B838128FC53D61B87A40142E5181A38C593CC4BA728D6F1AD16B"],
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

                { Assert-PatchFile -PatchFileObject ($patchFileContent | ConvertFrom-Json) -ErrorAction 'Stop' } |
                    Should -Throw -ExpectedMessage "Patch entry is missing 'ModuleVersion'."
            }
        }

        It 'Should throw correct error for missing ModuleFiles' {
            InModuleScope -ScriptBlock {
                $patchFileContent = @'
{
  "ModuleName": "TestModule",
  "ModuleVersion": "1.1.1"
}
'@

                { Assert-PatchFile -PatchFileObject ($patchFileContent | ConvertFrom-Json) -ErrorAction 'Stop' } |
                    Should -Throw -ExpectedMessage "Patch entry is missing 'ModuleFiles'."
            }
        }

        It 'Should throw correct error for missing ScriptFileName' {
            InModuleScope -ScriptBlock {
                $patchFileContent = @'
{
  "ModuleName": "TestModule",
  "ModuleVersion": "1.1.1",
  "ModuleFiles": [
    {
      "OriginalHashSHA": "4723258D788733FACED8BF20F60DFCBAD03E7AEB659D1B9C891DD9F86FEA2E73",
      "ValidationHashSHA": ["4444D5073A54B838128FC53D61B87A40142E5181A38C593CC4BA728D6F1AD16B"],
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

                { Assert-PatchFile -PatchFileObject ($patchFileContent | ConvertFrom-Json) -ErrorAction 'Stop' } |
                    Should -Throw -ExpectedMessage "Patch entry is missing 'ScriptFileName'."
            }
        }

        It 'Should throw correct error for missing OriginalHashSHA' {
            InModuleScope -ScriptBlock {
                $patchFileContent = @'
{
  "ModuleName": "TestModule",
  "ModuleVersion": "1.1.1",
  "ModuleFiles": [
    {
      "ScriptFileName": "TestModule.psm1",
      "ValidationHashSHA": ["4444D5073A54B838128FC53D61B87A40142E5181A38C593CC4BA728D6F1AD16B"],
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

                { Assert-PatchFile -PatchFileObject ($patchFileContent | ConvertFrom-Json) -ErrorAction 'Stop' } |
                    Should -Throw -ExpectedMessage "Patch entry is missing 'OriginalHashSHA'."
            }
        }

        It 'Should throw correct error for missing ValidationHashSHA' {
            InModuleScope -ScriptBlock {
                $patchFileContent = @'
{
  "ModuleName": "TestModule",
  "ModuleVersion": "1.1.1",
  "ModuleFiles": [
    {
      "ScriptFileName": "TestModule.psm1",
      "OriginalHashSHA": "4723258D788733FACED8BF20F60DFCBAD03E7AEB659D1B9C891DD9F86FEA2E73",
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

                { Assert-PatchFile -PatchFileObject ($patchFileContent | ConvertFrom-Json) -ErrorAction 'Stop' } |
                    Should -Throw -ExpectedMessage "Patch entry is missing 'ValidationHashSHA'."
            }
        }

        It 'Should throw correct error for missing FilePatches' {
            InModuleScope -ScriptBlock {
                $patchFileContent = @'
{
  "ModuleName": "TestModule",
  "ModuleVersion": "1.1.1",
  "ModuleFiles": [
    {
      "ScriptFileName": "TestModule.psm1",
      "OriginalHashSHA": "4723258D788733FACED8BF20F60DFCBAD03E7AEB659D1B9C891DD9F86FEA2E73",
      "ValidationHashSHA": ["4444D5073A54B838128FC53D61B87A40142E5181A38C593CC4BA728D6F1AD16B"]
    }
  ]
}
'@

                { Assert-PatchFile -PatchFileObject ($patchFileContent | ConvertFrom-Json) -ErrorAction 'Stop' } |
                    Should -Throw -ExpectedMessage "Patch entry is missing 'FilePatches'."
            }
        }

        It 'Should throw correct error for missing StartOffset' {
            InModuleScope -ScriptBlock {
                $patchFileContent = @'
{
  "ModuleName": "TestModule",
  "ModuleVersion": "1.1.1",
  "ModuleFiles": [
    {
      "ScriptFileName": "TestModule.psm1",
      "OriginalHashSHA": "4723258D788733FACED8BF20F60DFCBAD03E7AEB659D1B9C891DD9F86FEA2E73",
      "ValidationHashSHA": ["4444D5073A54B838128FC53D61B87A40142E5181A38C593CC4BA728D6F1AD16B"],
      "FilePatches": [
        {
          "EndOffset": 20,
          "PatchContent": "@{}"
        }
      ]
    }
  ]
}
'@
                { Assert-PatchFile -PatchFileObject ($patchFileContent | ConvertFrom-Json) -ErrorAction 'Stop' } |
                    Should -Throw -ExpectedMessage "Patch entry is missing 'StartOffset' or 'EndOffset'."
            }
        }

        It 'Should throw correct error for missing EndOffset' {
            InModuleScope -ScriptBlock {
                $patchFileContent = @'
{
  "ModuleName": "TestModule",
  "ModuleVersion": "1.1.1",
  "ModuleFiles": [
    {
      "ScriptFileName": "TestModule.psm1",
      "OriginalHashSHA": "4723258D788733FACED8BF20F60DFCBAD03E7AEB659D1B9C891DD9F86FEA2E73",
      "ValidationHashSHA": ["4444D5073A54B838128FC53D61B87A40142E5181A38C593CC4BA728D6F1AD16B"],
      "FilePatches": [
        {
          "StartOffset": 10,
          "PatchContent": "@{}"
        }
      ]
    }
  ]
}
'@
                { Assert-PatchFile -PatchFileObject ($patchFileContent | ConvertFrom-Json) -ErrorAction 'Stop' } |
                    Should -Throw -ExpectedMessage "Patch entry is missing 'StartOffset' or 'EndOffset'."
            }
        }

        It 'Should throw correct error for missing PatchContent' {
            InModuleScope -ScriptBlock {
                $patchFileContent = @'
{
  "ModuleName": "TestModule",
  "ModuleVersion": "1.1.1",
  "ModuleFiles": [
    {
      "ScriptFileName": "TestModule.psm1",
      "OriginalHashSHA": "4723258D788733FACED8BF20F60DFCBAD03E7AEB659D1B9C891DD9F86FEA2E73",
      "ValidationHashSHA": ["4444D5073A54B838128FC53D61B87A40142E5181A38C593CC4BA728D6F1AD16B"],
      "FilePatches": [
        {
          "StartOffset": 10,
          "EndOffset": 20
        }
      ]
    }
  ]
}
'@

                { Assert-PatchFile -PatchFileObject ($patchFileContent | ConvertFrom-Json) -ErrorAction 'Stop' } |
                    Should -Throw -ExpectedMessage "Patch entry is missing 'PatchContent'."
            }
        }
    }

    Context 'Additional Edge Cases' {
        It 'Should throw error for empty patch file' {
            InModuleScope -ScriptBlock {
                $patchFileContent = ' [] '
                { Assert-PatchFile -PatchFileObject ($patchFileContent | ConvertFrom-Json) -ErrorAction 'Stop' } |
                    Should -Throw
            }
        }

        It 'Should throw error for invalid JSON format' {
            InModuleScope -ScriptBlock {
                $patchFileContent = 'Invalid JSON'
                { Assert-PatchFile -PatchFileObject ($patchFileContent | ConvertFrom-Json) -ErrorAction 'Stop' } |
                    Should -Throw
            }
        }
    }
}
