<#
    .SYNOPSIS
        The localized resource strings in English (en-US). This file should only
        contain localized strings for private functions, public command, and
        classes (that are not a DSC resource).
#>

ConvertFrom-StringData @'
    ## Remove-History
    Convert_PesterSyntax_ShouldProcessVerboseDescription = Converting the script file '{0}'.
    Convert_PesterSyntax_ShouldProcessVerboseWarning = Are you sure you want to convert the script file '{0}'?
    # This string shall not end with full stop (.) since it is used as a title of ShouldProcess messages.
    Convert_PesterSyntax_ShouldProcessCaption = Convert script file

    New_SamplerGitHubReleaseTag_Rebase_ShouldProcessVerboseDescription = Switching to and rebasing the local default branch '{0}' from the upstream default branch '{0}'.
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
