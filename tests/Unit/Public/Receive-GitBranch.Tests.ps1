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

        It 'Should have WorkingDirectory as a non-mandatory parameter' {
            $parameterInfo = (Get-Command -Name 'Receive-GitBranch').Parameters['WorkingDirectory']
            $parameterInfo.Attributes.Mandatory | Should -BeFalse
            $parameterInfo.ParameterType | Should -Be ([System.String])
        }

        It 'Should support ShouldProcess' {
            $commandInfo = Get-Command -Name 'Receive-GitBranch'
            $commandInfo.Parameters.ContainsKey('WhatIf') | Should -BeTrue
            $commandInfo.Parameters.ContainsKey('Confirm') | Should -BeTrue
        }
    }

    Context 'When using default parameters with pull behavior' {
        BeforeAll {
            Mock -CommandName Get-Location -MockWith {
                return @{
                    Path = '/test/repo'
                }
            }

            Mock -CommandName Invoke-Git
        }

        It 'Should only pull changes by default without checkout' {
            $null = Receive-GitBranch -Force

            Should -Invoke -CommandName Invoke-Git -ParameterFilter {
                $Arguments -contains 'pull'
            }

            Should -Invoke -CommandName Invoke-Git -ParameterFilter {
                $Arguments -contains 'checkout'
            } -Times 0
        }

        It 'Should checkout specified branch and pull changes when -Checkout is used' {
            $null = Receive-GitBranch -Checkout -BranchName 'feature-branch' -Force

            Should -Invoke -CommandName Invoke-Git -ParameterFilter {
                $Arguments -contains 'checkout' -and $Arguments -contains 'feature-branch'
            }

            Should -Invoke -CommandName Invoke-Git -ParameterFilter {
                $Arguments -contains 'pull'
            }
        }
    }

    Context 'When using rebase behavior' {
        BeforeAll {
            Mock -CommandName Get-Location -MockWith {
                return @{
                    Path = '/test/repo'
                }
            }

            Mock -CommandName Invoke-Git
        }

        It 'Should fetch and rebase without checkout by default' {
            $null = Receive-GitBranch -Rebase -Force

            Should -Invoke -CommandName Invoke-Git -ParameterFilter {
                $Arguments -contains 'fetch' -and $Arguments -contains 'origin' -and $Arguments -contains 'main'
            }

            Should -Invoke -CommandName Invoke-Git -ParameterFilter {
                $Arguments -contains 'rebase' -and $Arguments -contains 'origin/main'
            }

            Should -Invoke -CommandName Invoke-Git -ParameterFilter {
                $Arguments -contains 'checkout'
            } -Times 0
        }

        It 'Should checkout, fetch, and rebase when -Checkout is used' {
            $null = Receive-GitBranch -Checkout -Rebase -BranchName 'feature-branch' -Force

            Should -Invoke -CommandName Invoke-Git -ParameterFilter {
                $Arguments -contains 'checkout' -and $Arguments -contains 'feature-branch'
            }

            Should -Invoke -CommandName Invoke-Git -ParameterFilter {
                $Arguments -contains 'fetch' -and $Arguments -contains 'origin' -and $Arguments -contains 'main'
            }

            Should -Invoke -CommandName Invoke-Git -ParameterFilter {
                $Arguments -contains 'rebase' -and $Arguments -contains 'origin/main'
            }
        }

        It 'Should checkout, fetch, and rebase with custom branches' {
            $null = Receive-GitBranch -Checkout -BranchName 'feature' -UpstreamBranchName 'develop' -Rebase -Force

            Should -Invoke -CommandName Invoke-Git -ParameterFilter {
                $Arguments -contains 'checkout' -and $Arguments -contains 'feature'
            }

            Should -Invoke -CommandName Invoke-Git -ParameterFilter {
                $Arguments -contains 'fetch' -and $Arguments -contains 'origin' -and $Arguments -contains 'develop'
            }

            Should -Invoke -CommandName Invoke-Git -ParameterFilter {
                $Arguments -contains 'rebase' -and $Arguments -contains 'origin/develop'
            }
        }

        It 'Should use custom remote name when specified' {
            $null = Receive-GitBranch -RemoteName 'upstream' -UpstreamBranchName 'main' -Rebase -Force

            Should -Invoke -CommandName Invoke-Git -ParameterFilter {
                $Arguments -contains 'fetch' -and $Arguments -contains 'upstream' -and $Arguments -contains 'main'
            }

            Should -Invoke -CommandName Invoke-Git -ParameterFilter {
                $Arguments -contains 'rebase' -and $Arguments -contains 'upstream/main'
            }
        }
    }

    Context 'When checkout fails' {
        BeforeAll {
            Mock -CommandName Get-Location -MockWith {
                return @{
                    Path = '/test/repo'
                }
            }

            Mock -CommandName Invoke-Git -MockWith {
                if ($Arguments -contains 'checkout')
                {
                    throw 'Checkout failed'
                }
            }

            $mockErrorMessage = InModuleScope -ScriptBlock {
                $script:localizedData.Receive_GitBranch_FailedCheckout -f 'nonexistent-branch'
            }
        }

        It 'Should handle non-terminating error correctly when checkout is used' {
            Mock -CommandName Write-Error

            $null = Receive-GitBranch -Checkout -BranchName 'nonexistent-branch' -Force

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
            Mock -CommandName Get-Location -MockWith {
                return @{
                    Path = '/test/repo'
                }
            }

            Mock -CommandName Invoke-Git -MockWith {
                if ($Arguments -contains 'checkout')
                {
                    # Checkout succeeds
                }
                elseif ($Arguments -contains 'fetch')
                {
                    throw 'Fetch failed'
                }
                else
                {
                    throw "Mock Invoke-Git unexpected args: $($Arguments -join ' ')"
                }
            }

            $mockErrorMessage = InModuleScope -ScriptBlock {
                $script:localizedData.Receive_GitBranch_FailedFetch -f 'origin', 'main'
            }
        }

        It 'Should handle non-terminating error correctly' {
            Mock -CommandName Write-Error

            $null = Receive-GitBranch -Rebase -Force

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
            Mock -CommandName Get-Location -MockWith {
                return @{
                    Path = '/test/repo'
                }
            }

            Mock -CommandName Invoke-Git -MockWith {
                if ($Arguments -contains 'checkout')
                {
                    # Checkout succeeds
                }
                elseif ($Arguments -contains 'fetch')
                {
                    # Fetch succeeds
                }
                elseif ($Arguments -contains 'rebase')
                {
                    throw 'Rebase failed'
                }
                else
                {
                    throw "Mock Invoke-Git unexpected args: $($Arguments -join ' ')"
                }
            }

            $mockErrorMessage = InModuleScope -ScriptBlock {
                $script:localizedData.Receive_GitBranch_FailedRebase -f 'origin', 'main'
            }
        }

        It 'Should handle non-terminating error correctly' {
            Mock -CommandName Write-Error

            $null = Receive-GitBranch -Rebase -Force

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
            Mock -CommandName Get-Location -MockWith {
                return @{
                    Path = '/test/repo'
                }
            }

            Mock -CommandName Invoke-Git -MockWith {
                if ($Arguments -contains 'checkout')
                {
                    # Checkout succeeds
                }
                elseif ($Arguments -contains 'pull')
                {
                    throw 'Pull failed'
                }
                else
                {
                    throw "Mock Invoke-Git unexpected args: $($Arguments -join ' ')"
                }
            }

            $mockErrorMessage = InModuleScope -ScriptBlock {
                $script:localizedData.Receive_GitBranch_FailedPull
            }
        }

        It 'Should handle non-terminating error correctly' {
            Mock -CommandName Write-Error

            $null = Receive-GitBranch -Force

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
            Mock -CommandName Get-Location -MockWith {
                return @{
                    Path = '/test/repo'
                }
            }

            Mock -CommandName Invoke-Git
        }

        It 'Should not execute git commands when WhatIf is specified' {
            $null = Receive-GitBranch -WhatIf

            Should -Not -Invoke -CommandName Invoke-Git
        }
    }
}
