<#
    .SYNOPSIS
        Checks if the specified Git remote exists locally and throws an error if it doesn't.

    .DESCRIPTION
        The `Assert-GitRemote` command checks if the remote specified in the `$Name`
        parameter exists locally. If the remote doesn't exist, it throws an error.

    .PARAMETER Name
        Specifies the name of the Git remote to check.

    .INPUTS
        None

        This function does not accept pipeline input.

    .OUTPUTS
        None

        This function does not return any output.

    .EXAMPLE
        Assert-GitRemote -Name "origin"

        This example checks if the Git remote named "origin" exists locally.
#>
function Assert-GitRemote
{
    [CmdletBinding()]
    [OutputType()]
    param
    (
        [Parameter(Mandatory = $true, Position = 0)]
        [System.String]
        $Name
    )

    <#
        Check if the remote specified in $Name exists locally and
        throw an error if it doesn't.
    #>
    $remoteExists = Test-GitRemote -Name $Name

    if (-not $remoteExists)
    {
        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                ($script:localizedData.Assert_GitRemote_RemoteMissing -f $Name),
                'AGR0001', # cspell: disable-line
                [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                $Name
            )
        )
    }
}
