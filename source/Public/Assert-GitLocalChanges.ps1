<#
    .SYNOPSIS
        Asserts that there are no unstaged or staged changes in the local Git branch.

    .DESCRIPTION
        The Assert-GitLocalChanges command checks whether there are any unstaged
        or staged changes in the local Git branch. If there are any staged or
        unstaged changes, it throws a terminating error.

    .EXAMPLE
        Assert-GitLocalChanges

        This example demonstrates how to use the Assert-GitLocalChanges command
        to ensure that there are no local changes in the Git repository.
#>
function Assert-GitLocalChanges
{
    [CmdletBinding()]
    param ()

    $hasChanges = Test-GitLocalChanges

    if ($hasChanges)
    {
        # cSpell:ignore unstaged
        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                ($script:localizedData.Assert_GitLocalChanges_FailedUnstagedChanges),
                'AGLC0001', # cspell: disable-line
                [System.Management.Automation.ErrorCategory]::InvalidResult,
                'Staged or unstaged changes'
            )
        )
    }
}
