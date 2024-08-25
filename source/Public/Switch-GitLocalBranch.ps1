<#
    .SYNOPSIS
        Switches to the specified local Git branch.

    .DESCRIPTION
        The Switch-GitLocalBranch command is used to switch to the specified local
        Git branch. It checks if the branch exists and performs the checkout operation.
        If the checkout fails, it throws an error.

    .PARAMETER BranchName
        The name of the branch to switch to.

    .EXAMPLE
        Switch-GitLocalBranch -BranchName "feature/branch"

        This example switches to the "feature/branch" local Git branch.
#>
function Switch-GitLocalBranch
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSShouldProcess', '', Justification = 'ShouldProcess is implemented without ShouldProcess/ShouldContinue.')]
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    param
    (
        [Parameter(Mandatory = $true, Position = 0)]
        [System.String]
        $BranchName
    )


    if ($WhatIfPreference)
    {
        Write-Information -MessageData ('What if: Checking out local branch ''{0}''.' -f $BranchName) -InformationAction Continue
    }
    else
    {
        git checkout $BranchName

        if ($LASTEXITCODE -ne 0) # cSpell: ignore LASTEXITCODE
        {
            $PSCmdlet.ThrowTerminatingError(
                [System.Management.Automation.ErrorRecord]::new(
                    ($script:localizedData.Switch_GitLocalBranch_FailedCheckoutLocalBranch -f $BranchName),
                    'SGLB0001', # cspell: disable-line
                    [System.Management.Automation.ErrorCategory]::InvalidOperation,
                    $BranchName
                )
            )
        }
    }
}
