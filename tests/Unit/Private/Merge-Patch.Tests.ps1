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
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -ResolveDependency -Tasks noop" first.'
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

Describe 'Merge-Patch' {
    Context 'When patch file is valid' {
        BeforeAll {
            Mock -CommandName Get-Content -MockWith {
                'This is the script file content'
            }

            Mock -CommandName Set-Content
        }

        It 'Should apply a patch' -ForEach @(
            @{
                PatchEntry = @{
                    StartOffset = 20
                    EndOffset = 30
                    PatchContent = 'PatchedContent1'
                }
            }
         ) {
            InModuleScope -Parameters $_ -ScriptBlock {
                $null = Merge-Patch -FilePath "$TestDrive/TestScript.ps1" -PatchEntry $PatchEntry
            }

            Should -Invoke -CommandName Get-Content -Exactly 1 -Scope It
            Should -Invoke -CommandName Set-Content -Exactly 1 -Scope It
        }
    }

    Context 'When start or end offset is invalid' {
        BeforeAll {
            Mock -CommandName Get-Content -MockWith {
                'This is the script file content'
            }

            Mock -CommandName Set-Content
        }

        It 'Should write an error and return' -TestCases @(
            <#
                Expected message contains a wildcard because of the $TestDrive variable
                in the path which is different on each run and is not available during
                the discovery phase.
            #>
            @{
                PatchEntry = @{
                    StartOffset = -1
                    EndOffset = 30
                    PatchContent = 'PatchedContent1'
                }
                ExpectedMessage = "Start or end offset (-1-30) in patch entry does not exist in the script file '*/TestScript.ps1'. (MP0001)"
            },
            @{
                PatchEntry = @{
                    StartOffset = 20
                    EndOffset = 1000
                    PatchContent = 'PatchedContent1'
                }
                ExpectedMessage = "Start or end offset (20-1000) in patch entry does not exist in the script file '*/TestScript.ps1'. (MP0001)"
            },
            @{
                PatchEntry = @{
                    StartOffset = 30
                    EndOffset = 20
                    PatchContent = 'PatchedContent1'
                }
                ExpectedMessage = "Start or end offset (30-20) in patch entry does not exist in the script file '*/TestScript.ps1'. (MP0001)"
            }
        ) {
            InModuleScope -Parameters $_ -ScriptBlock {
                { Merge-Patch -FilePath "$TestDrive/TestScript.ps1" -PatchEntry $PatchEntry -ErrorAction 'Stop' } |
                    Should -Throw -ExpectedMessage $ExpectedMessage
            }
        }
    }
}
