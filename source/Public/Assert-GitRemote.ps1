<#
    .SYNOPSIS
        Checks if the specified Git remote exists locally and throws an error if it doesn't.

    .DESCRIPTION
        The `Assert-GitRemote` command checks if the remote specified in the `$Name`
        parameter exists locally. If the remote doesn't exist, it throws an error.

    .PARAMETER RemoteName
        Specifies the name of the Git remote to check.

    .EXAMPLE
        PS> Assert-GitRemote -Name "origin"

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
        $Name
    )

    # Change the error action preference to always stop the script if an error occurs.
    $ErrorActionPreference = 'Stop'

    <#
        Check if the remote specified in $UpstreamRemoteName exists locally and
        throw an error if it doesn't.
    #>
    $remoteExists = Test-GitRemote -Name $Name

    if (-not $remoteExists)
    {

        $errorMessageParameters = @{
            Message = $script:localizedData.New_SamplerGitHubReleaseTag_RemoteMissing -f $Name
            Category = 'ObjectNotFound'
            ErrorId = 'AGR0001' # cspell: disable-line
            TargetObject = $Name
        }

        Write-Error @errorMessageParameters
    }
}
