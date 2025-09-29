<#
    .SYNOPSIS
        Creates a new Git tag locally.

    .DESCRIPTION
        The New-GitTag command creates a new Git tag in the local repository. This
        function supports ShouldProcess functionality for safe operations and includes
        a Force parameter to bypass confirmation prompts.

    .PARAMETER Name
        Specifies the name of the Git tag to create. This parameter is mandatory.

    .PARAMETER Force
        Forces the operation to proceed without confirmation prompts when similar
        to -Confirm:$false.

    .INPUTS
        None

        This function does not accept pipeline input.

    .OUTPUTS
        None

        This function does not return any output.

    .EXAMPLE
        PS> New-GitTag -Name 'v1.0.0'

        Creates a new Git tag named 'v1.0.0' at the current commit.

    .EXAMPLE
        PS> New-GitTag -Name 'release-2023' -Force

        Creates a new Git tag named 'release-2023' with the Force parameter,
        bypassing confirmation prompts when used with -Confirm:$false.

    .NOTES
        This function requires Git to be installed and accessible from the command line.
        The function will fail if there are any Git errors during tag creation.
#>
function New-GitTag
{
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    param
    (
        [Parameter(Mandatory = $true)]
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

    $descriptionMessage = $script:localizedData.New_GitTag_ShouldProcessVerboseDescription -f $Name
    $confirmationMessage = $script:localizedData.New_GitTag_ShouldProcessVerboseWarning -f $Name
    $captionMessage = $script:localizedData.New_GitTag_ShouldProcessCaption

    if ($PSCmdlet.ShouldProcess($descriptionMessage, $confirmationMessage, $captionMessage))
    {
        git tag $Name

        if ($LASTEXITCODE -ne 0) # cSpell: ignore LASTEXITCODE
        {
            $PSCmdlet.ThrowTerminatingError(
                [System.Management.Automation.ErrorRecord]::new(
                    ($script:localizedData.New_GitTag_FailedToCreateTag -f $Name),
                    'NGT0001', # cspell: disable-line
                    [System.Management.Automation.ErrorCategory]::InvalidOperation,
                    $Name
                )
            )
        }
    }
}
