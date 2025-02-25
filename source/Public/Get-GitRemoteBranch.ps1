function Get-GitRemoteBranch
{
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    [OutputType([System.String])]
    param
    (
        [Parameter(Position = 0, ParameterSetName = 'Default')]
        [Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'Name')]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $RemoteName,

        [Parameter(Position = 1, ParameterSetName = 'Name')]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Name,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $RemoveRefsHeads
    )

    $arguments = @()

    # Make sure the remote URL is not printed to stderr.
    $arguments += '--quiet'

    if ($PSBoundParameters.ContainsKey('RemoteName'))
    {
        $arguments += $RemoteName
    }

    if ($PSBoundParameters.ContainsKey('Name'))
    {
        if ($Name -match 'refs/heads/')
        {
            $Name = $Name -replace 'refs/heads/'
        }

        if ($Name -notmatch '\*\*$' -and $Name -match '^([^*].*\*)$')
        {
            <#
                if Name contains '*' but do not end with '**' or is already
                prefixed with'*', then prefix with '*'.
            #>
            $Name = '*{0}' -f $matches[1]
        }

        # Name can also have wildcard like 'feature/*'
        $arguments += $Name
    }

    $result = git ls-remote --branches @arguments

    if ($LASTEXITCODE -ne 0) # cSpell: ignore LASTEXITCODE
    {
        $targetObject = $null

        if ($PSBoundParameters.ContainsKey('Name'))
        {
            $errorMessage = $script:localizedData.Get_GitRemoteBranch_ByName_Failed -f $Name, $RemoteName
            $targetObject = 'Name'
        }
        elseif ($PSBoundParameters.ContainsKey('RemoteName'))
        {
            $errorMessage = $script:localizedData.Get_GitRemoteBranch_FromRemote_Failed -f $RemoteName
            $targetObject = 'RemoteName'
        }
        else
        {
            $errorMessage = $script:localizedData.Get_GitRemoteBranch_Failed
        }

        $errorMessageParameters = @{
            Message      = $errorMessage
            Category     = 'ObjectNotFound'
            ErrorId      = 'GGRB0001' # cspell: disable-line
            TargetObject = $targetObject # Null if neither RemoteName or Name is provided.
        }

        Write-Error @errorMessageParameters
    }

    $headsArray = $null

    if ($result)
    {
        $oidArray = @()
        $headsArray = @()

        $result | ForEach-Object -Process {
            $oid, $heads = $_ -split "`t"

            $oidArray += $oid
            $headsArray += $heads
        }

        # Remove refs/heads/ from the branch names.
        if ($RemoveRefsHeads.IsPresent)
        {
            $headsArray = $headsArray -replace 'refs/heads/'
        }
    }

    return $headsArray
}
