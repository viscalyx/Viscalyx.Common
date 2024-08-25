<#
    .SYNOPSIS
        Tests if a remote branch exists in a Git repository.

    .DESCRIPTION
        The Test-GitRemoteBranch command checks if a specified branch exists in a
        remote Git repository.

    .PARAMETER BranchName
        Specifies the name of the branch to check.

    .PARAMETER RemoteName
        Specifies the name of the remote repository.

    .EXAMPLE
        Test-GitRemoteBranch -BranchName "feature/branch" -RemoteName "origin"

        This example tests if the branch "feature/branch" exists in the remote repository
        named "origin".

    .INPUTS
        None. You cannot pipe input to this function.

    .OUTPUTS
        System.Boolean

        This function returns a Boolean value indicating whether the branch exists in
        the remote repository.
#>
function Test-GitRemoteBranch
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true, Position = 0)]
        [System.String]
        $BranchName,

        [Parameter(Mandatory = $true, Position = 1)]
        [System.String]
        $RemoteName
    )

    # Get the remote branches
    $branch = ls-remote --branches $RemoteName $BranchName

    $oid, $heads = $branch -split "`t"

    $result = $false

    # Check if the branch exists
    if ($heads -match "^refs/heads/$BranchName")
    {
        $result = $true
    }

    return $result
}
