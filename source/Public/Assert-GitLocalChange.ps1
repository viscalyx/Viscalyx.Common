<#
    .SYNOPSIS
        Asserts that there are no unstaged or staged changes in the local Git branch.

    .DESCRIPTION
        The Assert-GitLocalChange command checks whether there are any unstaged
        or staged changes in the local Git branch. If there are any staged or
        unstaged changes, it throws a terminating error.

    .EXAMPLE
        Assert-GitLocalChange

        This example demonstrates how to use the Assert-GitLocalChange command
        to ensure that there are no local changes in the Git repository.
#>
function Assert-GitLocalChange
{
    [CmdletBinding()]
    param ()

    # Change the error action preference to always stop the script if an error occurs.
    $ErrorActionPreference = 'Stop'

    $hasChanges = Test-GitLocalChanges

    if ($hasChanges)
    {
        $errorMessageParameters = @{
            Message = $script:localizedData.Assert_GitLocalChanges_FailedUnstagedChanges
            Category = 'InvalidResult'
            ErrorId = 'AGLC0001' # cspell: disable-line
            TargetObject = 'Staged or unstaged changes' # cSpell: ignore unstaged
        }

        Write-Error @errorMessageParameters
    }
}
