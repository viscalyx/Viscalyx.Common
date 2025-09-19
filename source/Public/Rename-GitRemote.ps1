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

    .NOTES
        This function requires Git to be installed and accessible in the system PATH.
        The remote being renamed must exist in the current Git repository.
#>
function Rename-GitRemote
{
    [CmdletBinding()]
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
        $NewName
    )

    # Rename the Git remote
    git remote rename $Name $NewName

    if ($LASTEXITCODE -eq 0) # cSpell: ignore LASTEXITCODE
    {
        Write-Verbose -Message ($script:localizedData.Rename_GitRemote_RenamedRemote -f $Name, $NewName)
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