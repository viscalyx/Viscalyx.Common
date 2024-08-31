<#
    .SYNOPSIS
        Tests if a Git remote exists locally.

    .DESCRIPTION
        The Test-GitRemote command checks if the specified Git remote exists locally
        and returns a boolean value indicating its existence.

    .PARAMETER Name
        Specifies the name of the Git remote to be tested.

    .EXAMPLE
        Test-GitRemote -Name "origin"

        Returns $true if the "origin" remote exists locally, otherwise returns $false.

    .NOTES
        This function requires Git to be installed and accessible from the command line.
#>
function Test-GitRemote
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true, Position = 0)]
        [System.String]
        $Name
    )

    $remoteExists = Get-GitRemote -Name $Name

    $result = $false

    if ($remoteExists)
    {
        $result = $true
    }

    return $result
}
