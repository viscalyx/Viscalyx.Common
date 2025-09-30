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
Describe 'Resume-GitRebase' {
    Context 'When repository is not in rebase state' {
        BeforeAll {
            Mock -CommandName Test-Path -MockWith {
                return $false
            }

            $mockErrorMessage = InModuleScope -ScriptBlock {
                $script:localizedData.Resume_GitRebase_NotInRebaseState
            }
        }

        It 'Should have a localized error message for not in rebase state' {
            $mockErrorMessage | Should -Not -BeNullOrEmpty -Because 'The error message should have been localized, and shall not be empty'
        }

        It 'Should handle non-terminating error correctly' {
            Mock -CommandName Write-Error

            $null = Resume-GitRebase -Force

            Should -Invoke -CommandName Write-Error -ParameterFilter {
                $Message -eq $mockErrorMessage
            }
        }

        It 'Should throw error correctly when ErrorAction is Stop' {
            {
                Resume-GitRebase -Force -ErrorAction 'Stop'
            } | Should -Throw -ExpectedMessage $mockErrorMessage
        }

        It 'Should throw error with correct error code RGRE0001' {
            {
                Resume-GitRebase -Force -ErrorAction 'Stop'
            } | Should -Throw -ErrorId 'RGRE0001,Resume-GitRebase'
        }

        It 'Should not call Invoke-Git when repository is not in rebase state' {
            Mock -CommandName Invoke-Git

            $null = Resume-GitRebase -Force

            Should -Invoke -CommandName Invoke-Git -Exactly -Times 0
        }
    }

    Context 'When resuming rebase with continue' {
        BeforeAll {
            Mock -CommandName Test-Path -MockWith {
                param ($Path)
                # Return true for rebase-merge path
                return $Path -like '*rebase-merge'
            }

            Mock -CommandName Invoke-Git -MockWith {
                $global:LASTEXITCODE = 0
            }
        }

        AfterEach {
            $global:LASTEXITCODE = 0
        }

        It 'Should call Invoke-Git with correct arguments for continue' {
            $null = Resume-GitRebase -Force

            Should -Invoke -CommandName Invoke-Git -ParameterFilter {
                $Path -eq (Get-Location).Path -and $Arguments -contains 'rebase' -and $Arguments -contains '--continue'
            }
        }

        It 'Should check for rebase-merge path' {
            $null = Resume-GitRebase -Force

            Should -Invoke -CommandName Test-Path -ParameterFilter {
                $Path -like '*rebase-merge'
            }
        }
    }

    Context 'When resuming rebase with skip' {
        BeforeAll {
            Mock -CommandName Test-Path -MockWith {
                param ($Path)
                # Return true for rebase-apply path
                return $Path -like '*rebase-apply'
            }

            Mock -CommandName Invoke-Git -MockWith {
                $global:LASTEXITCODE = 0
            }
        }

        AfterEach {
            $global:LASTEXITCODE = 0
        }

        It 'Should call Invoke-Git with correct arguments for skip' {
            $null = Resume-GitRebase -Skip -Force

            Should -Invoke -CommandName Invoke-Git -ParameterFilter {
                $Path -eq (Get-Location).Path -and $Arguments -contains 'rebase' -and $Arguments -contains '--skip'
            }
        }

        It 'Should check for rebase-apply path' {
            $null = Resume-GitRebase -Skip -Force

            Should -Invoke -CommandName Test-Path -ParameterFilter {
                $Path -like '*rebase-apply'
            }
        }
    }

    Context 'When Path parameter is specified' {
        BeforeAll {
            Mock -CommandName Test-Path -MockWith {
                param ($Path)
                return $Path -like '*custom*'
            }

            Mock -CommandName Invoke-Git -MockWith {
                $global:LASTEXITCODE = 0
            }
        }

        AfterEach {
            $global:LASTEXITCODE = 0
        }

        It 'Should pass the Path parameter to Invoke-Git' {
            $null = Resume-GitRebase -Path '/custom/path' -Force

            Should -Invoke -CommandName Invoke-Git -ParameterFilter {
                $Path -eq '/custom/path' -and $Arguments -contains 'rebase' -and $Arguments -contains '--continue'
            }
        }

        It 'Should check for rebase state in specified path' {
            $null = Resume-GitRebase -Path '/custom/path' -Force

            Should -Invoke -CommandName Test-Path -ParameterFilter {
                $Path -like '/custom/path*'
            }
        }
    }

    Context 'When the rebase operation fails' {
        BeforeAll {
            Mock -CommandName Test-Path -MockWith {
                param ($Path)
                return $Path -like '*rebase-merge'
            }

            Mock -CommandName Invoke-Git -MockWith {
                throw 'Git command failed'
            }

            $mockErrorMessage = InModuleScope -ScriptBlock {
                $script:localizedData.Resume_GitRebase_FailedRebase -f 'continue'
            }
        }

        It 'Should have a localized error message for failed rebase' {
            $mockErrorMessage | Should -Not -BeNullOrEmpty -Because 'The error message should have been localized, and shall not be empty'
        }

        It 'Should handle non-terminating error correctly' {
            Mock -CommandName Write-Error

            $null = Resume-GitRebase -Force

            Should -Invoke -CommandName Write-Error -ParameterFilter {
                $Message -eq $mockErrorMessage
            }
        }

        It 'Should throw error correctly when ErrorAction is Stop' {
            {
                Resume-GitRebase -Force -ErrorAction 'Stop'
            } | Should -Throw -ExpectedMessage $mockErrorMessage
        }

        It 'Should throw error with correct error code RGRE0002' {
            {
                Resume-GitRebase -Force -ErrorAction 'Stop'
            } | Should -Throw -ErrorId 'RGRE0002,Resume-GitRebase'
        }
    }

    Context 'When the skip operation fails' {
        BeforeAll {
            Mock -CommandName Test-Path -MockWith {
                param ($Path)
                return $Path -like '*rebase-merge'
            }

            Mock -CommandName Invoke-Git -MockWith {
                throw 'Git command failed'
            }

            $mockErrorMessage = InModuleScope -ScriptBlock {
                $script:localizedData.Resume_GitRebase_FailedRebase -f 'skip'
            }
        }

        It 'Should have a localized error message for failed skip' {
            $mockErrorMessage | Should -Not -BeNullOrEmpty -Because 'The error message should have been localized, and shall not be empty'
        }

        It 'Should handle non-terminating error correctly' {
            Mock -CommandName Write-Error

            $null = Resume-GitRebase -Skip -Force

            Should -Invoke -CommandName Write-Error -ParameterFilter {
                $Message -eq $mockErrorMessage
            }
        }

        It 'Should throw error correctly when ErrorAction is Stop' {
            {
                Resume-GitRebase -Skip -Force -ErrorAction 'Stop'
            } | Should -Throw -ExpectedMessage $mockErrorMessage
        }

        It 'Should throw error with correct error code RGRE0002' {
            {
                Resume-GitRebase -Skip -Force -ErrorAction 'Stop'
            } | Should -Throw -ErrorId 'RGRE0002,Resume-GitRebase'
        }
    }

    Context 'When using ShouldProcess' {
        BeforeAll {
            Mock -CommandName Test-Path -MockWith {
                param ($Path)
                return $Path -like '*rebase-merge'
            }

            Mock -CommandName Invoke-Git -MockWith {
                $global:LASTEXITCODE = 0
            }
        }

        AfterEach {
            $global:LASTEXITCODE = 0
        }

        It 'Should not execute rebase continue when WhatIf is specified' {
            $null = Resume-GitRebase -WhatIf

            Should -Invoke -CommandName Invoke-Git -Exactly -Times 0
        }

        It 'Should not execute rebase skip when WhatIf is specified' {
            $null = Resume-GitRebase -Skip -WhatIf

            Should -Invoke -CommandName Invoke-Git -Exactly -Times 0
        }

        It 'Should execute rebase continue when Force is specified' {
            $null = Resume-GitRebase -Force

            Should -Invoke -CommandName Invoke-Git -Exactly -Times 1
        }

        It 'Should execute rebase skip when Force is specified' {
            $null = Resume-GitRebase -Skip -Force

            Should -Invoke -CommandName Invoke-Git -Exactly -Times 1
        }
    }

    Context 'When verifying parameters' {
        It 'Should have Path parameter with default value' {
            $command = Get-Command -Name Resume-GitRebase
            $parameter = $command.Parameters['Path']

            $parameter | Should -Not -BeNullOrEmpty
            $parameter.ParameterType.Name | Should -Be 'String'
            $parameter.Attributes.Where({$_.TypeId.Name -eq 'ParameterAttribute'}).Mandatory | Should -BeFalse
        }

        It 'Should have Skip parameter as a switch' {
            $command = Get-Command -Name Resume-GitRebase
            $parameter = $command.Parameters['Skip']

            $parameter | Should -Not -BeNullOrEmpty
            $parameter.ParameterType.Name | Should -Be 'SwitchParameter'
            $parameter.Attributes.Where({$_.TypeId.Name -eq 'ParameterAttribute'}).Mandatory | Should -BeFalse
        }

        It 'Should have Force parameter as a switch' {
            $command = Get-Command -Name Resume-GitRebase
            $parameter = $command.Parameters['Force']

            $parameter | Should -Not -BeNullOrEmpty
            $parameter.ParameterType.Name | Should -Be 'SwitchParameter'
        }

        It 'Should support ShouldProcess' {
            $command = Get-Command -Name Resume-GitRebase
            $command.Parameters.ContainsKey('WhatIf') | Should -BeTrue
            $command.Parameters.ContainsKey('Confirm') | Should -BeTrue
        }
    }

    Context 'When verifying localized messages' {
        BeforeAll {
            Mock -CommandName Test-Path -MockWith {
                param ($Path)
                return $Path -like '*rebase-merge'
            }

            Mock -CommandName Invoke-Git -MockWith {
                $global:LASTEXITCODE = 0
            }
        }

        AfterEach {
            $global:LASTEXITCODE = 0
        }

        It 'Should have localized message for continue success' {
            $message = InModuleScope -ScriptBlock {
                $script:localizedData.Resume_GitRebase_Continue_Success
            }

            $message | Should -Not -BeNullOrEmpty
        }

        It 'Should have localized message for skip success' {
            $message = InModuleScope -ScriptBlock {
                $script:localizedData.Resume_GitRebase_Skip_Success
            }

            $message | Should -Not -BeNullOrEmpty
        }

        It 'Should have localized message for resuming action' {
            $message = InModuleScope -ScriptBlock {
                $script:localizedData.Resume_GitRebase_Resuming
            }

            $message | Should -Not -BeNullOrEmpty
        }

        It 'Should have localized ShouldProcess messages for continue' {
            $description = InModuleScope -ScriptBlock {
                $script:localizedData.Resume_GitRebase_Continue_ShouldProcessVerboseDescription
            }

            $warning = InModuleScope -ScriptBlock {
                $script:localizedData.Resume_GitRebase_Continue_ShouldProcessVerboseWarning
            }

            $caption = InModuleScope -ScriptBlock {
                $script:localizedData.Resume_GitRebase_Continue_ShouldProcessCaption
            }

            $description | Should -Not -BeNullOrEmpty
            $warning | Should -Not -BeNullOrEmpty
            $caption | Should -Not -BeNullOrEmpty
        }

        It 'Should have localized ShouldProcess messages for skip' {
            $description = InModuleScope -ScriptBlock {
                $script:localizedData.Resume_GitRebase_Skip_ShouldProcessVerboseDescription
            }

            $warning = InModuleScope -ScriptBlock {
                $script:localizedData.Resume_GitRebase_Skip_ShouldProcessVerboseWarning
            }

            $caption = InModuleScope -ScriptBlock {
                $script:localizedData.Resume_GitRebase_Skip_ShouldProcessCaption
            }

            $description | Should -Not -BeNullOrEmpty
            $warning | Should -Not -BeNullOrEmpty
            $caption | Should -Not -BeNullOrEmpty
        }
    }
}
