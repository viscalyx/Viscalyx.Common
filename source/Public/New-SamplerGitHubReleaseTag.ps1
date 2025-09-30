<#
    .SYNOPSIS
        Creates a new GitHub release tag for the Sampler project.

    .DESCRIPTION
        The New-SamplerGitHubReleaseTag function creates a new release tag for the
        Sampler project on GitHub. It performs the following steps:

        1. Checks if the remote specified in $UpstreamRemoteName exists locally and throws an error if it doesn't.
        2. Fetches the $DefaultBranchName branch from the $UpstreamRemoteName remote and throws an error if it doesn't exist.
        3. Checks out the $DefaultBranchName branch.
        4. Fetches the $DefaultBranchName branch from the $UpstreamRemoteName remote.
        5. Rebases the local $DefaultBranchName branch with the $UpstreamRemoteName/$DefaultBranchName branch.
        6. Gets the last commit ID of the $DefaultBranchName branch.
        7. Fetches tags from the $UpstreamRemoteName remote.
        8. If no release tag is specified, it checks if there are any tags in the local repository and selects the latest preview tag.
        9. Creates a new tag with the specified release tag or based on the latest preview tag.
        10. Optionally pushes the tag to the $UpstreamRemoteName remote.
        11. Switches back to the previous branch if requested.

    .PARAMETER DefaultBranchName
        Specifies the name of the default branch. Default value is 'main'.

    .PARAMETER UpstreamRemoteName
        Specifies the name of the upstream remote. Default value is 'origin'.

    .PARAMETER ReleaseTag
        Specifies the release tag to create. Must be in the format 'vX.X.X'. If
        not specified, the latest preview tag will be used.

    .PARAMETER ReturnToCurrentBranch
        Specifies that the command should switches back to the previous branch after
        creating the release tag.

    .PARAMETER Force
        Specifies that the command should run without prompting for confirmation.

    .PARAMETER PushTag
        Specifies that the tag should also be pushed to the upstream remote after
        creating it. This will always ask for confirmation before pushing the tag,
        unless Force is also specified.

    .EXAMPLE
        New-SamplerGitHubReleaseTag -ReleaseTag 'v1.0.0' -PushTag

        Creates a new release tag with the specified tag 'v1.0.0' and pushes it
        to the 'origin' remote.

    .EXAMPLE
        New-SamplerGitHubReleaseTag -ReturnToCurrentBranch

        Creates a new release tag and switches back to the previous branch.

    .INPUTS
        None

        This function does not accept values over the pipeline.

    .OUTPUTS
        None

        This function does not return any objects.
#>
function New-SamplerGitHubReleaseTag
{
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType()]
    param
    (
        [Parameter()]
        [System.String]
        $DefaultBranchName = 'main',

        [Parameter()]
        [System.String]
        $UpstreamRemoteName = 'origin',

        [Parameter()]
        [System.String]
        [ValidatePattern('^v\d+\.\d+\.\d+$')]
        $ReleaseTag,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $ReturnToCurrentBranch,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $PushTag,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Force
    )

    if ($Force.IsPresent -and -not $Confirm)
    {
        $ConfirmPreference = 'None'
    }

    # Only check assertions if not in WhatIf mode.
    if (-not $WhatIfPreference)
    {
        Assert-GitRemote -Name $UpstreamRemoteName -Verbose:$VerbosePreference -ErrorAction 'Stop'
    }

    $currentLocalBranchName = Get-GitLocalBranchName -Current -Verbose:$VerbosePreference -ErrorAction 'Stop'

    if ($DefaultBranchName -ne $currentLocalBranchName)
    {
        # This command will also assert that there are no local changes if not in WhatIf mode.
        Switch-GitLocalBranch -Name $DefaultBranchName -Verbose:$VerbosePreference -ErrorAction 'Stop'

        $switchedBranch = $true
    }

    try
    {
        Update-GitLocalBranch -Rebase -SkipSwitchingBranch -RemoteName $UpstreamRemoteName -BranchName $DefaultBranchName -Verbose:$VerbosePreference -ErrorAction 'Stop'

        $headCommitId = Get-GitBranchCommit -Latest -Verbose:$VerbosePreference -ErrorAction 'Stop'
    }
    catch
    {
        # If something failed, revert back to the previous branch if requested.
        if ($ReturnToCurrentBranch.IsPresent -and $switchedBranch)
        {
            # This command will also assert that there are no local changes if not in WhatIf mode.
            Switch-GitLocalBranch -Name $currentLocalBranchName -Verbose:$VerbosePreference -ErrorAction 'Stop'
        }

        $PSCmdlet.ThrowTerminatingError($_)
    }

    try
    {
        # Fetch all tags from the upstream remote.
        Request-GitTag -RemoteName $UpstreamRemoteName -Force:$Force -Verbose:$VerbosePreference -ErrorAction 'Stop'
    }
    catch
    {
        if ($ReturnToCurrentBranch.IsPresent -and $switchedBranch)
        {
            Switch-GitLocalBranch -Name $currentLocalBranchName -Verbose:$VerbosePreference -ErrorAction 'Stop'
        }

        $PSCmdlet.ThrowTerminatingError($_)
    }

    <#
        We cannot reliably determine during WhatIf if the current latest tag is
        the actual latest preview tag. So this section is skipped during WhatIf.
    #>
    if (-not $PSBoundParameters.ContainsKey('ReleaseTag') -and -not $WhatIfPreference)
    {
        try
        {
            $latestTag = Get-GitTag -Latest -Verbose:$VerbosePreference -ErrorAction 'Stop'

            if (-not $latestTag)
            {
                $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                    [System.InvalidOperationException]::new($script:localizedData.New_SamplerGitHubReleaseTag_MissingTagsInLocalRepository),
                    'NSGRT0032', # cspell: disable-line
                    [System.Management.Automation.ErrorCategory]::InvalidOperation,
                    'tag'
                )

                $PSCmdlet.ThrowTerminatingError($errorRecord)
            }

            $isCorrectlyFormattedPreviewTag = $latestTag -match '^(v\d+\.\d+\.\d+)-.*'

            if ($isCorrectlyFormattedPreviewTag)
            {
                $ReleaseTag = $matches[1]
            }
            else
            {
                $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                    [System.InvalidOperationException]::new(($script:localizedData.New_SamplerGitHubReleaseTag_LatestTagIsNotPreview -f $latestTag)),
                    'NSGRT0010', # cspell: disable-line
                    [System.Management.Automation.ErrorCategory]::InvalidOperation,
                    $latestTag
                )

                $PSCmdlet.ThrowTerminatingError($errorRecord)
            }
        }
        catch
        {
            if ($ReturnToCurrentBranch.IsPresent -and $switchedBranch)
            {
                Switch-GitLocalBranch -Name $currentLocalBranchName -Verbose:$VerbosePreference -ErrorAction 'Stop'
            }

            $PSCmdlet.ThrowTerminatingError($_)
        }
    }

    if ($WhatIfPreference -and -not $ReleaseTag)
    {
        $messageShouldProcess = $script:localizedData.New_SamplerGitHubReleaseTag_NewTagWhatIf_ShouldProcessDescription
    }
    else
    {
        $messageShouldProcess = $script:localizedData.New_SamplerGitHubReleaseTag_NewTag_ShouldProcessDescription
    }

    $descriptionMessage = $messageShouldProcess -f $ReleaseTag, $DefaultBranchName, $headCommitId
    $confirmationMessage = $script:localizedData.New_SamplerGitHubReleaseTag_NewTag_ShouldProcessConfirmation -f $ReleaseTag
    $captionMessage = $script:localizedData.New_SamplerGitHubReleaseTag_NewTag_ShouldProcessCaption

    # If ReleaseTag is specified and in WhatIf mode then we can skip ShouldProcess and let each individual command handle it.
    if (($WhatIfPreference -and $PSBoundParameters.ContainsKey('ReleaseTag')) -or $PSCmdlet.ShouldProcess($descriptionMessage, $confirmationMessage, $captionMessage))
    {
        try
        {
            <#
                Already asked if the user wants to create the tag, so we use Force
                to avoid asking again when creating the tag.
            #>
            New-GitTag -Name $ReleaseTag -Force -Verbose:$VerbosePreference -ErrorAction 'Stop'

            if ($PushTag.IsPresent)
            {
                Push-GitTag -RemoteName $UpstreamRemoteName -Name $ReleaseTag -Force:$Force -Verbose:$VerbosePreference -ErrorAction 'Stop'

                if (-not $WhatIfPreference)
                {
                    Write-Information -MessageData (ConvertTo-AnsiString -InputString ($script:localizedData.New_SamplerGitHubReleaseTag_TagCreatedAndPushed -f $ReleaseTag, $UpstreamRemoteName)) -InformationAction Continue
                }
            }
            else
            {
                if (-not $WhatIfPreference)
                {
                    # cSpell: disable-next-line
                    Write-Information -MessageData (ConvertTo-AnsiString -InputString ($script:localizedData.New_SamplerGitHubReleaseTag_TagCreatedNotPushed -f $ReleaseTag, $UpstreamRemoteName)) -InformationAction Continue
                }
            }
        }
        catch
        {
            if ($ReturnToCurrentBranch.IsPresent -and $switchedBranch)
            {
                Switch-GitLocalBranch -Name $currentLocalBranchName -Verbose:$VerbosePreference -ErrorAction 'Stop'
            }

            $PSCmdlet.ThrowTerminatingError($_)
        }
    }

    if ($ReturnToCurrentBranch.IsPresent -and $switchedBranch)
    {
        Switch-GitLocalBranch -Name $currentLocalBranchName -Verbose:$VerbosePreference -ErrorAction 'Stop'
    }
}
