<#
    .SYNOPSIS
        Sends a Wake-on-LAN magic packet to wake up a remote computer.

    .DESCRIPTION
        The Send-WakeOnLan command sends a Wake-on-LAN (WOL) magic packet to a
        specified MAC address to wake up a remote computer on the network. The
        magic packet is sent as a UDP broadcast packet containing the target
        computer's MAC address repeated 16 times, preceded by six bytes of 0xFF.
        The target computer must have Wake-on-LAN enabled in its BIOS/UEFI settings
        and network adapter configuration.

    .PARAMETER LinkLayerAddress
        Specifies the MAC address of the target computer to wake up. The MAC address
        can be provided in colon-separated (XX:XX:XX:XX:XX:XX) or hyphen-separated
        (XX-XX-XX-XX-XX-XX) format. This parameter accepts input from the pipeline
        and has an alias 'MacAddress'.

    .PARAMETER Broadcast
        Specifies the broadcast address to send the Wake-on-LAN packet to. The default
        value is '255.255.255.255' which broadcasts to the entire local network segment.

    .PARAMETER Port
        Specifies the UDP port number to send the Wake-on-LAN packet to. The default
        value is 9, which is the standard Wake-on-LAN port. Other commonly used ports
        are 0 and 7.

    .PARAMETER Force
        Overrides the confirmation dialog when sending the Wake-on-LAN packet.

    .EXAMPLE
        Send-WakeOnLan -LinkLayerAddress '00:11:22:33:44:55'

        Sends a Wake-on-LAN packet to the computer with MAC address '00:11:22:33:44:55'
        using the default broadcast address and port.

    .EXAMPLE
        Send-WakeOnLan -MacAddress '00-11-22-33-44-55' -Broadcast '192.168.1.255'

        Sends a Wake-on-LAN packet to the computer with MAC address '00-11-22-33-44-55'
        using a specific subnet broadcast address and the MacAddress alias.

    .EXAMPLE
        Send-WOL -LinkLayerAddress '001122334455' -Port 7

        Sends a Wake-on-LAN packet using the alias 'Send-WOL' to the computer with
        MAC address '001122334455' on port 7.

    .EXAMPLE
        '00:11:22:33:44:55', '00-AA-BB-CC-DD-EE' | Send-WakeOnLan -Force

        Sends Wake-on-LAN packets to multiple computers by passing MAC addresses through
        the pipeline, bypassing confirmation prompts with the Force parameter.

    .EXAMPLE
        Send-WakeOnLan -LinkLayerAddress '00:11:22:33:44:55' -WhatIf

        Shows what would happen if the Wake-on-LAN packet was sent without actually
        sending it.

    .NOTES
        This command requires that the target computer has Wake-on-LAN enabled in
        both the BIOS/UEFI settings and the network adapter configuration. The
        computer must also be connected to a power source and have a network
        connection (wired or wireless, depending on the adapter capabilities).
#>
function Send-WakeOnLan
{
    [Alias('Send-WOL')]
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidatePattern('^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$|^[0-9A-Fa-f]{12}$')]
        [Alias('MacAddress')]
        [System.String]
        $LinkLayerAddress,

        [Parameter()]
        [ValidatePattern('^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$')]
        [System.String]
        $Broadcast = '255.255.255.255',

        [Parameter()]
        [ValidateRange(0, 65535)]
        [System.UInt16]
        $Port = 9,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Force
    )

    process
    {
        if ($Force.IsPresent -and -not $Confirm)
        {
            $ConfirmPreference = 'None'
        }

        Write-Verbose -Message ($script:localizedData.Send_WakeOnLan_SendingPacket -f $LinkLayerAddress, $Broadcast, $Port)

        # Remove any separators from the MAC address and validate length
        $cleanMacAddress = $LinkLayerAddress -replace '[-:]', ''

        if ($cleanMacAddress.Length -ne 12)
        {
            $errorMessage = $script:localizedData.Send_WakeOnLan_InvalidMacAddress -f $LinkLayerAddress

            $PSCmdlet.ThrowTerminatingError(
                [System.Management.Automation.ErrorRecord]::new(
                    [System.ArgumentException]::new($errorMessage),
                    'InvalidMacAddressFormat',
                    [System.Management.Automation.ErrorCategory]::InvalidArgument,
                    $LinkLayerAddress
                )
            )
        }

        $verboseDescriptionMessage = $script:localizedData.Send_WakeOnLan_ShouldProcessVerboseDescription -f $LinkLayerAddress, $Broadcast, $Port
        $verboseWarningMessage = $script:localizedData.Send_WakeOnLan_ShouldProcessVerboseWarning -f $LinkLayerAddress
        $captionMessage = $script:localizedData.Send_WakeOnLan_ShouldProcessCaption

        if ($PSCmdlet.ShouldProcess($verboseDescriptionMessage, $verboseWarningMessage, $captionMessage))
        {
            Write-Debug -Message ($script:localizedData.Send_WakeOnLan_CreatingPacket -f $LinkLayerAddress)

            # Convert MAC address to byte array
            $macBytesArray = for ($i = 0; $i -lt $cleanMacAddress.Length; $i += 2)
            {
                [System.Byte]('0x' + $cleanMacAddress.Substring($i, 2))
            }

            # Create the magic packet: 6 bytes of 0xFF followed by 16 repetitions of the MAC address
            $packet = [System.Byte[]]::new(102)

            # Fill first 6 bytes with 0xFF
            for ($i = 0; $i -lt 6; $i++)
            {
                $packet[$i] = 0xFF
            }

            # Repeat MAC address 16 times
            for ($repetition = 0; $repetition -lt 16; $repetition++)
            {
                for ($byteIndex = 0; $byteIndex -lt 6; $byteIndex++)
                {
                    $packet[6 + ($repetition * 6) + $byteIndex] = $macBytesArray[$byteIndex]
                }
            }

            $udpClient = $null

            try
            {
                $udpClient = New-Object -TypeName 'System.Net.Sockets.UdpClient'
                $udpClient.Connect($Broadcast, $Port)

                [void] $udpClient.Send($packet, $packet.Length)

                Write-Verbose -Message $script:localizedData.Send_WakeOnLan_PacketSent
            }
            finally
            {
                if ($null -ne $udpClient)
                {
                    $udpClient.Close()
                    $udpClient.Dispose()
                }
            }
        }
    }
}
