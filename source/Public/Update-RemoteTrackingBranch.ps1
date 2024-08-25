<#
    .SYNOPSIS
        Updates the remote tracking branch in the local git repository.

    .DESCRIPTION
        The Update-RemoteTrackingBranch command fetches updates from the specified
        remote and branch in Git. It is used to keep the local tracking branch up
        to date with the remote branch.

    .PARAMETER RemoteName
        Specifies the name of the remote.

    .PARAMETER BranchName
        Specifies the name of the branch to update. If not provided, all branches
        will be updated.

    .EXAMPLE
        Update-RemoteTrackingBranch -RemoteName 'origin' -BranchName 'main'

        Fetches updates from the 'origin' remote repository for the 'main' branch.

    .EXAMPLE
        Update-RemoteTrackingBranch -RemoteName 'upstream'

        Fetches updates from the 'upstream' remote repository for all branches.

    .NOTES
        This function requires Git to be installed and accessible from the command line.
#>
function Update-RemoteTrackingBranch
{
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param
    (
        [Parameter(Mandatory = $true, Position = 0)]
        [System.String]
        $RemoteName,

        [Parameter(Position = 1)]
        [System.String]
        $BranchName
    )

    $arguments = @(
        $RemoteName
    )

    if ($PSBoundParameters.ContainsKey('BranchName'))
    {
        $arguments += @(
            $BranchName
        )
    }

    $verboseDescriptionMessage = $script:localizedData.Update_RemoteTrackingBranch_FetchUpstream_ShouldProcessVerboseDescription -f $BranchName, $RemoteName
    $verboseWarningMessage = $script:localizedData.Update_RemoteTrackingBranch_FetchUpstream_ShouldProcessVerboseWarning -f $BranchName, $RemoteName
    $captionMessage = $script:localizedData.Update_RemoteTrackingBranch_FetchUpstream_ShouldProcessCaption

    if ($PSCmdlet.ShouldProcess($verboseDescriptionMessage, $verboseWarningMessage, $captionMessage))
    {
        # Fetch the updates from the specified remote and branch
        git fetch @arguments

        if ($LASTEXITCODE -ne 0) # cSpell: ignore LASTEXITCODE
        {
            $PSCmdlet.ThrowTerminatingError(
                [System.Management.Automation.ErrorRecord]::new(
                    ($script:localizedData.Update_RemoteTrackingBranch_FailedFetchBranchFromRemote -f ($arguments -join ' ')),
                    'URTB0001', # cspell: disable-line
                    [System.Management.Automation.ErrorCategory]::InvalidOperation,
                    $DatabaseName
                )
            )
        }
    }
}
