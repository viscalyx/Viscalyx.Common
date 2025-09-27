<#
    .SYNOPSIS
        Pushes a Git tag to a remote repository.

    .DESCRIPTION
        The Push-GitTag function is used to push a Git tag to a remote repository.
        It supports pushing a specific tag or pushing all tags.

    .PARAMETER RemoteName
        Specifies the name of the remote repository. The default value is 'origin'.

    .PARAMETER Name
        Specifies the name of the tag to push. This parameter is optional if, if
        left out all tags are pushed.

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
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType()]
    param
    (
        [Parameter(Position = 0)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $RemoteName = 'origin',

        [Parameter(Position = 1)]
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

    if ($PSBoundParameters.ContainsKey('Name'))
    {
        $descriptionMessage = $script:localizedData.Push_GitTag_PushTag_ShouldProcessVerboseDescription -f $Name, $RemoteName
        $confirmationMessage = $script:localizedData.Push_GitTag_PushTag_ShouldProcessVerboseWarning -f $Name, $RemoteName
        $captionMessage = $script:localizedData.Push_GitTag_PushTag_ShouldProcessCaption
    }
    else
    {
        $descriptionMessage = $script:localizedData.Push_GitTag_PushAllTags_ShouldProcessVerboseDescription -f $RemoteName
        $confirmationMessage = $script:localizedData.Push_GitTag_PushAllTags_ShouldProcessVerboseWarning -f $RemoteName
        $captionMessage = $script:localizedData.Push_GitTag_PushAllTags_ShouldProcessCaption
    }

    if ($PSCmdlet.ShouldProcess($descriptionMessage, $confirmationMessage, $captionMessage))
    {
        # When pushing all tags, check if there are any local tags to push
        if (-not $PSBoundParameters.ContainsKey('Name'))
        {
            $localTags = git tag
            if ($LASTEXITCODE -eq 0 -and ([string]::IsNullOrEmpty($localTags) -or ($localTags -is [array] -and $localTags.Count -eq 0)))
            {
                # No local tags exist in valid git repository, this is a no-op case
                return
            }
            # If LASTEXITCODE -ne 0, let the error propagate by continuing to git push which will also fail
        }

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
