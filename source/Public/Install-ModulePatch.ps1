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

    .PARAMETER Uri
        Specifies the URL of the patch file.

    .PARAMETER Force
        Overrides the confirmation dialogs.

    .PARAMETER SkipHashValidation
        Skips the hash validation after patching are completed.

    .EXAMPLE
        Install-ModulePatch -Path "C:\patches\MyModule_1.0.0_patch.json"

        Applies the patches specified in the patch file located at "C:\patches\MyModule_1.0.0_patch.json".

    .EXAMPLE
        Install-ModulePatch -Uri "https://gist.githubusercontent.com/user/gistid/raw/MyModule_1.0.0_patch.json"

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
        $Uri,

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
        $Uri
    }

    $verboseDescriptionMessage = $script:localizedData.Install_ModulePatch_ShouldProcessDescription -f $patchLocation
    $verboseWarningMessage = $script:localizedData.Install_ModulePatch_ShouldProcessConfirmation -f $patchLocation
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
            Write-Debug -Message ($script:localizedData.Install_ModulePatch_Debug_URI -f $Uri)

            Get-PatchFileContentFromURI -Uri $Uri -ErrorAction 'Stop'
        }

        Write-Debug -Message ($script:localizedData.Install_ModulePatch_Debug_PatchFileContent -f ($patchFileContent | ConvertTo-Json -Depth 10 -Compress))

        Assert-PatchFile -PatchFileObject $patchFileContent

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

            # Initialize progress bar
            $progressId = 1
            $progressActivity = $script:localizedData.Install_ModulePatch_Progress_Activity
            $progressStatus = $script:localizedData.Install_ModulePatch_Progress_Status

            # Show progress bar
            Write-Progress -Id $progressId -Activity $progressActivity -Status $progressStatus -PercentComplete 0

            $patchFileEntries = $moduleFile.FilePatches |
                Sort-Object -Property 'StartOffset' -Descending

            $totalPatches = @($patchFileEntries).Count
            $patchCounter = 0

            foreach ($patchEntry in $patchFileEntries)
            {
                $patchCounter++

                $progressPercentComplete = ($patchCounter / $totalPatches) * 100
                $progressCurrentOperation = $script:localizedData.Install_ModulePatch_Progress_CurrentOperation -f $moduleFile.ScriptFileName, $patchEntry.StartOffset

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
                $hasNewFileHash = $false

                foreach ($validationHash in $moduleFile.ValidationHashSHA)
                {
                    # Verify the SHA256 hash of the patched file
                    $hasNewFileHash = Test-FileHash -Path $scriptFilePath -Algorithm 'SHA256' -ExpectedHash $validationHash

                    if ($hasNewFileHash)
                    {
                        break
                    }
                }

                if (-not $hasNewFileHash)
                {
                    $writeErrorParameters = @{
                        Message      = $script:localizedData.Install_ModulePatch_Error_HashMismatch -f $scriptFilePath
                        Category     = 'InvalidData'
                        ErrorId      = 'IMP0002' # cSpell: disable-line
                        TargetObject = $patchFileContent.ModuleName
                    }

                    Write-Error @writeErrorParameters

                    return $null
                }

                Write-Debug -Message ($script:localizedData.Install_ModulePatch_Patch_Success -f $scriptFilePath)
            }
            else
            {
                Write-Debug -Message ($script:localizedData.Install_ModulePatch_Patch_SuccessHashValidationSkipped -f $scriptFilePath)
            }
        }
    }
}
