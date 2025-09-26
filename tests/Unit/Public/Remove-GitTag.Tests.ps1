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
Describe 'Remove-GitTag' {
    Context 'When removing a tag from local repository' {
        BeforeAll {
            Mock -CommandName git -MockWith {
                if ($args[0] -eq 'tag' -and $args[1] -eq '-d')
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

        It 'Should remove a tag from local repository when only Tag is specified' {
            Remove-GitTag -Tag 'v1.0.0' -Force

            Should -Invoke -CommandName git -ParameterFilter {
                $args[0] -eq 'tag' -and $args[1] -eq '-d' -and $args[2] -eq 'v1.0.0'
            }
        }

        It 'Should remove a tag from local repository when Local switch is specified' {
            Remove-GitTag -Tag 'v1.0.0' -Local -Force

            Should -Invoke -CommandName git -ParameterFilter {
                $args[0] -eq 'tag' -and $args[1] -eq '-d' -and $args[2] -eq 'v1.0.0'
            }
        }

        It 'Should remove multiple tags from local repository' {
            Remove-GitTag -Tag @('v1.0.0', 'v1.1.0') -Force

            Should -Invoke -CommandName git -ParameterFilter {
                $args[0] -eq 'tag' -and $args[1] -eq '-d' -and $args[2] -eq 'v1.0.0'
            }

            Should -Invoke -CommandName git -ParameterFilter {
                $args[0] -eq 'tag' -and $args[1] -eq '-d' -and $args[2] -eq 'v1.1.0'
            }
        }
    }

    Context 'When removing a tag from remote repository' {
        BeforeAll {
            Mock -CommandName git -MockWith {
                if ($args[0] -eq 'push')
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

        It 'Should remove a tag from a single remote repository' {
            Remove-GitTag -Tag 'v1.0.0' -Remote 'origin' -Force

            Should -Invoke -CommandName git -ParameterFilter {
                $args[0] -eq 'push' -and $args[1] -eq 'origin' -and $args[2] -eq ':refs/tags/v1.0.0'
            }
        }

        It 'Should remove a tag from multiple remote repositories' {
            Remove-GitTag -Tag 'v1.0.0' -Remote @('origin', 'upstream') -Force

            Should -Invoke -CommandName git -ParameterFilter {
                $args[0] -eq 'push' -and $args[1] -eq 'origin' -and $args[2] -eq ':refs/tags/v1.0.0'
            }

            Should -Invoke -CommandName git -ParameterFilter {
                $args[0] -eq 'push' -and $args[1] -eq 'upstream' -and $args[2] -eq ':refs/tags/v1.0.0'
            }
        }

        It 'Should remove multiple tags from multiple remote repositories' {
            Remove-GitTag -Tag @('v1.0.0', 'v1.1.0') -Remote @('origin', 'upstream') -Force

            Should -Invoke -CommandName git -ParameterFilter {
                $args[0] -eq 'push' -and $args[1] -eq 'origin' -and $args[2] -eq ':refs/tags/v1.0.0'
            }

            Should -Invoke -CommandName git -ParameterFilter {
                $args[0] -eq 'push' -and $args[1] -eq 'upstream' -and $args[2] -eq ':refs/tags/v1.0.0'
            }

            Should -Invoke -CommandName git -ParameterFilter {
                $args[0] -eq 'push' -and $args[1] -eq 'origin' -and $args[2] -eq ':refs/tags/v1.1.0'
            }

            Should -Invoke -CommandName git -ParameterFilter {
                $args[0] -eq 'push' -and $args[1] -eq 'upstream' -and $args[2] -eq ':refs/tags/v1.1.0'
            }
        }
    }

    Context 'When removing a tag from both local and remote repositories' {
        BeforeAll {
            Mock -CommandName git -MockWith {
                if ($args[0] -eq 'tag' -and $args[1] -eq '-d')
                {
                    $global:LASTEXITCODE = 0
                }
                elseif ($args[0] -eq 'push')
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

        It 'Should remove a tag from both local and remote repositories' {
            Remove-GitTag -Tag 'v1.0.0' -Local -Remote 'origin' -Force

            Should -Invoke -CommandName git -ParameterFilter {
                $args[0] -eq 'tag' -and $args[1] -eq '-d' -and $args[2] -eq 'v1.0.0'
            }

            Should -Invoke -CommandName git -ParameterFilter {
                $args[0] -eq 'push' -and $args[1] -eq 'origin' -and $args[2] -eq ':refs/tags/v1.0.0'
            }
        }
    }

    Context 'When the local tag removal operation fails' {
        BeforeAll {
            Mock -CommandName git -MockWith {
                if ($args[0] -eq 'tag' -and $args[1] -eq '-d')
                {
                    $global:LASTEXITCODE = 1
                }
                else
                {
                    throw "Mock git unexpected args: $($args -join ' ')"
                }
            }

            $mockErrorMessage = InModuleScope -ScriptBlock {
                $script:localizedData.Remove_GitTag_FailedToRemoveLocalTag -f 'v1.0.0'
            }
        }

        AfterEach {
            $global:LASTEXITCODE = 0
        }

        It 'Should have a localized error message' {
            $mockErrorMessage | Should-BeTruthy -Because 'The error message should have been localized, and shall not be empty'
        }

        It 'Should throw terminating error when local tag removal fails' {
            {
                Remove-GitTag -Tag 'v1.0.0' -Force
            } | Should -Throw -ExpectedMessage $mockErrorMessage
        }
    }

    Context 'When the remote tag removal operation fails' {
        BeforeAll {
            Mock -CommandName git -MockWith {
                if ($args[0] -eq 'push')
                {
                    $global:LASTEXITCODE = 1
                }
                else
                {
                    throw "Mock git unexpected args: $($args -join ' ')"
                }
            }

            $mockErrorMessage = InModuleScope -ScriptBlock {
                $script:localizedData.Remove_GitTag_FailedToRemoveRemoteTag -f 'v1.0.0', 'origin'
            }
        }

        AfterEach {
            $global:LASTEXITCODE = 0
        }

        It 'Should have a localized error message' {
            $mockErrorMessage | Should-BeTruthy -Because 'The error message should have been localized, and shall not be empty'
        }

        It 'Should throw terminating error when remote tag removal fails' {
            {
                Remove-GitTag -Tag 'v1.0.0' -Remote 'origin' -Force
            } | Should -Throw -ExpectedMessage $mockErrorMessage
        }
    }

    Context 'When using parameter validation' {
        It 'Should require Tag parameter' {
            # Test that Tag parameter is mandatory by checking function metadata
            $parameterInfo = (Get-Command Remove-GitTag).Parameters['Tag']
            $parameterInfo.Attributes.Mandatory | Should -Contain $true
        }

        It 'Should accept string array for Tag parameter' {
            Mock -CommandName git -MockWith {
                $global:LASTEXITCODE = 0
            }

            { Remove-GitTag -Tag @('v1.0.0', 'v1.1.0') -Force } | Should -Not -Throw
        }

        It 'Should accept string array for Remote parameter' {
            Mock -CommandName git -MockWith {
                $global:LASTEXITCODE = 0
            }

            { Remove-GitTag -Tag 'v1.0.0' -Remote @('origin', 'upstream') -Force } | Should -Not -Throw
        }
    }
}
