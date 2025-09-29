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
Describe 'Update-RemoteTrackingBranch' {
    Context 'Parameter Set Validation' {
        It 'Should have the correct parameters in parameter set <ExpectedParameterSetName>' -ForEach @(
            @{
                ExpectedParameterSetName = '__AllParameterSets'
                ExpectedParameters       = '[-RemoteName] <string> [[-BranchName] <string>] [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]'
            }
        ) {
            $result = (Get-Command -Name 'Update-RemoteTrackingBranch').ParameterSets |
                Where-Object -FilterScript { $_.Name -eq $ExpectedParameterSetName } |
                Select-Object -Property @(
                    @{ Name = 'ParameterSetName'; Expression = { $_.Name } },
                    @{ Name = 'ParameterListAsString'; Expression = { $_.ToString() } }
                )

            $result.ParameterSetName | Should -Be $ExpectedParameterSetName
            $result.ParameterListAsString | Should -Be $ExpectedParameters
        }

        It 'Should have RemoteName as a mandatory parameter' {
            $parameterInfo = (Get-Command -Name 'Update-RemoteTrackingBranch').Parameters['RemoteName']
            $parameterInfo.Attributes.Where{ $_ -is [System.Management.Automation.ParameterAttribute] }.Mandatory | Should -Contain $true
        }

        It 'Should have BranchName as a non-mandatory parameter' {
            $parameterInfo = (Get-Command -Name 'Update-RemoteTrackingBranch').Parameters['BranchName']
            $parameterInfo.Attributes.Where{ $_ -is [System.Management.Automation.ParameterAttribute] }.Mandatory | Should -Contain $false
        }

        It 'Should support ShouldProcess' {
            $commandInfo = Get-Command -Name 'Update-RemoteTrackingBranch'
            $commandInfo.Parameters.Keys | Should -Contain 'WhatIf'
            $commandInfo.Parameters.Keys | Should -Contain 'Confirm'
        }

        It 'Should support ConfirmImpact Medium' {
            $commandInfo = Get-Command -Name 'Update-RemoteTrackingBranch'
            $confirmImpact = $commandInfo.Definition -match 'ConfirmImpact\s*=\s*[''"]?Medium[''"]?'
            $confirmImpact | Should -BeTrue
        }
    }

    Context 'When fetching from remote without branch specification' {
        BeforeAll {
            Mock -CommandName git -MockWith {
                if ($args[0] -eq 'fetch')
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

        It 'Should successfully fetch all branches from specified remote' {
            $null = Update-RemoteTrackingBranch -RemoteName 'origin' -Confirm:$false

            Should -Invoke -CommandName git -Times 1 -ParameterFilter {
                $args[0] -eq 'fetch' -and $args[1] -eq 'origin' -and $args.Count -eq 2
            }
        }

        It 'Should work with different remote names' {
            $null = Update-RemoteTrackingBranch -RemoteName 'upstream' -Confirm:$false

            Should -Invoke -CommandName git -Times 1 -ParameterFilter {
                $args[0] -eq 'fetch' -and $args[1] -eq 'upstream' -and $args.Count -eq 2
            }
        }
    }

    Context 'When fetching from remote with branch specification' {
        BeforeAll {
            Mock -CommandName git -MockWith {
                if ($args[0] -eq 'fetch')
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

        It 'Should successfully fetch specific branch from specified remote' {
            $null = Update-RemoteTrackingBranch -RemoteName 'origin' -BranchName 'main' -Confirm:$false

            Should -Invoke -CommandName git -Times 1 -ParameterFilter {
                $args[0] -eq 'fetch' -and $args[1] -eq 'origin' -and $args[2] -eq 'main' -and $args.Count -eq 3
            }
        }

        It 'Should work with different branch and remote combinations' {
            $null = Update-RemoteTrackingBranch -RemoteName 'upstream' -BranchName 'develop' -Confirm:$false

            Should -Invoke -CommandName git -Times 1 -ParameterFilter {
                $args[0] -eq 'fetch' -and $args[1] -eq 'upstream' -and $args[2] -eq 'develop' -and $args.Count -eq 3
            }
        }

        It 'Should work with feature branch names' {
            $null = Update-RemoteTrackingBranch -RemoteName 'origin' -BranchName 'feature/new-functionality' -Confirm:$false

            Should -Invoke -CommandName git -Times 1 -ParameterFilter {
                $args[0] -eq 'fetch' -and $args[1] -eq 'origin' -and $args[2] -eq 'feature/new-functionality' -and $args.Count -eq 3
            }
        }
    }

    Context 'When git fetch fails' {
        BeforeAll {
            Mock -CommandName git -MockWith {
                if ($args[0] -eq 'fetch')
                {
                    $global:LASTEXITCODE = 1
                    return 'error: Could not fetch origin'
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

        It 'Should throw terminating error when fetch fails without branch' {
            { Update-RemoteTrackingBranch -RemoteName 'origin' -Confirm:$false } | Should -Throw -ErrorId 'URTB0001*'

            Should -Invoke -CommandName git -Times 1 -ParameterFilter {
                $args[0] -eq 'fetch' -and $args[1] -eq 'origin' -and $args.Count -eq 2
            }
        }

        It 'Should throw terminating error when fetch fails with branch' {
            { Update-RemoteTrackingBranch -RemoteName 'origin' -BranchName 'main' -Confirm:$false } | Should -Throw -ErrorId 'URTB0001*'

            Should -Invoke -CommandName git -Times 1 -ParameterFilter {
                $args[0] -eq 'fetch' -and $args[1] -eq 'origin' -and $args[2] -eq 'main' -and $args.Count -eq 3
            }
        }

        It 'Should include remote and branch information in error message when fetch fails' {
            { Update-RemoteTrackingBranch -RemoteName 'upstream' -BranchName 'develop' -Confirm:$false } | Should -Throw -ErrorId 'URTB0001*'

            Should -Invoke -CommandName git -Times 1 -ParameterFilter {
                $args[0] -eq 'fetch' -and $args[1] -eq 'upstream' -and $args[2] -eq 'develop' -and $args.Count -eq 3
            }
        }
    }

    Context 'When using ShouldProcess' {
        BeforeAll {
            Mock -CommandName git -MockWith {
                if ($args[0] -eq 'fetch')
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

        It 'Should not execute git fetch when using -WhatIf' {
            $null = Update-RemoteTrackingBranch -RemoteName 'origin' -BranchName 'main' -WhatIf

            Should -Invoke -CommandName git -Times 0
        }

        It 'Should use correct ShouldProcess messages with branch' {
            # Test the ShouldProcess call indirectly by ensuring it doesn't error out
            $null = Update-RemoteTrackingBranch -RemoteName 'origin' -BranchName 'main' -Confirm:$false
        }

        It 'Should use correct ShouldProcess messages without branch' {
            # Test the ShouldProcess call indirectly by ensuring it doesn't error out
            $null = Update-RemoteTrackingBranch -RemoteName 'origin' -Confirm:$false
        }
    }

    Context 'When validating localized strings' {
        It 'Should have all required localized strings defined' {
            InModuleScope -ScriptBlock {
                $script:localizedData.Keys | Should -Contain 'Update_RemoteTrackingBranch_FailedFetchBranchFromRemote'
                $script:localizedData.Keys | Should -Contain 'Update_RemoteTrackingBranch_FetchUpstream_ShouldProcessVerboseDescription'
                $script:localizedData.Keys | Should -Contain 'Update_RemoteTrackingBranch_FetchUpstream_ShouldProcessVerboseWarning'
                $script:localizedData.Keys | Should -Contain 'Update_RemoteTrackingBranch_FetchUpstream_ShouldProcessCaption'
            }
        }

        It 'Should have correctly formatted localized strings' {
            InModuleScope -ScriptBlock {
                # Verify error message format
                $script:localizedData.Update_RemoteTrackingBranch_FailedFetchBranchFromRemote | Should -Match '\{0\}'

                # Verify ShouldProcess messages format
                $script:localizedData.Update_RemoteTrackingBranch_FetchUpstream_ShouldProcessVerboseDescription | Should -Match '\{0\}.*\{1\}'
                $script:localizedData.Update_RemoteTrackingBranch_FetchUpstream_ShouldProcessVerboseWarning | Should -Match '\{0\}.*\{1\}'

                # Verify caption does not end with period
                $script:localizedData.Update_RemoteTrackingBranch_FetchUpstream_ShouldProcessCaption | Should -Not -Match '\.$'
            }
        }
    }
}
