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
        $writeErrorParameters = @{
            Message      = $_.Exception.ToString()
            Category     = 'InvalidData'
            ErrorId      = 'GPFC0001' # cSpell: disable-line
            TargetObject = $JsonContent
        }

        Write-Error @writeErrorParameters
    }
}
