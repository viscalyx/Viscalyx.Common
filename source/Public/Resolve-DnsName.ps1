<#
    .SYNOPSIS
        Resolve a DNS host name (or dotted IP string) to a single IPv4 address.

    .DESCRIPTION
        Uses the cross-platform .NET System.Net.Dns class to resolve DNS names
        to IPv4 addresses, providing compatibility across Windows, macOS, and Linux
        platforms even when the built-in Resolve-DnsName cmdlet is not available.
        If the input is already a valid IPv4 address, it will be returned as-is.

    .PARAMETER HostName
        Specifies the DNS host name to resolve or an IPv4 address literal. The
        parameter accepts both fully qualified domain names (FQDN) and simple
        host names. IPv4 addresses are validated and returned without resolution.

    .INPUTS
        System.String

        DNS host name or IPv4 address as string.

    .OUTPUTS
        System.String

        Returns the first IPv4 address found for the specified host name, or the
        original IPv4 address if the input was already a valid IP address. Returns
        nothing if resolution fails.

    .EXAMPLE
        PS> Resolve-DnsName 'pc.company.local'
        192.168.1.42

        This example resolves the host name 'pc.company.local' to its IPv4 address.

    .EXAMPLE
        PS> Resolve-DnsName '192.168.1.42'
        192.168.1.42

        This example demonstrates that if the input is already a valid IPv4 address,
        it is returned without modification.

    .EXAMPLE
        PS> Resolve-DnsName 'google.com'
        142.250.191.14

        This example resolves the public domain 'google.com' to one of its IPv4
        addresses.

    .NOTES
        This function uses the .NET System.Net.Dns.GetHostAddresses method which
        provides cross-platform DNS resolution capabilities. Only IPv4 addresses
        are returned; IPv6 addresses are filtered out.
#>
function Resolve-DnsName
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true, Position = 0)]
        [System.String]
        $HostName
    )

    # Additional validation for whitespace-only strings
    if ([System.String]::IsNullOrWhiteSpace($HostName))
    {
        $writeErrorParameters = @{
            Message      = $script:localizedData.Resolve_DnsName_InvalidHostName
            Category     = 'InvalidArgument'
            ErrorId      = 'RDN0007'
            TargetObject = $HostName
        }

        $errorRecord = [System.Management.Automation.ErrorRecord]::new(
            [System.ArgumentException]::new($writeErrorParameters.Message),
            $writeErrorParameters.ErrorId,
            $writeErrorParameters.Category,
            $writeErrorParameters.TargetObject
        )

        $PSCmdlet.ThrowTerminatingError($errorRecord)
    }

    # Fast path: input is already an IPv4 literal
    if (Test-IPv4Address -IPAddress $HostName)
    {
        Write-Verbose -Message ($script:localizedData.Resolve_DnsName_ResolutionSuccessful -f $HostName, $HostName)
        return $HostName
    }

    Write-Verbose -Message ($script:localizedData.Resolve_DnsName_AttemptingResolution -f $HostName)

    try
    {
        $hostAddresses = [System.Net.Dns]::GetHostAddresses($HostName)

        $ipv4Address = $hostAddresses |
            Where-Object -FilterScript { $_.AddressFamily -eq [System.Net.Sockets.AddressFamily]::InterNetwork } |
            Select-Object -First 1

        if ($null -ne $ipv4Address)
        {
            $resolvedAddress = $ipv4Address.IPAddressToString
            Write-Verbose -Message ($script:localizedData.Resolve_DnsName_ResolutionSuccessful -f $HostName, $resolvedAddress)
            return $resolvedAddress
        }
        else
        {
            $writeErrorParameters = @{
                Message      = $script:localizedData.Resolve_DnsName_NoIPv4AddressFound -f $HostName
                Category     = 'ObjectNotFound'
                ErrorId      = 'RDN0006'
                TargetObject = $HostName
            }

            Write-Error @writeErrorParameters

            return
        }
    }
    catch [System.Exception]
    {
        $errorMessage = $script:localizedData.Resolve_DnsName_ResolutionFailed -f $HostName

        $newException = New-Exception -Message $errorMessage -ErrorRecord $_

        $writeErrorParameters = @{
            Message      = $errorMessage
            Category     = 'ObjectNotFound'
            ErrorId      = 'RDN0005'
            TargetObject = $HostName
            Exception    = $newException
        }

        Write-Error @writeErrorParameters

        return
    }
}
