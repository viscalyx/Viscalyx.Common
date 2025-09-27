<#
    .SYNOPSIS
        Retrieves the names of remote Git branches.

    .DESCRIPTION
        The Get-GitRemoteBranch command retrieves the names of remote Git branches
        from the specified remote repository. It supports filtering by branch name
        patterns and can optionally remove the 'refs/heads/' prefix from branch names.

    .PARAMETER RemoteName
        Specifies the name of the remote repository to query for branches.

    .PARAMETER Name
        Specifies the name or pattern of the branch to retrieve. Supports wildcard patterns.

    .PARAMETER RemoveRefsHeads
        When specified, removes the 'refs/heads/' prefix from the returned branch names.

    .INPUTS
        None

        This function does not accept pipeline input.

    .OUTPUTS
        System.String

        Returns the names of remote branches matching the specified criteria.

    .EXAMPLE
        Get-GitRemoteBranch -RemoteName 'origin'

        Retrieves all remote branches from the 'origin' remote repository.

    .EXAMPLE
        Get-GitRemoteBranch -RemoteName 'origin' -Name 'feature/*'

        Retrieves all remote branches from 'origin' that match the pattern 'feature/*'.

    .EXAMPLE
        Get-GitRemoteBranch -RemoteName 'origin' -Name 'main' -RemoveRefsHeads

        Retrieves the 'main' branch from 'origin' with the 'refs/heads/' prefix removed.

    .NOTES
        This function requires Git to be installed and accessible from the command line.
#>
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

    # Verify that the remote exists if RemoteName is specified
    if ($PSBoundParameters.ContainsKey('RemoteName'))
    {
        $existingRemote = Get-GitRemote -Name $RemoteName

        if (-not $existingRemote)
        {
            $errorMessageParameters = @{
                Message      = $script:localizedData.Get_GitRemoteBranch_RemoteNotFound -f $RemoteName
                Category     = 'ObjectNotFound'
                ErrorId      = 'GGRB0002' # cspell: disable-line
                TargetObject = $RemoteName
            }

            Write-Error @errorMessageParameters
            return
        }
    }

    $arguments = @()

    # Make sure the remote URL is not printed to stderr.
    $arguments += '--quiet'

    if ($PSBoundParameters.ContainsKey('RemoteName'))
    {
        $arguments += $RemoteName
    }

    if ($PSBoundParameters.ContainsKey('Name'))
    {
        # If Name is just '*', treat it as if no Name was specified
        if ($Name -eq '*')
        {
            # Skip adding the Name parameter - this will list all branches like when Name is not specified
        }
        else
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
