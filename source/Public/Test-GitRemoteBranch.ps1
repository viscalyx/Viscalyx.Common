<#
    .SYNOPSIS
        Tests if a remote branch exists in a Git repository.

    .DESCRIPTION
        The Test-GitRemoteBranch command checks if a specified branch exists in a
        remote Git repository.

    .PARAMETER Name
        Specifies the name of the branch to check.

    .PARAMETER RemoteName
        Specifies the name of the remote repository.

    .EXAMPLE
        Test-GitRemoteBranch -BranchName "feature/branch" -Name "origin"

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
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    [OutputType([System.Boolean])]
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
        $Name
    )

    $getGitRemoteBranchParameters = @{}

    if ($PSBoundParameters.ContainsKey('RemoteName'))
    {
        $getGitRemoteBranchParameters['RemoteName'] = $RemoteName
    }

    if ($PSBoundParameters.ContainsKey('Name'))
    {
        $getGitRemoteBranchParameters['Name'] = $Name
    }

    $branch = Get-GitRemoteBranch @getGitRemoteBranchParameters -RemoveRefsHeads

    $result = $false

    if ($branch)
    {
        $result = $true
    }

    return $result
}
