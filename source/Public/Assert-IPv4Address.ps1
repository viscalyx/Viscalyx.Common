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
        with octets exceeding 255.

    .EXAMPLE
        PS> Assert-IPv4Address -IPAddress '192.168.01.1'

        This example demonstrates validation failure for an IPv4 address with
        leading zeros in an octet.
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

    Write-Verbose -Message ($script:localizedData.Assert_IPv4Address_ValidatingAddress -f $IPAddress)

    if (-not (Test-IPv4Address -IPAddress $IPAddress))
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

    Write-Verbose -Message ($script:localizedData.Assert_IPv4Address_ValidationSuccessful -f $IPAddress)
}
