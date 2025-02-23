<#
    .SYNOPSIS
        Validates the structure and data of a patch file.

    .DESCRIPTION
        The Assert-PatchFile function validates the structure and data of a patch file.
        It ensures that the patch file contains the necessary properties and that the
        values are valid. The function checks for required properties, verifies the
        module version and hash against the existing module, and ensures the start and
        end offsets are within bounds.

    .PARAMETER PatchFileContent
        Specifies the content of the patch file to validate.

    .EXAMPLE
        $patchFileContent = Get-Content -Path "C:\patches\MyModule_1.0.0_patch.json" -Raw | ConvertFrom-Json
        Assert-PatchFile -PatchFileContent $patchFileContent

        Validates the structure and data of the patch file content.

    .INPUTS
        None. You cannot pipe input to this function.

    .OUTPUTS
        None. The function does not generate any output.
#>
function Assert-PatchFile
{
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Object]
        $PatchFileContent
    )

    if (-not $PatchFileContent.ModuleName)
    {
        $writeErrorParameters = @{
            Message      = $script:localizedData.Assert_PatchFile_MissingModuleName
            Category     = 'InvalidData'
            ErrorId      = 'APF0001' # cSpell: disable-line
            TargetObject = $PatchFileContent
        }

        Write-Error @writeErrorParameters

        continue
    }

    if (-not $PatchFileContent.ModuleVersion)
    {
        $writeErrorParameters = @{
            Message      = $script:localizedData.Assert_PatchFile_MissingModuleVersion
            Category     = 'InvalidData'
            ErrorId      = 'APF0002' # cSpell: disable-line
            TargetObject = $PatchFileContent
        }

        Write-Error @writeErrorParameters

        continue
    }

    # Should have the property ModuleFiles
    if (-not $PatchFileContent.ModuleFiles)
    {
        $writeErrorParameters = @{
            Message      = $script:localizedData.Assert_PatchFile_MissingModuleFiles
            Category     = 'InvalidData'
            ErrorId      = 'APF0003' # cSpell: disable-line
            TargetObject = $PatchFileContent
        }

        Write-Error @writeErrorParameters

        continue
    }

    foreach ($scriptFile in $PatchFileContent.ModuleFiles)
    {
        if (-not $scriptFile.ScriptFileName)
        {
            $writeErrorParameters = @{
                Message      = $script:localizedData.Assert_PatchFile_MissingScriptFileName
                Category     = 'InvalidData'
                ErrorId      = 'APF0004' # cSpell: disable-line
                TargetObject = $scriptFile
            }

            Write-Error @writeErrorParameters

            continue
        }

        if (-not $scriptFile.OriginalHashSHA)
        {
            $writeErrorParameters = @{
                Message      = $script:localizedData.Assert_PatchFile_MissingOriginalHashSHA
                Category     = 'InvalidData'
                ErrorId      = 'APF0005' # cSpell: disable-line
                TargetObject = $scriptFile
            }

            Write-Error @writeErrorParameters

            continue
        }

        if (-not $scriptFile.ValidationHashSHA)
        {
            $writeErrorParameters = @{
                Message      = $script:localizedData.Assert_PatchFile_MissingValidationHashSHA
                Category     = 'InvalidData'
                ErrorId      = 'APF0006' # cSpell: disable-line
                TargetObject = $scriptFile
            }

            Write-Error @writeErrorParameters

            continue
        }

        # Should have the property FilePatches
        if (-not $scriptFile.FilePatches)
        {
            $writeErrorParameters = @{
                Message      = $script:localizedData.Assert_PatchFile_MissingFilePatches
                Category     = 'InvalidData'
                ErrorId      = 'APF0007' # cSpell: disable-line
                TargetObject = $scriptFile
            }

            Write-Error @writeErrorParameters

            continue
        }

        foreach ($patchEntry in $scriptFile.FilePatches)
        {
            if ($null -eq $patchEntry.StartOffset -or $null -eq $patchEntry.EndOffset)
            {
                $writeErrorParameters = @{
                    Message      = $script:localizedData.Assert_PatchFile_MissingOffset
                    Category     = 'InvalidData'
                    ErrorId      = 'APF0008' # cSpell: disable-line
                    TargetObject = $patchEntry
                }

                Write-Error @writeErrorParameters

                continue
            }

            if (-not $patchEntry.PatchContent)
            {
                $writeErrorParameters = @{
                    Message      = $script:localizedData.Assert_PatchFile_MissingPatchContent
                    Category     = 'InvalidData'
                    ErrorId      = 'APF0009' # cSpell: disable-line
                    TargetObject = $patchEntry
                }

                Write-Error @writeErrorParameters

                continue
            }
        }
    }
}
