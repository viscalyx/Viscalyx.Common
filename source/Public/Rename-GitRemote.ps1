<#
    .SYNOPSIS
        Renames a Git remote to a new name.

    .DESCRIPTION
        This function renames a Git remote in the current repository. It wraps the
        'git remote rename' command and provides proper error handling and validation.

    .PARAMETER Name
        The current name of the remote to be renamed.

    .PARAMETER NewName
        The new name for the remote.

    .PARAMETER Force
        Forces the rename operation to proceed without confirmation prompts.

    .INPUTS
        None

        This function does not accept pipeline input.

    .OUTPUTS
        None

        This function does not return any output.

    .EXAMPLE
        Rename-GitRemote -Name "my" -NewName "origin"

        This example renames the Git remote from "my" to "origin".

    .EXAMPLE
        Rename-GitRemote -Name "upstream" -NewName "fork"

        This example renames the Git remote from "upstream" to "fork".

    .EXAMPLE
        Rename-GitRemote -Name "my" -NewName "origin" -Force

        This example renames the Git remote from "my" to "origin" without prompting for confirmation.

    .NOTES
        This function requires Git to be installed and accessible in the system PATH.
        The remote being renamed must exist in the current Git repository.
#>
function Rename-GitRemote
{
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $NewName,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Force
    )

    if ($Force.IsPresent -and -not $Confirm)
    {
        $ConfirmPreference = 'None'
    }

    # Rename the Git remote
    $descriptionMessage = $script:localizedData.Rename_GitRemote_Action_ShouldProcessDescription -f $Name, $NewName
    $confirmationMessage = $script:localizedData.Rename_GitRemote_Action_ShouldProcessConfirmation -f $Name, $NewName
    $captionMessage = $script:localizedData.Rename_GitRemote_Action_ShouldProcessCaption

    if ($PSCmdlet.ShouldProcess($descriptionMessage, $confirmationMessage, $captionMessage))
    {
        git remote rename $Name $NewName

        if ($LASTEXITCODE -eq 0) # cSpell: ignore LASTEXITCODE
        {
            Write-Information -MessageData ($script:localizedData.Rename_GitRemote_RenamedRemote -f $Name, $NewName) -InformationAction Continue
        }
        else
        {
            $PSCmdlet.ThrowTerminatingError(
                [System.Management.Automation.ErrorRecord]::new(
                    ($script:localizedData.Rename_GitRemote_FailedToRename -f $Name, $NewName),
                    'RGR0001', # cspell: disable-line
                    [System.Management.Automation.ErrorCategory]::InvalidOperation,
                    $Name
                )
            )
        }
    }
}
