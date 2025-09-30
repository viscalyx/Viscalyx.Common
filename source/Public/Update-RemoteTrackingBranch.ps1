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

    .PARAMETER Force
        Forces the operation to proceed without confirmation prompts when similar
        to -Confirm:$false.

    .INPUTS
        None

        This function does not accept pipeline input.

    .OUTPUTS
        None

        This function does not return any output.

    .EXAMPLE
        Update-RemoteTrackingBranch -RemoteName 'origin' -BranchName 'main'

        Fetches updates from the 'origin' remote repository for the 'main' branch.

    .EXAMPLE
        Update-RemoteTrackingBranch -RemoteName 'upstream'

        Fetches updates from the 'upstream' remote repository for all branches.

    .EXAMPLE
        Update-RemoteTrackingBranch -RemoteName 'origin' -BranchName 'main' -Force

        Fetches updates from the 'origin' remote repository for the 'main' branch
        with the Force parameter, bypassing confirmation prompts when used with
        -Confirm:$false.

    .NOTES
        This function requires Git to be installed and accessible from the command line.
#>
function Update-RemoteTrackingBranch
{
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType()]
    param
    (
        [Parameter(Mandatory = $true, Position = 0)]
        [System.String]
        $RemoteName,

        [Parameter(Position = 1)]
        [System.String]
        $BranchName,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Force
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

    if ($Force.IsPresent -and -not $Confirm)
    {
        $ConfirmPreference = 'None'
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
                    ($BranchName + ' ' + $RemoteName)
                )
            )
        }
    }
}
