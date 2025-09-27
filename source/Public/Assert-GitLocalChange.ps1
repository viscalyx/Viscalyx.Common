<#
    .SYNOPSIS
        Asserts that there are no unstaged or staged changes in the local Git branch.

    .DESCRIPTION
        The Assert-GitLocalChange command checks whether there are any unstaged
        or staged changes in the local Git branch. If there are any staged or
        unstaged changes, it throws a terminating error.

    .INPUTS
        None

        This function does not accept pipeline input.

    .OUTPUTS
        None

        This function does not return any output.

    .EXAMPLE
        Assert-GitLocalChange

        This example demonstrates how to use the Assert-GitLocalChange command
        to ensure that there are no local changes in the Git repository.

    .NOTES
        This function requires Git to be installed and accessible from the command line.
        The function will throw a terminating error if any staged or unstaged changes
        are detected in the repository.
#>
function Assert-GitLocalChange
{
    [CmdletBinding()]
    [OutputType()]
    param ()

    $hasChanges = Test-GitLocalChanges

    if ($hasChanges)
    {
        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                $script:localizedData.Assert_GitLocalChanges_FailedUnstagedChanges,
                'AGLC0001', # cspell: disable-line
                [System.Management.Automation.ErrorCategory]::InvalidResult,
                'Staged or unstaged changes' # cSpell: ignore unstaged
            )
        )
    }
}
