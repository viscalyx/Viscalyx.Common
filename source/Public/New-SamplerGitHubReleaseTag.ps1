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

    .PARAMETER SwitchBackToPreviousBranch
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
        New-SamplerGitHubReleaseTag -SwitchBackToPreviousBranch

        Creates a new release tag and switches back to the previous branch.

    .NOTES
        This function requires Git to be installed and accessible from the command
        line.
#>
function New-SamplerGitHubReleaseTag
{
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
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
        $SwitchBackToPreviousBranch,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Force,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $PushTag
    )

    if ($Force.IsPresent -and -not $Confirm)
    {
        $ConfirmPreference = 'None'
    }

    # Check if the remote specified in $UpstreamRemoteName exists locally and throw an error if it doesn't.
    $remoteExists = git remote | Where-Object -FilterScript { $_ -eq $UpstreamRemoteName }

    if (-not $remoteExists)
    {
        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                ($script:localizedData.New_SamplerGitHubReleaseTag_RemoteMissing -f $UpstreamRemoteName),
                'NSGRT0001', # cspell: disable-line
                [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                $UpstreamRemoteName
            )
        )
    }

    $descriptionMessage = $script:localizedData.New_SamplerGitHubReleaseTag_FetchUpstream_ShouldProcessDescription -f $DefaultBranchName, $UpstreamRemoteName
    $confirmationMessage = $script:localizedData.New_SamplerGitHubReleaseTag_FetchUpstream_ShouldProcessConfirmation -f $DefaultBranchName, $UpstreamRemoteName
    $captionMessage = $script:localizedData.New_SamplerGitHubReleaseTag_FetchUpstream_ShouldProcessCaption

    if ($PSCmdlet.ShouldProcess($descriptionMessage, $confirmationMessage, $captionMessage))
    {
        # Fetch $DefaultBranchName from upstream and throw an error if it doesn't exist.
        git fetch $UpstreamRemoteName $DefaultBranchName

        if ($LASTEXITCODE -ne 0) # cSpell: ignore LASTEXITCODE
        {
            $PSCmdlet.ThrowTerminatingError(
                [System.Management.Automation.ErrorRecord]::new(
                    ($script:localizedData.New_SamplerGitHubReleaseTag_FailedFetchBranchFromRemote -f $DefaultBranchName, $UpstreamRemoteName),
                    'NSGRT0002', # cspell: disable-line
                    [System.Management.Automation.ErrorCategory]::InvalidOperation,
                    $UpstreamRemoteName
                )
            )
        }
    }

    if ($SwitchBackToPreviousBranch.IsPresent)
    {
        $currentLocalBranchName = git rev-parse --abbrev-ref HEAD

        if ($LASTEXITCODE -ne 0)
        {
            $PSCmdlet.ThrowTerminatingError(
                [System.Management.Automation.ErrorRecord]::new(
                    $script:localizedData.New_SamplerGitHubReleaseTag_FailedGetLocalBranchName,
                    'NSGRT0003', # cspell: disable-line
                    [System.Management.Automation.ErrorCategory]::InvalidOperation,
                    $null
                )
            )
        }
    }

    $continueProcessing = $true
    $errorMessage = $null

    $descriptionMessage = $script:localizedData.New_SamplerGitHubReleaseTag_Rebase_ShouldProcessDescription -f $DefaultBranchName, $UpstreamRemoteName
    $confirmationMessage = $script:localizedData.New_SamplerGitHubReleaseTag_Rebase_ShouldProcessConfirmation -f $DefaultBranchName
    $captionMessage = $script:localizedData.New_SamplerGitHubReleaseTag_Rebase_ShouldProcessCaption

    if ($PSCmdlet.ShouldProcess($descriptionMessage, $confirmationMessage, $captionMessage))
    {
        git checkout $DefaultBranchName

        if ($LASTEXITCODE -ne 0)
        {
            $continueProcessing = $false
            $errorMessage = $script:localizedData.New_SamplerGitHubReleaseTag_FailedCheckoutLocalBranch -f $DefaultBranchName
            $errorCode = 'NSGRT0004' # cspell: disable-line
        }

        # Set only after successful checkout
        if ($continueProcessing)
        {
            $switchedToDefaultBranch = $true
        }

        if ($continueProcessing)
        {
            git rebase $UpstreamRemoteName/$DefaultBranchName

            if ($LASTEXITCODE -ne 0)
            {
                $continueProcessing = $false
                $errorMessage = $script:localizedData.New_SamplerGitHubReleaseTag_FailedRebaseLocalDefaultBranch -f $DefaultBranchName, $UpstreamRemoteName
                $errorCode = 'NSGRT0005' # cspell: disable-line
            }

            if ($continueProcessing)
            {
                $headCommitId = git rev-parse HEAD

                if ($LASTEXITCODE -ne 0)
                {
                    $continueProcessing = $false
                    $errorMessage = $script:localizedData.New_SamplerGitHubReleaseTag_FailedGetLastCommitId -f $DefaultBranchName
                    $errorCode = 'NSGRT0006' # cspell: disable-line
                }
            }
        }

        if (-not $continueProcessing)
        {
            # If something failed, revert back to the previous branch if requested.
            if ($SwitchBackToPreviousBranch.IsPresent -and $switchedToDefaultBranch)
            {
                git checkout $currentLocalBranchName
            }

            $PSCmdlet.ThrowTerminatingError(
                [System.Management.Automation.ErrorRecord]::new(
                    $errorMessage,
                    $errorCode, # cspell: disable-line
                    [System.Management.Automation.ErrorCategory]::InvalidOperation,
                    $DefaultBranchName
                )
            )
        }
    }

    $descriptionMessage = $script:localizedData.New_SamplerGitHubReleaseTag_UpstreamTags_ShouldProcessDescription -f $UpstreamRemoteName
    $confirmationMessage = $script:localizedData.New_SamplerGitHubReleaseTag_UpstreamTags_ShouldProcessConfirmation -f $UpstreamRemoteName
    $captionMessage = $script:localizedData.New_SamplerGitHubReleaseTag_UpstreamTags_ShouldProcessCaption

    if ($PSCmdlet.ShouldProcess($descriptionMessage, $confirmationMessage, $captionMessage))
    {
        git fetch $UpstreamRemoteName --tags

        if ($LASTEXITCODE -ne 0)
        {
            if ($SwitchBackToPreviousBranch.IsPresent -and $switchedToDefaultBranch)
            {
                git checkout $currentLocalBranchName
            }

            $PSCmdlet.ThrowTerminatingError(
                [System.Management.Automation.ErrorRecord]::new(
                    ($script:localizedData.New_SamplerGitHubReleaseTag_FailedFetchTagsFromUpstreamRemote -f $UpstreamRemoteName),
                    'NSGRT0007', # cspell: disable-line
                    [System.Management.Automation.ErrorCategory]::InvalidOperation,
                    $UpstreamRemoteName
                )
            )
        }
    }

    if (-not $ReleaseTag)
    {
        $tagExist = git tag | Select-Object -First 1

        if ($LASTEXITCODE -ne 0 -or -not $tagExist)
        {
            $continueProcessing = $false
            $errorMessage = $script:localizedData.New_SamplerGitHubReleaseTag_FailedGetTagsOrMissingTagsInLocalRepository
            $errorCode = 'NSGRT0008' # cspell: disable-line
        }

        if ($continueProcessing)
        {
            $latestPreviewTag = git describe --tags --abbrev=0

            if ($LASTEXITCODE -ne 0)
            {
                $continueProcessing = $false
                $errorMessage = $script:localizedData.New_SamplerGitHubReleaseTag_FailedDescribeTags
                $errorCode = 'NSGRT0009' # cspell: disable-line
            }

            if ($continueProcessing)
            {
                $isCorrectlyFormattedPreviewTag = $latestPreviewTag -match '^(v\d+\.\d+\.\d+)-.*'

                if ($isCorrectlyFormattedPreviewTag)
                {
                    $ReleaseTag = $matches[1]
                }
                else
                {
                    $continueProcessing = $false
                    $errorMessage = $script:localizedData.New_SamplerGitHubReleaseTag_LatestTagIsNotPreview -f $latestPreviewTag
                    $errorCode = 'NSGRT0010' # cspell: disable-line
                }
            }
        }

        if (-not $continueProcessing)
        {
            if ($SwitchBackToPreviousBranch.IsPresent -and $switchedToDefaultBranch)
            {
                git checkout $currentLocalBranchName
            }

            $PSCmdlet.ThrowTerminatingError(
                [System.Management.Automation.ErrorRecord]::new(
                    $errorMessage,
                    $errorCode, # cspell: disable-line
                    [System.Management.Automation.ErrorCategory]::InvalidOperation,
                    $null
                )
            )
        }
    }

    if ($WhatIfPreference)
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

    if ($PSCmdlet.ShouldProcess($descriptionMessage, $confirmationMessage, $captionMessage))
    {
        git tag $ReleaseTag

        if ($LASTEXITCODE -ne 0)
        {
            $PSCmdlet.ThrowTerminatingError(
                [System.Management.Automation.ErrorRecord]::new(
                    ($script:localizedData.New_SamplerGitHubReleaseTag_FailedCreateTag -f $ReleaseTag),
                    'NSGRT0035',
                    [System.Management.Automation.ErrorCategory]::InvalidOperation,
                    $ReleaseTag
                )
            )
        }

        if ($PushTag -and ($Force -or $PSCmdlet.ShouldContinue(($script:localizedData.New_SamplerGitHubReleaseTag_PushTag_ShouldContinueMessage -f $UpstreamRemoteName), $script:localizedData.New_SamplerGitHubReleaseTag_PushTag_ShouldContinueCaption)))
        {
            $pushDescriptionMessage = $script:localizedData.New_SamplerGitHubReleaseTag_PushTag_ShouldProcessDescription -f $ReleaseTag, $UpstreamRemoteName
            $pushConfirmationMessage = $script:localizedData.New_SamplerGitHubReleaseTag_PushTag_ShouldProcessConfirmation -f $ReleaseTag, $UpstreamRemoteName
            $pushCaptionMessage = $script:localizedData.New_SamplerGitHubReleaseTag_PushTag_ShouldProcessCaption

            if ($PSCmdlet.ShouldProcess($pushDescriptionMessage, $pushConfirmationMessage, $pushCaptionMessage))
            {
                git push $UpstreamRemoteName --tags

                Write-Information -MessageData (ConvertTo-AnsiString -InputString ($script:localizedData.New_SamplerGitHubReleaseTag_TagCreatedAndPushed -f $ReleaseTag, $UpstreamRemoteName)) -InformationAction Continue
            }
        }
        else
        {
            Write-Information -MessageData (ConvertTo-AnsiString -InputString ($script:localizedData.New_SamplerGitHubReleaseTag_TagCreatedNotPushed -f $ReleaseTag, $UpstreamRemoteName)) -InformationAction Continue
        }
    }

    if ($SwitchBackToPreviousBranch.IsPresent)
    {
        $descriptionMessage = $script:localizedData.New_SamplerGitHubReleaseTag_SwitchBack_ShouldProcessDescription -f $currentLocalBranchName
        $confirmationMessage = $script:localizedData.New_SamplerGitHubReleaseTag_SwitchBack_ShouldProcessConfirmation -f $currentLocalBranchName
        $captionMessage = $script:localizedData.New_SamplerGitHubReleaseTag_SwitchBack_ShouldProcessCaption

        if ($PSCmdlet.ShouldProcess($descriptionMessage, $confirmationMessage, $captionMessage))
        {
            git checkout $currentLocalBranchName

            if ($LASTEXITCODE -ne 0)
            {
                $PSCmdlet.ThrowTerminatingError(
                    [System.Management.Automation.ErrorRecord]::new(
                        ($script:localizedData.New_SamplerGitHubReleaseTag_FailedCheckoutPreviousBranch -f $currentLocalBranchName),
                        'NSGRT0011', # cspell: disable-line
                        [System.Management.Automation.ErrorCategory]::InvalidOperation,
                        $currentLocalBranchName
                    )
                )
            }
        }
    }
}
