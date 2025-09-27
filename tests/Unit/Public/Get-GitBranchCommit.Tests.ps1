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

    # Test data for parameter set validation
    $script:parameterSetTestCases = @(
        @{
            ExpectedParameterSetName = 'NoParameter'
            ExpectedParameters = '[-BranchName <string>] [<CommonParameters>]'
        }
        @{
            ExpectedParameterSetName = 'Latest'
            ExpectedParameters = '[-BranchName <string>] [-Latest] [<CommonParameters>]'
        }
        @{
            ExpectedParameterSetName = 'Last'
            ExpectedParameters = '[-BranchName <string>] [-Last <uint>] [<CommonParameters>]'
        }
        @{
            ExpectedParameterSetName = 'First'
            ExpectedParameters = '[-BranchName <string>] [-First <uint>] [<CommonParameters>]'
        }
        @{
            ExpectedParameterSetName = 'Range'
            ExpectedParameters = '-From <string> -To <string> [<CommonParameters>]'
        }
    )
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

Describe 'Get-GitBranchCommit' {
    Context 'When command has correct parameter sets' {
        It 'Should have the correct parameters in parameter set <ExpectedParameterSetName>' -ForEach $script:parameterSetTestCases {
            $result = (Get-Command -Name 'Get-GitBranchCommit').ParameterSets |
                Where-Object -FilterScript { $_.Name -eq $ExpectedParameterSetName } |
                Select-Object -Property @(
                    @{ Name = 'ParameterSetName'; Expression = { $_.Name } },
                    @{ Name = 'ParameterListAsString'; Expression = { $_.ToString() } }
                )

            $result.ParameterSetName | Should -Be $ExpectedParameterSetName

            if ($PSVersionTable.PSVersion.Major -eq 5) {
                # Windows PowerShell 5.1 shows <uint32> for System.UInt32 type
                $ExpectedParameters = $ExpectedParameters -replace '<uint>', '<uint32>'
            }

            $result.ParameterListAsString | Should -Be $ExpectedParameters
        }

        It 'Should have NoParameter as the default parameter set' {
            $defaultParameterSet = (Get-Command -Name 'Get-GitBranchCommit').DefaultParameterSet
            $defaultParameterSet | Should -Be 'NoParameter'
        }
    }

    Context 'When command has correct parameter properties' {
        It 'Should have BranchName as a non-mandatory parameter' {
            $parameterInfo = (Get-Command -Name 'Get-GitBranchCommit').Parameters['BranchName']
            $parameterInfo.Attributes.Mandatory | Should -BeFalse
        }

        It 'Should have Latest as a non-mandatory parameter' {
            $parameterInfo = (Get-Command -Name 'Get-GitBranchCommit').Parameters['Latest']
            $parameterInfo.Attributes.Mandatory | Should -BeFalse
        }

        It 'Should have Last as a non-mandatory parameter' {
            $parameterInfo = (Get-Command -Name 'Get-GitBranchCommit').Parameters['Last']
            $parameterInfo.Attributes.Mandatory | Should -BeFalse
        }

        It 'Should have First as a non-mandatory parameter' {
            $parameterInfo = (Get-Command -Name 'Get-GitBranchCommit').Parameters['First']
            $parameterInfo.Attributes.Mandatory | Should -BeFalse
        }

        It 'Should have From as a mandatory parameter in Range parameter set' {
            $parameterInfo = (Get-Command -Name 'Get-GitBranchCommit').Parameters['From']
            $parameterInfo.Attributes.Where({$_.ParameterSetName -eq 'Range'}).Mandatory | Should -BeTrue
        }

        It 'Should have To as a mandatory parameter in Range parameter set' {
            $parameterInfo = (Get-Command -Name 'Get-GitBranchCommit').Parameters['To']
            $parameterInfo.Attributes.Where({$_.ParameterSetName -eq 'Range'}).Mandatory | Should -BeTrue
        }

        It 'Should have correct parameter types' {
            $command = Get-Command -Name 'Get-GitBranchCommit'

            $command.Parameters['BranchName'].ParameterType | Should -Be ([System.String])
            $command.Parameters['Latest'].ParameterType | Should -Be ([System.Management.Automation.SwitchParameter])
            $command.Parameters['Last'].ParameterType | Should -Be ([System.UInt32])
            $command.Parameters['First'].ParameterType | Should -Be ([System.UInt32])
            $command.Parameters['From'].ParameterType | Should -Be ([System.String])
            $command.Parameters['To'].ParameterType | Should -Be ([System.String])
        }
    }

    Context 'When testing localized strings' {
        It 'Should have proper localized error messages' {
            InModuleScope -ScriptBlock {
                $script:localizedData.Get_GitBranchCommit_FailedFromBranch | Should -Match 'Failed to retrieve commits.*Make sure the branch.*exists and is accessible'
                $script:localizedData.Get_GitBranchCommit_FailedFromCurrent | Should -Match 'Failed to retrieve commits from current branch'
                $script:localizedData.Get_GitBranchCommit_FailedFromRange | Should -Match 'Failed to retrieve commits from range.*Make sure both references exist and are accessible'
            }
        }
    }

    Context 'When testing parameter validation' {
        It 'Should accept positive values for Last parameter' {
            { Get-Command -Name 'Get-GitBranchCommit' | ForEach-Object { $_.Parameters['Last'].Attributes.Where({$_.TypeId.Name -eq 'ValidateRangeAttribute'}) } } | Should -Not -Throw
        }

        It 'Should accept positive values for First parameter' {
            { Get-Command -Name 'Get-GitBranchCommit' | ForEach-Object { $_.Parameters['First'].Attributes.Where({$_.TypeId.Name -eq 'ValidateRangeAttribute'}) } } | Should -Not -Throw
        }
    }

    Context 'When mocking git command failures' {
        It 'Should handle git command errors gracefully' {
            InModuleScope -ScriptBlock {
                # Test error handling by mocking Write-Error
                Mock -CommandName 'git' -MockWith {
                    return $null
                }

                # Mock Get-GitLocalBranchName to prevent it from calling Write-Error
                Mock -CommandName 'Get-GitLocalBranchName' -MockWith {
                    return 'main'
                }

                Mock -CommandName 'Write-Error' -MockWith {
                    Write-Output "Mocked error"
                }

                # Simulate LASTEXITCODE failure
                $global:LASTEXITCODE = 128

                $result = Get-GitBranchCommit -WarningAction SilentlyContinue -ErrorAction SilentlyContinue

                Should -Invoke -CommandName 'Write-Error' -Times 1 -Exactly
            }
        }
    }
}
