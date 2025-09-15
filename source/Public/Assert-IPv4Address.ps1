<#
    .SYNOPSIS
        Asserts that a string is a valid IPv4 address.

    .DESCRIPTION
        Validates that the input string represents a valid IPv4 address by checking
        both format and value ranges (0-255 for each octet). This command also
        validates that octets do not have leading zeros (except for '0' itself)
        which is important for proper IPv4 address validation. Throws an exception
        if the input is not a valid IPv4 address.

    .PARAMETER IPAddress
        Specifies the string to validate as an IPv4 address. The string should
        be in the format of four decimal numbers separated by periods.

    .INPUTS
        None

    .OUTPUTS
        None. This command does not return a value but throws an exception if
        validation fails.

    .EXAMPLE
        PS> Assert-IPv4Address -IPAddress '192.168.1.1'

        This example validates a standard IPv4 address. No output is returned
        if the validation succeeds.

    .EXAMPLE
        PS> Assert-IPv4Address -IPAddress '999.999.999.999'

        This example demonstrates validation failure for an invalid IPv4 address
        with octets exceeding 255. A terminating error is thrown (ErrorId AIV0004).

    .EXAMPLE
        PS> Assert-IPv4Address -IPAddress '192.168.01.1'

        This example demonstrates validation failure for an IPv4 address with
        leading zeros in an octet. A terminating error is thrown (ErrorId AIV0003).

    .NOTES
        This command performs strict validation including checking for leading
        zeros which are not allowed in standard IPv4 address notation. Throws
        a terminating error if validation fails.
#>
function Assert-IPv4Address
{
    [CmdletBinding()]
    [OutputType()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $IPAddress
    )

    # Check if IPAddress is whitespace only before trimming
    if ([string]::IsNullOrWhiteSpace($IPAddress))
    {
        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                [System.InvalidOperationException]::new(($script:localizedData.Assert_IPv4Address_InvalidFormatException -f $IPAddress)),
                'AIV0003',
                [System.Management.Automation.ErrorCategory]::InvalidData,
                $IPAddress
            )
        )
    }

    $IPAddress = $IPAddress.Trim()

    Write-Verbose -Message ($script:localizedData.Assert_IPv4Address_ValidatingAddress -f $IPAddress)

    if (-not (Test-IPv4Address -IPAddress $IPAddress))
    {
        # Need to determine the specific error to throw the appropriate exception
        # Re-run the validation to get specific error details

        # Basic format check - must be four groups of digits (0 or 1-3 digits without leading zeros) separated by periods
        if ($IPAddress -notmatch '^(0|[1-9]\d{0,2})\.(0|[1-9]\d{0,2})\.(0|[1-9]\d{0,2})\.(0|[1-9]\d{0,2})$')
        {
            $PSCmdlet.ThrowTerminatingError(
                [System.Management.Automation.ErrorRecord]::new(
                    [System.InvalidOperationException]::new(($script:localizedData.Assert_IPv4Address_InvalidFormatException -f $IPAddress)),
                    'AIV0003',
                    [System.Management.Automation.ErrorCategory]::InvalidData,
                    $IPAddress
                )
            )
        }

        # Split and validate each octet to find the specific error
        $octets = $IPAddress -split '\.'

        foreach ($octet in $octets)
        {
            try
            {
                $octetValue = [System.Int32] $octet

                # Check if octet value is within valid range (0-255)
                if ($octetValue -lt 0 -or $octetValue -gt 255)
                {
                    $PSCmdlet.ThrowTerminatingError(
                        [System.Management.Automation.ErrorRecord]::new(
                            [System.InvalidOperationException]::new(($script:localizedData.Assert_IPv4Address_OctetOutOfRangeException -f $octet, $IPAddress)),
                            'AIV0004',
                            [System.Management.Automation.ErrorCategory]::InvalidData,
                            $IPAddress
                        )
                    )
                }
            }
            catch [System.Management.Automation.RuntimeException]
            {
                # Re-throw our custom exceptions
                throw
            }
            catch
            {
                $PSCmdlet.ThrowTerminatingError(
                    [System.Management.Automation.ErrorRecord]::new(
                        [System.InvalidOperationException]::new(($script:localizedData.Assert_IPv4Address_OctetConversionFailedException -f $octet, $IPAddress)),
                        'AIV0005',
                        [System.Management.Automation.ErrorCategory]::InvalidData,
                        $IPAddress
                    )
                )
            }
        }
    }

    Write-Verbose -Message ($script:localizedData.Assert_IPv4Address_ValidationSuccessful -f $IPAddress)
}
