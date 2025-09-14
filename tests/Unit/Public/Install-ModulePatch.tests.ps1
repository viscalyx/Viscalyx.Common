[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification = 'Suppressing this rule because Script Analyzer does not understand Pester syntax.')]
param ()

BeforeDiscovery {
    try
    {
        if (-not (Get-Module -Name 'DscResource.Test'))
        {
            # Assumes dependencies have been resolved, so if this module is not available, run 'noop' task.
            if (-not (Get-Module -Name 'DscResource.Test' -ListAvailable))
            {
                # Redirect all streams to $null, except the error stream (stream 2)
                & "$PSScriptRoot/../../../build.ps1" -Tasks 'noop' 3>&1 4>&1 5>&1 6>&1 > $null
            }

            # If the dependencies have not been resolved, this will throw an error.
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

Describe 'Install-ModulePatch' {
    Context 'When checking command structure' {
        It 'Should have the correct parameters in parameter set <ExpectedParameterSetName>' -ForEach @(
            @{
                ExpectedParameterSetName = 'Path'
                ExpectedParameters = '-Path <string> [-Force] [-SkipHashValidation] [-WhatIf] [-Confirm] [<CommonParameters>]'
            }
            @{
                ExpectedParameterSetName = 'URI'
                ExpectedParameters = '-Uri <uri> [-Force] [-SkipHashValidation] [-WhatIf] [-Confirm] [<CommonParameters>]'
            }
        ) {
            $result = (Get-Command -Name 'Install-ModulePatch').ParameterSets |
                Where-Object -FilterScript { $_.Name -eq $ExpectedParameterSetName } |
                Select-Object -Property @(
                    @{ Name = 'ParameterSetName'; Expression = { $_.Name } },
                    @{ Name = 'ParameterListAsString'; Expression = { $_.ToString() } }
                )
            $result.ParameterSetName | Should -Be $ExpectedParameterSetName
            $result.ParameterListAsString | Should -Be $ExpectedParameters
        }

        It 'Should have Path as a mandatory parameter in Path parameter set' {
            $parameterInfo = (Get-Command -Name 'Install-ModulePatch').Parameters['Path']
            $mandatoryAttribute = $parameterInfo.Attributes | Where-Object { $_.TypeId.Name -eq 'ParameterAttribute' -and $_.ParameterSetName -eq 'Path' }
            $mandatoryAttribute.Mandatory | Should -BeTrue
        }

        It 'Should have Uri as a mandatory parameter in URI parameter set' {
            $parameterInfo = (Get-Command -Name 'Install-ModulePatch').Parameters['Uri']
            $mandatoryAttribute = $parameterInfo.Attributes | Where-Object { $_.TypeId.Name -eq 'ParameterAttribute' -and $_.ParameterSetName -eq 'URI' }
            $mandatoryAttribute.Mandatory | Should -BeTrue
        }
    }

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

            Mock -CommandName Assert-PatchFile
            Mock -CommandName Assert-ScriptFileValidity
            Mock -CommandName Merge-Patch
            Mock -CommandName Get-ModuleByVersion -MockWith {
                return @{
                    ModuleBase = "$TestDrive/Modules/TestModule"
                }
            }

            Mock -CommandName Get-PatchFileContentFromPath -MockWith {
                $patchFileContent | ConvertFrom-Json
            }

            Mock -CommandName Get-PatchFileContentFromURI -MockWith {
                $patchFileContent | ConvertFrom-Json
            }

            Mock -CommandName Test-FileHash -MockWith {
                return $true
            }
        }

        It 'Should apply patches from local file' {
            $null = Install-ModulePatch -Force -Path "$TestDrive/patches/TestModule_1.0.0_patch.json" -ErrorAction 'Stop'

            Should -Invoke -CommandName Get-PatchFileContentFromURI -Exactly 0 -Scope It
            Should -Invoke -CommandName Get-PatchFileContentFromPath -Exactly 1 -Scope It
            Should -Invoke -CommandName Merge-Patch -Exactly 1 -Scope It
        }

        It 'Should apply patches from URL' {
            $null = Install-ModulePatch -Force -URI 'https://gist.githubusercontent.com/user/gistid/raw/TestModule_1.0.0_patch.json' -ErrorAction 'Stop'

            Should -Invoke -CommandName Get-PatchFileContentFromPath -Exactly 0 -Scope It
            Should -Invoke -CommandName Get-PatchFileContentFromURI -Exactly 1 -Scope It
            Should -Invoke -CommandName Merge-Patch -Exactly 1 -Scope It
        }

        It 'Should be able to skip hash validation' {
            $null = Install-ModulePatch -SkipHashValidation -Force -Path "$TestDrive/patches/TestModule_1.0.0_patch.json" -ErrorAction 'Stop'

            Should -Invoke -CommandName Get-PatchFileContentFromURI -Exactly 0 -Scope It
            Should -Invoke -CommandName Get-PatchFileContentFromPath -Exactly 1 -Scope It
            Should -Invoke -CommandName Merge-Patch -Exactly 1 -Scope It
        }
    }

    Context 'When validation hash does not match' {
        BeforeAll {
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

            Mock -CommandName Assert-PatchFile
            Mock -CommandName Assert-ScriptFileValidity
            Mock -CommandName Merge-Patch
            Mock -CommandName Get-ModuleByVersion -MockWith {
                return @{
                    ModuleBase = "$TestDrive/Modules/TestModule"
                }
            }

            Mock -CommandName Get-PatchFileContentFromPath -MockWith {
                $patchFileContent | ConvertFrom-Json
            }

            Mock -CommandName Get-PatchFileContentFromURI -MockWith {
                $patchFileContent | ConvertFrom-Json
            }

            Mock -CommandName Test-FileHash -MockWith {
                return $false
            }
        }

        It 'Should apply patches from local file' {
            $null = Install-ModulePatch -Force -Path "$TestDrive/patches/TestModule_1.0.0_patch.json" -ErrorAction 'SilentlyContinue'

            Should -Invoke -CommandName Get-PatchFileContentFromURI -Exactly 0 -Scope It
            Should -Invoke -CommandName Get-PatchFileContentFromPath -Exactly 1 -Scope It
            Should -Invoke -CommandName Merge-Patch -Exactly 1 -Scope It
        }
    }

    Context 'When module does not exist' {
        BeforeAll {
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

            Mock -CommandName Assert-PatchFile
            Mock -CommandName Assert-ScriptFileValidity
            Mock -CommandName Get-ModuleByVersion -MockWith {
                return $null
            }

            Mock -CommandName Get-PatchFileContentFromPath -MockWith {
                $patchFileContent | ConvertFrom-Json
            }
        }

        It 'Should throw the correct error' {
            { Install-ModulePatch -Force -Path "$TestDrive/patches/TestModule_1.0.0_patch.json" -ErrorAction 'Stop' } |
                Should -Throw -ExpectedMessage "Module 'TestModule' version '1.1.1' not found."
        }
    }
}
