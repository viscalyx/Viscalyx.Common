<#
    .SYNOPSIS
        Reads patch file content from a specified URI.

    .DESCRIPTION
        The Get-PatchFileContentFromURI function reads the content of a patch file from a specified URI.
        It attempts to fetch the patch file content using Invoke-RestMethod and returns the content as a JSON object.

    .PARAMETER URI
        Specifies the URI of the patch file.

    .EXAMPLE
        $patchFileContent = Get-PatchFileContentFromURI -URI "https://gist.githubusercontent.com/user/gistid/raw/MyModule_1.0.0_patch.json"

        Reads the content of the patch file located at the specified URI.

    .INPUTS
        None. You cannot pipe input to this function.

    .OUTPUTS
        System.Object. The function returns the content of the patch file as a JSON object.
#>
function Get-PatchFileContentFromUri
{
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Uri]
        $Uri
    )

    try
    {
        $response = Invoke-WebRequest -Uri $Uri -UseBasicParsing -ErrorAction 'Stop'
    }
    catch
    {
        $writeErrorParameters = @{
            Message      = $_.Exception.ToString()
            Category     = 'ConnectionError'
            ErrorId      = 'GPFCFU0001' # cSpell: disable-line
            TargetObject = $Uri
        }

        Write-Error @writeErrorParameters

        return $null
    }

    $patchFileContent = Get-PatchFileContent -JsonContent $response.Content -ErrorAction 'Stop'

    return $patchFileContent
}
