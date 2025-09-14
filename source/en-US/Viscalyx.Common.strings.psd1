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

    ## Install-ModulePatch
    Install_ModulePatch_ShouldProcessVerboseDescription = Apply module patch file at location '{0}'.
    Install_ModulePatch_ShouldProcessVerboseWarning = Are you sure you want to apply the module patch at the location '{0}'?
    # This string shall not end with full stop (.) since it is used as a title of ShouldProcess messages.
    Install_ModulePatch_ShouldProcessCaption = Apply module patch
    Install_ModulePatch_PatchFilePathNotFound = The module patch file at location '{0}' does not exist.
    Install_ModulePatch_Debug_Path = Patch file path: '{0}'.
    Install_ModulePatch_Debug_URI = Patch file URI: '{0}'.
    Install_ModulePatch_Debug_PatchFileContent = Patch file content: '{0}'.
    Install_ModulePatch_Debug_PatchEntry = Processing patch entry: '{0}'.
    Install_ModulePatch_Progress_Activity = Applying Module Patches
    Install_ModulePatch_Progress_Status = Starting patch process...
    Install_ModulePatch_Progress_CurrentOperation = Processing script file '{0}' at start offset {1}.
    Install_ModulePatch_MissingModule = Module '{0}' version '{1}' not found.
    Install_ModulePatch_Error_HashMismatch = Hash validation failed for script file '{0}' after patching.
    Install_ModulePatch_Patch_Success = Successfully patched script file '{0}'.
    Install_ModulePatch_Patch_SuccessHashValidationSkipped = Successfully patched script file '{0}', but hash validation was skipped.

    ## Merge-Patch
    Merge_Patch_InvalidStartOrEndOffset = Start or end offset ({0}-{1}) in patch entry does not exist in the script file '{2}'.
    Merge_Patch_SuccessfullyPatched = Successfully patched file '{0}' at start offset {1}.

    ## Assert-ScriptFileValidity
    Assert_ScriptFileValidity_ScriptFileNotFound = Script file not found: {0}
    Assert_ScriptFileValidity_HashValidationFailed = Hash validation failed for script file: {0}. Expected: {1}

    ## Assert-PatchFile
    Assert_PatchFile_MissingModuleName = Patch entry is missing 'ModuleName'.
    Assert_PatchFile_MissingModuleVersion = Patch entry is missing 'ModuleVersion'.
    Assert_PatchFile_MissingModuleFiles = Patch entry is missing 'ModuleFiles'.
    Assert_PatchFile_MissingScriptFileName = Patch entry is missing 'ScriptFileName'.
    Assert_PatchFile_MissingOriginalHashSHA = Patch entry is missing 'OriginalHashSHA'.
    Assert_PatchFile_MissingValidationHashSHA = Patch entry is missing 'ValidationHashSHA'.
    Assert_PatchFile_MissingFilePatches = Patch entry is missing 'FilePatches'.
    Assert_PatchFile_MissingOffset = Patch entry is missing 'StartOffset' or 'EndOffset'.
    Assert_PatchFile_MissingPatchContent = Patch entry is missing 'PatchContent'.

    ## Get-ModuleFileSha
    Get_ModuleFileSha_MissingModule = Module not found: {0}
    Get_ModuleFileSha_MissingModuleVersion = Module with specified version not found: {0} {1}
    Get_ModuleFileSha_PathMustBeDirectory = The specified path must be a directory, the root of a module including its version folder, e.g. './Viscalyx.Common/1.0.0'.

    ## Test-FileHash
    TestFileHash_CalculatingHash = Calculating hash for file: {0} using algorithm: {1}
    TestFileHash_ComparingHash = Comparing file hash: {0} with expected hash: {1}

    ## Get-TextOffset
    TextNotFoundWarning = Text '{0}' not found in the file '{1}'.

    ## Assert-IPv4Address
    Assert_IPv4Address_ValidatingAddress = Validating IPv4 address format for '{0}'. (AIV0001)
    Assert_IPv4Address_ValidationSuccessful = IPv4 address '{0}' is valid. (AIV0002)
    Assert_IPv4Address_InvalidFormatException = The input '{0}' is not a valid IPv4 address format. (AIV0003)
    Assert_IPv4Address_OctetOutOfRangeException = Octet '{0}' in address '{1}' is out of valid range (0-255). (AIV0004)
    Assert_IPv4Address_InvalidLeadingZeroException = Octet '{0}' in address '{1}' contains invalid leading zero. (AIV0005)
    Assert_IPv4Address_OctetConversionFailedException = Failed to convert octet '{0}' to integer in address '{1}'. (AIV0006)

    ## Resolve-DnsName
    Resolve_DnsName_AttemptingResolution = Attempting to resolve DNS name '{0}'. (RDN0001)
    Resolve_DnsName_ResolutionSuccessful = Successfully resolved '{0}' to '{1}'. (RDN0002)
    Resolve_DnsName_ResolutionException = DNS resolution for '{0}' failed with exception: {1} (RDN0004)
    Resolve_DnsName_ResolutionFailed = DNS resolution failed for '{0}'. {1} (RDN0005)
    Resolve_DnsName_NoIPv4AddressFound = No IPv4 addresses found for '{0}'. (RDN0006)

    ## Send-WakeOnLan
    Send_WakeOnLan_SendingPacket = Sending Wake-on-LAN packet to MAC address '{0}' via broadcast '{1}' on port {2}. (SWOL0001)
    Send_WakeOnLan_PacketSent = Wake-on-LAN packet sent successfully. (SWOL0002)
    Send_WakeOnLan_CreatingPacket = Creating Wake-on-LAN magic packet with MAC address '{0}'. (SWOL0004)
    Send_WakeOnLan_ShouldProcessVerboseDescription = Send Wake-on-LAN packet to MAC address '{0}' via broadcast '{1}' on port {2}. (SWOL0005)
    Send_WakeOnLan_ShouldProcessVerboseWarning = Are you sure you want to send a Wake-on-LAN packet to MAC address '{0}'? (SWOL0006)
    # This string shall not end with full stop (.) since it is used as a title of ShouldProcess messages.
    Send_WakeOnLan_ShouldProcessCaption = Send Wake-on-LAN packet

    ## Get-LinkLayerAddress
    Get_LinkLayerAddress_RefreshingArpEntry = Refreshing ARP entry for IP address '{0}'. (GLLA0001)
    Get_LinkLayerAddress_QueryingArpTable = Querying ARP table for IP address '{0}'. (GLLA0002)
    Get_LinkLayerAddress_UsingGetNetNeighbor = Using Get-NetNeighbor cmdlet to retrieve neighbor information. (GLLA0003)
    Get_LinkLayerAddress_UsingArpCommand = Using arp command to retrieve ARP table information. (GLLA0004)
    Get_LinkLayerAddress_UsingIpCommand = Using ip command to retrieve neighbor table information. (GLLA0005)
    Get_LinkLayerAddress_FoundMacAddress = Found MAC address '{1}' for IP address '{0}'. (GLLA0006)
    Get_LinkLayerAddress_ArpCommandFailed = ARP command failed with error: {0} (GLLA0007)
    Get_LinkLayerAddress_IpCommandFailed = IP command failed with error: {0} (GLLA0008)
    Get_LinkLayerAddress_CouldNotFindMac = Could not find a MAC address for '{0}'. Ensure the IP address is on the same subnet and the computer is powered on and reachable. (GLLA0009)
    Get_LinkLayerAddress_InvalidIPAddress = Invalid IP address format '{0}'. Expected format: 'XXX.XXX.XXX.XXX'. (GLLA0010)

    ## Invoke-PesterJob
    Invoke_PesterJob_ModuleBuilderRequired = The ModuleBuilder module is required for source line mapping but is not available. Please install the ModuleBuilder module or run the command in a Sampler project environment. (IPJ0001)
'@
