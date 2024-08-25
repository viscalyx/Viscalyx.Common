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

    .PARAMETER CheckoutOriginalBranch
        If specified, switches back to the original branch after performing the
        pull or rebase.

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
        Update-GitLocalBranch -CheckoutOriginalBranch

        Checks out the 'main' branch, pulls the latest changes, and switches back
        to the original branch.
#>
function Update-GitLocalBranch
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSShouldProcess', '', Justification = 'ShouldProcess is implemented correctly.')]
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param
    (
        [Parameter()]
        [System.String]
        $BranchName = 'main',

        [Parameter()]
        [System.String]
        $UpstreamBranchName,

        [Parameter()]
        [System.String]
        $RemoteName = 'origin',

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Rebase,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $CheckoutOriginalBranch
    )

    Assert-GitRemote -RemoteName $RemoteName

    if ($BranchName -eq '.')
    {
        $BranchName = Get-GitLocalBranchName -Current

        Write-Debug -Message ('Using the current branch ''{0}''.' -f $BranchName)
    }

    if (-not $UpstreamBranchName)
    {
        $UpstreamBranchName = $BranchName
    }

    if ($WhatIfPreference -eq $false)
    {
        Assert-GitLocalChanges
    }

    # Capture the current branch name only if CheckoutOriginalBranch is specified.
    if ($CheckoutOriginalBranch)
    {
        $currentLocalBranch = Get-GitLocalBranchName -Current
    }

    # Fetch the upstream branch
    Update-RemoteTrackingBranch -RemoteName $RemoteName -BranchName $UpstreamBranchName

    Switch-GitLocalBranch -BranchName $BranchName

    if ($Rebase)
    {
        if ($WhatIfPreference)
        {
            Write-Information -MessageData ('What if: Rebasing the local branch ''{0}'' using tracking branch ''{1}/{0}''.' -f $UpstreamBranchName, $RemoteName) -InformationAction Continue
        }
        else
        {
            # Rebase the local branch
            git rebase $RemoteName/$UpstreamBranchName
        }
    }
    else
    {
        if ($WhatIfPreference)
        {
            Write-Information -MessageData ('What if: Updating the local branch ''{0}'' by pulling from tracking branch ''{1}/{0}''.' -f $UpstreamBranchName, $RemoteName) -InformationAction Continue
        }
        else
        {
            # Run git pull with the specified remote and upstream branch
            git pull $RemoteName $UpstreamBranchName
        }
    }

    # Switch back to the original branch if specified
    if ($CheckoutOriginalBranch -and $WhatIfPreference -eq $false)
    {
        Switch-GitLocalBranch -BranchName $currentLocalBranch
    }
}
