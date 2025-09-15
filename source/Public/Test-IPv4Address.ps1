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

    .INPUTS
        System.String

        Accepts strings from the pipeline for testing as IPv4 addresses.

    .OUTPUTS
        [System.Boolean]

        Returns true if the string is a valid IPv4 address, false otherwise.

    .EXAMPLE
        Test-IPv4Address -IPAddress '192.168.1.1'

        This example tests a standard IPv4 address and returns True.

    .EXAMPLE
        '192.168.1.1', '10.0.0.1' | Test-IPv4Address

        This example demonstrates pipeline input with multiple IP addresses.

    .EXAMPLE
        Test-IPv4Address -IPAddress '999.999.999.999'

        This example tests an invalid IPv4 address with octets exceeding 255
        and returns False.

    .EXAMPLE
        Test-IPv4Address -IPAddress '192.168.01.1'

        This example tests an IPv4 address with leading zeros in an octet
        and returns False.

    .NOTES
        This command performs strict validation including checking for leading
        zeros which are not allowed in standard IPv4 address notation.
#>
function Test-IPv4Address
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('UseSyntacticallyCorrectExamples', '', Justification = 'Because the examples are syntactically correct. The rule does not seem to understand that there is pipeline input.')]
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $IPAddress
    )

    process
    {
        Write-Verbose -Message ($script:localizedData.Test_IPv4Address_ValidatingAddress -f $IPAddress)

        # Validate IPv4 address format and range (0-255) with no leading zeros
        if ($IPAddress -notmatch '^(?:0|[1-9]\d?|1\d\d|2[0-4]\d|25[0-5])(?:\.(?:0|[1-9]\d?|1\d\d|2[0-4]\d|25[0-5])){3}$')
        {
            Write-Verbose -Message ($script:localizedData.Test_IPv4Address_InvalidFormat -f $IPAddress)
            return $false
        }

        Write-Verbose -Message ($script:localizedData.Test_IPv4Address_ValidationSuccessful -f $IPAddress)
        return $true
    }
}
