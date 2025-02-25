<#
    .SYNOPSIS
        The localized resource strings in English (en-US). This file should only
        contain localized strings for private functions, public command, and
        classes (that are not a DSC resource).
#>

# cSpell: ignore unstaged
ConvertFrom-StringData @'
    ## Assert-GitLocalChange
    Assert_GitLocalChanges_FailedUnstagedChanges = There are unstaged or staged changes. Please commit or stash your changes before proceeding.

    ## Get-GitLocalBranchName
    Get_GitLocalBranchName_Failed = Failed to get the name of the local branch. Make sure git repository is accessible.

    ## Get-GitBranchCommit
    Get_GitBranchCommit_FailedFromBranch = Failed to retrieve commits. Make sure the branch '{0}' exists and is accessible.
    Get_GitBranchCommit_FailedFromCurrent = Failed to retrieve commits from current branch.

    ## Get-GitRemote
    Get_GitRemote_Failed = Failed to get the remote '{0}'. Make sure the remote exists and is accessible.

    ## Get-GitRemoteBranch
    Get_GitRemoteBranch_Failed = Failed to get the remote branches'. Make sure the remote branch exists and is accessible.
    Get_GitRemoteBranch_FromRemote_Failed = Failed to get the remote branches from remote '{0}'. Make sure the remote branch exists and is accessible.
    Get_GitRemoteBranch_ByName_Failed = Failed to get the remote branch '{0}' using the remote '{1}'. Make sure the remote branch exists and is accessible.

    ## Get-GitTag
    Get_GitTag_FailedToGetTag = Failed to get the tag '{0}'. Make sure the tags exist and is accessible.

    ## Remove-History
    Convert_PesterSyntax_ShouldProcessVerboseDescription = Converting the script file '{0}'.
    Convert_PesterSyntax_ShouldProcessVerboseWarning = Are you sure you want to convert the script file '{0}'?
    # This string shall not end with full stop (.) since it is used as a title of ShouldProcess messages.
    Convert_PesterSyntax_ShouldProcessCaption = Convert script file

    ## Rename-GitLocalBranch
    Rename_GitLocalBranch_FailedToRename = Failed to rename branch '{0}' to '{1}'. Make sure the local repository is accessible.
    Rename_GitLocalBranch_FailedFetch = Failed to fetch from remote '{0}'. Make sure the remote exists and is accessible.
    Rename_GitLocalBranch_FailedSetUpstreamTracking = Failed to set upstream tracking for branch '{0}' against remote '{1}'. Make sure the local repository is accessible.
    Rename_GitLocalBranch_FailedSetDefaultBranchForRemote = Failed to set '{0}' as the default branch for remote '{1}'. Make sure the local repository is accessible.
    Rename_GitLocalBranch_RenamedBranch = Successfully renamed branch '{0}' to '{1}'.

    ## New-GitTag
    New_GitTag_ShouldProcessVerboseDescription = Creating tag '{0}'.
    New_GitTag_ShouldProcessVerboseWarning = Are you sure you want to create tag '{0}'?
    # This string shall not end with full stop (.) since it is used as a title of ShouldProcess messages.
    New_GitTag_ShouldProcessCaption = Create tag
    New_GitTag_FailedToCreateTag = Failed to create tag '{0}'. Make sure the local repository is accessible.

    ## New-SamplerGitHubReleaseTag
    New_SamplerGitHubReleaseTag_RemoteMissing = The remote '{0}' does not exist in the local git repository. Please add the remote before proceeding.
    New_SamplerGitHubReleaseTag_FailedRebaseLocalDefaultBranch = Failed to rebase the local default branch '{0}' using '{1}/{0}'. Make sure the branch exists and is accessible.
    New_SamplerGitHubReleaseTag_MissingTagsInLocalRepository = Tags are missing. Make sure that at least one preview tag exist in the local repository, or specify a release tag.
    New_SamplerGitHubReleaseTag_LatestTagIsNotPreview = The latest tag '{0}' is not a preview tag or not a correctly formatted preview tag. Make sure the latest tag is a preview tag, or specify a release tag.
    New_SamplerGitHubReleaseTag_FailedCheckoutPreviousBranch = Failed to checkout the previous branch '{0}'.
    New_SamplerGitHubReleaseTag_NewTag_ShouldProcessVerboseDescription = Creating tag '{0}' for (latest) commit '{2}' in the local branch '{1}'.
    New_SamplerGitHubReleaseTag_NewTagWhatIf_ShouldProcessVerboseDescription = Creating tag for latest commit in the local branch '{1}'. Note: Actual tag name and commit id cannot be determine during -WhatIf.
    New_SamplerGitHubReleaseTag_NewTag_ShouldProcessVerboseWarning = Are you sure you want to create tag '{0}'?
    # This string shall not end with full stop (.) since it is used as a title of ShouldProcess messages.
    New_SamplerGitHubReleaseTag_NewTag_ShouldProcessCaption = Create tag

    ## Push-GitTag
    Push_GitTag_PushTag_ShouldProcessVerboseDescription = Pushing tag '{0}' to remote '{1}'.
    Push_GitTag_PushTag_ShouldProcessVerboseWarning = Are you sure you want to push tag '{0}' to remote '{1}'?
    # This string shall not end with full stop (.) since it is used as a title of ShouldProcess messages.
    Push_GitTag_PushTag_ShouldProcessCaption = Push tag
    Push_GitTag_PushAllTags_ShouldProcessVerboseDescription = Pushing all tags to remote '{0}'.
    Push_GitTag_PushAllTags_ShouldProcessVerboseWarning = Are you sure you want to push all tags to remote '{0}'?
    # This string shall not end with full stop (.) since it is used as a title of ShouldProcess messages.
    Push_GitTag_PushAllTags_ShouldProcessCaption = Push all tags
    Push_GitTag_FailedPushTag = Failed to push tag '{0}' to remote '{1}'.
    Push_GitTag_FailedPushAllTags = Failed to push all tags to remote '{0}'.

    ## Request-GitTag
    Request_GitTag_FetchTag_ShouldProcessVerboseDescription = Fetching tag '{0}' from remote '{1}'.
    Request_GitTag_FetchTag_ShouldProcessVerboseWarning = Are you sure you want to fetch tag '{0}' from remote '{1}'?
    # This string shall not end with full stop (.) since it is used as a title of ShouldProcess messages.
    Request_GitTag_FetchTag_ShouldProcessCaption = Fetch tag
    Request_GitTag_FetchAllTags_ShouldProcessVerboseDescription = Fetching all tags from remote '{0}'.
    Request_GitTag_FetchAllTags_ShouldProcessVerboseWarning = Are you sure you want to fetch all tags from remote '{0}'?
    # This string shall not end with full stop (.) since it is used as a title of ShouldProcess messages.
    Request_GitTag_FetchAllTags_ShouldProcessCaption = Fetch all tags
    Request_GitTag_FailedFetchTag = Failed to fetch tag '{0}' from remote '{1}'. Make sure the tag exists and remote is accessible.
    Request_GitTag_FailedFetchAllTags = Failed to fetch all tags from remote '{0}'.

    ## Switch-GitLocalBranch
    Switch_GitLocalBranch_FailedCheckoutLocalBranch = Failed to checkout the local branch '{0}'. Make sure the branch exists and is accessible.
    Switch_GitLocalBranch_ShouldProcessVerboseDescription = Switching to the local branch '{0}'.
    Switch_GitLocalBranch_ShouldProcessVerboseWarning = Are you sure you want to switch to the local branch '{0}'?
    # This string shall not end with full stop (.) since it is used as a title of ShouldProcess messages.
    Switch_GitLocalBranch_ShouldProcessCaption = Switch local branch

    ## Update-GitLocalBranch
    Update_GitLocalBranch_Rebase_ShouldProcessVerboseDescription = Rebasing the local branch '{0}' using tracking branch '{1}/{2}'.
    Update_GitLocalBranch_Rebase_ShouldProcessVerboseWarning = Are you sure you want to rebase the local branch '{0}'?
    # This string shall not end with full stop (.) since it is used as a title of ShouldProcess messages.
    Update_GitLocalBranch_Rebase_ShouldProcessCaption = Rebase local branch
    Update_GitLocalBranch_Pull_ShouldProcessVerboseDescription = Updating the local branch '{0}' by pulling from tracking branch '{1}/{2}'.
    Update_GitLocalBranch_Pull_ShouldProcessVerboseWarning = Are you sure you want to pull into the local branch '{0}'?
    # This string shall not end with full stop (.) since it is used as a title of ShouldProcess messages.
    Update_GitLocalBranch_Pull_ShouldProcessCaption = Pull into local branch
    Update_GitLocalBranch_FailedRebase = Failed to rebase the local branch '{0}' from remote '{1}'. Make sure the branch exists and is accessible.

    ## Update-RemoteTrackingBranch
    Update_RemoteTrackingBranch_FailedFetchBranchFromRemote = Failed to fetch from '{0}'. Make sure the branch exists in the remote git repository and the remote is accessible.
    Update_RemoteTrackingBranch_FetchUpstream_ShouldProcessVerboseDescription = Fetching branch '{0}' from the upstream remote '{1}'.
    Update_RemoteTrackingBranch_FetchUpstream_ShouldProcessVerboseWarning = Are you sure you want to fetch branch '{0}' from the upstream remote '{1}'?
    # This string shall not end with full stop (.) since it is used as a title of ShouldProcess messages.
    Update_RemoteTrackingBranch_FetchUpstream_ShouldProcessCaption = Fetch upstream branch
'@
