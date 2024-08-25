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

    .PARAMETER CheckoutOriginalBranch
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
        New-SamplerGitHubReleaseTag -CheckoutOriginalBranch

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
        $CheckoutOriginalBranch,

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

    if ($WhatIfPreference -eq $false)
    {
        Assert-GitRemote -RemoteName $UpstreamRemoteName

        Assert-GitLocalChanges
    }

    # Fetch $DefaultBranchName from upstream and throw an error if it doesn't exist.
    Update-RemoteTrackingBranch -RemoteName $UpstreamRemoteName -BranchName $DefaultBranchName

    if ($CheckoutOriginalBranch.IsPresent)
    {
        $currentLocalBranchName = Get-GitLocalBranchName -Current
    }

    $continueProcessing = $true
    $errorMessage = $null

    $verboseDescriptionMessage = $script:localizedData.New_SamplerGitHubReleaseTag_Rebase_ShouldProcessVerboseDescription -f $DefaultBranchName, $UpstreamRemoteName
    $verboseWarningMessage = $script:localizedData.New_SamplerGitHubReleaseTag_Rebase_ShouldProcessVerboseWarning -f $DefaultBranchName
    $captionMessage = $script:localizedData.New_SamplerGitHubReleaseTag_Rebase_ShouldProcessCaption

    if ($PSCmdlet.ShouldProcess($verboseDescriptionMessage, $verboseWarningMessage, $captionMessage))
    {
        Switch-GitLocalBranch -BranchName $DefaultBranchName

        $switchedToDefaultBranch = $true

        if ($continueProcessing)
        {
            git rebase $UpstreamRemoteName/$DefaultBranchName

            if ($LASTEXITCODE -ne 0) # cSpell: ignore LASTEXITCODE
            {
                $continueProcessing = $false
                $errorMessage = $script:localizedData.New_SamplerGitHubReleaseTag_FailedRebaseLocalDefaultBranch -f $DefaultBranchName, $UpstreamRemoteName
                $errorCode = 'NSGRT0005' # cspell: disable-line
            }

            if ($continueProcessing)
            {
                $headCommitId = Get-GitBranchCommit -Latest
            }
        }

        if (-not $continueProcessing)
        {
            # If something failed, revert back to the previous branch if requested.
            if ($CheckoutOriginalBranch.IsPresent -and $switchedToDefaultBranch)
            {
                Switch-GitLocalBranch -BranchName $currentLocalBranchName
            }

            $PSCmdlet.ThrowTerminatingError(
                [System.Management.Automation.ErrorRecord]::new(
                    $errorMessage,
                    $errorCode, # cspell: disable-line
                    [System.Management.Automation.ErrorCategory]::InvalidOperation,
                    $DatabaseName
                )
            )
        }
    }

    $verboseDescriptionMessage = $script:localizedData.New_SamplerGitHubReleaseTag_UpstreamTags_ShouldProcessVerboseDescription -f $UpstreamRemoteName
    $verboseWarningMessage = $script:localizedData.New_SamplerGitHubReleaseTag_UpstreamTags_ShouldProcessVerboseWarning -f $UpstreamRemoteName
    $captionMessage = $script:localizedData.New_SamplerGitHubReleaseTag_UpstreamTags_ShouldProcessCaption

    if ($PSCmdlet.ShouldProcess($verboseDescriptionMessage, $verboseWarningMessage, $captionMessage))
    {
        git fetch $UpstreamRemoteName --tags

        if ($LASTEXITCODE -ne 0)
        {
            if ($CheckoutOriginalBranch.IsPresent -and $switchedToDefaultBranch)
            {
                Switch-GitLocalBranch -BranchName $currentLocalBranchName
            }

            $PSCmdlet.ThrowTerminatingError(
                [System.Management.Automation.ErrorRecord]::new(
                    ($script:localizedData.New_SamplerGitHubReleaseTag_FailedFetchTagsFromUpstreamRemote -f $UpstreamRemoteName),
                    'NSGRT0007', # cspell: disable-line
                    [System.Management.Automation.ErrorCategory]::InvalidOperation,
                    $DatabaseName
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
            if ($CheckoutOriginalBranch.IsPresent -and $switchedToDefaultBranch)
            {
                Switch-GitLocalBranch -BranchName $currentLocalBranchName
            }

            $PSCmdlet.ThrowTerminatingError(
                [System.Management.Automation.ErrorRecord]::new(
                    $errorMessage,
                    $errorCode, # cspell: disable-line
                    [System.Management.Automation.ErrorCategory]::InvalidOperation,
                    $DatabaseName
                )
            )
        }
    }

    if ($WhatIfPreference)
    {
        $messageShouldProcess = $script:localizedData.New_SamplerGitHubReleaseTag_NewTagWhatIf_ShouldProcessVerboseDescription
    }
    else
    {
        $messageShouldProcess = $script:localizedData.New_SamplerGitHubReleaseTag_NewTag_ShouldProcessVerboseDescription
    }

    $verboseDescriptionMessage = $messageShouldProcess -f $ReleaseTag, $DefaultBranchName, $headCommitId
    $verboseWarningMessage = $script:localizedData.New_SamplerGitHubReleaseTag_NewTag_ShouldProcessVerboseWarning -f $ReleaseTag
    $captionMessage = $script:localizedData.New_SamplerGitHubReleaseTag_NewTag_ShouldProcessCaption

    if ($PSCmdlet.ShouldProcess($verboseDescriptionMessage, $verboseWarningMessage, $captionMessage))
    {
        git tag $ReleaseTag

        if ($PushTag -and ($Force -or $PSCmdlet.ShouldContinue(('Do you want to push the tags to the upstream ''{0}''?' -f $UpstreamRemoteName), 'Confirm')))
        {
            git push origin --tags

            Write-Information -MessageData ("`e[32mTag `e[1;37;44m{0}`e[0m`e[32m was created and pushed to upstream '{1}'`e[0m" -f $ReleaseTag, $UpstreamRemoteName) -InformationAction Continue
        }
        else
        {
            # cSpell: disable-next-line
            Write-Information -MessageData ("`e[32mTag `e[1;37;44m{0}`e[0m`e[32m was created. To push the tag to upstream, run `e[1;37;44mgit push {1} --tags`e[0m`e[32m.`e[0m" -f $ReleaseTag, $UpstreamRemoteName) -InformationAction Continue
        }
    }

    if ($CheckoutOriginalBranch.IsPresent)
    {
        $verboseDescriptionMessage = $script:localizedData.New_SamplerGitHubReleaseTag_SwitchBack_ShouldProcessVerboseDescription -f $currentLocalBranchName
        $verboseWarningMessage = $script:localizedData.New_SamplerGitHubReleaseTag_SwitchBack_ShouldProcessVerboseWarning -f $currentLocalBranchName
        $captionMessage = $script:localizedData.New_SamplerGitHubReleaseTag_SwitchBack_ShouldProcessCaption

        if ($PSCmdlet.ShouldProcess($verboseDescriptionMessage, $verboseWarningMessage, $captionMessage))
        {
            Switch-GitLocalBranch -BranchName $currentLocalBranchName
        }
    }
}
