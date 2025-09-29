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
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -ResolveDependency -Tasks noop" first.'
    }
}

BeforeAll {
    $script:dscModuleName = 'Viscalyx.Common'

    Import-Module -Name $script:dscModuleName -Force -ErrorAction Stop

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
Describe 'Rename-GitLocalBranch' {
    Context 'When renaming a local branch' {
        BeforeAll {
            Mock -CommandName git -MockWith {
                if ($args[0] -eq 'branch' -and $args[1] -eq '-m')
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

        It 'Should rename the branch successfully' {
            Rename-GitLocalBranch -Name 'old-branch' -NewName 'new-branch' -Force

            Should -Invoke -CommandName git -ParameterFilter {
                $args[0] -eq 'branch' -and $args[1] -eq '-m' -and $args[2] -eq 'old-branch' -and $args[3] -eq 'new-branch'
            }
        }

        Context 'When the operation fails' {
            BeforeAll {
                Mock -CommandName git -MockWith {
                    if ($args[0] -eq 'branch' -and $args[1] -eq '-m')
                    {
                        $global:LASTEXITCODE = 1
                    }
                    else
                    {
                        throw "Mock git unexpected args: $($args -join ' ')"
                    }
                }

                $mockErrorMessage = InModuleScope -ScriptBlock {
                    $script:localizedData.Rename_GitLocalBranch_FailedToRename
                }

                $mockErrorMessage = $mockErrorMessage -f 'old-branch', 'new-branch'
            }

            AfterEach {
                $global:LASTEXITCODE = 0
            }

            It 'Should throw terminating error regardless of ErrorAction' {
                {
                    Rename-GitLocalBranch -Name 'old-branch' -NewName 'new-branch' -ErrorAction 'SilentlyContinue' -Confirm:$false
                } | Should -Throw -ExpectedMessage $mockErrorMessage
            }

            It 'Should handle terminating error correctly' {
                {
                    Rename-GitLocalBranch -Name 'old-branch' -NewName 'new-branch' -ErrorAction 'Stop' -Confirm:$false
                } | Should -Throw -ExpectedMessage $mockErrorMessage
            }
        }
    }

    Context 'When updating upstream tracking' {
        BeforeAll {
            Mock -CommandName git -MockWith {
                if (($args[0] -eq 'branch' -and $args[1] -eq '-m') -or $args[0] -eq 'fetch' -or ($args[0] -eq 'branch' -and $args[1] -eq '-u'))
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

        It 'Should update upstream tracking when TrackUpstream is specified' {
            Rename-GitLocalBranch -Name 'old-branch' -NewName 'new-branch' -TrackUpstream -Confirm:$false

            Should -Invoke -CommandName git -ParameterFilter { $args[0] -eq 'fetch' }
            Should -Invoke -CommandName git -ParameterFilter { $args[0] -eq 'branch' -and $args[1] -eq '-u' }
        }

        Context 'When the operation fails' {
            Context 'When fetching fails' {
                BeforeAll {
                    Mock -CommandName git -MockWith {
                        if ($args[0] -eq 'branch' -and $args[1] -eq '-m')
                        {
                            $global:LASTEXITCODE = 0
                        }
                        elseif ($args[0] -eq 'fetch')
                        {
                            $global:LASTEXITCODE = 1
                        }
                        else
                        {
                            throw "Mock git unexpected args: $($args -join ' ')"
                        }
                    }

                    $mockErrorMessage = InModuleScope -ScriptBlock {
                        $script:localizedData.Rename_GitLocalBranch_FailedFetch
                    }

                    $mockErrorMessage = $mockErrorMessage -f 'origin'
                }

                AfterEach {
                    $global:LASTEXITCODE = 0
                }

                It 'Should have a localized error message' {
                    $mockErrorMessage | Should-BeTruthy -Because 'The error message should have been localized, and shall not be empty'
                }

                It 'Should throw terminating error regardless of ErrorAction' {
                    {
                        Rename-GitLocalBranch -Name 'old-branch' -NewName 'new-branch' -TrackUpstream -ErrorAction 'SilentlyContinue' -Confirm:$false
                    } | Should -Throw -ExpectedMessage $mockErrorMessage
                }

                It 'Should handle terminating error correctly' {
                    {
                        Rename-GitLocalBranch -Name 'old-branch' -NewName 'new-branch' -TrackUpstream -ErrorAction 'Stop' -Confirm:$false
                    } | Should -Throw -ExpectedMessage $mockErrorMessage
                }
            }

            Context 'When setting upstream tracking fails' {
                BeforeAll {
                    Mock -CommandName git -MockWith {
                        if ($args[0] -eq 'branch' -and $args[1] -eq '-m')
                        {
                            $global:LASTEXITCODE = 0
                        }
                        elseif ($args[0] -eq 'fetch')
                        {
                            $global:LASTEXITCODE = 0
                        }
                        elseif ($args[0] -eq 'branch' -and $args[1] -eq '-u')
                        {
                            $global:LASTEXITCODE = 1
                        }
                        else
                        {
                            throw "Mock git unexpected args: $($args -join ' ')"
                        }
                    }

                    $mockErrorMessage = InModuleScope -ScriptBlock {
                        $script:localizedData.Rename_GitLocalBranch_FailedSetUpstreamTracking
                    }

                    $mockErrorMessage = $mockErrorMessage -f 'new-branch', 'origin'
                }

                AfterEach {
                    $global:LASTEXITCODE = 0
                }

                It 'Should have a localized error message' {
                    $mockErrorMessage | Should-BeTruthy -Because 'The error message should have been localized, and shall not be empty'
                }

                It 'Should throw terminating error regardless of ErrorAction when setting upstream tracking fails' {
                    {
                        Rename-GitLocalBranch -Name 'old-branch' -NewName 'new-branch' -TrackUpstream -ErrorAction 'SilentlyContinue' -Confirm:$false
                    } | Should -Throw -ExpectedMessage $mockErrorMessage
                }

                It 'Should handle terminating error correctly when setting upstream tracking fails' {
                    {
                        Rename-GitLocalBranch -Name 'old-branch' -NewName 'new-branch' -TrackUpstream -ErrorAction 'Stop' -Confirm:$false
                    } | Should -Throw -ExpectedMessage $mockErrorMessage
                }
            }
        }
    }

    Context 'When setting the default branch' {
        BeforeAll {
            Mock -CommandName git -MockWith {
                if ($args[0] -eq 'branch' -and $args[1] -eq '-m')
                {
                    $global:LASTEXITCODE = 0
                }
                elseif ($args[0] -eq 'fetch')
                {
                    $global:LASTEXITCODE = 0
                }
                elseif ($args[0] -eq 'remote' -and $args[1] -eq 'set-head')
                {
                    $global:LASTEXITCODE = 0
                }
                else
                {
                    throw "Mock git unexpected args: $($args -join ' ')"
                }
            }
        }

        It 'Should set the new branch as default for the remote' {
            Rename-GitLocalBranch -Name 'old-branch' -NewName 'new-branch' -SetDefault -Confirm:$false
            Should -Invoke -CommandName git -ParameterFilter {
                $args -contains 'remote' -and $args -contains 'set-head' -and $args -contains '--auto'
            }
        }

        Context 'When setting default branch fails' {
            BeforeAll {
                Mock -CommandName git -MockWith {
                    if ($args[0] -eq 'branch' -and $args[1] -eq '-m')
                    {
                        $global:LASTEXITCODE = 0
                    }
                    elseif ($args[0] -eq 'fetch')
                    {
                        $global:LASTEXITCODE = 0
                    }
                    elseif ($args[0] -eq 'remote' -and $args[1] -eq 'set-head')
                    {
                        $global:LASTEXITCODE = 1
                    }
                    else
                    {
                        throw "Mock git unexpected args: $($args -join ' ')"
                    }
                }

                $mockErrorMessage = InModuleScope -ScriptBlock {
                    $script:localizedData.Rename_GitLocalBranch_FailedSetDefaultBranchForRemote
                }

                $mockErrorMessage = $mockErrorMessage -f 'new-branch', 'origin'
            }

            It 'Should have a localized error message' {
                $mockErrorMessage | Should-BeTruthy -Because 'The error message should have been localized, and shall not be empty'
            }

            It 'Should throw terminating error regardless of ErrorAction when setting default branch fails' {
                {
                    Rename-GitLocalBranch -Name 'old-branch' -NewName 'new-branch' -SetDefault -ErrorAction 'SilentlyContinue' -Confirm:$false
                } | Should -Throw -ExpectedMessage $mockErrorMessage
            }

            It 'Should handle terminating error correctly when setting default branch fails' {
                {
                    Rename-GitLocalBranch -Name 'old-branch' -NewName 'new-branch' -SetDefault -ErrorAction 'Stop' -Confirm:$false
                } | Should -Throw -ExpectedMessage $mockErrorMessage
            }
        }
    }

    Context 'When using the default remote name' {
        BeforeAll {
            Mock -CommandName git -MockWith {
                $global:LASTEXITCODE = 0
            }
        }

        AfterEach {
            $global:LASTEXITCODE = 0
        }

        It 'Should update upstream tracking when TrackUpstream is specified' {
            Rename-GitLocalBranch -Name 'old-branch' -NewName 'new-branch' -TrackUpstream -Confirm:$false

            Should -Invoke -CommandName git -ParameterFilter { $args[0] -eq 'fetch' -and $args[1] -eq 'origin' }
            Should -Invoke -CommandName git -ParameterFilter { $args[0] -eq 'branch' -and $args[1] -eq '-u' -and $args[2] -eq 'origin/new-branch' -and $args[3] -eq 'new-branch' }
        }
    }

    Context 'When specifying a custom remote name' {
        BeforeAll {
            Mock -CommandName git -MockWith {
                $global:LASTEXITCODE = 0
            }
        }

        AfterEach {
            $global:LASTEXITCODE = 0
        }

        It 'Should update upstream tracking when TrackUpstream is specified' {
            Rename-GitLocalBranch -Name 'old-branch' -NewName 'new-branch' -RemoteName 'upstream' -TrackUpstream -Confirm:$false

            Should -Invoke -CommandName git -ParameterFilter { $args[0] -eq 'fetch' -and $args[1] -eq 'upstream' }
            Should -Invoke -CommandName git -ParameterFilter { $args[0] -eq 'branch' -and $args[1] -eq '-u' -and $args[2] -eq 'upstream/new-branch' -and $args[3] -eq 'new-branch' }
        }
    }

    Context 'When ShouldProcess is used' {
        BeforeAll {
            Mock -CommandName git -MockWith {
                if ($args[0] -eq 'branch' -and $args[1] -eq '-m')
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

        It 'Should support ShouldProcess' {
            $commandInfo = Get-Command -Name 'Rename-GitLocalBranch'
            $commandInfo.Parameters.ContainsKey('WhatIf') | Should -BeTrue
            $commandInfo.Parameters.ContainsKey('Confirm') | Should -BeTrue
        }

        It 'Should support ConfirmImpact Medium' {
            $commandInfo = Get-Command -Name 'Rename-GitLocalBranch'
            $confirmImpact = $commandInfo.Definition -match 'ConfirmImpact\s*=\s*[''"]?Medium[''"]?'
            $confirmImpact | Should -BeTrue
        }

        It 'Should not rename branch when WhatIf is specified' {
            Rename-GitLocalBranch -Name 'old-branch' -NewName 'new-branch' -WhatIf

            Should -Invoke -CommandName git -Times 0
        }
    }

    Context 'When Force parameter is used' {
        BeforeAll {
            Mock -CommandName git -MockWith {
                if ($args[0] -eq 'branch' -and $args[1] -eq '-m')
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

        It 'Should have Force parameter' {
            $commandInfo = Get-Command -Name 'Rename-GitLocalBranch'
            $commandInfo.Parameters.ContainsKey('Force') | Should -BeTrue
        }

        It 'Should execute when Force is used' {
            Rename-GitLocalBranch -Name 'old-branch' -NewName 'new-branch' -Force

            Should -Invoke -CommandName git -ParameterFilter {
                $args[0] -eq 'branch' -and $args[1] -eq '-m' -and $args[2] -eq 'old-branch' -and $args[3] -eq 'new-branch'
            }
        }
    }
}
