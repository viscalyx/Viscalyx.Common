<#
    .SYNOPSIS
        Pushes a Git tag to a remote repository.

    .DESCRIPTION
        The Push-GitTag function is used to push a Git tag to a remote repository.
        It supports pushing a specific tag or pushing all tags.

    .PARAMETER RemoteName
        Specifies the name of the remote repository. The default value is 'origin'.

    .PARAMETER Name
        Specifies the name of the tag to push. This parameter is optional; if
        left out, all tags are pushed.

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
        Push-GitTag

        Pushes all tags to the default remote ('origin') repository.

    .EXAMPLE
        Push-GitTag -Name 'v1.0.0'

        Pushes the 'v1.0.0' tag to the default ('origin') remote repository.

    .EXAMPLE
        Push-GitTag -RemoteName 'my' -Name 'v1.0.0'

        Pushes the 'v1.0.0' tag to the 'my' remote repository.

    .EXAMPLE
        Push-GitTag -RemoteName 'upstream'

        Pushes all tags to the 'upstream' remote repository.

    .NOTES
        This function requires Git to be installed and accessible from the command
        line.
#>
function Push-GitTag
{
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium', DefaultParameterSetName = 'AllTags')]
    [OutputType()]
    param
    (
        [Parameter(Position = 0)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $RemoteName = 'origin',

        [Parameter(Position = 1, ParameterSetName = 'SingleTag')]
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

    $arguments = @($RemoteName)

    # If Name is not provided, push all tags.
    if ($PSBoundParameters.ContainsKey('Name'))
    {
        $arguments += "refs/tags/$Name"
    }
    else
    {
        $arguments += '--tags'
    }

    # When pushing all tags, check if there are any local tags to push before prompting
    if (-not $PSBoundParameters.ContainsKey('Name'))
    {
        $localTags = git tag

        if ($LASTEXITCODE -ne 0)
        {
            $errorMessage = $script:localizedData.Push_GitTag_FailedListTags

            $PSCmdlet.ThrowTerminatingError(
                [System.Management.Automation.ErrorRecord]::new(
                    $errorMessage,
                    'PGT0010', # cspell: disable-line
                    [System.Management.Automation.ErrorCategory]::InvalidOperation,
                    $null
                )
            )
        }
        elseif ([string]::IsNullOrEmpty($localTags) -or ($localTags -is [array] -and $localTags.Count -eq 0))
        {
            Write-Information -MessageData ($script:localizedData.Push_GitTag_NoLocalTags -f $RemoteName) -InformationAction Continue
            return
        }
    }

    if ($PSBoundParameters.ContainsKey('Name'))
    {
        $descriptionMessage = $script:localizedData.Push_GitTag_PushTag_ShouldProcessDescription -f $Name, $RemoteName
        $confirmationMessage = $script:localizedData.Push_GitTag_PushTag_ShouldProcessConfirmation -f $Name, $RemoteName
        $captionMessage = $script:localizedData.Push_GitTag_PushTag_ShouldProcessCaption
    }
    else
    {
        $descriptionMessage = $script:localizedData.Push_GitTag_PushAllTags_ShouldProcessDescription -f $RemoteName
        $confirmationMessage = $script:localizedData.Push_GitTag_PushAllTags_ShouldProcessConfirmation -f $RemoteName
        $captionMessage = $script:localizedData.Push_GitTag_PushAllTags_ShouldProcessCaption
    }

    if ($PSCmdlet.ShouldProcess($descriptionMessage, $confirmationMessage, $captionMessage))
    {

        git push @arguments

        if ($LASTEXITCODE -ne 0) # cSpell: ignore LASTEXITCODE
        {
            if ($PSBoundParameters.ContainsKey('Name'))
            {
                $errorMessage = $script:localizedData.Push_GitTag_FailedPushTag -f $Name, $RemoteName
            }
            else
            {
                $errorMessage = $script:localizedData.Push_GitTag_FailedPushAllTags -f $RemoteName
            }

            $PSCmdlet.ThrowTerminatingError(
                [System.Management.Automation.ErrorRecord]::new(
                    $errorMessage,
                    'PGT0001', # cspell: disable-line
                    [System.Management.Automation.ErrorCategory]::InvalidOperation,
                    $Name # Null if Name is not provided.
                )
            )
        }
    }
}
