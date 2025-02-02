<#
    .SYNOPSIS
        The localized resource strings in English (en-US). This file should only
        contain localized strings for private functions, public command, and
        classes (that are not a DSC resource).
#>

ConvertFrom-StringData @'
    ## New-SamplerGitHubReleaseTag
    New_SamplerGitHubReleaseTag_RemoteMissing = The remote '{0}' does not exist in the local git repository. Please add the remote before proceeding.
    New_SamplerGitHubReleaseTag_FailedFetchBranchFromRemote = Failed to fetch branch '{0}' from the remote '{1}'. Make sure the branch exists in the remote git repository and the remote is accessible.
    New_SamplerGitHubReleaseTag_FailedGetLocalBranchName = Failed to get the name of the local branch. Make sure the local branch exists and is accessible.
    New_SamplerGitHubReleaseTag_FailedCheckoutLocalBranch = Failed to checkout the local branch '{0}'. Make sure the branch exists and is accessible.
    New_SamplerGitHubReleaseTag_FailedRebaseLocalDefaultBranch = Failed to rebase the local default branch '{0}' using '{1}/{0}'. Make sure the branch exists and is accessible.
    New_SamplerGitHubReleaseTag_FailedGetLastCommitId = Failed to get the last commit id of the local branch '{0}'. Make sure the branch exists and is accessible.
    New_SamplerGitHubReleaseTag_FailedFetchTagsFromUpstreamRemote = Failed to fetch tags from the upstream remote '{0}'. Make sure the remote exists and is accessible.
    New_SamplerGitHubReleaseTag_FailedGetTagsOrMissingTagsInLocalRepository = Failed to get tags from the local repository or the tags are missing. Make sure that at least one preview tag exist in the local repository, or specify a release tag.
    New_SamplerGitHubReleaseTag_FailedDescribeTags = Failed to describe the tags. Make sure the tags exist in the local repository.
    New_SamplerGitHubReleaseTag_LatestTagIsNotPreview = The latest tag '{0}' is not a preview tag or not a correctly formatted preview tag. Make sure the latest tag is a preview tag, or specify a release tag.
    New_SamplerGitHubReleaseTag_FailedCheckoutPreviousBranch = Failed to checkout the previous branch '{0}'.

    New_SamplerGitHubReleaseTag_FetchUpstream_ShouldProcessVerboseDescription = Fetching branch '{0}' from the upstream remote '{1}'.
    New_SamplerGitHubReleaseTag_FetchUpstream_ShouldProcessVerboseWarning = Are you sure you want to fetch branch '{0}' from the upstream remote '{1}'?
    # This string shall not end with full stop (.) since it is used as a title of ShouldProcess messages.
    New_SamplerGitHubReleaseTag_FetchUpstream_ShouldProcessCaption = Fetch upstream branch

    New_SamplerGitHubReleaseTag_Rebase_ShouldProcessVerboseDescription = Switching to and rebasing the local default branch '{0}' using the upstream branch '{1}/{0}'.
    New_SamplerGitHubReleaseTag_Rebase_ShouldProcessVerboseWarning = Are you sure you want switch to and rebase the local branch '{0}'?
    # This string shall not end with full stop (.) since it is used as a title of ShouldProcess messages.
    New_SamplerGitHubReleaseTag_Rebase_ShouldProcessCaption = Rebase the local default branch

    New_SamplerGitHubReleaseTag_UpstreamTags_ShouldProcessVerboseDescription = Fetching the tags from (upstream) remote '{0}'.
    New_SamplerGitHubReleaseTag_UpstreamTags_ShouldProcessVerboseWarning = Are you sure you want to fetch tags from remote '{0}'?
    # This string shall not end with full stop (.) since it is used as a title of ShouldProcess messages.
    New_SamplerGitHubReleaseTag_UpstreamTags_ShouldProcessCaption = Fetch tags from remote

    New_SamplerGitHubReleaseTag_NewTag_ShouldProcessVerboseDescription = Creating tag '{0}' for commit '{2}' in the local branch '{1}'.
    New_SamplerGitHubReleaseTag_NewTagWhatIf_ShouldProcessVerboseDescription = Creating tag for commit in the local branch '{1}'. Note: Actual tag name and commit id cannot be determine during -WhatIf.
    New_SamplerGitHubReleaseTag_NewTag_ShouldProcessVerboseWarning = Are you sure you want to create tag '{0}'?
    # This string shall not end with full stop (.) since it is used as a title of ShouldProcess messages.
    New_SamplerGitHubReleaseTag_NewTag_ShouldProcessCaption = Create tag

    New_SamplerGitHubReleaseTag_SwitchBack_ShouldProcessVerboseDescription = Switching back to previous local branch '{0}'.
    New_SamplerGitHubReleaseTag_SwitchBack_ShouldProcessVerboseWarning = Are you sure you want to switch back to previous local branch '{0}'?
    # This string shall not end with full stop (.) since it is used as a title of ShouldProcess messages.
    New_SamplerGitHubReleaseTag_SwitchBack_ShouldProcessCaption = Switch to previous branch
'@
