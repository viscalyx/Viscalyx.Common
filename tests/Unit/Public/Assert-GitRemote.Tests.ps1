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

Describe 'Assert-GitRemote' {
    Context 'When checking parameter sets' {
        It 'Should have the correct parameters in parameter set <ExpectedParameterSetName>' -ForEach @(
            @{
                ExpectedParameterSetName = '__AllParameterSets'
                ExpectedParameters = '[-Name] <string> [<CommonParameters>]'
            }
        ) {
            $result = (Get-Command -Name 'Assert-GitRemote').ParameterSets |
                Where-Object -FilterScript { $_.Name -eq $ExpectedParameterSetName } |
                Select-Object -Property @(
                    @{ Name = 'ParameterSetName'; Expression = { $_.Name } },
                    @{ Name = 'ParameterListAsString'; Expression = { $_.ToString() } }
                )

            $result.ParameterSetName | Should -Be $ExpectedParameterSetName
            $result.ParameterListAsString | Should -Be $ExpectedParameters
        }
    }

    Context 'When the remote exists' {
        BeforeAll {
            Mock -CommandName 'Test-GitRemote' -MockWith {
                return $true
            }
        }

        It 'Should not throw an exception' {
            $null = Assert-GitRemote -Name 'origin'
        }

        It 'Should call Test-GitRemote once' {
            Assert-GitRemote -Name 'origin'

            Should -Invoke -CommandName 'Test-GitRemote' -ParameterFilter { $Name -eq 'origin' } -Exactly -Times 1
        }
    }

    Context 'When the remote does not exist' {
        BeforeAll {
            Mock -CommandName 'Test-GitRemote' -MockWith {
                return $false
            }

            $script:mockLocalizedData = InModuleScope -ScriptBlock {
                $script:localizedData
            }
        }

        It 'Should throw a terminating error with the correct message' {
            $expectedMessage = $script:mockLocalizedData.Assert_GitRemote_RemoteMissing -f 'origin'

            { Assert-GitRemote -Name 'origin' } | Should -Throw -ExpectedMessage $expectedMessage
        }

        It 'Should throw a terminating error with the correct error ID' {
            try {
                Assert-GitRemote -Name 'origin'
            }
            catch {
                $_.FullyQualifiedErrorId | Should -Be 'AGR0001,Assert-GitRemote'
            }
        }

        It 'Should throw a terminating error with the correct error category' {
            try {
                Assert-GitRemote -Name 'origin'
            }
            catch {
                $_.CategoryInfo.Category | Should -Be 'ObjectNotFound'
            }
        }

        It 'Should throw a terminating error with the correct target object' {
            try {
                Assert-GitRemote -Name 'origin'
            }
            catch {
                $_.TargetObject | Should -Be 'origin'
            }
        }

        It 'Should call Test-GitRemote once' {
            try {
                Assert-GitRemote -Name 'origin'
            }
            catch {
                # Expected to throw, ignore the error
            }

            Should -Invoke -CommandName 'Test-GitRemote' -ParameterFilter { $Name -eq 'origin' } -Exactly -Times 1
        }
    }

    Context 'When validating output type' {
        It 'Should have OutputType of [void]' {
            $commandInfo = Get-Command -Name 'Assert-GitRemote'
            $outputType = $commandInfo.OutputType.Name

            $outputType | Should -BeNullOrEmpty
        }
    }

    Context 'When testing different remote names' {
        BeforeAll {
            Mock -CommandName 'Test-GitRemote' -MockWith {
                return $true
            }
        }

        It 'Should work with remote name <RemoteName>' -ForEach @(
            @{ RemoteName = 'origin' }
            @{ RemoteName = 'upstream' }
            @{ RemoteName = 'fork' }
            @{ RemoteName = 'my-remote' }
        ) {
            $null = Assert-GitRemote -Name $RemoteName

            Should -Invoke -CommandName 'Test-GitRemote' -ParameterFilter { $Name -eq $RemoteName } -Exactly -Times 1
        }
    }
}