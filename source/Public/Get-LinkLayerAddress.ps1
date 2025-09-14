<#
    .SYNOPSIS
        Cross-platform replacement for Get-NetNeighbor that returns the MAC
        address for an IP address on the local subnet/VLAN.

    .DESCRIPTION
        The Get-LinkLayerAddress command retrieves the Media Access Control (MAC)
        address for a specified IP address that is on the local subnet or VLAN.
        This command works across different operating systems including Windows,
        Linux, and macOS by using the appropriate platform-specific tools and
        commands to query the ARP table or neighbor cache.

    .PARAMETER IPAddress
        Specifies the IP address for which to retrieve the MAC address. The IP
        address must be on the same subnet/VLAN as the local computer and the
        target computer must be reachable.

    .INPUTS
        System.String

        IP address as string for pipeline input.

    .OUTPUTS
        System.String

        MAC address in standard format (e.g., '00:11:22:33:44:55').

    .EXAMPLE
        Get-LinkLayerAddress -IPAddress '192.168.1.42'

        Returns the MAC address for the computer with IP address 192.168.1.42
        on the local subnet.

    .EXAMPLE
        '192.168.1.10', '192.168.1.20' | Get-LinkLayerAddress

        Returns the MAC addresses for multiple IP addresses using pipeline input.

    .EXAMPLE
        Get-MacAddress -IPAddress '10.0.0.5'

        Uses the alias 'Get-MacAddress' to retrieve the MAC address for IP
        address 10.0.0.5.

    .NOTES
        The target computer must be powered on and reachable on the network for
        the MAC address to be retrieved successfully. This command first sends
        a ping to refresh the ARP table entry before attempting to retrieve
        the MAC address.
#>
function Get-LinkLayerAddress
{
    [Alias('Get-MacAddress')]
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateScript({
            if ($_ -match '^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$')
            {
                $true
            }
            else
            {
                throw ($script:localizedData.Get_LinkLayerAddress_InvalidIPAddress -f $_)
            }
        })]
        [System.String]
        $IPAddress
    )

    process
    {
        Write-Verbose -Message ($script:localizedData.Get_LinkLayerAddress_RefreshingArpEntry -f $IPAddress)

        # 1. Nudge the stack so the entry is fresh
        $null = Test-Connection -ComputerName $IPAddress -Count 1 -Quiet

        Write-Debug -Message ($script:localizedData.Get_LinkLayerAddress_QueryingArpTable -f $IPAddress)

        # 2. Grab it in an OS-specific way
        if ($IsWindows -and (Get-Command -Name 'Get-NetNeighbor' -ErrorAction 'SilentlyContinue'))
        {
            Write-Debug -Message $script:localizedData.Get_LinkLayerAddress_UsingGetNetNeighbor

            # Native cmdlet available
            $neighbor = Get-NetNeighbor -IPAddress $IPAddress -ErrorAction 'SilentlyContinue'
            $mac = $neighbor.LinkLayerAddress

            if ($null -ne $mac -and $mac -ne '')
            {
                $normalizedMac = ConvertTo-CanonicalMacAddress -MacAddress $mac
                Write-Verbose -Message ($script:localizedData.Get_LinkLayerAddress_FoundMacAddress -f $IPAddress, $normalizedMac)
                return $normalizedMac
            }
        }
        elseif ($IsWindows)
        {
            Write-Debug -Message $script:localizedData.Get_LinkLayerAddress_UsingArpCommand

            # Legacy Windows without Get-NetNeighbor command
            try
            {
                $arpOutput = arp.exe -a $IPAddress 2>$null
                $line = $arpOutput | Select-String -Pattern $IPAddress -SimpleMatch

                if ($line)
                {
                    $mac = ($line -split '\s+')[1]

                    if ($null -ne $mac -and $mac -ne '')
                    {
                        $normalizedMac = ConvertTo-CanonicalMacAddress -MacAddress $mac
                        Write-Verbose -Message ($script:localizedData.Get_LinkLayerAddress_FoundMacAddress -f $IPAddress, $normalizedMac)
                        return $normalizedMac
                    }
                }
            }
            catch
            {
                Write-Debug -Message ($script:localizedData.Get_LinkLayerAddress_ArpCommandFailed -f $_.Exception.Message)
            }
        }
        elseif ($IsLinux)
        {
            Write-Debug -Message $script:localizedData.Get_LinkLayerAddress_UsingIpCommand

            try
            {
                $text = (ip neigh show $IPAddress 2>$null)

                if ($text -match 'lladdr\s+([0-9a-f:]{17})') # cSpell: disable-line
                {
                    $mac = $Matches[1]
                    $normalizedMac = ConvertTo-CanonicalMacAddress -MacAddress $mac
                    Write-Verbose -Message ($script:localizedData.Get_LinkLayerAddress_FoundMacAddress -f $IPAddress, $normalizedMac)
                    return $normalizedMac
                }
            }
            catch
            {
                Write-Debug -Message ($script:localizedData.Get_LinkLayerAddress_IpCommandFailed -f $_.Exception.Message)
            }
        }
        elseif ($IsMacOS)
        {
            Write-Debug -Message $script:localizedData.Get_LinkLayerAddress_UsingArpCommand

            try
            {
                $text = (arp -n $IPAddress 2>$null)

                if ($text -match '(([0-9a-f]{1,2}:){5}[0-9a-f]{1,2})')
                {
                    $mac = $Matches[1]

                    # Normalize MAC address to canonical format
                    $normalizedMac = ConvertTo-CanonicalMacAddress -MacAddress $mac

                    Write-Verbose -Message ($script:localizedData.Get_LinkLayerAddress_FoundMacAddress -f $IPAddress, $normalizedMac)
                    return $normalizedMac
                }
            }
            catch
            {
                Write-Debug -Message ($script:localizedData.Get_LinkLayerAddress_ArpCommandFailed -f $_.Exception.Message)
            }
        }

        Write-Warning -Message ($script:localizedData.Get_LinkLayerAddress_CouldNotFindMac -f $IPAddress)
        return $null
    }
}
