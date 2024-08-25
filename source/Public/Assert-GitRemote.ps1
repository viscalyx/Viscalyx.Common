<#
    .SYNOPSIS
        Checks if the specified Git remote exists locally and throws an error if it doesn't.

    .DESCRIPTION
        The `Assert-GitRemote` command checks if the remote specified in the `$RemoteName`
        parameter exists locally. If the remote doesn't exist, it throws an error.

    .PARAMETER RemoteName
        Specifies the name of the Git remote to check.

    .EXAMPLE
        PS> Assert-GitRemote -RemoteName "origin"

        This example checks if the Git remote named "origin" exists locally.

    .INPUTS
        None.

    .OUTPUTS
        None.
#>
function Assert-GitRemote
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true, Position = 0)]
        [System.String]
        $RemoteName
    )

    <#
        Check if the remote specified in $UpstreamRemoteName exists locally and
        throw an error if it doesn't.
    #>
    $remoteExists = Test-GitRemote -RemoteName $RemoteName

    if (-not $remoteExists)
    {
        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                ($script:localizedData.New_SamplerGitHubReleaseTag_RemoteMissing -f $UpstreamRemoteName),
                'AGR0001', # cspell: disable-line
                [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                $DatabaseName
            )
        )
    }
}
