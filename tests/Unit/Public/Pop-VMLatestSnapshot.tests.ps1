[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
param ()

BeforeDiscovery {
    try
    {
        if (-not (Get-Module -Name 'DscResource.Test'))
        {
            # Assumes dependencies has been resolved, so if this module is not available, run 'noop' task.
            if (-not (Get-Module -Name 'DscResource.Test' -ListAvailable))
            {
                # Redirect all streams to $null, except the error stream (stream 2)
                & "$PSScriptRoot/../../../build.ps1" -Tasks 'noop' 3>&1 4>&1 5>&1 6>&1 > $null
            }

            # If the dependencies has not been resolved, this will throw an error.
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

    Import-Module -Name $script:moduleName

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

Describe 'Pop-VMLatestSnapShot' {
    BeforeAll {
        # Setting up stubs for Hyper-V commands.
        InModuleScope -ScriptBlock {
            function script:Get-VM
            {
                [CmdletBinding()]
                param
                (
                    [Parameter()]
                    [System.String]
                    $Name
                )
            }

            function script:Get-Snapshot {}
            function script:Set-VM
            {
                [CmdletBinding()]
                param
                (
                    [Parameter(ValueFromPipeline = $true)]
                    [System.String]
                    $Name,

                    [Parameter()]
                    [System.String]
                    $VM
                )
            }

            function script:Start-VM {}
        }

        Mock -CommandName Get-VM -MockWith {
            return @{
                Name = $ServerName
            }
        }

        Mock -CommandName Get-Snapshot -MockWith {
            return @{
                IsCurrent = $true
            }
        }

        Mock -CommandName Set-VM -MockWith {
            return @{
                VM = $ServerName
            }
        }

        Mock -CommandName Start-VM
    }

    It 'Should call the correct mock with the correct ServerName' {
        Pop-VMLatestSnapShot -ServerName 'VM1'

        Should -Invoke -CommandName Get-VM -ParameterFilter {
            $Name -eq 'VM1'
        } -Exactly -Times 1 -Scope It

        Should -Invoke -CommandName Get-Snapshot -Exactly -Times 1 -Scope It

        Should -Invoke -CommandName Set-VM -ParameterFilter {
            $VM -eq 'VM1'
        } -Exactly -Times 1 -Scope It

        Should -Invoke -CommandName Start-VM -Exactly -Times 1 -Scope It
    }
}

