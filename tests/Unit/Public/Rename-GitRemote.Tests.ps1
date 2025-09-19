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
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -ResolveDependency -Tasks noop" first.'
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

# cSpell: ignore LASTEXITCODE
Describe 'Rename-GitRemote' {
    Context 'When the command has correct parameter properties' {
        It 'Should have Name as a mandatory parameter' {
            $parameterInfo = (Get-Command -Name 'Rename-GitRemote').Parameters['Name']
            $parameterInfo.Attributes.Mandatory | Should -BeTrue
        }

        It 'Should have NewName as a mandatory parameter' {
            $parameterInfo = (Get-Command -Name 'Rename-GitRemote').Parameters['NewName']
            $parameterInfo.Attributes.Mandatory | Should -BeTrue
        }

        It 'Should have Name parameter with ValidateNotNullOrEmpty attribute' {
            $parameterInfo = (Get-Command -Name 'Rename-GitRemote').Parameters['Name']
            $parameterInfo.Attributes.TypeId.Name | Should -Contain 'ValidateNotNullOrEmptyAttribute'
        }

        It 'Should have NewName parameter with ValidateNotNullOrEmpty attribute' {
            $parameterInfo = (Get-Command -Name 'Rename-GitRemote').Parameters['NewName']
            $parameterInfo.Attributes.TypeId.Name | Should -Contain 'ValidateNotNullOrEmptyAttribute'
        }
    }

    Context 'When renaming a Git remote successfully' {
        BeforeAll {
            Mock -CommandName git -MockWith {
                if ($args[0] -eq 'remote' -and $args[1] -eq 'rename')
                {
                    $global:LASTEXITCODE = 0
                }
                else
                {
                    throw "Mock git unexpected args: $($args -join ' ')"
                }
            }
        }

        AfterEach {
            $global:LASTEXITCODE = 0
        }

        It 'Should rename a Git remote from "my" to "origin"' {
            Rename-GitRemote -Name 'my' -NewName 'origin'

            Should -Invoke -CommandName git -ParameterFilter {
                $args[0] -eq 'remote' -and $args[1] -eq 'rename' -and $args[2] -eq 'my' -and $args[3] -eq 'origin'
            }
        }

        It 'Should rename a Git remote from "upstream" to "fork"' {
            Rename-GitRemote -Name 'upstream' -NewName 'fork'

            Should -Invoke -CommandName git -ParameterFilter {
                $args[0] -eq 'remote' -and $args[1] -eq 'rename' -and $args[2] -eq 'upstream' -and $args[3] -eq 'fork'
            }
        }

        It 'Should write verbose message when remote is renamed successfully' {
            $mockSuccessMessage = InModuleScope -ScriptBlock {
                $script:localizedData.Rename_GitRemote_RenamedRemote -f 'my', 'origin'
            }

            Rename-GitRemote -Name 'my' -NewName 'origin' -Verbose 4>&1 | Should -Be $mockSuccessMessage
        }
    }

    Context 'When the Git remote rename operation fails' {
        BeforeAll {
            Mock -CommandName git -MockWith {
                if ($args[0] -eq 'remote' -and $args[1] -eq 'rename')
                {
                    $global:LASTEXITCODE = 1
                }
                else
                {
                    throw "Mock git unexpected args: $($args -join ' ')"
                }
            }

            $mockErrorMessage = InModuleScope -ScriptBlock {
                $script:localizedData.Rename_GitRemote_FailedToRename -f 'nonexistent', 'origin'
            }
        }

        AfterEach {
            $global:LASTEXITCODE = 0
        }

        It 'Should have a localized error message' {
            $mockErrorMessage | Should -Not -BeNullOrEmpty -Because 'The error message should have been localized, and shall not be empty'
        }

        It 'Should throw terminating error when remote rename fails' {
            {
                Rename-GitRemote -Name 'nonexistent' -NewName 'origin'
            } | Should -Throw -ExpectedMessage $mockErrorMessage
        }

        It 'Should throw error with correct error ID' {
            try
            {
                Rename-GitRemote -Name 'nonexistent' -NewName 'origin'
            }
            catch
            {
                $_.FullyQualifiedErrorId | Should -Be 'RGR0001,Rename-GitRemote'
            }
        }

        It 'Should throw error with correct error category' {
            try
            {
                Rename-GitRemote -Name 'nonexistent' -NewName 'origin'
            }
            catch
            {
                $_.CategoryInfo.Category | Should -Be 'InvalidOperation'
            }
        }

        It 'Should throw error with correct target object' {
            try
            {
                Rename-GitRemote -Name 'nonexistent' -NewName 'origin'
            }
            catch
            {
                $_.TargetObject | Should -Be 'nonexistent'
            }
        }
    }
}