<#
.SYNOPSIS
    Converts JSON content to a PowerShell object.

.DESCRIPTION
    The Get-PatchFileContent function converts JSON content to a PowerShell object.
    It takes the JSON content as input and returns the corresponding PowerShell object.

.PARAMETER JsonContent
    Specifies the JSON content to convert.

.EXAMPLE
    $jsonContent = Get-Content -Path "C:\patches\MyModule_1.0.0_patch.json" -Raw
    $patchFileContent = Get-PatchFileContent -JsonContent $jsonContent

    Converts the JSON content to a PowerShell object.

.INPUTS
    None. You cannot pipe input to this function.

.OUTPUTS
    System.Object. The function returns the JSON content as a PowerShell object.
#>
function Get-PatchFileContent
{
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $JsonContent
    )

    try
    {
        $patchFileContent = $JsonContent | ConvertFrom-Json

        return $patchFileContent
    }
    catch
    {
        throw "Failed to convert JSON content to PowerShell object. Error: $_"
    }
}
