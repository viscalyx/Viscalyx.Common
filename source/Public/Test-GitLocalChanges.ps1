<#
    .SYNOPSIS
        Checks for unstaged or staged changes in the current local Git branch.

    .DESCRIPTION
        The Test-GitLocalChanges command checks whether there are any unstaged or
        staged changes in the current local Git branch.

    .OUTPUTS
        System.Boolean

        Returns $true if there are unstaged or staged changes, otherwise returns $false.

    .EXAMPLE
        PS> Test-GitLocalChanges

        This example demonstrates how to use the Test-GitLocalChanges function to
        check for unstaged or staged changes in the current local Git branch.
#>
function Test-GitLocalChanges
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param ()

    # Check for unstaged or staged changes
    $status = git status --porcelain # cSpell: ignore unstaged

    $result = $false

    if ($status)
    {
        $result = $true
    }

    return $result
}
