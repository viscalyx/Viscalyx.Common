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
Describe 'Receive-GitBranch' {
    Context 'When the command has correct parameter structure' {
        It 'Should have BranchName as a non-mandatory parameter with default value' {
            $parameterInfo = (Get-Command -Name 'Receive-GitBranch').Parameters['BranchName']
            $parameterInfo.Attributes.Mandatory | Should -BeFalse
        }

        It 'Should have UpstreamBranchName as a non-mandatory parameter with default value' {
            $parameterInfo = (Get-Command -Name 'Receive-GitBranch').Parameters['UpstreamBranchName']
            $parameterInfo.Attributes.Mandatory | Should -BeFalse
        }

        It 'Should have Rebase as a non-mandatory switch parameter' {
            $parameterInfo = (Get-Command -Name 'Receive-GitBranch').Parameters['Rebase']
            $parameterInfo.Attributes.Mandatory | Should -BeFalse
            $parameterInfo.ParameterType | Should -Be ([System.Management.Automation.SwitchParameter])
        }

        It 'Should have RemoteName as a non-mandatory parameter with default value' {
            $parameterInfo = (Get-Command -Name 'Receive-GitBranch').Parameters['RemoteName']
            $parameterInfo.Attributes.Mandatory | Should -BeFalse
        }

        It 'Should have Checkout as a non-mandatory switch parameter' {
            $parameterInfo = (Get-Command -Name 'Receive-GitBranch').Parameters['Checkout']
            $parameterInfo.Attributes.Mandatory | Should -BeFalse
            $parameterInfo.ParameterType | Should -Be ([System.Management.Automation.SwitchParameter])
        }

        It 'Should have Force as a non-mandatory switch parameter' {
            $parameterInfo = (Get-Command -Name 'Receive-GitBranch').Parameters['Force']
            $parameterInfo.Attributes.Mandatory | Should -BeFalse
            $parameterInfo.ParameterType | Should -Be ([System.Management.Automation.SwitchParameter])
        }

        It 'Should support ShouldProcess' {
            $commandInfo = Get-Command -Name 'Receive-GitBranch'
            $commandInfo.Parameters.ContainsKey('WhatIf') | Should -BeTrue
            $commandInfo.Parameters.ContainsKey('Confirm') | Should -BeTrue
        }
    }

    Context 'When using default parameters with pull behavior' {
        BeforeAll {
            Mock -CommandName git -MockWith {
                $global:LASTEXITCODE = 0
            }
        }

        AfterEach {
            $global:LASTEXITCODE = 0
        }

        It 'Should only pull changes by default without checkout' {
            Receive-GitBranch -Force

            Should -Invoke -CommandName git -ParameterFilter {
                $args[0] -eq 'pull'
            }

            Should -Invoke -CommandName git -ParameterFilter {
                $args[0] -eq 'checkout'
            } -Times 0
        }

        It 'Should checkout specified branch and pull changes when -Checkout is used' {
            Receive-GitBranch -Checkout -BranchName 'feature-branch' -Force

            Should -Invoke -CommandName git -ParameterFilter {
                $args[0] -eq 'checkout' -and $args[1] -eq 'feature-branch'
            }

            Should -Invoke -CommandName git -ParameterFilter {
                $args[0] -eq 'pull'
            }
        }
    }

    Context 'When using rebase behavior' {
        BeforeAll {
            Mock -CommandName git -MockWith {
                $global:LASTEXITCODE = 0
            }
        }

        AfterEach {
            $global:LASTEXITCODE = 0
        }

        It 'Should fetch and rebase without checkout by default' {
            Receive-GitBranch -Rebase -Force

            Should -Invoke -CommandName git -ParameterFilter {
                $args[0] -eq 'fetch' -and $args[1] -eq 'origin' -and $args[2] -eq 'main'
            }

            Should -Invoke -CommandName git -ParameterFilter {
                $args[0] -eq 'rebase' -and $args[1] -eq 'origin/main'
            }

            Should -Invoke -CommandName git -ParameterFilter {
                $args[0] -eq 'checkout'
            } -Times 0
        }

        It 'Should checkout, fetch, and rebase when -Checkout is used' {
            Receive-GitBranch -Checkout -Rebase -BranchName 'feature-branch' -Force

            Should -Invoke -CommandName git -ParameterFilter {
                $args[0] -eq 'checkout' -and $args[1] -eq 'feature-branch'
            }

            Should -Invoke -CommandName git -ParameterFilter {
                $args[0] -eq 'fetch' -and $args[1] -eq 'origin' -and $args[2] -eq 'main'
            }

            Should -Invoke -CommandName git -ParameterFilter {
                $args[0] -eq 'rebase' -and $args[1] -eq 'origin/main'
            }
        }

        It 'Should checkout, fetch, and rebase with custom branches' {
            Receive-GitBranch -Checkout -BranchName 'feature' -UpstreamBranchName 'develop' -Rebase -Force

            Should -Invoke -CommandName git -ParameterFilter {
                $args[0] -eq 'checkout' -and $args[1] -eq 'feature'
            }

            Should -Invoke -CommandName git -ParameterFilter {
                $args[0] -eq 'fetch' -and $args[1] -eq 'origin' -and $args[2] -eq 'develop'
            }

            Should -Invoke -CommandName git -ParameterFilter {
                $args[0] -eq 'rebase' -and $args[1] -eq 'origin/develop'
            }
        }

        It 'Should use custom remote name when specified' {
            Receive-GitBranch -RemoteName 'upstream' -UpstreamBranchName 'main' -Rebase -Force

            Should -Invoke -CommandName git -ParameterFilter {
                $args[0] -eq 'fetch' -and $args[1] -eq 'upstream' -and $args[2] -eq 'main'
            }

            Should -Invoke -CommandName git -ParameterFilter {
                $args[0] -eq 'rebase' -and $args[1] -eq 'upstream/main'
            }
        }
    }

    Context 'When checkout fails' {
        BeforeAll {
            Mock -CommandName git -MockWith {
                if ($args[0] -eq 'checkout')
                {
                    $global:LASTEXITCODE = 1
                }
                else
                {
                    $global:LASTEXITCODE = 0
                }
            }

            $mockErrorMessage = InModuleScope -ScriptBlock {
                $script:localizedData.Receive_GitBranch_FailedCheckout -f 'nonexistent-branch'
            }
        }

        AfterEach {
            $global:LASTEXITCODE = 0
        }

        It 'Should handle non-terminating error correctly when checkout is used' {
            Mock -CommandName Write-Error

            Receive-GitBranch -Checkout -BranchName 'nonexistent-branch' -Force

            Should -Invoke -CommandName Write-Error -ParameterFilter {
                $Message -eq $mockErrorMessage
            }
        }

        It 'Should handle terminating error correctly when checkout is used' {
            {
                Receive-GitBranch -Checkout -BranchName 'nonexistent-branch' -Force -ErrorAction 'Stop'
            } | Should -Throw -ExpectedMessage $mockErrorMessage
        }
    }

    Context 'When fetch fails during rebase' {
        BeforeAll {
            Mock -CommandName git -MockWith {
                if ($args[0] -eq 'checkout')
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
                $script:localizedData.Receive_GitBranch_FailedFetch -f 'origin', 'main'
            }
        }

        AfterEach {
            $global:LASTEXITCODE = 0
        }

        It 'Should handle non-terminating error correctly' {
            Mock -CommandName Write-Error

            Receive-GitBranch -Rebase -Force

            Should -Invoke -CommandName Write-Error -ParameterFilter {
                $Message -eq $mockErrorMessage
            }
        }

        It 'Should handle terminating error correctly' {
            {
                Receive-GitBranch -Rebase -Force -ErrorAction 'Stop'
            } | Should -Throw -ExpectedMessage $mockErrorMessage
        }
    }

    Context 'When rebase fails' {
        BeforeAll {
            Mock -CommandName git -MockWith {
                if ($args[0] -eq 'checkout')
                {
                    $global:LASTEXITCODE = 0
                }
                elseif ($args[0] -eq 'fetch')
                {
                    $global:LASTEXITCODE = 0
                }
                elseif ($args[0] -eq 'rebase')
                {
                    $global:LASTEXITCODE = 1
                }
                else
                {
                    throw "Mock git unexpected args: $($args -join ' ')"
                }
            }

            $mockErrorMessage = InModuleScope -ScriptBlock {
                $script:localizedData.Receive_GitBranch_FailedRebase -f 'origin', 'main'
            }
        }

        AfterEach {
            $global:LASTEXITCODE = 0
        }

        It 'Should handle non-terminating error correctly' {
            Mock -CommandName Write-Error

            Receive-GitBranch -Rebase -Force

            Should -Invoke -CommandName Write-Error -ParameterFilter {
                $Message -eq $mockErrorMessage
            }
        }

        It 'Should handle terminating error correctly' {
            {
                Receive-GitBranch -Rebase -Force -ErrorAction 'Stop'
            } | Should -Throw -ExpectedMessage $mockErrorMessage
        }
    }

    Context 'When pull fails' {
        BeforeAll {
            Mock -CommandName git -MockWith {
                if ($args[0] -eq 'checkout')
                {
                    $global:LASTEXITCODE = 0
                }
                elseif ($args[0] -eq 'pull')
                {
                    $global:LASTEXITCODE = 1
                }
                else
                {
                    throw "Mock git unexpected args: $($args -join ' ')"
                }
            }

            $mockErrorMessage = InModuleScope -ScriptBlock {
                $script:localizedData.Receive_GitBranch_FailedPull
            }
        }

        AfterEach {
            $global:LASTEXITCODE = 0
        }

        It 'Should handle non-terminating error correctly' {
            Mock -CommandName Write-Error

            Receive-GitBranch -Force

            Should -Invoke -CommandName Write-Error -ParameterFilter {
                $Message -eq $mockErrorMessage
            }
        }

        It 'Should handle terminating error correctly' {
            {
                Receive-GitBranch -Force -ErrorAction 'Stop'
            } | Should -Throw -ExpectedMessage $mockErrorMessage
        }
    }

    Context 'When using WhatIf' {
        BeforeAll {
            Mock -CommandName git -MockWith {
                $global:LASTEXITCODE = 0
            }
        }

        AfterEach {
            $global:LASTEXITCODE = 0
        }

        It 'Should not execute git commands when WhatIf is specified' {
            Receive-GitBranch -WhatIf

            Should -Not -Invoke -CommandName git
        }
    }
}
