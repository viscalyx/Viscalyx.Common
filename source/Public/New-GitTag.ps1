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

    $verboseDescriptionMessage =  $script:localizedData.New_GitTag_ShouldProcessVerboseDescription -f $Name
    $verboseWarningMessage = $script:localizedData.New_GitTag_ShouldProcessVerboseWarning -f $Name
    $captionMessage = $script:localizedData.New_GitTag_ShouldProcessCaption

    if ($PSCmdlet.ShouldProcess($verboseDescriptionMessage, $verboseWarningMessage, $captionMessage))
    {
        git tag $ReleaseTag

        if ($LASTEXITCODE -ne 0) # cSpell: ignore LASTEXITCODE
        {
            $errorMessageParameters = @{
                Message      = $script:localizedData.New_GitTag_FailedToCreateTag -f $Name
                Category     = 'InvalidOperation'
                ErrorId      = 'NGT0001' # cspell: disable-line
                TargetObject = $Name
            }

            Write-Error @errorMessageParameters
        }
    }
}
