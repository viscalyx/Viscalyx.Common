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
Describe 'Stop-GitRebase' {
    Context 'When repository is not in a rebase state' {
        BeforeAll {
            Mock -CommandName Test-Path -MockWith {
                return $false
            }

            $mockErrorMessage = InModuleScope -ScriptBlock {
                $script:localizedData.Stop_GitRebase_NotInRebaseState
            }
        }

        It 'Should have a localized error message for not in rebase state' {
            $mockErrorMessage | Should -Not -BeNullOrEmpty -Because 'The error message should have been localized, and shall not be empty'
        }

        It 'Should handle non-terminating error correctly when not in rebase state' {
            Mock -CommandName Write-Error

            $null = Stop-GitRebase -Force

            Should -Invoke -CommandName Write-Error -ParameterFilter {
                $Message -eq $mockErrorMessage
            }
        }

        It 'Should handle terminating error correctly when not in rebase state' {
            {
                Stop-GitRebase -Force -ErrorAction 'Stop'
            } | Should -Throw -ExpectedMessage $mockErrorMessage
        }

        It 'Should throw error with correct error code SPGR0001' {
            {
                Stop-GitRebase -Force -ErrorAction 'Stop'
            } | Should -Throw -ErrorId 'SPGR0001,Stop-GitRebase'
        }

        It 'Should not call Invoke-Git when not in rebase state' {
            Mock -CommandName Invoke-Git

            $null = Stop-GitRebase -Force

            Should -Invoke -CommandName Invoke-Git -Exactly -Times 0
        }
    }

    Context 'When repository is in a rebase state (rebase-merge)' {
        BeforeAll {
            Mock -CommandName Test-Path -MockWith {
                param ($Path)

                if ($Path -like '*rebase-merge')
                {
                    return $true
                }

                return $false
            }

            Mock -CommandName Invoke-Git -MockWith {
                $global:LASTEXITCODE = 0
            }
        }

        AfterEach {
            $global:LASTEXITCODE = 0
        }

        It 'Should call Invoke-Git with correct arguments to abort rebase' {
            $null = Stop-GitRebase -Force

            Should -Invoke -CommandName Invoke-Git -ParameterFilter {
                $Path -eq (Get-Location).Path -and $Arguments -contains 'rebase' -and $Arguments -contains '--abort'
            }
        }

        It 'Should not change directory when Path is not specified' {
            Mock -CommandName Set-Location

            $null = Stop-GitRebase -Force

            Should -Invoke -CommandName Set-Location -Exactly -Times 0
        }
    }

    Context 'When repository is in a rebase state (rebase-apply)' {
        BeforeAll {
            Mock -CommandName Test-Path -MockWith {
                param ($Path)

                if ($Path -like '*rebase-apply')
                {
                    return $true
                }

                return $false
            }

            Mock -CommandName Invoke-Git -MockWith {
                $global:LASTEXITCODE = 0
            }
        }

        AfterEach {
            $global:LASTEXITCODE = 0
        }

        It 'Should call Invoke-Git with correct arguments to abort rebase' {
            $null = Stop-GitRebase -Force

            Should -Invoke -CommandName Invoke-Git -ParameterFilter {
                $Path -eq (Get-Location).Path -and $Arguments -contains 'rebase' -and $Arguments -contains '--abort'
            }
        }
    }

    Context 'When Path parameter is specified' {
        BeforeAll {
            Mock -CommandName Test-Path -MockWith {
                return $true
            }

            Mock -CommandName Invoke-Git -MockWith {
                $global:LASTEXITCODE = 0
            }
        }

        AfterEach {
            $global:LASTEXITCODE = 0
        }

        It 'Should pass the Path parameter to Invoke-Git' {
            $null = Stop-GitRebase -Path '/custom/path' -Force

            Should -Invoke -CommandName Invoke-Git -ParameterFilter {
                $Path -eq '/custom/path' -and $Arguments -contains 'rebase' -and $Arguments -contains '--abort'
            }
        }

        It 'Should check for rebase state in the specified Path' {
            $null = Stop-GitRebase -Path '/custom/path' -Force

            Should -Invoke -CommandName Test-Path -ParameterFilter {
                $Path -like '/custom/path/.git/rebase-*'
            }
        }
    }

    Context 'When the abort operation fails' {
        BeforeAll {
            Mock -CommandName Test-Path -MockWith {
                return $true
            }

            Mock -CommandName Invoke-Git -MockWith {
                throw 'Git command failed'
            }

            $mockErrorMessage = InModuleScope -ScriptBlock {
                $script:localizedData.Stop_GitRebase_FailedAbort
            }
        }

        It 'Should have a localized error message for failed abort' {
            $mockErrorMessage | Should -Not -BeNullOrEmpty -Because 'The error message should have been localized, and shall not be empty'
        }

        It 'Should handle non-terminating error correctly' {
            Mock -CommandName Write-Error

            $null = Stop-GitRebase -Force

            Should -Invoke -CommandName Write-Error -ParameterFilter {
                $Message -eq $mockErrorMessage
            }
        }

        It 'Should handle terminating error correctly' {
            {
                Stop-GitRebase -Force -ErrorAction 'Stop'
            } | Should -Throw -ExpectedMessage $mockErrorMessage
        }

        It 'Should throw error with correct error code SPGR0003' {
            {
                Stop-GitRebase -Force -ErrorAction 'Stop'
            } | Should -Throw -ErrorId 'SPGR0003,Stop-GitRebase'
        }
    }

    Context 'When using ShouldProcess' {
        BeforeAll {
            Mock -CommandName Test-Path -MockWith {
                return $true
            }

            Mock -CommandName Invoke-Git -MockWith {
                $global:LASTEXITCODE = 0
            }
        }

        AfterEach {
            $global:LASTEXITCODE = 0
        }

        It 'Should not execute abort when WhatIf is specified' {
            $null = Stop-GitRebase -WhatIf

            Should -Invoke -CommandName Invoke-Git -Exactly -Times 0
        }

        It 'Should execute abort when Force is specified' {
            $null = Stop-GitRebase -Force

            Should -Invoke -CommandName Invoke-Git -Exactly -Times 1
        }
    }

    Context 'When verifying parameters' {
        It 'Should have Path parameter' {
            $command = Get-Command -Name Stop-GitRebase
            $parameter = $command.Parameters['Path']

            $parameter | Should -Not -BeNullOrEmpty
            $parameter.ParameterType.Name | Should -Be 'String'
            $parameter.Attributes.Where({$_.TypeId.Name -eq 'ParameterAttribute'}).Mandatory | Should -BeFalse
        }

        It 'Should have Force parameter' {
            $command = Get-Command -Name Stop-GitRebase
            $parameter = $command.Parameters['Force']

            $parameter | Should -Not -BeNullOrEmpty
            $parameter.ParameterType.Name | Should -Be 'SwitchParameter'
        }

        It 'Should support ShouldProcess' {
            $command = Get-Command -Name Stop-GitRebase
            $command.Parameters.ContainsKey('WhatIf') | Should -BeTrue
            $command.Parameters.ContainsKey('Confirm') | Should -BeTrue
        }
    }

    Context 'When checking localization' {
        It 'Should have all required localized strings' {
            InModuleScope -ScriptBlock {
                $script:localizedData.Stop_GitRebase_NotInRebaseState | Should -Not -BeNullOrEmpty
                $script:localizedData.Stop_GitRebase_AbortingRebase | Should -Not -BeNullOrEmpty
                $script:localizedData.Stop_GitRebase_FailedAbort | Should -Not -BeNullOrEmpty
                $script:localizedData.Stop_GitRebase_Success | Should -Not -BeNullOrEmpty
                $script:localizedData.Stop_GitRebase_ShouldProcessVerboseDescription | Should -Not -BeNullOrEmpty
                $script:localizedData.Stop_GitRebase_ShouldProcessVerboseWarning | Should -Not -BeNullOrEmpty
                $script:localizedData.Stop_GitRebase_ShouldProcessCaption | Should -Not -BeNullOrEmpty
            }
        }
    }
}
