<#
    .SYNOPSIS
        Applies patches to PowerShell modules based on a patch file.

    .DESCRIPTION
        The Install-ModulePatch command reads a patch file, validates its content, and applies patches to PowerShell modules.
        The patch file can be provided as a local file path or a URL. The command verifies the module version and hash,
        and replaces the content according to the patch file. It supports multiple patch entries in a single patch file,
        applying them in descending order of StartOffset.

    .PARAMETER Path
        Specifies the path to the patch file.

    .PARAMETER URI
        Specifies the URL of the patch file.

    .PARAMETER Force
        Overrides the confirmation dialogs.

    .EXAMPLE
        Install-ModulePatch -Path "C:\patches\MyModule_1.0.0_patch.json"

        Applies the patches specified in the patch file located at "C:\patches\MyModule_1.0.0_patch.json".

    .EXAMPLE
        Install-ModulePatch -URI "https://gist.githubusercontent.com/user/gistid/raw/MyModule_1.0.0_patch.json"

        Applies the patches specified in the patch file located at the specified URL.

    .INPUTS
        None. You cannot pipe input to this function.

    .OUTPUTS
        None. The function does not generate any output.
#>
function Install-ModulePatch
{
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param
    (
        [Parameter(Mandatory = $true, ParameterSetName = 'Path')]
        [System.String]
        $Path,

        [Parameter(Mandatory = $true, ParameterSetName = 'URI')]
        [System.Uri]
        $URI,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Force,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $SkipHashCheck
    )

    if ($Force.IsPresent -and -not $Confirm)
    {
        $ConfirmPreference = 'None'
    }

    $patchLocation = if ($PSCmdlet.ParameterSetName -eq 'Path')
    {
        $Path
    }
    else
    {
        $URI
    }

    $verboseDescriptionMessage = $script:localizedData.Install_ModulePatch_ShouldProcessVerboseDescription -f $patchLocation
    $verboseWarningMessage = $script:localizedData.Install_ModulePatch_ShouldProcessVerboseWarning -f $patchLocation
    $captionMessage = $script:localizedData.Install_ModulePatch_ShouldProcessCaption

    if ($PSCmdlet.ShouldProcess($verboseDescriptionMessage, $verboseWarningMessage, $captionMessage))
    {
        $patchFileContent = if ($PSCmdlet.ParameterSetName -eq 'Path')
        {
            Write-Debug -Message ($script:localizedData.Install_ModulePatch_Debug_Path -f $Path)

            Get-PatchFileContentFromPath -Path $Path -ErrorAction 'Stop'
        }
        else
        {
            Write-Debug -Message ($script:localizedData.Install_ModulePatch_Debug_URI -f $URI)

            Get-PatchFileContentFromURI -URI $URI -ErrorAction 'Stop'
        }

        Write-Debug -Message ($script:localizedData.Install_ModulePatch_Debug_PatchFileContent -f ($patchFileContent | ConvertTo-Json -Compress))

        Assert-PatchFile -PatchFileContent $patchFileContent

        $patchFileContent = $patchFileContent |
            Sort-Object -Property StartOffset -Descending

        # Initialize progress bar
        $progressId = 1
        $progressActivity = $script:localizedData.Install_ModulePatch_Progress_Activity
        $progressStatus = $script:localizedData.Install_ModulePatch_Progress_Status

        # Show progress bar
        Write-Progress -Id $progressId -Activity $progressActivity -Status $progressStatus -PercentComplete 0

        $totalPatches = $patchFileContent.Count
        $patchCounter = 0

        foreach ($patchEntry in $patchFileContent)
        {
            $patchCounter++
            $progressPercentComplete = ($patchCounter / $totalPatches) * 100
            $progressCurrentOperation = $script:localizedData.Install_ModulePatch_Progress_CurrentOperation -f $patchEntry.ModuleName, $patchEntry.ModuleVersion, $patchEntry.ScriptFileName

            Write-Debug -Message ($script:localizedData.Install_ModulePatch_Debug_PatchEntry -f ($patchEntry | ConvertTo-Json -Compress))

            # Update progress bar
            Write-Progress -Id $progressId -Activity $progressActivity -Status "$progressStatus - $progressCurrentOperation" -PercentComplete $progressPercentComplete

            Merge-Patch -PatchEntry $patchEntry -ErrorAction 'Stop'

            # Should we skip hash check?
            if (-not $SkipHashCheck.IsPresent)
            {
                # # Verify the SHA256 hash of the patched file
                # $moduleScriptFilePath = Join-Path -Path (Get-Module -Name $patchEntry.ModuleName -ListAvailable).ModuleBase -ChildPath $patchEntry.ScriptFileName
                # $patchedFileHash = Test-FileHash -Path $moduleScriptFilePath -Algorithm 'SHA256' -ExpectedHash $patchEntry.PatchedHashSHA

                # if (-not $patchedFileHash -and -not $SkipHashCheck)
                # {
                #     $errorMessage = $script:localizedData.Install_ModulePatch_Error_HashMismatch -f $patchEntry.ModuleName, $patchEntry.ModuleVersion, $patchEntry.ScriptFileName

                #     throw $errorMessage
                # }
                # else
                # {
                #     Write-Debug -Message "$($patchEntry.ScriptFileName) at $($patchEntry.StartOffset) has been patched successfully, and hash matches."
                # }
            }
            # else
            # {
            #     Write-Debug -Message "$($patchEntry.ScriptFileName) at $($patchEntry.StartOffset) has been patched successfully, but hash check was skipped."
            # }
        }

        # Clear progress bar
        Write-Progress -Id $progressId -Activity $progressActivity -Completed

        Write-Debug -Message "Patching completed successfully."
    }
}
