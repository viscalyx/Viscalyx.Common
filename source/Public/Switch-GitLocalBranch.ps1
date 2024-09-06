0<#
    .SYNOPSIS
        Switches to the specified local Git branch.

    .DESCRIPTION
        The Switch-GitLocalBranch command is used to switch to the specified local
        Git branch. It checks if the branch exists and performs the checkout operation.
        If the checkout fails, it throws an error.

    .PARAMETER Name
        The name of the branch to switch to.

    .EXAMPLE
        Switch-GitLocalBranch -Name "feature/branch"

        This example switches to the "feature/branch" local Git branch.
#>
function Switch-GitLocalBranch
{
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
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

    $verboseDescriptionMessage = $script:localizedData.Switch_GitLocalBranch_ShouldProcessVerboseDescription -f $Name
    $verboseWarningMessage = $script:localizedData.Switch_GitLocalBranch_ShouldProcessVerboseWarning -f $Name
    $captionMessage = $script:localizedData.Switch_GitLocalBranch_ShouldProcessCaption

    if ($PSCmdlet.ShouldProcess($verboseDescriptionMessage, $verboseWarningMessage, $captionMessage))
    {
        git checkout $Name

        if ($LASTEXITCODE -ne 0) # cSpell: ignore LASTEXITCODE
        {
            $errorMessageParameters = @{
                Message = $script:localizedData.Switch_GitLocalBranch_FailedCheckoutLocalBranch -f $Name
                Category = 'InvalidOperation'
                ErrorId = 'SGLB0001' # cspell: disable-line
                TargetObject = $Name
            }

            Write-Error @errorMessageParameters
        }
    }
}
