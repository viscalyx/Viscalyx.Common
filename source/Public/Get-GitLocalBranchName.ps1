<#
    .SYNOPSIS
        Retrieves the name of the local Git branch.

    .DESCRIPTION
        The Get-GitLocalBranchName command is used to retrieve the name of the
        current local Git branch. It uses the `git rev-parse --abbrev-ref HEAD`
        command to get the branch name.

    .OUTPUTS
        [System.String]

        The function returns the name of the current local Git branch as a string.

    .EXAMPLE
        PS C:\> Get-GitLocalBranchName -Current

        Returns the name of the current local Git branch.
#>
function Get-GitLocalBranchName
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSShouldProcess', '', Justification = 'ShouldProcess is implemented without ShouldProcess/ShouldContinue.')]
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([System.String])]
    param
    (
        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Current
    )

    $branchName = $null

    if ($WhatIfPreference)
    {
        if ($Current.IsPresent)
        {
            Write-Information -MessageData 'What if: Getting current local branch name' -InformationAction Continue
        }
        else
        {
            Write-Information -MessageData 'What if: Getting local branch names.' -InformationAction Continue
        }
    }
    else
    {
        if ($Current.IsPresent)
        {
            $branchName = git rev-parse --abbrev-ref HEAD
        }
        else
        {
            $branchName = git branch --format='%(refname:short)' --list
        }

        if ($LASTEXITCODE -ne 0) # cSpell: ignore LASTEXITCODE
        {
            $PSCmdlet.ThrowTerminatingError(
                [System.Management.Automation.ErrorRecord]::new(
                    $script:localizedData.Get_GitLocalBranchName_Failed,
                    'GGLBN0001', # cspell: disable-line
                    [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                    $branchName
                )
            )
        }
    }

    return $branchName
}
