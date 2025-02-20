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

    foreach ($patchEntry in $PatchFileContent)
    {
        if (-not $patchEntry.ModuleName)
        {
            $writeErrorParameters = @{
                Message      = $script:localizedData.Assert_PatchFile_MissingModuleName
                Category     = 'InvalidData'
                ErrorId      = 'APF0001' # cSpell: disable-line
                TargetObject = $PatchEntry
            }

            Write-Error @writeErrorParameters

            continue
        }

        if (-not $patchEntry.ModuleVersion)
        {
            $writeErrorParameters = @{
                Message      = $script:localizedData.Assert_PatchFile_MissingModuleVersion
                Category     = 'InvalidData'
                ErrorId      = 'APF0002' # cSpell: disable-line
                TargetObject = $PatchEntry
            }
            Write-Error @writeErrorParameters
            continue
        }

        if (-not $patchEntry.ScriptFileName)
        {
            $writeErrorParameters = @{
                Message      = $script:localizedData.Assert_PatchFile_MissingScriptFileName
                Category     = 'InvalidData'
                ErrorId      = 'APF0003' # cSpell: disable-line
                TargetObject = $PatchEntry
            }

            Write-Error @writeErrorParameters

            continue
        }

        if (-not $patchEntry.HashSHA)
        {
            $writeErrorParameters = @{
                Message      = $script:localizedData.Assert_PatchFile_MissingHashSHA
                Category     = 'InvalidData'
                ErrorId      = 'APF0004' # cSpell: disable-line
                TargetObject = $PatchEntry
            }

            Write-Error @writeErrorParameters

            continue
        }

        if ($null -eq $patchEntry.StartOffset -or $null -eq $patchEntry.EndOffset)
        {
            $writeErrorParameters = @{
                Message      = $script:localizedData.Assert_PatchFile_MissingOffset
                Category     = 'InvalidData'
                ErrorId      = 'APF0005' # cSpell: disable-line
                TargetObject = $PatchEntry
            }

            Write-Error @writeErrorParameters

            continue
        }

        if (-not $patchEntry.PatchContent)
        {
            $writeErrorParameters = @{
                Message      = $script:localizedData.Assert_PatchFile_MissingPatchContent
                Category     = 'InvalidData'
                ErrorId      = 'APF0006' # cSpell: disable-line
                TargetObject = $PatchEntry
            }

            Write-Error @writeErrorParameters

            continue
        }

        Assert-PatchValidity -PatchEntry $patchEntry -ErrorAction 'Stop'
    }
}
