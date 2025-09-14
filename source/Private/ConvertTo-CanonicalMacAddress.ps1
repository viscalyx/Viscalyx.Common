<#
    .SYNOPSIS
        Normalizes a MAC address to the canonical format.

    .DESCRIPTION
        The ConvertTo-CanonicalMacAddress function normalizes a MAC address to
        a canonical format with uppercase hexadecimal characters, colon-separated,
        and two-digit octets (e.g., '00:11:22:33:44:55'). The function validates
        the MAC address length and format, providing fallback handling for invalid
        input.

    .PARAMETER MacAddress
        Specifies the MAC address to normalize. Can be in various formats like
        '00:11:22:33:44:55', '00-11-22-33-44-55', or '001122334455'.

    .EXAMPLE
        ConvertTo-CanonicalMacAddress -MacAddress 'a:b:c:d:e:f'

        Returns '0A:0B:0C:0D:0E:0F' with normalized uppercase and padded octets.

    .EXAMPLE
        ConvertTo-CanonicalMacAddress -MacAddress '00-11-22-33-44-55'

        Returns '00:11:22:33:44:55' with colons instead of hyphens.

    .INPUTS
        System.String

        MAC address as string for input.

    .OUTPUTS
        System.String

        Normalized MAC address in canonical format, or the original input if
        normalization fails.
#>
function ConvertTo-CanonicalMacAddress
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [System.String]
        $MacAddress
    )

    Write-Debug -Message ($script:localizedData.ConvertTo_CanonicalMacAddress_NormalizingMac -f $MacAddress)

    try
    {
        # Remove all non-hexadecimal characters (colons, hyphens, spaces, etc.)
        $cleanMac = $MacAddress -replace '[^0-9A-Fa-f]', ''

        # Validate that we have exactly 12 hexadecimal characters (6 octets * 2 chars each)
        if ($cleanMac.Length -ne 12)
        {
            Write-Debug -Message ($script:localizedData.ConvertTo_CanonicalMacAddress_InvalidLength -f $MacAddress, $cleanMac.Length)
            return $MacAddress
        }

        # Split into 6 pairs of 2 characters each, convert to uppercase, and join with colons
        $normalizedOctets = for ($i = 0; $i -lt 12; $i += 2)
        {
            $cleanMac.Substring($i, 2).ToUpper()
        }

        $normalizedMac = $normalizedOctets -join ':'

        Write-Debug -Message ($script:localizedData.ConvertTo_CanonicalMacAddress_NormalizedMac -f $MacAddress, $normalizedMac)

        return $normalizedMac
    }
    catch
    {
        Write-Debug -Message ($script:localizedData.ConvertTo_CanonicalMacAddress_NormalizationFailed -f $MacAddress, $_.Exception.Message)
        return $MacAddress
    }
}