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
            throw "Patch entry is missing 'ModuleName'."
        }

        if (-not $patchEntry.ModuleVersion)
        {
            throw "Patch entry is missing 'ModuleVersion'."
        }

        if (-not $patchEntry.ScriptFileName)
        {
            throw "Patch entry is missing 'ScriptFileName'."
        }

        if (-not $patchEntry.HashSHA)
        {
            throw "Patch entry is missing 'HashSHA'."
        }

        if ($null -eq $patchEntry.StartOffset -or $null -eq $patchEntry.EndOffset)
        {
            throw "Patch entry is missing 'StartOffset' or 'EndOffset'."
        }

        if (-not $patchEntry.PatchContent)
        {
            throw "Patch entry is missing 'PatchContent'."
        }

        Assert-PatchValidity -PatchEntry $patchEntry
    }
}
