<#
    .SYNOPSIS
        Reads patch file content from a specified path.

    .DESCRIPTION
        The Get-PatchFileContentFromPath function reads the content of a patch file from a specified path.
        It attempts to fetch the patch file content using Get-Content and returns the content as a JSON object.

    .PARAMETER Path
        Specifies the path of the patch file.

    .EXAMPLE
        $patchFileContent = Get-PatchFileContentFromPath -Path "C:\patches\MyModule_1.0.0_patch.json"

        Reads the content of the patch file located at the specified path.

    .INPUTS
        None. You cannot pipe input to this function.

    .OUTPUTS
        System.Object. The function returns the content of the patch file as a JSON object.
#>
function Get-PatchFileContentFromPath
{
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Path
    )

    if (-not (Test-Path -Path $Path))
    {
        $writeErrorParameters = @{
            Message      = $script:localizedData.Install_ModulePatch_PatchFilePathNotFound -f $Path
            Category     = 'ObjectNotFound'
            ErrorId      = 'GPFCFP0001' # cSpell: disable-line
            TargetObject = $Path
        }

        Write-Error @writeErrorParameters
    }

    $jsonContent = Get-Content -Path $Path -Raw

    $patchFileContent = Get-PatchFileContent -JsonContent $jsonContent

    return $patchFileContent
}
