<#
    .SYNOPSIS
        The localized resource strings in English (en-US). This file should only
        contain localized strings for private functions, public command, and
        classes (that are not a DSC resource).
#>

ConvertFrom-StringData @'
    ## New-SamplerGitHubReleaseTag
    New_SamplerGitHubReleaseTag_RemoteMissing = The remote '{0}' does not exist in the local git repository. Please add the remote before proceeding. (NSGRT0001)
    New_SamplerGitHubReleaseTag_FailedFetchBranchFromRemote = Failed to fetch branch '{0}' from the remote '{1}'. Make sure the branch exists in the remote git repository and the remote is accessible. (NSGRT0002)
    New_SamplerGitHubReleaseTag_FailedGetLocalBranchName = Failed to get the name of the local branch. Make sure the local branch exists and is accessible. (NSGRT0003)
    New_SamplerGitHubReleaseTag_FailedCheckoutLocalBranch = Failed to checkout the local branch '{0}'. Make sure the branch exists and is accessible. (NSGRT0004)
    New_SamplerGitHubReleaseTag_FailedRebaseLocalDefaultBranch = Failed to rebase the local default branch '{0}' using '{1}/{0}'. Make sure the branch exists and is accessible. (NSGRT0005)
    New_SamplerGitHubReleaseTag_FailedGetLastCommitId = Failed to get the last commit id of the local branch '{0}'. Make sure the branch exists and is accessible. (NSGRT0006)
    New_SamplerGitHubReleaseTag_FailedFetchTagsFromUpstreamRemote = Failed to fetch tags from the upstream remote '{0}'. Make sure the remote exists and is accessible. (NSGRT0007)
    New_SamplerGitHubReleaseTag_FailedGetTagsOrMissingTagsInLocalRepository = Failed to get tags from the local repository or the tags are missing. Make sure that at least one preview tag exist in the local repository, or specify a release tag. (NSGRT0008)
    New_SamplerGitHubReleaseTag_FailedDescribeTags = Failed to describe the tags. Make sure the tags exist in the local repository. (NSGRT0009)
    New_SamplerGitHubReleaseTag_LatestTagIsNotPreview = The latest tag '{0}' is not a preview tag or not a correctly formatted preview tag. Make sure the latest tag is a preview tag, or specify a release tag. (NSGRT0010)
    New_SamplerGitHubReleaseTag_FailedCheckoutPreviousBranch = Failed to checkout the previous branch '{0}'. (NSGRT0011)

    New_SamplerGitHubReleaseTag_FetchUpstream_ShouldProcessDescription = Fetching branch '{0}' from the upstream remote '{1}'. (NSGRT0012)
    New_SamplerGitHubReleaseTag_FetchUpstream_ShouldProcessConfirmation = Are you sure you want to fetch branch '{0}' from the upstream remote '{1}'? (NSGRT0013)
    # This string shall not end with full stop (.) since it is used as a title of ShouldProcess messages.
    New_SamplerGitHubReleaseTag_FetchUpstream_ShouldProcessCaption = Fetch upstream branch (NSGRT0014)

    New_SamplerGitHubReleaseTag_Rebase_ShouldProcessDescription = Switching to and rebasing the local default branch '{0}' using the upstream branch '{1}/{0}'. (NSGRT0015)
    New_SamplerGitHubReleaseTag_Rebase_ShouldProcessConfirmation = Are you sure you want to switch to and rebase the local branch '{0}'? (NSGRT0016)
    # This string shall not end with full stop (.) since it is used as a title of ShouldProcess messages.
    New_SamplerGitHubReleaseTag_Rebase_ShouldProcessCaption = Rebase the local default branch (NSGRT0017)

    New_SamplerGitHubReleaseTag_UpstreamTags_ShouldProcessDescription = Fetching the tags from (upstream) remote '{0}'. (NSGRT0018)
    New_SamplerGitHubReleaseTag_UpstreamTags_ShouldProcessConfirmation = Are you sure you want to fetch tags from remote '{0}'? (NSGRT0019)
    # This string shall not end with full stop (.) since it is used as a title of ShouldProcess messages.
    New_SamplerGitHubReleaseTag_UpstreamTags_ShouldProcessCaption = Fetch tags from remote (NSGRT0020)

    New_SamplerGitHubReleaseTag_NewTag_ShouldProcessDescription = Creating tag '{0}' for commit '{2}' in the local branch '{1}'. (NSGRT0021)
    New_SamplerGitHubReleaseTag_NewTagWhatIf_ShouldProcessDescription = Creating tag for commit in the local branch '{1}'. Note: Actual tag name and commit id cannot be determined during -WhatIf. (NSGRT0022)
    New_SamplerGitHubReleaseTag_NewTag_ShouldProcessConfirmation = Are you sure you want to create tag '{0}'? (NSGRT0023)
    # This string shall not end with full stop (.) since it is used as a title of ShouldProcess messages.
    New_SamplerGitHubReleaseTag_NewTag_ShouldProcessCaption = Create tag (NSGRT0024)

    New_SamplerGitHubReleaseTag_SwitchBack_ShouldProcessDescription = Switching back to previous local branch '{0}'. (NSGRT0025)
    New_SamplerGitHubReleaseTag_SwitchBack_ShouldProcessConfirmation = Are you sure you want to switch back to previous local branch '{0}'? (NSGRT0026)
    # This string shall not end with full stop (.) since it is used as a title of ShouldProcess messages.
    New_SamplerGitHubReleaseTag_SwitchBack_ShouldProcessCaption = Switch to previous branch (NSGRT0027)

    New_SamplerGitHubReleaseTag_PushTag_ShouldContinueMessage = Do you want to push the tags to the remote repository '{0}'? (NSGRT0028)
    # This string shall not end with full stop (.) since it is used as a title of ShouldContinue messages.
    New_SamplerGitHubReleaseTag_PushTag_ShouldContinueCaption = 'Push tag to remote repository' (NSGRT0029)
    New_SamplerGitHubReleaseTag_TagCreatedAndPushed = [32mTag[0m [1;37;44m{0}[0m[32m has been created and pushed to the remote repository '{1}'.[0m (NSGRT0030)
    New_SamplerGitHubReleaseTag_TagCreatedNotPushed = [32mTag[0m [1;37;44m{0}[0m[32m has been created, but not pushed. To push the tag to the remote repository, run '[30mgit push {1} --tags[32m'.[0m (NSGRT0031)

    ## Install-ModulePatch
    Install_ModulePatch_ShouldProcessDescription = Apply module patch file at location '{0}'. (IMP0001)
    Install_ModulePatch_ShouldProcessConfirmation = Are you sure you want to apply the module patch at the location '{0}'? (IMP0002)
    # This string shall not end with full stop (.) since it is used as a title of ShouldProcess messages.
    Install_ModulePatch_ShouldProcessCaption = Apply module patch (IMP0003)
    Install_ModulePatch_PatchFilePathNotFound = The module patch file at location '{0}' does not exist. (IMP0004)
    Install_ModulePatch_Debug_Path = Patch file path: '{0}'. (IMP0005)
    Install_ModulePatch_Debug_URI = Patch file URI: '{0}'. (IMP0006)
    Install_ModulePatch_Debug_PatchFileContent = Patch file content: '{0}'. (IMP0007)
    Install_ModulePatch_Debug_PatchEntry = Processing patch entry: '{0}'. (IMP0008)
    Install_ModulePatch_Progress_Activity = Applying Module Patches (IMP0009)
    Install_ModulePatch_Progress_Status = Starting patch process... (IMP0010)
    Install_ModulePatch_Progress_CurrentOperation = Processing script file '{0}' at start offset {1}. (IMP0011)
    Install_ModulePatch_MissingModule = Module '{0}' version '{1}' not found. (IMP0012)
    Install_ModulePatch_Error_HashMismatch = Hash validation failed for script file '{0}' after patching. (IMP0013)
    Install_ModulePatch_Patch_Success = Successfully patched script file '{0}'. (IMP0014)
    Install_ModulePatch_Patch_SuccessHashValidationSkipped = Successfully patched script file '{0}', but hash validation was skipped. (IMP0015)

    ## Merge-Patch
    Merge_Patch_InvalidStartOrEndOffset = Start or end offset ({0}-{1}) in patch entry does not exist in the script file '{2}'. (MP0001)
    Merge_Patch_SuccessfullyPatched = Successfully patched file '{0}' at start offset {1}. (MP0002)

    ## Assert-ScriptFileValidity
    Assert_ScriptFileValidity_ScriptFileNotFound = Script file not found: {0} (ASFV0001)
    Assert_ScriptFileValidity_HashValidationFailed = Hash validation failed for script file: {0}. Expected: {1} (ASFV0002)

    ## Assert-PatchFile
    Assert_PatchFile_MissingModuleName = Patch entry is missing 'ModuleName'. (APF0001)
    Assert_PatchFile_MissingModuleVersion = Patch entry is missing 'ModuleVersion'. (APF0002)
    Assert_PatchFile_MissingModuleFiles = Patch entry is missing 'ModuleFiles'. (APF0003)
    Assert_PatchFile_MissingScriptFileName = Patch entry is missing 'ScriptFileName'. (APF0004)
    Assert_PatchFile_MissingOriginalHashSHA = Patch entry is missing 'OriginalHashSHA'. (APF0005)
    Assert_PatchFile_MissingValidationHashSHA = Patch entry is missing 'ValidationHashSHA'. (APF0006)
    Assert_PatchFile_MissingFilePatches = Patch entry is missing 'FilePatches'. (APF0007)
    Assert_PatchFile_MissingOffset = Patch entry is missing 'StartOffset' or 'EndOffset'. (APF0008)
    Assert_PatchFile_MissingPatchContent = Patch entry is missing 'PatchContent'. (APF0009)

    ## Get-ModuleFileSha
    Get_ModuleFileSha_MissingModule = Module not found: {0} (GMFS0001)
    Get_ModuleFileSha_MissingModuleVersion = Module with specified version not found: {0} {1} (GMFS0002)
    Get_ModuleFileSha_PathMustBeDirectory = The specified path must be a directory, the root of a module including its version folder, e.g. './Viscalyx.Common/1.0.0'. (GMFS0003)

    ## Test-FileHash
    TestFileHash_CalculatingHash = Calculating hash for file: {0} using algorithm: {1} (TFH0001)
    TestFileHash_ComparingHash = Comparing file hash: {0} with expected hash: {1} (TFH0002)

    ## Get-TextOffset
    TextNotFoundWarning = Text '{0}' not found in the file '{1}'. (GTO0001)

    ## Assert-IPv4Address
    Assert_IPv4Address_ValidatingAddress = Validating IPv4 address format for '{0}'. (AIV0001)
    Assert_IPv4Address_ValidationSuccessful = IPv4 address '{0}' is valid. (AIV0002)
    Assert_IPv4Address_InvalidFormatException = The input '{0}' is not a valid IPv4 address format. (AIV0003)
    Assert_IPv4Address_OctetOutOfRangeException = Octet '{0}' in address '{1}' is out of valid range (0-255). (AIV0004)
    Assert_IPv4Address_OctetConversionFailedException = Failed to convert octet '{0}' to integer in address '{1}'. (AIV0005)

    ## Test-IPv4Address
    Test_IPv4Address_ValidatingAddress = Testing IPv4 address format for '{0}'. (TIV0001)
    Test_IPv4Address_ValidationSuccessful = IPv4 address '{0}' is valid. (TIV0002)
    Test_IPv4Address_InvalidFormat = The input '{0}' is not a valid IPv4 address format. (TIV0003)
    Test_IPv4Address_OctetOutOfRange = Octet '{0}' in address '{1}' is out of valid range (0-255). (TIV0004)
    Test_IPv4Address_OctetConversionFailed = Failed to convert octet '{0}' to integer in address '{1}'. (TIV0005)

    ## Resolve-DnsName
    Resolve_DnsName_AttemptingResolution = Attempting to resolve DNS name '{0}'. (RDN0001)
    Resolve_DnsName_ResolutionSuccessful = Successfully resolved '{0}' to '{1}'. (RDN0002)
    Resolve_DnsName_ResolutionFailed = DNS resolution failed for '{0}'. (RDN0003)
    Resolve_DnsName_NoIPv4AddressFound = No IPv4 addresses found for '{0}'. (RDN0004)

    ## Send-WakeOnLan
    Send_WakeOnLan_SendingPacket = Sending Wake-on-LAN packet to MAC address '{0}' via broadcast '{1}' on port {2}. (SWOL0001)
    Send_WakeOnLan_PacketSent = Wake-on-LAN packet sent successfully. (SWOL0002)
    Send_WakeOnLan_SendFailed = Failed to send Wake-on-LAN packet. (SWOL0003)
    Send_WakeOnLan_CreatingPacket = Creating Wake-on-LAN magic packet with MAC address '{0}'. (SWOL0004)
    Send_WakeOnLan_ShouldProcessDescription = Send Wake-on-LAN packet to MAC address '{0}' via broadcast '{1}' on port {2}. (SWOL0005)
    Send_WakeOnLan_ShouldProcessConfirmation = Are you sure you want to send a Wake-on-LAN packet to MAC address '{0}'? (SWOL0006)
    # This string shall not end with full stop (.) since it is used as a title of ShouldProcess messages.
    Send_WakeOnLan_ShouldProcessCaption = Send Wake-on-LAN packet (SWOL0007)

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

    ## ConvertTo-CanonicalMacAddress
    ConvertTo_CanonicalMacAddress_NormalizingMac = Normalizing MAC address '{0}' to canonical format. (CCMA0001)
    ConvertTo_CanonicalMacAddress_InvalidLength = MAC address '{0}' has invalid length '{1}', expected 12 hexadecimal characters. Returning original value. (CCMA0002)
    ConvertTo_CanonicalMacAddress_NormalizedMac = Successfully normalized MAC address from '{0}' to '{1}'. (CCMA0003)
    ConvertTo_CanonicalMacAddress_NormalizationFailed = Failed to normalize MAC address '{0}' with error: {1}. Returning original value. (CCMA0004)

    ## Invoke-PesterJob
    Invoke_PesterJob_ModuleBuilderRequired = The ModuleBuilder module is required for source line mapping but is not available. Please install the ModuleBuilder module or run the command in a Sampler project environment. (IPJ0001)

    ## Remove-PSHistory
    Remove_PSHistory_ShouldProcessDescription = Removing content matching the pattern '{0}'. (RH0001)
    Remove_PSHistory_ShouldProcessConfirmation = Are you sure you want to remove the content matching the pattern '{0}' from PowerShell history? (RH0002)
    # This string shall not end with full stop (.) since it is used as a title of ShouldProcess messages.
    Remove_PSHistory_ShouldProcessCaption = Remove content matching the pattern from PowerShell history (RH0005)
    Remove_PSHistory_Removed = Removed PowerShell history content matching the pattern. (RH0003)
    Remove_PSHistory_NoMatches = No PowerShell history content matching the pattern. (RH0004)

    ## Remove-PSReadLineHistory
    Remove_PSReadLineHistory_ShouldProcessDescription = Removing content matching the pattern '{0}'. (RPSH0001)
    Remove_PSReadLineHistory_ShouldProcessConfirmation = Are you sure you want to remove the content matching the pattern '{0}' from PSReadLine history? (RPSH0002)
    # This string shall not end with full stop (.) since it is used as a title of ShouldProcess messages.
    Remove_PSReadLineHistory_ShouldProcessCaption = Remove content matching the pattern from PSReadLine history (RPSH0005)
    Remove_PSReadLineHistory_Removed = Removed PSReadLine history content matching the pattern. (RPSH0003)
    Remove_PSReadLineHistory_NoMatches = No PSReadLine history content matching the pattern. (RPSH0004)

    ## ConvertTo-AnsiString
    ConvertTo_AnsiString_ProcessingBegin = Begin processing ANSI sequence conversion. (CTAS0001)
    ConvertTo_AnsiString_EmptyInput = Input string is null or empty, returning as-is. (CTAS0002)
    ConvertTo_AnsiString_ProcessingString = Processing string with {0} characters for ANSI sequence conversion. (CTAS0003)
    ConvertTo_AnsiString_ProcessingSequence = Processing ANSI sequence with codes '{0}'. (CTAS0004)
    ConvertTo_AnsiString_ProcessingComplete = ANSI sequence conversion completed. (CTAS0005)
'@
