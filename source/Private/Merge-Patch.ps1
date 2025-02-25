<#
    .SYNOPSIS
        Applies a patch to a file.

    .DESCRIPTION
        The `Merge-Patch` function applies a patch to a file based on the provided
        patch entry. It reads the content of the file, applies the patch, and writes
        the patched content back to the file.

    .PARAMETER FilePath
        Specifies the path to the file to be patched.

    .PARAMETER PatchEntry
        Specifies the patch entry to apply. The patch entry should contain the
        `StartOffset`, `EndOffset`, and `PatchContent` properties.

    .EXAMPLE
        Merge-Patch -FilePath "C:\path\to\myfile.txt" -PatchEntry $patchEntry

        Applies the patch specified in `$patchEntry` to the file "C:\path\to\myfile.txt".

    .INPUTS
        None. You cannot pipe input to this function.

    .OUTPUTS
        None. The function does not generate any output.
#>
function Merge-Patch
{
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $FilePath,

        [Parameter(Mandatory = $true)]
        [System.Object]
        $PatchEntry
    )

    # TODO: Get-Content and Set-Content should be moved out to Install-ModulePatch so that we read and write once, and also can rollback on error.
    $scriptContent = Get-Content -Path $FilePath -Raw -ErrorAction 'Stop'

    $startOffset = $PatchEntry.StartOffset
    $endOffset = $PatchEntry.EndOffset

    if ($startOffset -lt 0 -or $endOffset -gt $scriptContent.Length -or $startOffset -ge $endOffset)
    {
        $writeErrorParameters = @{
            Message      = $script:localizedData.Merge_Patch_InvalidStartOrEndOffset -f $startOffset, $endOffset, $FilePath
            Category     = 'InvalidArgument'
            ErrorId      = 'MP0001' # cSpell: disable-line
            TargetObject = $FilePath
        }

        Write-Error @writeErrorParameters

        return
    }

    $patchedContent = $scriptContent.Substring(0, $startOffset) + $PatchEntry.PatchContent + $scriptContent.Substring($endOffset)

    Set-Content -Path $FilePath -Value $patchedContent -ErrorAction 'Stop'

    Write-Debug -Message ($script:localizedData.Merge_Patch_SuccessfullyPatched -f $FilePath, $PatchEntry.StartOffset)
}
