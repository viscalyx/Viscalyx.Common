<#
    .SYNOPSIS
        Tests if a string is a valid IPv4 address.

    .DESCRIPTION
        Validates that the input string represents a valid IPv4 address by checking
        both format and value ranges (0-255 for each octet). This command also
        validates that octets do not have leading zeros (except for '0' itself)
        which is important for proper IPv4 address validation. Returns true if
        the input is a valid IPv4 address, false otherwise.

    .PARAMETER IPAddress
        Specifies the string to test as an IPv4 address. The string should
        be in the format of four decimal numbers separated by periods.

    .OUTPUTS
        [System.Boolean]
        Returns true if the string is a valid IPv4 address, false otherwise.

    .EXAMPLE
        PS> Test-IPv4Address -IPAddress '192.168.1.1'
        True

        This example tests a standard IPv4 address and returns True.

    .EXAMPLE
        PS> Test-IPv4Address -IPAddress '999.999.999.999'
        False

        This example tests an invalid IPv4 address with octets exceeding 255
        and returns False.

    .EXAMPLE
        PS> Test-IPv4Address -IPAddress '192.168.01.1'
        False

        This example tests an IPv4 address with leading zeros in an octet
        and returns False.

    .NOTES
        This command performs strict validation including checking for leading
        zeros which are not allowed in standard IPv4 address notation.
#>
function Test-IPv4Address
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $IPAddress
    )

    Write-Verbose -Message ($script:localizedData.Test_IPv4Address_ValidatingAddress -f $IPAddress)

    # Basic format check - must be four groups of 1-3 digits separated by periods
    if ($IPAddress -notmatch '^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$')
    {
        Write-Verbose -Message ($script:localizedData.Test_IPv4Address_InvalidFormat -f $IPAddress)
        return $false
    }

    # Split and validate each octet
    $octets = $IPAddress -split '\.'

    foreach ($octet in $octets)
    {
        try
        {
            $octetValue = [System.Int32] $octet

            # Check if octet value is within valid range (0-255)
            if ($octetValue -lt 0 -or $octetValue -gt 255)
            {
                Write-Verbose -Message ($script:localizedData.Test_IPv4Address_OctetOutOfRange -f $octet, $IPAddress)
                return $false
            }

            # Check for leading zeros (except for '0' itself)
            if ($octet.Length -gt 1 -and $octet.StartsWith('0'))
            {
                Write-Verbose -Message ($script:localizedData.Test_IPv4Address_InvalidLeadingZero -f $octet, $IPAddress)
                return $false
            }
        }
        catch
        {
            Write-Verbose -Message ($script:localizedData.Test_IPv4Address_OctetConversionFailed -f $octet, $IPAddress)
            return $false
        }
    }

    Write-Verbose -Message ($script:localizedData.Test_IPv4Address_ValidationSuccessful -f $IPAddress)
    return $true
}
