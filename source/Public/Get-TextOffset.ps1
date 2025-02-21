<#
    .SYNOPSIS
        Finds the start and end offsets of a given text within a file.

    .DESCRIPTION
        Reads the content of a file and searches for the specified text.
        Returns the start and end offsets of the text within the file.

    .PARAMETER FilePath
        The path to the file.

    .PARAMETER TextToFind
        The text to search for within the file.

    .EXAMPLE
        Get-TextOffset -FilePath 'C:\path\to\your\script.ps1' -TextToFind 'if ($condition) {'
#>
function Get-TextOffset
{
    [OutputType([PSCustomObject])]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $FilePath,

        [Parameter(Mandatory = $true)]
        [System.String]
        $TextToFind
    )

    $scriptContent = (Get-Content -Path $FilePath -Raw -ErrorAction 'Stop') -replace '\r?\n', "`n"

    $TextToFind = $TextToFind -replace '\r?\n', "`n"

    $startIndex = $scriptContent.IndexOf($TextToFind)

    $result = $null

    if ($startIndex -ne -1)
    {
        $endIndex = $startIndex + $TextToFind.Length

        $result = [PSCustomObject] @{
            ScriptFile  = $FilePath
            StartOffset = $startIndex
            EndOffset   = $endIndex
            JsonText    = (($TextToFind -replace '(["\\])', '\$1') -replace '\n', '\n') -replace '\t', '\t'
        }
    }
    else
    {
        Write-Warning "Text '$TextToFind' not found in the file '$FilePath'."
    }

    return $result
}
