<#
    .SYNOPSIS
        Tests the hash of a file against an expected hash value.

    .DESCRIPTION
        This function calculates the hash of a file using a specified algorithm and
        compares it to an expected hash value. It returns $true if the calculated
        hash matches the expected hash, and $false otherwise.

    .PARAMETER Path
        The path to the file to be hashed.

    .PARAMETER Algorithm
        The hashing algorithm to use (SHA1, SHA256, SHA384, SHA512, or MD5).

    .PARAMETER ExpectedHash
        The expected hash value to compare against.

    .EXAMPLE
        Test-FileHash -Path "C:\example.txt" -Algorithm "SHA256" -ExpectedHash "e5b7e987e069f57439dfe8341f942f142e924a3a344b8941466011c5049a0855"

        Returns $true if the SHA256 hash of C:\example.txt matches the expected hash.
#>
function Test-FileHash
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Path,

        [Parameter(Mandatory = $true)]
        [ValidateSet('SHA1', 'SHA256', 'SHA384', 'SHA512', 'MD5')]
        [System.String]
        $Algorithm,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ExpectedHash
    )

    Write-Debug -Message ($script:localizedData.TestFileHash_CalculatingHash -f $Path, $Algorithm)

    $fileHash = Get-FileHash -Path $Path -Algorithm $Algorithm -ErrorAction 'Stop' |
        Select-Object -ExpandProperty Hash

    Write-Debug -Message ($script:localizedData.TestFileHash_ComparingHash -f $fileHash, $ExpectedHash)

    return $fileHash -eq $ExpectedHash
}
