function Request-GitTag
{
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
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
        $verboseDescriptionMessage = $script:localizedData.Request_GitTag_FetchTag_ShouldProcessVerboseDescription -f $Name, $RemoteName
        $verboseWarningMessage = $script:localizedData.Request_GitTag_FetchTag_ShouldProcessVerboseWarning -f $Name, $RemoteName
        $captionMessage = $script:localizedData.Request_GitTag_FetchTag_ShouldProcessCaption
    }
    else
    {
        $verboseDescriptionMessage = $script:localizedData.Request_GitTag_FetchAllTags_ShouldProcessVerboseDescription -f $RemoteName
        $verboseWarningMessage = $script:localizedData.Request_GitTag_FetchAllTags_ShouldProcessVerboseWarning -f $RemoteName
        $captionMessage = $script:localizedData.Request_GitTag_FetchAllTags_ShouldProcessCaption
    }

    if ($PSCmdlet.ShouldProcess($verboseDescriptionMessage, $verboseWarningMessage, $captionMessage))
    {
        $arguments = @($RemoteName)

        if ($PSBoundParameters.ContainsKey('Name'))
        {
            $arguments += "refs/tags/$Name:refs/tags/$Name"
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

            $errorMessageParameters = @{
                Message      = $errorMessage
                Category     = 'InvalidOperation'
                ErrorId      = 'RGT0001' # cspell: disable-line
                TargetObject = $Name # Null if Name is not provided.
            }

            Write-Error @errorMessageParameters
        }
    }
}
