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
        [ValidateNotNullOrEmpty()]
        [System.String]
        $HostName
    )

    Write-Verbose -Message ($script:localizedData.Resolve_DnsName_AttemptingResolution -f $HostName)

    try
    {
        $hostAddresses = [System.Net.Dns]::GetHostAddresses($HostName)

        $ipv4Address = $hostAddresses |
            Where-Object -FilterScript { $_.AddressFamily -eq 'InterNetwork' } |
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
    catch
    {
        $writeErrorParameters = @{
            Message      = $script:localizedData.Resolve_DnsName_ResolutionFailed -f $HostName
            Category     = 'ObjectNotFound'
            ErrorId      = 'RDN0005'
            TargetObject = $HostName
            Exception    = $_.Exception
        }

        Write-Error @writeErrorParameters

        return
    }
}
