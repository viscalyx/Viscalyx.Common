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
                & "$PSScriptRoot/../../../build.ps1" -Tasks 'noop' 2>&1 4>&1 5>&1 6>&1 > $null
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
    $script:dscModuleName = 'Viscalyx.Common'

    Import-Module -Name $script:dscModuleName

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

Describe 'New-SamplerGitHubReleaseTag' {
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
        { New-SamplerGitHubReleaseTag -Force } | Should -Not -Throw
    }

    It 'Should create the specified release tag' {
        { New-SamplerGitHubReleaseTag -ReleaseTag 'v1.0.0' -Confirm:$false } | Should -Not -Throw
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
        { New-SamplerGitHubReleaseTag -ReleaseTag 'v1.0.0' -ReturnToCurrentBranch -Force } | Should -Not -Throw
    }

    It 'Should push tag to upstream if specified' {
        { New-SamplerGitHubReleaseTag -ReleaseTag 'v1.0.0' -PushTag -Force } | Should -Not -Throw
    }
}
