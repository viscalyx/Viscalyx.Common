<#
    .SYNOPSIS
        Updates the specified Git branch by pulling or rebasing from the upstream
        branch.

    .DESCRIPTION
        This function checks out the specified local branch and either pulls the
        latest changes or rebases it with the upstream branch.

    .PARAMETER BranchName
        Specifies the local branch name. Default is 'main'.

    .PARAMETER UpstreamBranchName
        Specifies the upstream branch name. If not specified the value in BranchName
        will be used.

    .PARAMETER RemoteName
        Specifies the remote name. Default is 'origin'.

    .PARAMETER Rebase
        Specifies that the local branch should be rebased with the upstream branch.

    .PARAMETER ReturnToCurrentBranch
        If specified, switches back to the original branch after performing the
        pull or rebase.

    .PARAMETER SkipSwitchingBranch
        If specified, the function will not switch to the specified branch.

    .PARAMETER OnlyUpdateRemoteTrackingBranch
        If specified, only the remote tracking branch will be updated.

    .PARAMETER UseExistingTrackingBranch
        If specified, only the existing tracking branch will be used to update the
        local branch.

    .PARAMETER Force
        If specified, the command will not prompt for confirmation.

    .EXAMPLE
        Update-GitLocalBranch

        Checks out the 'main' branch and pulls the latest changes.

    .EXAMPLE
        Update-GitLocalBranch -BranchName 'feature-branch'

        Checks out the 'feature-branch' and pulls the latest changes.

    .EXAMPLE
        Update-GitLocalBranch -BranchName 'feature-branch' -UpstreamBranchName 'develop' -Rebase

        Checks out the 'feature-branch' and rebases it with the 'develop' branch.

    .EXAMPLE
        Update-GitLocalBranch -BranchName 'feature-branch' -RemoteName 'upstream'

        Checks out the 'feature-branch' and pulls the latest changes from the
        'upstream' remote.

    .EXAMPLE
        Update-GitLocalBranch -BranchName .

        Pulls the latest changes into the current branch.

    .EXAMPLE
        Update-GitLocalBranch -ReturnToCurrentBranch

        Checks out the 'main' branch, pulls the latest changes, and switches back
        to the original branch.
#>
function Update-GitLocalBranch
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSShouldProcess', '', Justification = 'ShouldProcess is implemented correctly.')]
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium', DefaultParameterSetName = 'Default')]
    param
    (
        [Parameter(ParameterSetName = 'Default')]
        [Parameter(ParameterSetName = 'Default_SkipSwitchingBranch')]
        [Parameter(ParameterSetName = 'Default_UseExistingTrackingBranch')]
        [System.String]
        $BranchName = 'main',

        [Parameter(ParameterSetName = 'Default')]
        [Parameter(ParameterSetName = 'Default_SkipSwitchingBranch')]
        [Parameter(ParameterSetName = 'Default_UseExistingTrackingBranch')]
        [System.String]
        $UpstreamBranchName,

        [Parameter(ParameterSetName = 'Default')]
        [Parameter(ParameterSetName = 'Default_SkipSwitchingBranch')]
        [Parameter(ParameterSetName = 'Default_UseExistingTrackingBranch')]
        [System.String]
        $RemoteName = 'origin',

        [Parameter(ParameterSetName = 'Default')]
        [Parameter(ParameterSetName = 'Default_SkipSwitchingBranch')]
        [Parameter(ParameterSetName = 'Default_UseExistingTrackingBranch')]
        [System.Management.Automation.SwitchParameter]
        $Rebase,

        [Parameter(ParameterSetName = 'Default')]
        [Parameter(ParameterSetName = 'Default_UseExistingTrackingBranch')]
        [System.Management.Automation.SwitchParameter]
        $ReturnToCurrentBranch,

        [Parameter(ParameterSetName = 'Default_SkipSwitchingBranch')]
        [System.Management.Automation.SwitchParameter]
        $SkipSwitchingBranch,

        [Parameter(ParameterSetName = 'Default')]
        [Parameter(ParameterSetName = 'Default_SkipSwitchingBranch')]
        [System.Management.Automation.SwitchParameter]
        $OnlyUpdateRemoteTrackingBranch,

        [Parameter(ParameterSetName = 'Default_UseExistingTrackingBranch')]
        [System.Management.Automation.SwitchParameter]
        $UseExistingTrackingBranch,

        [Parameter(ParameterSetName = 'Default')]
        [Parameter(ParameterSetName = 'Default_SkipSwitchingBranch')]
        [Parameter(ParameterSetName = 'Default_UseExistingTrackingBranch')]
        [System.Management.Automation.SwitchParameter]
        $Force
    )

    if ($Force.IsPresent -and -not $Confirm)
    {
        $ConfirmPreference = 'None'
    }

    # Only check assertions if not in WhatIf mode.
    if ($WhatIfPreference -eq $false)
    {
        Assert-GitRemote -Name $RemoteName
    }

    $currentLocalBranchName = Get-GitLocalBranchName -Current

    if ($BranchName -eq '.')
    {
        $BranchName = $currentLocalBranchName
    }

    if (-not $UpstreamBranchName)
    {
        $UpstreamBranchName = $BranchName
    }

    if (-not $SkipSwitchingBranch.IsPresent -and $BranchName -ne $currentLocalBranchName)
    {
        # This command will also assert that there are no local changes if not in WhatIf mode.
        Switch-GitLocalBranch -BranchName $BranchName -Verbose:$VerbosePreference -ErrorAction 'Stop'
    }

    if ($Rebase.IsPresent)
    {
        $verboseDescriptionMessage = $script:localizedData.Update_GitLocalBranch_Rebase_ShouldProcessVerboseDescription -f $BranchName, $RemoteName, $UpstreamBranchName
        $verboseWarningMessage = $script:localizedData.Update_GitLocalBranch_Rebase_ShouldProcessVerboseWarning -f $BranchName
        $captionMessage = $script:localizedData.Update_GitLocalBranch_Rebase_ShouldProcessCaption
    }
    else
    {
        $verboseDescriptionMessage = $script:localizedData.Update_GitLocalBranch_Pull_ShouldProcessVerboseDescription -f $BranchName, $RemoteName, $UpstreamBranchName
        $verboseWarningMessage = $script:localizedData.Update_GitLocalBranch_Pull_ShouldProcessVerboseWarning -f $BranchName
        $captionMessage = $script:localizedData.Update_GitLocalBranch_Pull_ShouldProcessCaption
    }

    if ($PSCmdlet.ShouldProcess($verboseDescriptionMessage, $verboseWarningMessage, $captionMessage))
    {
        # Fetch the upstream branch
        if (-not $UseExistingTrackingBranch.IsPresent)
        {
            # TODO: If this fails it should switch to the previous branch
            Update-RemoteTrackingBranch -RemoteName $RemoteName -BranchName $UpstreamBranchName -Verbose:$VerbosePreference -ErrorAction 'Stop'
        }

        if (-not $OnlyUpdateRemoteTrackingBranch.IsPresent)
        {
            if ($Rebase.IsPresent)
            {
                $argument = "$RemoteName/$UpstreamBranchName"

                # TODO: Should call new command `Start-GitRebase`
                # Rebase the local branch
                git rebase $argument

                $exitCode = $LASTEXITCODE # cSpell: ignore LASTEXITCODE

                # TODO: Handle when error is rebase conflict resolution
                Write-Verbose -Message "Rebase exit code: $exitCode" -Verbose
            }
            else
            {
                $argument = @($RemoteName, $UpstreamBranchName)

                # Run git pull with the specified remote and upstream branch
                git pull @argument

                $exitCode = $LASTEXITCODE
            }

            if ($ReturnToCurrentBranch.IsPresent -and $BranchName -ne $currentLocalBranchName)
            {
                Switch-GitLocalBranch -BranchName $currentLocalBranchName -Verbose:$VerbosePreference  -ErrorAction 'Stop'
            }

            if ($exitCode -ne 0)
            {
                $errorMessageParameters = @{
                    Message = $script:localizedData.Update_GitLocalBranch_FailedRebase -f $RemoteName, $UpstreamBranchName

                    Category = 'InvalidOperation'
                    ErrorId = 'UGLB0001' # cspell: disable-line
                    TargetObject = $argument -join ' '
                }

                Write-Error @errorMessageParameters
            }
        }
    }

    # Switch back to the original branch if specified
    if ($ReturnToCurrentBranch.IsPresent -and $BranchName -ne $currentLocalBranchName)
    {
        Switch-GitLocalBranch -BranchName $currentLocalBranchName -Verbose:$VerbosePreference -ErrorAction 'Stop'
    }
}
