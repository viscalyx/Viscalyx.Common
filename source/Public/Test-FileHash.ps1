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

    Write-Debug -Message "Calculating hash for file: $Path using algorithm: $Algorithm"

    $fileHash = Get-FileHash -Path $Path -Algorithm $Algorithm -ErrorAction 'Stop' |
        Select-Object -ExpandProperty Hash

    Write-Debug -Message "Comparing file hash: $fileHash with expected hash: $ExpectedHash"

    return $fileHash -eq $ExpectedHash
}
