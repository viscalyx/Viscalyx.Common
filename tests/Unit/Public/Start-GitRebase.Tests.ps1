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
Describe 'Start-GitRebase' {
    Context 'When rebasing from default remote and branch' {
        BeforeAll {
            Mock -CommandName Invoke-Git -MockWith {
                $global:LASTEXITCODE = 0
            }
        }

        AfterEach {
            $global:LASTEXITCODE = 0
        }

        It 'Should call Invoke-Git with correct arguments for default remote and branch' {
            $null = Start-GitRebase -Force

            Should -Invoke -CommandName Invoke-Git -ParameterFilter {
                $Path -eq (Get-Location).Path -and $Arguments -contains 'rebase' -and $Arguments -contains 'origin/main'
            }
        }

        It 'Should not change directory when Path is not specified' {
            Mock -CommandName Set-Location

            $null = Start-GitRebase -Force

            Should -Invoke -CommandName Set-Location -Exactly -Times 0
        }
    }

    Context 'When rebasing from custom remote and branch' {
        BeforeAll {
            Mock -CommandName Invoke-Git -MockWith {
                $global:LASTEXITCODE = 0
            }
        }

        AfterEach {
            $global:LASTEXITCODE = 0
        }

        It 'Should call Invoke-Git with correct arguments for custom remote and branch' {
            $null = Start-GitRebase -RemoteName 'upstream' -Branch 'develop' -Force

            Should -Invoke -CommandName Invoke-Git -ParameterFilter {
                $Path -eq (Get-Location).Path -and $Arguments -contains 'rebase' -and $Arguments -contains 'upstream/develop'
            }
        }
    }

    Context 'When Path parameter is specified' {
        BeforeAll {
            Mock -CommandName Invoke-Git -MockWith {
                $global:LASTEXITCODE = 0
            }
        }

        AfterEach {
            $global:LASTEXITCODE = 0
        }

        It 'Should pass the Path parameter to Invoke-Git' {
            $null = Start-GitRebase -Path '/custom/path' -Force

            Should -Invoke -CommandName Invoke-Git -ParameterFilter {
                $Path -eq '/custom/path' -and $Arguments -contains 'rebase' -and $Arguments -contains 'origin/main'
            }
        }
    }

    Context 'When the rebase operation fails' {
        BeforeAll {
            Mock -CommandName Invoke-Git -MockWith {
                throw 'Git command failed'
            }

            $mockErrorMessage = InModuleScope -ScriptBlock {
                $script:localizedData.Start_GitRebase_FailedRebase -f 'origin/main'
            }
        }

        It 'Should have a localized error message for failed rebase' {
            $mockErrorMessage | Should -Not -BeNullOrEmpty -Because 'The error message should have been localized, and shall not be empty'
        }

        It 'Should handle non-terminating error correctly' {
            Mock -CommandName Write-Error

            $null = Start-GitRebase -Force

            Should -Invoke -CommandName Write-Error -ParameterFilter {
                $Message -eq $mockErrorMessage
            }
        }

        It 'Should handle terminating error correctly' {
            {
                Start-GitRebase -Force -ErrorAction 'Stop'
            } | Should -Throw -ExpectedMessage $mockErrorMessage
        }

        It 'Should throw error with correct error code SGR0001' {
            {
                Start-GitRebase -Force -ErrorAction 'Stop'
            } | Should -Throw -ErrorId 'SGR0001,Start-GitRebase'
        }
    }

    Context 'When using ShouldProcess' {
        BeforeAll {
            Mock -CommandName Invoke-Git -MockWith {
                $global:LASTEXITCODE = 0
            }
        }

        AfterEach {
            $global:LASTEXITCODE = 0
        }

        It 'Should not execute rebase when WhatIf is specified' {
            $null = Start-GitRebase -WhatIf

            Should -Invoke -CommandName Invoke-Git -Exactly -Times 0
        }

        It 'Should execute rebase when Force is specified' {
            $null = Start-GitRebase -Force

            Should -Invoke -CommandName Invoke-Git -Exactly -Times 1
        }
    }

    Context 'When verifying parameters' {
        It 'Should have RemoteName parameter with default value of origin' {
            $command = Get-Command -Name Start-GitRebase
            $parameter = $command.Parameters['RemoteName']

            $parameter | Should -Not -BeNullOrEmpty
            $parameter.ParameterType.Name | Should -Be 'String'
            $parameter.Attributes.Where({$_.TypeId.Name -eq 'ParameterAttribute'}).Mandatory | Should -BeFalse
        }

        It 'Should have Branch parameter with default value of main' {
            $command = Get-Command -Name Start-GitRebase
            $parameter = $command.Parameters['Branch']

            $parameter | Should -Not -BeNullOrEmpty
            $parameter.ParameterType.Name | Should -Be 'String'
            $parameter.Attributes.Where({$_.TypeId.Name -eq 'ParameterAttribute'}).Mandatory | Should -BeFalse
        }

        It 'Should have Path parameter' {
            $command = Get-Command -Name Start-GitRebase
            $parameter = $command.Parameters['Path']

            $parameter | Should -Not -BeNullOrEmpty
            $parameter.ParameterType.Name | Should -Be 'String'
            $parameter.Attributes.Where({$_.TypeId.Name -eq 'ParameterAttribute'}).Mandatory | Should -BeFalse
        }

        It 'Should have Force parameter' {
            $command = Get-Command -Name Start-GitRebase
            $parameter = $command.Parameters['Force']

            $parameter | Should -Not -BeNullOrEmpty
            $parameter.ParameterType.Name | Should -Be 'SwitchParameter'
        }

        It 'Should support ShouldProcess' {
            $command = Get-Command -Name Start-GitRebase
            $command.Parameters.ContainsKey('WhatIf') | Should -BeTrue
            $command.Parameters.ContainsKey('Confirm') | Should -BeTrue
        }
    }

    Context 'When checking localization' {
        It 'Should have all required localized strings' {
            InModuleScope -ScriptBlock {
                $script:localizedData.Start_GitRebase_RebasingFrom | Should -Not -BeNullOrEmpty
                $script:localizedData.Start_GitRebase_FailedRebase | Should -Not -BeNullOrEmpty
                $script:localizedData.Start_GitRebase_Success | Should -Not -BeNullOrEmpty
                $script:localizedData.Start_GitRebase_ShouldProcessVerboseDescription | Should -Not -BeNullOrEmpty
                $script:localizedData.Start_GitRebase_ShouldProcessVerboseWarning | Should -Not -BeNullOrEmpty
                $script:localizedData.Start_GitRebase_ShouldProcessCaption | Should -Not -BeNullOrEmpty
            }
        }
    }
}
