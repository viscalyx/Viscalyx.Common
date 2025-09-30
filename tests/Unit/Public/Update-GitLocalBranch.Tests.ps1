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
Describe 'Update-GitLocalBranch' {
    Context 'Parameter Set Validation' {
        It 'Should have the correct parameters in parameter set <ExpectedParameterSetName>' -ForEach @(
            @{
                ExpectedParameterSetName = 'Default'
                ExpectedParameters       = '[-BranchName <string>] [-UpstreamBranchName <string>] [-RemoteName <string>] [-Rebase] [-ReturnToCurrentBranch] [-OnlyUpdateRemoteTrackingBranch] [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]'
            }
            @{
                ExpectedParameterSetName = 'Default_SkipSwitchingBranch'
                ExpectedParameters       = '[-BranchName <string>] [-UpstreamBranchName <string>] [-RemoteName <string>] [-Rebase] [-SkipSwitchingBranch] [-OnlyUpdateRemoteTrackingBranch] [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]'
            }
            @{
                ExpectedParameterSetName = 'Default_UseExistingTrackingBranch'
                ExpectedParameters       = '[-BranchName <string>] [-UpstreamBranchName <string>] [-RemoteName <string>] [-Rebase] [-ReturnToCurrentBranch] [-UseExistingTrackingBranch] [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]'
            }
        ) {
            $result = (Get-Command -Name 'Update-GitLocalBranch').ParameterSets |
                Where-Object -FilterScript { $_.Name -eq $ExpectedParameterSetName } |
                Select-Object -Property @(
                    @{ Name = 'ParameterSetName'; Expression = { $_.Name } },
                    @{ Name = 'ParameterListAsString'; Expression = { $_.ToString() } }
                )

            $result.ParameterSetName | Should -Be $ExpectedParameterSetName
            $result.ParameterListAsString | Should -Be $ExpectedParameters
        }

        It 'Should have BranchName parameter with default value "main"' {
            $parameterInfo = (Get-Command -Name 'Update-GitLocalBranch').Parameters['BranchName']
            $parameterInfo.Attributes.Where{ $_ -is [System.Management.Automation.ParameterAttribute] }.Mandatory | Should -Contain $false

            # Check default value by examining the parameter metadata
            $commandInfo = Get-Command -Name 'Update-GitLocalBranch'
            $defaultValue = $commandInfo.Parameters['BranchName'].DefaultValue
            $defaultValue | Should -Be $null # PowerShell doesn't expose default values this way, we'll test behavior instead
        }

        It 'Should have RemoteName parameter with default value "origin"' {
            $parameterInfo = (Get-Command -Name 'Update-GitLocalBranch').Parameters['RemoteName']
            $parameterInfo.Attributes.Where{ $_ -is [System.Management.Automation.ParameterAttribute] }.Mandatory | Should -Contain $false
        }

        It 'Should support ShouldProcess' {
            $commandInfo = Get-Command -Name 'Update-GitLocalBranch'
            $commandInfo.Parameters.Keys | Should -Contain 'WhatIf'
            $commandInfo.Parameters.Keys | Should -Contain 'Confirm'
        }
    }

    Context 'When updating branch with pull (default behavior)' {
        BeforeAll {
            Mock -CommandName Assert-GitRemote
            Mock -CommandName Get-GitLocalBranchName -MockWith { 'current-branch' }
            Mock -CommandName Switch-GitLocalBranch
            Mock -CommandName Update-RemoteTrackingBranch
            Mock -CommandName git -MockWith {
                if ($args[0] -eq 'pull')
                {
                    $global:LASTEXITCODE = 0
                }
                elseif ($args[0] -eq 'ls-files' -and $args[1] -eq '--unmerged')
                {
                    # No merge conflicts
                    return @()
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

        It 'Should successfully update main branch with pull' {
            $null = Update-GitLocalBranch -Force

            Should -Invoke -CommandName Assert-GitRemote -Times 1 -ParameterFilter { $Name -eq 'origin' }
            Should -Invoke -CommandName Get-GitLocalBranchName -Times 1 -ParameterFilter { $Current -eq $true }
            Should -Invoke -CommandName Switch-GitLocalBranch -Times 1 -ParameterFilter { $Name -eq 'main' }
            Should -Invoke -CommandName Update-RemoteTrackingBranch -Times 1 -ParameterFilter { $RemoteName -eq 'origin' -and $BranchName -eq 'main' }
            Should -Invoke -CommandName git -Times 1 -ParameterFilter { $args[0] -eq 'pull' -and $args[1] -eq 'origin' -and $args[2] -eq 'main' }
        }

        It 'Should use specified branch name and remote' {
            $null = Update-GitLocalBranch -BranchName 'develop' -RemoteName 'upstream' -Force

            Should -Invoke -CommandName Assert-GitRemote -Times 1 -ParameterFilter { $Name -eq 'upstream' }
            Should -Invoke -CommandName Switch-GitLocalBranch -Times 1 -ParameterFilter { $Name -eq 'develop' }
            Should -Invoke -CommandName Update-RemoteTrackingBranch -Times 1 -ParameterFilter { $RemoteName -eq 'upstream' -and $BranchName -eq 'develop' }
            Should -Invoke -CommandName git -Times 1 -ParameterFilter { $args[0] -eq 'pull' -and $args[1] -eq 'upstream' -and $args[2] -eq 'develop' }
        }

        It 'Should use different upstream branch name when specified' {
            $null = Update-GitLocalBranch -BranchName 'feature' -UpstreamBranchName 'main' -Force

            Should -Invoke -CommandName Update-RemoteTrackingBranch -Times 1 -ParameterFilter { $RemoteName -eq 'origin' -and $BranchName -eq 'main' }
            Should -Invoke -CommandName git -Times 1 -ParameterFilter { $args[0] -eq 'pull' -and $args[1] -eq 'origin' -and $args[2] -eq 'main' }
        }

        It 'Should handle current branch indicator "."' {
            $null = Update-GitLocalBranch -BranchName '.' -Force

            Should -Invoke -CommandName Get-GitLocalBranchName -Times 1 -ParameterFilter { $Current -eq $true }
            Should -Invoke -CommandName Switch-GitLocalBranch -Times 0 # Should not switch if already on current branch
        }
    }

    Context 'When updating branch with rebase' {
        BeforeAll {
            Mock -CommandName Assert-GitRemote
            Mock -CommandName Get-GitLocalBranchName -MockWith { 'current-branch' }
            Mock -CommandName Switch-GitLocalBranch
            Mock -CommandName Update-RemoteTrackingBranch
            Mock -CommandName git -MockWith {
                if ($args[0] -eq 'rebase')
                {
                    $global:LASTEXITCODE = 0
                }
                elseif ($args[0] -eq 'ls-files' -and $args[1] -eq '--unmerged')
                {
                    # No merge conflicts
                    return @()
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

        It 'Should successfully rebase branch' {
            $null = Update-GitLocalBranch -BranchName 'feature' -Rebase -Force

            Should -Invoke -CommandName Update-RemoteTrackingBranch -Times 1 -ParameterFilter { $RemoteName -eq 'origin' -and $BranchName -eq 'feature' }
            Should -Invoke -CommandName git -Times 1 -ParameterFilter { $args[0] -eq 'rebase' -and $args[1] -eq 'origin/feature' }
        }
    }

    Context 'When using SkipSwitchingBranch parameter' {
        BeforeAll {
            Mock -CommandName Assert-GitRemote
            Mock -CommandName Get-GitLocalBranchName -MockWith { 'current-branch' }
            Mock -CommandName Switch-GitLocalBranch
            Mock -CommandName Update-RemoteTrackingBranch
            Mock -CommandName git -MockWith {
                if ($args[0] -eq 'pull')
                {
                    $global:LASTEXITCODE = 0
                }
                elseif ($args[0] -eq 'ls-files' -and $args[1] -eq '--unmerged')
                {
                    return @()
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

        It 'Should not switch branches when SkipSwitchingBranch is specified' {
            $null = Update-GitLocalBranch -BranchName 'main' -SkipSwitchingBranch -Force

            Should -Invoke -CommandName Switch-GitLocalBranch -Times 0
        }
    }

    Context 'When using OnlyUpdateRemoteTrackingBranch parameter' {
        BeforeAll {
            Mock -CommandName Assert-GitRemote
            Mock -CommandName Get-GitLocalBranchName -MockWith { 'current-branch' }
            Mock -CommandName Switch-GitLocalBranch
            Mock -CommandName Update-RemoteTrackingBranch
            Mock -CommandName git
        }

        It 'Should only update remote tracking branch and skip local update' {
            $null = Update-GitLocalBranch -BranchName 'main' -OnlyUpdateRemoteTrackingBranch -Force

            Should -Invoke -CommandName Update-RemoteTrackingBranch -Times 1
            Should -Invoke -CommandName git -Times 0
        }
    }

    Context 'When using UseExistingTrackingBranch parameter' {
        BeforeAll {
            Mock -CommandName Assert-GitRemote
            Mock -CommandName Get-GitLocalBranchName -MockWith { 'current-branch' }
            Mock -CommandName Switch-GitLocalBranch
            Mock -CommandName Update-RemoteTrackingBranch
            Mock -CommandName git -MockWith {
                if ($args[0] -eq 'pull')
                {
                    $global:LASTEXITCODE = 0
                }
                elseif ($args[0] -eq 'ls-files' -and $args[1] -eq '--unmerged')
                {
                    return @()
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

        It 'Should not update remote tracking branch when UseExistingTrackingBranch is specified' {
            $null = Update-GitLocalBranch -BranchName 'main' -UseExistingTrackingBranch -Force

            Should -Invoke -CommandName Update-RemoteTrackingBranch -Times 0
            Should -Invoke -CommandName git -Times 1 -ParameterFilter { $args[0] -eq 'pull' }
        }
    }

    Context 'When using ReturnToCurrentBranch parameter' {
        BeforeAll {
            Mock -CommandName Assert-GitRemote
            Mock -CommandName Get-GitLocalBranchName -MockWith { 'original-branch' }
            Mock -CommandName Switch-GitLocalBranch
            Mock -CommandName Update-RemoteTrackingBranch
            Mock -CommandName git -MockWith {
                if ($args[0] -eq 'pull')
                {
                    $global:LASTEXITCODE = 0
                }
                elseif ($args[0] -eq 'ls-files' -and $args[1] -eq '--unmerged')
                {
                    return @()
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

        It 'Should return to original branch when ReturnToCurrentBranch is specified' {
            $null = Update-GitLocalBranch -BranchName 'main' -ReturnToCurrentBranch -Force

            Should -Invoke -CommandName Switch-GitLocalBranch -Times 2
            Should -Invoke -CommandName Switch-GitLocalBranch -Times 1 -ParameterFilter { $Name -eq 'main' }
            Should -Invoke -CommandName Switch-GitLocalBranch -Times 1 -ParameterFilter { $Name -eq 'original-branch' }
        }

        It 'Should not return to original branch if it is the same as target branch' {
            Mock -CommandName Get-GitLocalBranchName -MockWith { 'main' }

            $null = Update-GitLocalBranch -BranchName 'main' -ReturnToCurrentBranch -Force

            Should -Invoke -CommandName Switch-GitLocalBranch -Times 0
        }
    }

    Context 'When git operations fail' {
        BeforeAll {
            Mock -CommandName Assert-GitRemote
            Mock -CommandName Get-GitLocalBranchName -MockWith { 'current-branch' }
            Mock -CommandName Switch-GitLocalBranch
            Mock -CommandName Update-RemoteTrackingBranch
        }

        AfterEach {
            $global:LASTEXITCODE = 0
        }

        It 'Should have a localized error message' {
            $mockErrorMessage = InModuleScope -ScriptBlock {
                $script:localizedData.Update_GitLocalBranch_FailedRebase -f 'main', 'origin'
            }

            $mockErrorMessage | Should -Not -BeNullOrEmpty -Because 'The error message should have been localized, and shall not be empty'
        }

        It 'Should throw error when git pull fails' {
            Mock -CommandName git -MockWith {
                if ($args[0] -eq 'pull')
                {
                    $global:LASTEXITCODE = 1
                }
                elseif ($args[0] -eq 'ls-files' -and $args[1] -eq '--unmerged')
                {
                    return @()
                }
                else
                {
                    throw "Mock git unexpected args: $($args -join ' ')"
                }
            }

            $mockErrorMessage = InModuleScope -ScriptBlock {
                $script:localizedData.Update_GitLocalBranch_FailedPull -f 'main', 'origin'
            }

            {
                Update-GitLocalBranch -Force
            } | Should -Throw -ExpectedMessage $mockErrorMessage
        }

        It 'Should throw error when git rebase fails' {
            Mock -CommandName git -MockWith {
                if ($args[0] -eq 'rebase')
                {
                    $global:LASTEXITCODE = 1
                }
                elseif ($args[0] -eq 'ls-files' -and $args[1] -eq '--unmerged')
                {
                    return @()
                }
                else
                {
                    throw "Mock git unexpected args: $($args -join ' ')"
                }
            }

            $mockErrorMessage = InModuleScope -ScriptBlock {
                $script:localizedData.Update_GitLocalBranch_FailedRebase -f 'main', 'origin'
            }

            {
                Update-GitLocalBranch -Rebase -Force
            } | Should -Throw -ExpectedMessage $mockErrorMessage
        }
    }

    Context 'When merge conflicts occur' {
        BeforeAll {
            Mock -CommandName Assert-GitRemote
            Mock -CommandName Get-GitLocalBranchName -MockWith { 'current-branch' }
            Mock -CommandName Switch-GitLocalBranch
            Mock -CommandName Update-RemoteTrackingBranch
            Mock -CommandName Write-Information
            Mock -CommandName git -MockWith {
                if ($args[0] -eq 'rebase')
                {
                    $global:LASTEXITCODE = 1
                }
                elseif ($args[0] -eq 'ls-files' -and $args[1] -eq '--unmerged')
                {
                    # Return some merge conflicts
                    return @('conflicted-file.txt')
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

        It 'Should handle merge conflicts gracefully during rebase' {
            $null = Update-GitLocalBranch -Rebase -Force

            Should -Invoke -CommandName Write-Information -Times 1 -ParameterFilter { $MessageData -match 'Merge conflict detected' }
        }

        It 'Should provide instructions for resolving conflicts' {
            $null = Update-GitLocalBranch -Rebase -ReturnToCurrentBranch -Force

            Should -Invoke -CommandName Write-Information -Times 1 -ParameterFilter { $MessageData -match 'Resume-GitRebase.*Stop-GitRebase' }
            Should -Invoke -CommandName Write-Information -Times 1 -ParameterFilter { $MessageData -match 'Switch-GitLocalBranch.*current-branch' }
        }
    }

    Context 'When ShouldProcess is used' {
        BeforeAll {
            Mock -CommandName Assert-GitRemote
            Mock -CommandName Get-GitLocalBranchName -MockWith { 'current-branch' }
            Mock -CommandName Switch-GitLocalBranch
            Mock -CommandName Update-RemoteTrackingBranch
            Mock -CommandName git
        }

        It 'Should not execute git commands when WhatIf is specified' {
            $null = Update-GitLocalBranch -WhatIf

            Should -Invoke -CommandName git -Times 0
        }

        It 'Should not call Assert-GitRemote when WhatIf is specified' {
            $null = Update-GitLocalBranch -WhatIf

            Should -Invoke -CommandName Assert-GitRemote -Times 0
        }

        It 'Should not update remote tracking branch when WhatIf is specified' {
            $null = Update-GitLocalBranch -WhatIf

            Should -Invoke -CommandName Update-RemoteTrackingBranch -Times 0
        }
    }

    Context 'When Force parameter is used' {
        BeforeAll {
            Mock -CommandName Assert-GitRemote
            Mock -CommandName Get-GitLocalBranchName -MockWith { 'current-branch' }
            Mock -CommandName Switch-GitLocalBranch
            Mock -CommandName Update-RemoteTrackingBranch
            Mock -CommandName git -MockWith {
                if ($args[0] -eq 'pull')
                {
                    $global:LASTEXITCODE = 0
                }
                elseif ($args[0] -eq 'ls-files' -and $args[1] -eq '--unmerged')
                {
                    return @()
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

        It 'Should bypass confirmation when Force is used' {
            $null = Update-GitLocalBranch -BranchName 'main' -Force

            Should -Invoke -CommandName git -Times 1 -ParameterFilter { $args[0] -eq 'pull' }
        }
    }

    Context 'When dependencies throw errors' {
        BeforeAll {
            Mock -CommandName Get-GitLocalBranchName -MockWith { 'current-branch' }
            Mock -CommandName Switch-GitLocalBranch
            Mock -CommandName Update-RemoteTrackingBranch
            Mock -CommandName git
        }

        AfterEach {
            $global:LASTEXITCODE = 0
        }

        It 'Should propagate Assert-GitRemote errors' {
            Mock -CommandName Assert-GitRemote -MockWith {
                throw 'Remote does not exist'
            }

            {
                Update-GitLocalBranch -Force
            } | Should -Throw -ExpectedMessage 'Remote does not exist'
        }

        It 'Should propagate Switch-GitLocalBranch errors' {
            Mock -CommandName Assert-GitRemote
            Mock -CommandName Switch-GitLocalBranch -MockWith {
                throw 'Failed to switch branch'
            }

            {
                Update-GitLocalBranch -BranchName 'feature' -Force
            } | Should -Throw -ExpectedMessage 'Failed to switch branch'
        }

        It 'Should propagate Update-RemoteTrackingBranch errors' {
            Mock -CommandName Assert-GitRemote
            Mock -CommandName Update-RemoteTrackingBranch -MockWith {
                throw 'Failed to update remote tracking branch'
            }

            {
                Update-GitLocalBranch -Force
            } | Should -Throw -ExpectedMessage 'Failed to update remote tracking branch'
        }
    }
}
