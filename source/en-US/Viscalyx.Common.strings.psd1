<#
    .SYNOPSIS
        The localized resource strings in English (en-US). This file should only
        contain localized strings for private functions, public command, and
        classes (that are not a DSC resource).
#>

# cSpell: ignore unstaged
ConvertFrom-StringData @'
    ## Disable-CursorShortcutCode
    Disable_CursorShortcutCode_CursorPathNotFound = Cursor path not found in the PATH environment variable. Exiting. (DCSC0001)
    Disable_CursorShortcutCode_MultipleCursorPaths = More than one Cursor path was found in the PATH environment variable. (DCSC0002)
    Disable_CursorShortcutCode_RenameCodeCmd_ShouldProcessDescription = Renaming 'code.cmd' to 'code.cmd.old' in the Cursor path '{0}'. (DCSC0007)
    Disable_CursorShortcutCode_RenameCodeCmd_ShouldProcessConfirmation = Are you sure you want to rename 'code.cmd' to 'code.cmd.old'? (DCSC0008)
    # This string shall not end with full stop (.) since it is used as a title of ShouldProcess messages.
    Disable_CursorShortcutCode_RenameCodeCmd_ShouldProcessCaption = Rename code.cmd (DCSC0009)
    Disable_CursorShortcutCode_RenamedCodeCmd = Renamed code.cmd to code.cmd.old (DCSC0003)
    Disable_CursorShortcutCode_CodeCmdNotFound = File 'code.cmd' not found in the Cursor path. Skipping. (DCSC0004)
    Disable_CursorShortcutCode_RenameCode_ShouldProcessDescription = Renaming 'code' to 'code.old' in the Cursor path '{0}'. (DCSC0010)
    Disable_CursorShortcutCode_RenameCode_ShouldProcessConfirmation = Are you sure you want to rename 'code' to 'code.old'? (DCSC0011)
    # This string shall not end with full stop (.) since it is used as a title of ShouldProcess messages.
    Disable_CursorShortcutCode_RenameCode_ShouldProcessCaption = Rename code (DCSC0012)
    Disable_CursorShortcutCode_RenamedCode = Renamed code to code.old (DCSC0005)
    Disable_CursorShortcutCode_CodeNotFound = File 'code' not found in the Cursor path. Skipping. (DCSC0006)

    ## Assert-GitLocalChange
    Assert_GitLocalChange_FailedUnstagedChanges = There are unstaged or staged changes. Please commit or stash your changes before proceeding. (AGLC0001)

    ## Test-GitLocalChanges
    Test_GitLocalChanges_GitFailed = Failed to execute git status. Make sure git is installed and the current directory is a valid git repository. (TGLC0001)

    ## Assert-GitRemote
    Assert_GitRemote_RemoteMissing = The remote '{0}' does not exist in the local git repository. Please add the remote before proceeding. (AGR0001)

    ## Get-GitLocalBranchName
    Get_GitLocalBranchName_Failed = Failed to get the name of the local branch. Make sure git repository is accessible. (GGLBN0001)

    ## Get-GitBranchCommit
    Get_GitBranchCommit_FailedFromBranch = Failed to retrieve commits. Make sure the branch '{0}' exists and is accessible. (GGBC0001)
    Get_GitBranchCommit_FailedFromCurrent = Failed to retrieve commits from current branch. (GGBC0002)
    Get_GitBranchCommit_FailedFromRange = Failed to retrieve commits from range '{0}..{1}'. Make sure both references exist and are accessible. (GGBC0003)

    ## Get-GitRemote
    Get_GitRemote_Failed = Failed to get the remote '{0}'. Make sure the remote exists and is accessible. (GGR0001)

    ## Get-GitRemoteBranch
    Get_GitRemoteBranch_Failed = Failed to get the remote branches. Make sure the remote branch exists and is accessible. (GGRB0003)
    Get_GitRemoteBranch_FromRemote_Failed = Failed to get the remote branches from remote '{0}'. Make sure the remote branch exists and is accessible. (GGRB0004)
    Get_GitRemoteBranch_ByName_Failed = Failed to get the remote branch '{0}' using the remote '{1}'. Make sure the remote branch exists and is accessible. (GGRB0005)
    Get_GitRemoteBranch_RemoteNotFound = The remote '{0}' does not exist in the local git repository. Please add the remote before proceeding. (GGRB0002)

    ## Get-GitTag
    Get_GitTag_FailedToGetTag = Failed to get the tag '{0}'. Make sure the tag exists and is accessible. (GGT0001)

    ## Rename-GitLocalBranch
    Rename_GitLocalBranch_FailedToRename = Failed to rename branch '{0}' to '{1}'. Make sure the local repository is accessible. (RGLB0005)
    Rename_GitLocalBranch_FailedFetch = Failed to fetch from remote '{0}'. Make sure the remote exists and is accessible. (RGLB0006)
    Rename_GitLocalBranch_FailedSetUpstreamTracking = Failed to set upstream tracking for branch '{0}' against remote '{1}'. Make sure the local repository is accessible. (RGLB0007)
    Rename_GitLocalBranch_FailedSetDefaultBranchForRemote = Failed to set '{0}' as the default branch for remote '{1}'. Make sure the local repository is accessible. (RGLB0008)
    Rename_GitLocalBranch_RenamedBranch = Successfully renamed branch '{0}' to '{1}'. (RGLB0001)
    Rename_GitLocalBranch_Rename_ShouldProcessDescription = Renaming Git branch '{0}' to '{1}'. (RGLB0002)
    Rename_GitLocalBranch_Rename_ShouldProcessConfirmation = Are you sure you want to rename Git branch '{0}' to '{1}'? (RGLB0003)
    Rename_GitLocalBranch_Rename_ShouldProcessCaption = Rename Git branch (RGLB0004)

    ## Rename-GitRemote
    Rename_GitRemote_FailedToRename = Failed to rename remote '{0}' to '{1}'. Make sure the remote exists and the local repository is accessible. (RGR0001)
    Rename_GitRemote_RenamedRemote = Successfully renamed remote '{0}' to '{1}'. (RGR0002)
    Rename_GitRemote_Action_ShouldProcessDescription = Renaming Git remote '{0}' to '{1}'. (RGR0003)
    Rename_GitRemote_Action_ShouldProcessConfirmation = Are you sure you want to rename Git remote '{0}' to '{1}'? (RGR0004)
    # This string shall not end with full stop (.) since it is used as a title of ShouldProcess messages.
    Rename_GitRemote_Action_ShouldProcessCaption = Rename Git remote (RGR0005)

    ## New-GitTag
    New_GitTag_ShouldProcessVerboseDescription = Creating tag '{0}'. (NGT0001)
    New_GitTag_ShouldProcessVerboseWarning = Are you sure you want to create tag '{0}'? (NGT0002)
    # This string shall not end with full stop (.) since it is used as a title of ShouldProcess messages.
    New_GitTag_ShouldProcessCaption = Create tag (NGT0003)
    New_GitTag_FailedToCreateTag = Failed to create tag '{0}'. Make sure the local repository is accessible. (NGT0004)

    ## New-SamplerGitHubReleaseTag
    New_SamplerGitHubReleaseTag_LatestTagIsNotPreview = The latest tag '{0}' is not a preview tag or not a correctly formatted preview tag. Make sure the latest tag is a preview tag, or specify a release tag. (NSGRT0010)
    New_SamplerGitHubReleaseTag_MissingTagsInLocalRepository = Tags are missing. Make sure that at least one preview tag exist in the local repository, or specify a release tag. (NSGRT0032)
    New_SamplerGitHubReleaseTag_NewTag_ShouldProcessDescription = Creating tag '{0}' for commit '{2}' in the local branch '{1}'. (NSGRT0021)
    New_SamplerGitHubReleaseTag_NewTagWhatIf_ShouldProcessDescription = Creating tag for commit in the local branch '{1}'. Note: Actual tag name and commit id cannot be determined during -WhatIf. (NSGRT0022)
    New_SamplerGitHubReleaseTag_NewTag_ShouldProcessConfirmation = Are you sure you want to create tag '{0}'? (NSGRT0023)
    # This string shall not end with full stop (.) since it is used as a title of ShouldProcess messages.
    New_SamplerGitHubReleaseTag_NewTag_ShouldProcessCaption = Create tag (NSGRT0024)
    New_SamplerGitHubReleaseTag_TagCreatedAndPushed = [32mTag[0m [1;37;44m{0}[0m[32m has been created and pushed to the remote repository '{1}'.[0m (NSGRT0030)
    New_SamplerGitHubReleaseTag_TagCreatedNotPushed = [32mTag[0m [1;37;44m{0}[0m[32m has been created, but not pushed. To push the tag to the remote repository, run '[39mgit push {1} --tags[32m'.[0m (NSGRT0031)

    ## Push-GitTag
    Push_GitTag_PushTag_ShouldProcessDescription = Pushing tag '{0}' to remote '{1}'. (PGT0001)
    Push_GitTag_PushTag_ShouldProcessConfirmation = Are you sure you want to push tag '{0}' to remote '{1}'? (PGT0002)
    # This string shall not end with full stop (.) since it is used as a title of ShouldProcess messages.
    Push_GitTag_PushTag_ShouldProcessCaption = Push tag (PGT0003)
    Push_GitTag_PushAllTags_ShouldProcessDescription = Pushing all tags to remote '{0}'. (PGT0004)
    Push_GitTag_PushAllTags_ShouldProcessConfirmation = Are you sure you want to push all tags to remote '{0}'? (PGT0005)
    # This string shall not end with full stop (.) since it is used as a title of ShouldProcess messages.
    Push_GitTag_PushAllTags_ShouldProcessCaption = Push all tags (PGT0006)
    Push_GitTag_FailedPushTag = Failed to push tag '{0}' to remote '{1}'. (PGT0007)
    Push_GitTag_FailedPushAllTags = Failed to push all tags to remote '{0}'. (PGT0008)
    Push_GitTag_NoLocalTags = No local tags found to push to remote '{0}'. (PGT0009)
    Push_GitTag_FailedListTags = Failed to list local tags. Make sure you are in a valid git repository. (PGT0010)

    ## Receive-GitBranch
    Receive_GitBranch_FailedCheckout = Failed to checkout branch '{0}'. Make sure the branch exists and is accessible. (RGB0006)
    Receive_GitBranch_FailedFetch = Failed to fetch upstream branch '{1}' from remote '{0}'. Make sure the branch exists and is accessible. (RGB0008)
    Receive_GitBranch_FailedRebase = Failed to rebase with upstream branch '{1}' from remote '{0}'. Make sure the branches exist and are accessible. (RGB0010)
    Receive_GitBranch_FailedPull = Failed to pull changes into current branch '{0}'. Make sure the branch exists and is accessible (no staged or unstaged changes). (RGB0012)
    Receive_GitBranch_Success = Successfully updated branch. (RGB0013)
    Receive_GitBranch_NoTrackingBranch = Branch '{0}' has no upstream tracking branch configured. Use 'git branch --set-upstream-to=<remote>/<branch>' to set one. (RGB0014)
    Receive_GitBranch_Checkout_ShouldProcessDescription = Checking out branch '{0}'. (RGB0026)
    Receive_GitBranch_Checkout_ShouldProcessConfirmation = Are you sure you want to checkout branch '{0}'? (RGB0027)
    # This string shall not end with full stop (.) since it is used as a title of ShouldProcess messages.
    Receive_GitBranch_Checkout_ShouldProcessCaption = Checkout branch (RGB0028)
    Receive_GitBranch_Fetch_ShouldProcessDescription = Fetching upstream branch '{0}' from remote '{1}'. (RGB0029)
    Receive_GitBranch_Fetch_ShouldProcessConfirmation = Are you sure you want to fetch upstream branch '{0}' from remote '{1}'? (RGB0030)
    # This string shall not end with full stop (.) since it is used as a title of ShouldProcess messages.
    Receive_GitBranch_Fetch_ShouldProcessCaption = Fetch upstream branch (RGB0031)
    Receive_GitBranch_RebaseOperation_ShouldProcessDescription = Rebasing local branch '{0}' with upstream branch '{1}' from remote '{2}'. (RGB0032)
    Receive_GitBranch_RebaseOperation_ShouldProcessConfirmation = Are you sure you want to rebase local branch '{0}' with upstream branch '{1}' from remote '{2}'? (RGB0033)
    # This string shall not end with full stop (.) since it is used as a title of ShouldProcess messages.
    Receive_GitBranch_RebaseOperation_ShouldProcessCaption = Rebase with upstream branch (RGB0034)
    Receive_GitBranch_PullOperation_ShouldProcessDescription = Pulling latest changes into current branch '{0}'. (RGB0035)
    Receive_GitBranch_PullOperation_ShouldProcessConfirmation = Are you sure you want to pull into current branch '{0}'? (RGB0036)
    # This string shall not end with full stop (.) since it is used as a title of ShouldProcess messages.
    Receive_GitBranch_PullOperation_ShouldProcessCaption = Pull into current branch (RGB0037)

    ## Remove-GitTag
    Remove_GitTag_Local_ShouldProcessVerboseDescription = Removing tag '{0}' from local repository. (RGT0001)
    Remove_GitTag_Local_ShouldProcessVerboseWarning = Are you sure you want to remove tag '{0}' from the local repository? (RGT0002)
    # This string shall not end with full stop (.) since it is used as a title of ShouldProcess messages.
    Remove_GitTag_Local_ShouldProcessCaption = Remove local tag (RGT0003)
    Remove_GitTag_Remote_ShouldProcessVerboseDescription = Removing tag '{0}' from remote '{1}'. (RGT0004)
    Remove_GitTag_Remote_ShouldProcessVerboseWarning = Are you sure you want to remove tag '{0}' from remote '{1}'? (RGT0005)
    # This string shall not end with full stop (.) since it is used as a title of ShouldProcess messages.
    Remove_GitTag_Remote_ShouldProcessCaption = Remove remote tag (RGT0006)
    Remove_GitTag_FailedToRemoveLocalTag = Failed to remove tag '{0}' from local repository. (RGT0007)
    Remove_GitTag_FailedToRemoveRemoteTag = Failed to remove tag '{0}' from remote '{1}'. (RGT0008)

    ## Request-GitTag
    Request_GitTag_FetchTag_ShouldProcessVerboseDescription = Fetching tag '{0}' from remote '{1}'. (RQT0001)
    Request_GitTag_FetchTag_ShouldProcessVerboseWarning = Are you sure you want to fetch tag '{0}' from remote '{1}'? (RQT0002)
    # This string shall not end with full stop (.) since it is used as a title of ShouldProcess messages.
    Request_GitTag_FetchTag_ShouldProcessCaption = Fetch tag (RQT0003)
    Request_GitTag_FetchAllTags_ShouldProcessVerboseDescription = Fetching all tags from remote '{0}'. (RQT0004)
    Request_GitTag_FetchAllTags_ShouldProcessVerboseWarning = Are you sure you want to fetch all tags from remote '{0}'? (RQT0005)
    # This string shall not end with full stop (.) since it is used as a title of ShouldProcess messages.
    Request_GitTag_FetchAllTags_ShouldProcessCaption = Fetch all tags (RQT0006)
    Request_GitTag_FailedFetchTag = Failed to fetch tag '{0}' from remote '{1}'. Make sure the tag exists and remote is accessible. (RQT0007)
    Request_GitTag_FailedFetchAllTags = Failed to fetch all tags from remote '{0}'. (RQT0008)

    ## Start-GitRebase
    Start_GitRebase_RebasingFrom = Rebasing current branch from '{0}'. (SGRE0002)
    Start_GitRebase_FailedRebase = Failed to rebase from '{0}'. Make sure the branch exists and is accessible. (SGRE0003)
    Start_GitRebase_Success = Successfully rebased current branch. (SGRE0004)
    Start_GitRebase_ShouldProcessVerboseDescription = Rebasing current branch from '{0}'. (SGRE0005)
    Start_GitRebase_ShouldProcessVerboseWarning = Are you sure you want to rebase current branch from '{0}'? (SGRE0006)
    # This string shall not end with full stop (.) since it is used as a title of ShouldProcess messages.
    Start_GitRebase_ShouldProcessCaption = Rebase current branch (SGRE0007)

    ## Stop-GitRebase
    Stop_GitRebase_NotInRebaseState = The repository is not in a rebase state. Cannot abort rebase. (SPGR0001)
    Stop_GitRebase_AbortingRebase = Aborting current rebase operation. (SPGR0002)
    Stop_GitRebase_FailedAbort = Failed to abort rebase operation. (SPGR0003)
    Stop_GitRebase_Success = Successfully aborted rebase operation. (SPGR0004)
    Stop_GitRebase_ShouldProcessVerboseDescription = Aborting current rebase operation. (SPGR0005)
    Stop_GitRebase_ShouldProcessVerboseWarning = Are you sure you want to abort the current rebase operation? (SPGR0006)
    # This string shall not end with full stop (.) since it is used as a title of ShouldProcess messages.
    Stop_GitRebase_ShouldProcessCaption = Abort rebase operation (SPGR0007)

    ## Resume-GitRebase
    Resume_GitRebase_NotInRebaseState = The repository is not in a rebase state. Start a rebase operation first. (RGRE0001)
    Resume_GitRebase_FailedRebase = Failed to {0} rebase. Make sure the repository is in a valid rebase state. (RGRE0002)
    Resume_GitRebase_Resuming = Resuming rebase with action '{0}'. (RGRE0003)
    Resume_GitRebase_Continue_Success = Successfully continued rebase operation. (RGRE0004)
    Resume_GitRebase_Skip_Success = Successfully skipped commit and continued rebase operation. (RGRE0005)
    Resume_GitRebase_Continue_ShouldProcessVerboseDescription = Continuing rebase operation after resolving conflicts. (RGRE0006)
    Resume_GitRebase_Continue_ShouldProcessVerboseWarning = Are you sure you want to continue the rebase operation? (RGRE0007)
    # This string shall not end with full stop (.) since it is used as a title of ShouldProcess messages.
    Resume_GitRebase_Continue_ShouldProcessCaption = Continue rebase (RGRE0008)
    Resume_GitRebase_Skip_ShouldProcessVerboseDescription = Skipping current commit and continuing rebase operation. (RGRE0009)
    Resume_GitRebase_Skip_ShouldProcessVerboseWarning = Are you sure you want to skip the current commit? (RGRE0010)
    # This string shall not end with full stop (.) since it is used as a title of ShouldProcess messages.
    Resume_GitRebase_Skip_ShouldProcessCaption = Skip commit (RGRE0011)

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

    ## Test-IPv4Address
    Test_IPv4Address_ValidatingAddress = Testing IPv4 address format for '{0}'. (TIV0001)
    Test_IPv4Address_ValidationSuccessful = IPv4 address '{0}' is valid. (TIV0002)
    Test_IPv4Address_InvalidFormat = The input '{0}' is not a valid IPv4 address format. (TIV0003)

    ## Resolve-DnsName
    Resolve_DnsName_AttemptingResolution = Attempting to resolve DNS name '{0}'. (RDN0001)
    Resolve_DnsName_ResolutionSuccessful = Successfully resolved '{0}' to '{1}'. (RDN0002)
    Resolve_DnsName_ResolutionFailed = DNS resolution failed for '{0}'. (RDN0003)
    Resolve_DnsName_NoIPv4AddressFound = No IPv4 addresses found for '{0}'. (RDN0004)
    Resolve_DnsName_InvalidHostName = The host name cannot be null, empty, or contain only whitespace characters. (RDN0007)

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
    Invoke_PesterJob_AllLinesCovered = All lines are covered by tests. (IPJ0002)
    Invoke_PesterJob_AllLinesCoveredFiltered = All lines are covered by tests based on filtering criteria. (IPJ0003)
    Invoke_PesterJob_NoPesterObjectReturned = Unable to determine code coverage result because no Pester object was returned from the test execution. (IPJ0004)
    Invoke_PesterJob_PesterImportFailed = Failed to import Pester module at {0}. (IPJ0005)

    ## Switch-GitLocalBranch
    Switch_GitLocalBranch_FailedCheckoutLocalBranch = Failed to checkout the local branch '{0}'. Make sure the branch exists and is accessible. (SGLB0001)
    Switch_GitLocalBranch_ShouldProcessVerboseDescription = Switching to the local branch '{0}'. (SGLB0002)
    Switch_GitLocalBranch_ShouldProcessVerboseWarning = Are you sure you want to switch to the local branch '{0}'? (SGLB0003)
    # This string shall not end with full stop (.) since it is used as a title of ShouldProcess messages.
    Switch_GitLocalBranch_ShouldProcessCaption = Switch local branch (SGLB0004)

    ## Update-GitLocalBranch
    Update_GitLocalBranch_Rebase_ShouldProcessVerboseDescription = Rebasing the local branch '{0}' using tracking branch '{1}/{2}'. (UGLB0001)
    Update_GitLocalBranch_Rebase_ShouldProcessVerboseWarning = Are you sure you want to rebase the local branch '{0}'? (UGLB0002)
    # This string shall not end with full stop (.) since it is used as a title of ShouldProcess messages.
    Update_GitLocalBranch_Rebase_ShouldProcessCaption = Rebase local branch (UGLB0003)
    Update_GitLocalBranch_Pull_ShouldProcessVerboseDescription = Updating the local branch '{0}' by pulling from tracking branch '{1}/{2}'. (UGLB0004)
    Update_GitLocalBranch_Pull_ShouldProcessVerboseWarning = Are you sure you want to pull into the local branch '{0}'? (UGLB0005)
    # This string shall not end with full stop (.) since it is used as a title of ShouldProcess messages.
    Update_GitLocalBranch_Pull_ShouldProcessCaption = Pull into local branch (UGLB0006)
    Update_GitLocalBranch_FailedRebase = Failed to rebase the local branch '{0}' from remote '{1}'. Make sure the branch exists and is accessible. (UGLB0007)
    Update_GitLocalBranch_FailedPull = Failed to pull into the local branch '{0}' from remote '{1}'. Make sure the branch exists and is accessible. (UGLB0008)
    Update_GitLocalBranch_MergeConflictMessage = Merge conflict detected, when conflicts are resolved run `Resume-GitRebase` or to abort rebase run `Stop-GitRebase`. (UGLB0009)
    Update_GitLocalBranch_ReturnToBranchMessage = After rebase is finished run `Switch-GitLocalBranch -Name {0}` to return to the original branch. (UGLB0010)

    ## Update-RemoteTrackingBranch
    Update_RemoteTrackingBranch_FailedFetchBranchFromRemote = Failed to fetch from '{0}'. Make sure the branch exists in the remote git repository and the remote is accessible. (URTB0001)
    Update_RemoteTrackingBranch_FetchUpstream_ShouldProcessVerboseDescription = Fetching branch '{0}' from the upstream remote '{1}'. (URTB0002)
    Update_RemoteTrackingBranch_FetchUpstream_ShouldProcessVerboseWarning = Are you sure you want to fetch branch '{0}' from the upstream remote '{1}'? (URTB0003)
    # This string shall not end with full stop (.) since it is used as a title of ShouldProcess messages.
    Update_RemoteTrackingBranch_FetchUpstream_ShouldProcessCaption = Fetch upstream branch (URTB0004)

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

    ## Get-ClassAst
    Get_ClassAst_ParsingScriptFile = Parsing script file '{0}' for class definitions. (GCA0001)
    Get_ClassAst_FilteringForClass = Filtering for specific class '{0}'. (GCA0002)
    Get_ClassAst_ReturningAllClasses = Returning all class definitions found in the script file. (GCA0003)
    Get_ClassAst_FoundClassCount = Found {0} class definition(s) in the script file. (GCA0004)
    Get_ClassAst_ScriptFileNotFound = The script file '{0}' does not exist. (GCA0005)
    Get_ClassAst_ParseFailed = Parsing of script file '{0}' failed: {1} (GCA0006)

    ## Get-ClassResourceAst
    Get_ClassResourceAst_FoundClassCount = Found {0} DSC class resource definition(s) in the script file. (GCRA0004)

    ## Clear-AnsiSequence
    Clear_AnsiSequence_ProcessingBegin = Begin processing ANSI sequence clearing. (CAS0001)
    Clear_AnsiSequence_EmptyInput = Input string is null or empty, returning as-is. (CAS0002)
    Clear_AnsiSequence_ProcessingString = Processing string with {0} characters for ANSI sequence clearing. (CAS0003)
    Clear_AnsiSequence_ProcessingComplete = ANSI sequence clearing completed. (CAS0004)

    ## ConvertTo-DifferenceString
    ConvertTo_DifferenceString_ReferenceLabelTruncated = Reference label '{0}' is longer than the maximum width of {1} characters and has been truncated to '{2}'. (CTDS0001)

    ## Invoke-Git
    Invoke_Git_InvokingGitMessage = Invoking Git using arguments '{0}'. (IG0001)
    Invoke_Git_StandardOutputMessage = Output: '{0}' (IG0002)
    Invoke_Git_StandardErrorMessage = Error: '{0}' (IG0003)
    Invoke_Git_ExitCodeMessage = Exit code: '{0}' (IG0004)
    Invoke_Git_CommandDebug = Command: {0} (IG0005)
    Invoke_Git_WorkingDirectoryDebug = Working Directory: '{0}' (IG0006)
    Invoke_Git_TimeoutError = Git command timed out after {0} milliseconds. Command: git {1} (IG0007)
    Invoke_Git_KillProcessFailed = Failed to kill git process: {0} (IG0008)
    Invoke_Git_CommandFailed = Git command failed with exit code {0}. (IG0009)
'@
