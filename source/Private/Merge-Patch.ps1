<#
    .SYNOPSIS
        Applies patches to PowerShell modules based on a patch file.

    .DESCRIPTION
        The Merge-Patch function reads a patch file, validates its content, and applies patches to PowerShell modules.
        The patch file can be provided as a local file path or a URL. The function verifies the module version and hash,
        and replaces the content according to the patch file. It supports multiple patch entries in a single patch file,
        applying them in descending order of StartOffset.

    .PARAMETER PatchEntry
        Specifies the patch entry to apply.

    .EXAMPLE
        $patchFileContent = Get-Content -Path "C:\patches\MyModule_1.0.0_patch.json" -Raw | ConvertFrom-Json
        foreach ($patchEntry in $patchFileContent) {
            Merge-Patch -PatchEntry $patchEntry
        }

        Applies the patches specified in the patch file content.

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
        [System.Object]
        $PatchEntry
    )

    $modulePath = Join-Path -Path (Get-Module -Name $PatchEntry.ModuleName).ModuleBase -ChildPath $PatchEntry.ScriptFileName

    if (-not (Test-Path -Path $modulePath))
    {
        $writeErrorParameters = @{
            Message      = $script:localizedData.Install_ModulePatch_ScriptFileNotFound -f $modulePath
            Category     = 'ObjectNotFound'
            ErrorId      = 'GPFCFP0001' # cSpell: disable-line
            TargetObject = $modulePath
        }

        Write-Error @writeErrorParameters
    }

    $scriptContent = Get-Content -Path $modulePath -Raw

    $startOffset = $PatchEntry.StartOffset
    $endOffset = $PatchEntry.EndOffset

    if ($startOffset -lt 0 -or $endOffset -gt $scriptContent.Length -or $startOffset -ge $endOffset)
    {
        $writeErrorParameters = @{
            Message      = $script:localizedData.Install_ModulePatch_InvalidStartOrEndOffset -f $startOffset, $endOffset
            Category     = 'InvalidArgument'
            ErrorId      = 'GPFCFP0001' # cSpell: disable-line
            TargetObject = $modulePath
        }

        Write-Error @writeErrorParameters
    }

    $patchedContent = $scriptContent.Substring(0, $startOffset) + $PatchEntry.PatchContent + $scriptContent.Substring($endOffset)

    Set-Content -Path $modulePath -Value $patchedContent
}
