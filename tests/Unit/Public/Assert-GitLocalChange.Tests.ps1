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

Describe 'Assert-GitLocalChange' {
    Context 'When checking parameter sets' {
        It 'Should have the correct parameters in parameter set <ExpectedParameterSetName>' -ForEach @(
            @{
                ExpectedParameterSetName = '__AllParameterSets'
                ExpectedParameters       = '[<CommonParameters>]'
            }
        ) {
            $result = (Get-Command -Name 'Assert-GitLocalChange').ParameterSets |
                Where-Object -FilterScript { $_.Name -eq $ExpectedParameterSetName } |
                Select-Object -Property @(
                    @{ Name = 'ParameterSetName'; Expression = { $_.Name } },
                    @{ Name = 'ParameterListAsString'; Expression = { $_.ToString() } }
                )

            $result.ParameterSetName | Should -Be $ExpectedParameterSetName
            $result.ParameterListAsString | Should -Be $ExpectedParameters
        }
    }

    Context 'When there are no local changes' {
        BeforeAll {
            Mock -CommandName 'Test-GitLocalChanges' -MockWith {
                return $false
            }
        }

        It 'Should not throw an exception' {
            $null = Assert-GitLocalChange
        }

        It 'Should call Test-GitLocalChanges once' {
            Assert-GitLocalChange

            Should -Invoke -CommandName 'Test-GitLocalChanges' -Exactly -Times 1
        }
    }

    Context 'When there are local changes' {
        BeforeAll {
            Mock -CommandName 'Test-GitLocalChanges' -MockWith {
                return $true
            }

            $script:mockLocalizedData = InModuleScope -ScriptBlock {
                $script:localizedData
            }
        }

        It 'Should throw a terminating error with the correct message' {
            { Assert-GitLocalChange } | Should -Throw -ExpectedMessage $script:mockLocalizedData.Assert_GitLocalChanges_FailedUnstagedChanges
        }

        It 'Should throw a terminating error with the correct error ID' {
            try
            {
                Assert-GitLocalChange
            }
            catch
            {
                $_.FullyQualifiedErrorId | Should -Be 'AGLC0001,Assert-GitLocalChange'
            }
        }

        It 'Should throw a terminating error with the correct error category' {
            try
            {
                Assert-GitLocalChange
            }
            catch
            {
                $_.CategoryInfo.Category | Should -Be 'InvalidResult'
            }
        }

        It 'Should call Test-GitLocalChanges once' {
            try
            {
                Assert-GitLocalChange
            }
            catch
            {
                # Expected to throw, ignore the error
            }

            Should -Invoke -CommandName 'Test-GitLocalChanges' -Exactly -Times 1
        }
    }

    Context 'When validating output type' {
        It 'Should have OutputType of [void]' {
            $commandInfo = Get-Command -Name 'Assert-GitLocalChange'
            $outputType = $commandInfo.OutputType.Name

            $outputType | Should -BeNullOrEmpty
        }
    }
}
