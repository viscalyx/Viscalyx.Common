<#
    .SYNOPSIS
        Creates a new GitHub release tag for the Sampler project.

    .DESCRIPTION
        The New-SamplerGitHubReleaseTag function creates a new release tag for the
        Sampler project on GitHub. It performs the following steps:

        1. Checks if the 'main' branch exists and throws an error if it doesn't.
        2. Checks if the 'origin' remote exists and throws an error if it doesn't.
        3. Optionally switches back to the previous branch.
        4. Checks out the 'main' branch.
        5. Fetches the 'main' branch from the 'origin' remote.
        6. Rebases the local 'main' branch with the 'origin/main' branch.
        7. Gets the last commit ID of the 'main' branch.
        8. Fetches tags from the 'origin' remote.
        9. If no release tag is specified, it checks if there are any tags in the local repository and selects the latest preview tag.
        10. Creates a new tag with the specified release tag.
        11. Optionally pushes the tag to the 'origin' remote.
        12. Switches back to the previous branch if requested.

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
        throw "Remote '$UpstreamRemoteName' does not exist in the local git repository."
    }

    # Fetch $DefaultBranchName from upstream and throw an error if it doesn't exist.
    git fetch $UpstreamRemoteName $DefaultBranchName

    if ($LASTEXITCODE -ne 0)
    {
        throw "Branch '$DefaultBranchName' does not exist in the upstream remote '$UpstreamRemoteName'."
    }

    if ($SwitchBackToPreviousBranch.IsPresent)
    {
        $currentLocalBranchName = git rev-parse --abbrev-ref HEAD

        if ($LASTEXITCODE -ne 0)
        {
            # cSpell: ignore LASTEXITCODE
            throw 'Failed to fetch the name of the current branch.'
        }
    }

    $previousCommandFailed = $false
    $errorMessage = $null

    $verboseDescriptionMessage = $script:localizedData.New_SamplerGitHubReleaseTag_Rebase_ShouldProcessVerboseDescription -f $DefaultBranchName
    $verboseWarningMessage = $script:localizedData.New_SamplerGitHubReleaseTag_Rebase_ShouldProcessVerboseWarning -f $DefaultBranchName
    $captionMessage = $script:localizedData.New_SamplerGitHubReleaseTag_Rebase_ShouldProcessCaption

    if ($PSCmdlet.ShouldProcess($verboseDescriptionMessage, $verboseWarningMessage, $captionMessage))
    {
        $previousCommandFailed = $false

        git checkout $DefaultBranchName

        if ($LASTEXITCODE -ne 0)
        {
            $previousCommandFailed = $true
            $errorMessage = "Failed to checkout branch $DefaultBranchName. Make sure the branch exists in the local git repository."
        }

        $switchedToDefaultBranch = $true

        if (-not $previousCommandFailed)
        {
            git fetch $UpstreamRemoteName $DefaultBranchName

            if ($LASTEXITCODE -ne 0)
            {
                $previousCommandFailed = $true
                $errorMessage = "Failed to fetch branch $DefaultBranchName from $UpstreamRemoteName. Make sure the branch exists in the remote git repository and there is a remote named $UpstreamRemoteName."
            }

            if (-not $previousCommandFailed)
            {
                git rebase $UpstreamRemoteName/$DefaultBranchName

                if ($LASTEXITCODE -ne 0)
                {
                    $previousCommandFailed = $true
                    $errorMessage = "Failed to rebase local branch $DefaultBranchName with $UpstreamRemoteName/$DefaultBranchName"
                }

                if (-not $previousCommandFailed)
                {
                    $headCommitId = git rev-parse HEAD

                    if ($LASTEXITCODE -ne 0)
                    {
                        $previousCommandFailed = $true
                        $errorMessage = "Failed to get the last commit ID of the branch '$DefaultBranchName'."
                    }
                }
            }
        }

        if ($previousCommandFailed)
        {
            if ($SwitchBackToPreviousBranch.IsPresent -and $switchedToDefaultBranch)
            {
                git checkout $currentLocalBranchName
            }

            throw $errorMessage
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
            if ($SwitchBackToPreviousBranch.IsPresent -and $switchedToDefaultBranch)
            {
                git checkout $currentLocalBranchName
            }

            throw "Failed to fetch tags from $UpstreamRemoteName."
        }
    }

    if (-not $ReleaseTag)
    {
        $previousCommandFailed = $false

        $tagExist = git tag  | Select-Object -First 1

        if ($LASTEXITCODE -ne 0 -or -not $tagExist)
        {
            $previousCommandFailed = $true
            $errorMessage = 'Either failed to list tags or no tags were found in the local repository. Please specify a release tag.'
        }

        if (-not $previousCommandFailed)
        {
            $latestPreviewTag = git describe --tags --abbrev=0

            if ($LASTEXITCODE -ne 0)
            {
                $previousCommandFailed = $true
                $errorMessage = 'Failed to describe tags.'
            }

            if (-not $previousCommandFailed)
            {
                $isCorrectlyFormattedPreviewTag = $latestPreviewTag -match '^(v\d+\.\d+\.\d+)-.*'

                if ($isCorrectlyFormattedPreviewTag)
                {
                    $ReleaseTag = $matches[1]
                }
                else
                {
                    $previousCommandFailed = $true
                    $errorMessage = 'Latest tag ''{0}'' is not a preview tag or not a correctly formatted preview tag.' -f $latestPreviewTag
                }
            }
        }

        if ($previousCommandFailed)
        {
            if ($SwitchBackToPreviousBranch.IsPresent -and $switchedToDefaultBranch)
            {
                git checkout $currentLocalBranchName
            }

            throw $errorMessage
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

    if ($SwitchBackToPreviousBranch.IsPresent)
    {
        $verboseDescriptionMessage = $script:localizedData.New_SamplerGitHubReleaseTag_SwitchBack_ShouldProcessVerboseDescription -f $currentLocalBranchName
        $verboseWarningMessage = $script:localizedData.New_SamplerGitHubReleaseTag_SwitchBack_ShouldProcessVerboseWarning -f $currentLocalBranchName
        $captionMessage = $script:localizedData.New_SamplerGitHubReleaseTag_SwitchBack_ShouldProcessCaption

        if ($PSCmdlet.ShouldProcess($verboseDescriptionMessage, $verboseWarningMessage, $captionMessage))
        {
            git checkout $currentLocalBranchName

            if ($LASTEXITCODE -ne 0)
            {
                throw 'Failed to checkout the previous local branch.'
            }
        }
    }
}
