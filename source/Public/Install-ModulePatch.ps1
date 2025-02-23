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

    .PARAMETER SkipHashValidation
        Skips the hash validation after patching are completed.

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
        $SkipHashValidation
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

        Write-Debug -Message ($script:localizedData.Install_ModulePatch_Debug_PatchFileContent -f ($patchFileContent | ConvertTo-Json -Depth 10 -Compress))

        Assert-PatchFile -PatchFileContent $patchFileContent

        $module = Get-ModuleByVersion -Name $patchFileContent.ModuleName -Version $patchFileContent.ModuleVersion

        if (-not $module)
        {
            $writeErrorParameters = @{
                Message      = $script:localizedData.Install_ModulePatch_MissingModule -f $patchFileContent.ModuleName, $patchFileContent.ModuleVersion
                Category     = 'ObjectNotFound'
                ErrorId      = 'IMP0001' # cSpell: disable-line
                TargetObject = $patchFileContent.ModuleName
            }

            Write-Error @writeErrorParameters

            return
        }

        foreach ($moduleFile in $patchFileContent.ModuleFiles)
        {
            $scriptFilePath = Join-Path -Path $module.ModuleBase -ChildPath $moduleFile.ScriptFileName

            Assert-ScriptFileValidity -FilePath $scriptFilePath -Hash $moduleFile.OriginalHashSHA -ErrorAction 'Stop'

            Write-Debug -Message "Successfully validated script file: $scriptFilePath"

            # Initialize progress bar
            $progressId = 1
            $progressActivity = $script:localizedData.Install_ModulePatch_Progress_Activity
            $progressStatus = $script:localizedData.Install_ModulePatch_Progress_Status

            # Show progress bar
            Write-Progress -Id $progressId -Activity $progressActivity -Status $progressStatus -PercentComplete 0

            $patchFileEntries = $moduleFile.FilePatches |
                Sort-Object -Property 'StartOffset' -Descending

            $totalPatches = $patchFileEntries.Count
            $patchCounter = 0

            foreach ($patchEntry in $patchFileEntries)
            {
                $patchCounter++
                $progressPercentComplete = ($patchCounter / $totalPatches) * 100
                $progressCurrentOperation = $script:localizedData.Install_ModulePatch_Progress_CurrentOperation -f $patchFileContent.ModuleName, $patchFileContent.ModuleVersion, $moduleFile.ScriptFileName

                Write-Debug -Message ($script:localizedData.Install_ModulePatch_Debug_PatchEntry -f ($patchEntry | ConvertTo-Json -Depth 10 -Compress))

                # Update progress bar
                Write-Progress -Id $progressId -Activity $progressActivity -Status "$progressStatus - $progressCurrentOperation" -PercentComplete $progressPercentComplete

                Merge-Patch -FilePath $scriptFilePath -PatchEntry $patchEntry -ErrorAction 'Stop'
            }

            # Clear progress bar
            Write-Progress -Id $progressId -Activity $progressActivity -Completed

            # Should we skip hash check?
            if (-not $SkipHashValidation.IsPresent)
            {
                # # Verify the SHA256 hash of the patched file
                # $moduleScriptFilePath = Join-Path -Path (Get-Module -Name $patchEntry.ModuleName -ListAvailable).ModuleBase -ChildPath $patchEntry.ScriptFileName
                # $hasNewFileHash = Test-FileHash -Path $moduleScriptFilePath -Algorithm 'SHA256' -ExpectedHash $patchEntry.ValidationHashSHA

                # if (-not $hasNewFileHash)
                # {
                #     $errorMessage = $script:localizedData.Install_ModulePatch_Error_HashMismatch -f $patchEntry.ModuleName, $patchEntry.ModuleVersion, $patchEntry.ScriptFileName

                #     throw $errorMessage
                # }
                # else
                # {
                #     Write-Debug -Message "$($patchEntry.ScriptFileName) at $($patchEntry.StartOffset) has been patched successfully, and hash matches."
                # }
            }
            else
            {
                Write-Debug -Message "$scriptFilePath has been patched successfully, but hash validation was skipped."
            }
        }

        Write-Debug -Message 'Patching completed successfully.'
    }
}
