<#
    .SYNOPSIS
        Checks for unstaged or staged changes in the current local Git branch.

    .DESCRIPTION
        The Test-GitLocalChanges command checks whether there are any unstaged or
        staged changes in the current local Git branch.

    .OUTPUTS
        System.Boolean

        Returns $true if there are unstaged or staged changes, otherwise returns $false.

    .INPUTS
        None

        This function does not accept pipeline input.

    .EXAMPLE
        PS> Test-GitLocalChanges

        This example demonstrates how to use the Test-GitLocalChanges function to
        check for unstaged or staged changes in the current local Git branch.

    .NOTES
        This function requires Git to be installed and accessible from the command line.
        The function uses 'git status --porcelain' to detect any changes in the repository.
#>
function Test-GitLocalChanges
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '', Justification = 'The function tests for multiple changes, making the plural noun semantically appropriate.')]
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
