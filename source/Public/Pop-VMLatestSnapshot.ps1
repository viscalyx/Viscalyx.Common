<#
    .SYNOPSIS
        Sets the latest snapshot of a virtual machine and starts it.

    .DESCRIPTION
        The Pop-VMLatestSnapShot command sets the latest snapshot of a virtual
        machine specified by the $ServerName parameter and starts it.

    .PARAMETER ServerName
        Specifies the name of the server for which to set the latest snapshot.

    .EXAMPLE
        Pop-VMLatestSnapShot -ServerName 'VM1'

        Sets the latest snapshot of the virtual machine named "VM1" and starts it.
#>
function Pop-VMLatestSnapShot
{
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $ServerName
    )

    Get-VM -Name $ServerName |
        Get-Snapshot | # TODO: Should this not be Get-VMSnapshot?
        Where-Object -FilterScript {
            $_.IsCurrent -eq $true
        } |
        Set-VM -VM $ServerName | # TODO: Is -VM necessary?
        Start-VM
}
