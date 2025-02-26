<#
    .SYNOPSIS
        Validates the existence and SHA256 hash of a file.

    .DESCRIPTION
        The Assert-ScriptFileValidity function checks if a file exists at the
        specified path and validates that its SHA256 hash matches the expected
        value.

    .PARAMETER FilePath
        Specifies the path to the file to validate.

    .PARAMETER Hash
        Specifies the expected SHA256 hash of the file.

    .EXAMPLE
        Assert-ScriptFileValidity -FilePath "C:\path\to\myfile.txt" -Hash "A1B2C3D4E5F6..."

        Validates that the file "myfile.txt" exists at the specified path and that
        its SHA256 hash matches the provided hash.

    .INPUTS
        None. You cannot pipe input to this function.

    .OUTPUTS
        None. The function does not generate any output.
#>
function Assert-ScriptFileValidity
{
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $FilePath,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Hash
    )

    if (-not (Test-Path -Path $FilePath))
    {
        $writeErrorParameters = @{
            Message      = $script:localizedData.Assert_ScriptFileValidity_ScriptFileNotFound -f $FilePath
            Category     = 'ObjectNotFound'
            ErrorId      = 'APV0003' # cSpell: disable-line
            TargetObject = $FilePath
        }

        Write-Error @writeErrorParameters

        return
    }

    $hasExpectedHash = Test-FileHash -Path $FilePath -Algorithm 'SHA256' -ExpectedHash $Hash

    if (-not $hasExpectedHash)
    {
        $writeErrorParameters = @{
            Message      = $script:localizedData.Assert_ScriptFileValidity_HashValidationFailed -f $FilePath, $Hash
            Category     = 'InvalidData'
            ErrorId      = 'APV0004' # cSpell: disable-line
            TargetObject = $FilePath
        }

        Write-Error @writeErrorParameters

        return
    }
}
