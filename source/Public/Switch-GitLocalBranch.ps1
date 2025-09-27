<#
    .SYNOPSIS
        Switches to the specified local Git branch.

    .DESCRIPTION
        The Switch-GitLocalBranch command is used to switch to the specified local
        Git branch. It checks if the branch exists and performs the checkout operation.
        If the checkout fails, it throws an error.

    .PARAMETER Name
        The name of the branch to switch to.

    .PARAMETER Force
        Forces the operation to proceed without confirmation prompts when used with
        -Confirm:$false.

    .INPUTS
        None

        This function does not accept pipeline input.

    .OUTPUTS
        None

        This function does not return any output.

    .EXAMPLE
        Switch-GitLocalBranch -Name "feature/branch"

        This example switches to the "feature/branch" local Git branch.

    .NOTES
        This function requires Git to be installed and accessible from the command line.
        The function will check for unstaged or staged changes before switching branches.
#>
function Switch-GitLocalBranch
{
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType()]
    param
    (
        [Parameter(Mandatory = $true, Position = 0)]
        [System.String]
        $Name,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Force
    )

    if ($Force.IsPresent -and -not $Confirm)
    {
        $ConfirmPreference = 'None'
    }

    # Only check assertions if not in WhatIf mode.
    if ($WhatIfPreference -eq $false)
    {
        Assert-GitLocalChange
    }

    $descriptionMessage = $script:localizedData.Switch_GitLocalBranch_ShouldProcessVerboseDescription -f $Name
    $confirmationMessage = $script:localizedData.Switch_GitLocalBranch_ShouldProcessVerboseWarning -f $Name
    $captionMessage = $script:localizedData.Switch_GitLocalBranch_ShouldProcessCaption

    if ($PSCmdlet.ShouldProcess($descriptionMessage, $confirmationMessage, $captionMessage))
    {
        git checkout $Name

        if ($LASTEXITCODE -ne 0) # cSpell: ignore LASTEXITCODE
        {
            $PSCmdlet.ThrowTerminatingError(
                [System.Management.Automation.ErrorRecord]::new(
                    ($script:localizedData.Switch_GitLocalBranch_FailedCheckoutLocalBranch -f $Name),
                    'SGLB0001', # cspell: disable-line
                    [System.Management.Automation.ErrorCategory]::InvalidOperation,
                    $Name
                )
            )
        }
    }
}
