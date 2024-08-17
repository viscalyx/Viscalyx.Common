function New-SamplerGitHubReleaseTag
{
    # TODO: Change to Medium impact once the function is stable.
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
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
        $Force
    )

    if ($Force.IsPresent -and -not $Confirm)
    {
        $ConfirmPreference = 'None'
    }

    # TODO: Check if 'main' branch exists and throw an error if it doesn't.

    # TODO: Check if 'origin' remote exists and throw an error if it doesn't.

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

        Write-Information -MessageData "`e[32mTag created, push tag to upstream by running 'git push $UpstreamRemoteName --tags'`e[0m" -InformationAction Continue
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
