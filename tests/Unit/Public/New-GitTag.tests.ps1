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

# cSpell: ignore LASTEXITCODE
Describe 'New-GitTag' {
    BeforeAll {
        InModuleScope -ScriptBlock {
            # Stub for git command
            function script:git
            {
            }
        }
    }

    Context 'When creating a new tag' {
        BeforeAll {
            Mock -CommandName git -MockWith {
                if ($args[0] -eq 'tag')
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

        It 'Should create a new tag successfully' {
            New-GitTag -Name 'v1.0.0' -Force

            Should -Invoke -CommandName git -ParameterFilter {
                $args[0] -eq 'tag' -and $args[1] -eq 'v1.0.0'
            }
        }

        It 'Should create an annotated tag when Message is provided' {
            New-GitTag -Name 'v1.0.0' -Message 'Release version 1.0.0' -Force

            Should -Invoke -CommandName git -ParameterFilter {
                $args[0] -eq 'tag' -and $args[1] -eq '-a' -and $args[2] -eq 'v1.0.0' -and $args[3] -eq '-m' -and $args[4] -eq 'Release version 1.0.0'
            }
        }

        It 'Should create a tag for a specific commit when CommitHash is provided' {
            New-GitTag -Name 'v1.0.0' -CommitHash 'abc1234' -Force

            Should -Invoke -CommandName git -ParameterFilter {
                $args[0] -eq 'tag' -and $args[1] -eq 'v1.0.0' -and $args[2] -eq 'abc1234'
            }
        }

        Context 'When the operation fails' {
            BeforeAll {
                Mock -CommandName git -MockWith {
                    if ($args[0] -eq 'tag')
                    {
                        $global:LASTEXITCODE = 1
                    }
                    else
                    {
                        throw "Mock git unexpected args: $($args -join ' ')"
                    }
                }

                $mockErrorMessage = InModuleScope -ScriptBlock {
                    $script:localizedData.New_GitTag_FailedToCreate
                }

                $mockErrorMessage = $mockErrorMessage -f 'v1.0.0'
            }

            AfterEach {
                $global:LASTEXITCODE = 0
            }

            It 'Should have a localized error message' {
                $mockErrorMessage | Should-BeTruthy -Because 'The error message should have been localized, and shall not be empty'
            }

            It 'Should handle non-terminating error correctly' {
                Mock -CommandName Write-Error

                New-GitTag -Name 'v1.0.0' -Force

                Should -Invoke -CommandName Write-Error -ParameterFilter {
                    $Message -eq $mockErrorMessage
                }
            }

            It 'Should handle terminating error correctly' {
                {
                    New-GitTag -Name 'v1.0.0' -ErrorAction 'Stop' -Force
                } | Should -Throw -ExpectedMessage $mockErrorMessage
            }
        }
    }

    Context 'When using the Force parameter' {
        BeforeAll {
            Mock -CommandName git -MockWith {
                if ($args[0] -eq 'tag' -and $args -contains '-f')
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

        It 'Should force create a tag when Force is specified' {
            New-GitTag -Name 'v1.0.0' -Force -Force

            Should -Invoke -CommandName git -ParameterFilter {
                $args[0] -eq 'tag' -and $args[1] -eq '-f' -and $args[2] -eq 'v1.0.0'
            }
        }
    }
}
