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

Describe 'New-SamplerGitHubReleaseTag' {
    Context 'When checking command structure' {
        It 'Should have the correct parameters in parameter set <ExpectedParameterSetName>' -ForEach @(
            @{
                ExpectedParameterSetName = '__AllParameterSets'
                ExpectedParameters       = '[[-DefaultBranchName] <string>] [[-UpstreamRemoteName] <string>] [[-ReleaseTag] <string>] [-SwitchBackToPreviousBranch] [-Force] [-PushTag] [-WhatIf] [-Confirm] [<CommonParameters>]'
            }
        ) {
            $result = (Get-Command -Name 'New-SamplerGitHubReleaseTag').ParameterSets |
                Where-Object -FilterScript { $_.Name -eq $ExpectedParameterSetName } |
                Select-Object -Property @(
                    @{ Name = 'ParameterSetName'; Expression = { $_.Name } },
                    @{ Name = 'ParameterListAsString'; Expression = { $_.ToString() } }
                )
            $result.ParameterSetName | Should -Be $ExpectedParameterSetName
            $result.ParameterListAsString | Should -Be $ExpectedParameters
        }

        It 'Should have no mandatory parameters' {
            $mandatoryParams = (Get-Command -Name 'New-SamplerGitHubReleaseTag').Parameters.Values | Where-Object { $_.Attributes.Mandatory -eq $true }
            $mandatoryParams | Should -BeNullOrEmpty
        }
    }

    BeforeAll {
        $script:MockLastExitCode = 0

        Mock -CommandName Write-Information
    }

    BeforeEach {
        # Mock git executable. cSpell: ignore LASTEXITCODE
        Mock -CommandName 'git' -MockWith {
            Set-Variable -Name 'LASTEXITCODE' -Value $script:MockLastExitCode -Scope Global

            switch ($args[0])
            {
                'remote'
                {
                    return 'origin' # Default remote name
                }

                'rev-parse'
                {
                    if ($args[1] -eq '--abbrev-ref' -and $args[2] -eq 'HEAD')
                    {
                        return 'feature-branch' # Mocked local current branch name
                    }

                    return '3c3092976409645d74f58707331f66ffe1967127' # Commit hash
                }

                'describe'
                {
                    return 'v1.1.0-preview'
                }

                'tag'
                {
                    if ($null -eq $args[1])
                    {
                        return @('v1.0.0-preview', 'v1.1.0-preview')
                    }

                    return
                }

                default
                {
                    return
                }
            }
        }
    }

    It 'Should create a release tag using default parameters' {
        $null = New-SamplerGitHubReleaseTag -Force
    }

    It 'Should create the specified release tag' {
        $null = New-SamplerGitHubReleaseTag -ReleaseTag 'v1.0.0' -Confirm:$false
    }

    Context 'When git commands fail' {
        BeforeAll {
            $script:MockLastExitCode = 1
        }

        AfterAll {
            $script:MockLastExitCode = 0

            # Reset the LASTEXITCODE to 0 after all the tests
            Set-Variable -Name 'LASTEXITCODE' -Value $script:MockLastExitCode -Scope Global
        }

        It 'Should throw if branch does not exist' {
            $mockErrorMessage = InModuleScope -ScriptBlock {
                ($script:localizedData.New_SamplerGitHubReleaseTag_FailedFetchBranchFromRemote -f 'UnknownBranchName', 'origin')
            }

            {
                New-SamplerGitHubReleaseTag -DefaultBranchName 'UnknownBranchName' -ReleaseTag 'v1.0.0' -Force
            } | Should-Throw -ExceptionMessage $mockErrorMessage
        }

        It 'Should throw if remote does not exist' {
            $mockErrorMessage = InModuleScope -ScriptBlock {
                ($script:localizedData.New_SamplerGitHubReleaseTag_RemoteMissing -f 'UnknownRemoteName')
            }

            {
                New-SamplerGitHubReleaseTag -UpstreamRemoteName 'UnknownRemoteName' -ReleaseTag 'v1.0.0' -Force
            } | Should-Throw -ExceptionMessage $mockErrorMessage
        }
    }

    It 'Should switch back to previous branch if specified' {
        $null = New-SamplerGitHubReleaseTag -ReleaseTag 'v1.0.0' -SwitchBackToPreviousBranch -Force
    }

    It 'Should push tag to upstream if specified' {
        $null = New-SamplerGitHubReleaseTag -ReleaseTag 'v1.0.0' -PushTag -Force
    }
}
