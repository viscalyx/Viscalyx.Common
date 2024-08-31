<#
    .SYNOPSIS
        Retrieves the names or URL(s) of the specified Git remote or all remotes.

    .DESCRIPTION
        The Get-GitRemote commands retrieves the names or URL(s) of the specified
        Git remote or all remotes. It can be used to get the name of a remote or
        the URL(s) for fetching or pushing.

    .PARAMETER Name
        Specifies the name of the Git remote.

    .PARAMETER FetchUrl
        Indicates that the URL(s) for fetching should be retrieved.

    .PARAMETER PushUrl
        Indicates that the URL(s) for pushing should be retrieved.

    .INPUTS
        None. You cannot pipe input to this function.

    .OUTPUTS
        System.String[]

        The function returns an array of strings representing the names or URL of
        the specified Git remote or all remotes.

    .EXAMPLE
        PS C:\> Get-GitRemote

        Returns the names of all Git remotes.

    .EXAMPLE
        PS C:\> Get-GitRemote -Name origin

        Returns the name of the Git remote named 'origin' if it exist.

    .EXAMPLE
        PS C:\> Get-GitRemote -Name origin -FetchUrl

        Returns the URL for fetching from the Git remote named 'origin'.

    .EXAMPLE
        PS C:\> Get-GitRemote -Name origin -PushUrl

        Returns the URL for pushing to the Git remote named 'origin'.
#>
function Get-GitRemote
{
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    [OutputType([System.String])]
    param
    (
        [Parameter(Position = 0, ParameterSetName = 'Default')]
        [Parameter(Mandatory = $true, ParameterSetName = 'FetchUrl')]
        [Parameter(Mandatory = $true, ParameterSetName = 'PushUrl')]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true, ParameterSetName = 'FetchUrl')]
        [Switch]
        $FetchUrl,

        [Parameter(Mandatory = $true, ParameterSetName = 'PushUrl')]
        [Switch]
        $PushUrl
    )

    $arguments = @()

    if ($PSCmdlet.ParameterSetName -in 'FetchUrl', 'PushUrl')
    {
        $arguments += 'get-url'

        if ($PSBoundParameters.ContainsKey('PushUrl'))
        {
            $arguments += '--push'
        }

        $arguments += $Name
    }

    $result = git remote @arguments

    if ($LASTEXITCODE -ne 0) # cSpell: ignore LASTEXITCODE
    {
        $errorMessageParameters = @{
            Message      = $script:localizedData.Get_GitRemote_Failed
            Category     = 'ObjectNotFound'
            ErrorId      = 'GGR0001' # cspell: disable-line
            TargetObject = $Name
        }

        Write-Error @errorMessageParameters
    }

    if ($PSCmdlet.ParameterSetName -eq 'Default')
    {
        # Filter out the remote if it exist.
        $result = @($result) -eq $Name
    }

    return $result
}
