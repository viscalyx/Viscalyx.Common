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
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -ResolveDependency -Tasks build" first.'
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

Describe 'Get-PSReadLineHistory' {
    Context 'When checking command structure' {
        It 'Should have the correct parameters in parameter set <ExpectedParameterSetName>' -ForEach @(
            @{
                ExpectedParameterSetName = '__AllParameterSets'
                ExpectedParameters = '[[-Pattern] <string>] [<CommonParameters>]'
            }
        ) {
            $result = (Get-Command -Name 'Get-PSReadLineHistory').ParameterSets |
                Where-Object -FilterScript { $_.Name -eq $ExpectedParameterSetName } |
                Select-Object -Property @(
                    @{ Name = 'ParameterSetName'; Expression = { $_.Name } },
                    @{ Name = 'ParameterListAsString'; Expression = { $_.ToString() } }
                )
            $result.ParameterSetName | Should -Be $ExpectedParameterSetName
            $result.ParameterListAsString | Should -Be $ExpectedParameters
        }

        It 'Should have Pattern as an optional parameter' {
            $parameterInfo = (Get-Command -Name 'Get-PSReadLineHistory').Parameters['Pattern']
            $parameterInfo.Attributes.Mandatory | Should -BeFalse
        }
    }

    BeforeAll {
        # Mock Get-PSReadLineOption to return a custom history path
        Mock -CommandName Get-PSReadLineOption -MockWith {
            return @{
                HistorySavePath = '/mock/path/PSReadLineHistory.txt'
            }
        }

        # Mock Get-Content to return predefined history content
        Mock -CommandName Get-Content -MockWith {
            return @(
                'git status',
                'ls',
                'git commit -m "Initial commit"',
                'cd /projects',
                'git push'
            )
        }
    }

    It 'Returns the entire history when no pattern is specified' {
        $result = Get-PSReadLineHistory

        $expected = @(
            'git status',
            'ls',
            'git commit -m "Initial commit"',
            'cd /projects',
            'git push'
        )

        $result | Should-BeEquivalent $expected
    }

    It 'Returns filtered history when a pattern is specified' {
        $result = Get-PSReadLineHistory -Pattern 'git'

        <#
            The last line is always skipped by Get-PSReadLineHistory, since it's
            the `Get-PSReadLineHistory` entry.
        #>
        $expected = @(
            'git status',
            'git commit -m "Initial commit"'
        )

        $result | Should-BeEquivalent $expected
    }
}
