<#
    .SYNOPSIS
        Fetches Git tags from a remote repository.

    .DESCRIPTION
        The Request-GitTag command fetches Git tags from a remote repository.
        It can fetch a specific tag by name or all tags if no name is specified.

    .PARAMETER RemoteName
        Specifies the name of the remote repository to fetch tags from.

    .PARAMETER Name
        Specifies the name of the specific tag to fetch. If not provided, all tags will be fetched.

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
        Request-GitTag -RemoteName 'origin' -Name 'v1.0.0'

        Fetches the 'v1.0.0' tag from the 'origin' remote repository.

    .EXAMPLE
        Request-GitTag -RemoteName 'upstream'

        Fetches all tags from the 'upstream' remote repository.

    .NOTES
        This function requires Git to be installed and accessible from the command line.
#>
function Request-GitTag
{
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $RemoteName,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
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

    if ($PSBoundParameters.ContainsKey('Name'))
    {
        $descriptionMessage = $script:localizedData.Request_GitTag_FetchTag_ShouldProcessVerboseDescription -f $Name, $RemoteName
        $confirmationMessage = $script:localizedData.Request_GitTag_FetchTag_ShouldProcessVerboseWarning -f $Name, $RemoteName
        $captionMessage = $script:localizedData.Request_GitTag_FetchTag_ShouldProcessCaption
    }
    else
    {
        $descriptionMessage = $script:localizedData.Request_GitTag_FetchAllTags_ShouldProcessVerboseDescription -f $RemoteName
        $confirmationMessage = $script:localizedData.Request_GitTag_FetchAllTags_ShouldProcessVerboseWarning -f $RemoteName
        $captionMessage = $script:localizedData.Request_GitTag_FetchAllTags_ShouldProcessCaption
    }

    if ($PSCmdlet.ShouldProcess($descriptionMessage, $confirmationMessage, $captionMessage))
    {
        $arguments = @($RemoteName)

        if ($PSBoundParameters.ContainsKey('Name'))
        {
            $arguments += "refs/tags/$($Name):refs/tags/$Name"
        }
        else
        {
            $arguments += '--tags'
        }

        git fetch @arguments

        if ($LASTEXITCODE -ne 0) # cSpell: ignore LASTEXITCODE
        {
            if ($PSBoundParameters.ContainsKey('Name'))
            {
                $errorMessage = $script:localizedData.Request_GitTag_FailedFetchTag -f $Name, $RemoteName
            }
            else
            {
                $errorMessage = $script:localizedData.Request_GitTag_FailedFetchAllTags -f $RemoteName
            }

            $PSCmdlet.ThrowTerminatingError(
                [System.Management.Automation.ErrorRecord]::new(
                    $errorMessage,
                    'RGT0001', # cspell: disable-line
                    [System.Management.Automation.ErrorCategory]::InvalidOperation,
                    $Name # Null if Name is not provided.
                )
            )
        }
    }
}
