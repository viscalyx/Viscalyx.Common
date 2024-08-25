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
        Specifies the upstream branch name. Default is 'main'.

    .PARAMETER RemoteName
        Specifies the remote name. Default is 'origin'.

    .PARAMETER Rebase
        Specifies that the local branch should be rebased with the upstream branch.

    .PARAMETER CheckoutOriginalBranch
        If specified, switches back to the original branch after performing the
        pull or rebase.

    .EXAMPLE
        Update-GitBranch

        Checks out the 'main' branch and pulls the latest changes.

    .EXAMPLE
        Update-GitBranch -BranchName 'feature-branch'

        Checks out the 'feature-branch' and pulls the latest changes.

    .EXAMPLE
        Update-GitBranch -BranchName 'feature-branch' -UpstreamBranchName 'develop' -Rebase

        Checks out the 'feature-branch' and rebases it with the 'develop' branch.

    .EXAMPLE
        Update-GitBranch -BranchName 'feature-branch' -RemoteName 'upstream'

        Checks out the 'feature-branch' and pulls the latest changes from the
        'upstream' remote.

    .EXAMPLE
        Update-GitBranch -BranchName .

        Pulls the latest changes into the current branch.

    .EXAMPLE
        Update-GitBranch -CheckoutOriginalBranch

        Checks out the 'main' branch, pulls the latest changes, and switches back
        to the original branch.
#>
function Update-GitBranch
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [System.String]
        $BranchName = 'main',

        [Parameter()]
        [System.String]
        $UpstreamBranchName = 'main',

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

    # Check for unstaged or staged changes
    $status = git status --porcelain

    if ($status)
    {
        # cSpell:ignore unstaged
        throw 'There are unstaged or staged changes. Please commit or stash your changes before proceeding.'
    }

    if ($BranchName -eq '.')
    {
        $BranchName = git rev-parse --abbrev-ref HEAD
    }

    # Capture the current branch name only if CheckoutOriginalBranch is specified.
    if ($CheckoutOriginalBranch)
    {
        $currentBranch = git rev-parse --abbrev-ref HEAD
    }

    # Checkout the specified branch
    git checkout $BranchName

    if ($Rebase)
    {
        # Fetch the upstream branch and rebase the local branch
        git fetch $RemoteName $UpstreamBranchName
        git rebase $RemoteName/$UpstreamBranchName
    }
    else
    {
        # Run git pull with the specified remote and upstream branch
        git pull $RemoteName $UpstreamBranchName
    }

    # Switch back to the original branch if specified
    if ($CheckoutOriginalBranch)
    {
        git checkout $currentBranch
    }
}
