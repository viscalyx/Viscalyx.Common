<#
    .SYNOPSIS
        Removes Git tags from local repository and/or remote repositories.

    .DESCRIPTION
        The Remove-GitTag command removes Git tags from the local repository
        and/or one or more remote repositories. It supports removing multiple
        tags and handling multiple remotes in a single operation.

    .PARAMETER Tag
        Specifies the tag or tags to remove. This parameter is mandatory and
        accepts an array of strings to support removing multiple tags.

    .PARAMETER Remote
        Specifies the remote repository or repositories from which to remove
        the tag(s). This parameter accepts an array of strings to support
        removing from multiple remotes.

    .PARAMETER Local
        Specifies that the tag should be removed from the local repository.
        When neither Remote nor Local is specified, Local is assumed.

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
        PS> Remove-GitTag -Tag 'v1.0.0'

        Removes the tag 'v1.0.0' from the local repository.

    .EXAMPLE
        PS> Remove-GitTag -Tag 'v1.0.0' -Remote 'origin'

        Removes the tag 'v1.0.0' from the 'origin' remote repository.

    .EXAMPLE
        PS> Remove-GitTag -Tag 'v1.0.0' -Remote 'origin', 'upstream'

        Removes the tag 'v1.0.0' from both 'origin' and 'upstream' remote repositories.

    .EXAMPLE
        PS> Remove-GitTag -Tag 'v1.0.0' -Local -Remote 'origin'

        Removes the tag 'v1.0.0' from both the local repository and the 'origin' remote.

    .EXAMPLE
        PS> Remove-GitTag -Tag @('v1.0.0', 'v1.1.0') -Remote 'origin', 'my'

        Removes multiple tags from multiple remotes.

    .NOTES
        This function requires Git to be installed and accessible from the command line.
        The function will fail if there are any Git errors during tag removal.

        When only the Tag parameter is specified, the tag will be removed from the
        local repository (equivalent to specifying -Local).
#>
function Remove-GitTag
{
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType()]
    param
    (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [System.String[]]
        $Tag,

        [Parameter(ParameterSetName = 'RemoteOrLocal')]
        [ValidateNotNullOrEmpty()]
        [System.String[]]
        $Remote,

        [Parameter(ParameterSetName = 'RemoteOrLocal')]
        [System.Management.Automation.SwitchParameter]
        $Local,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Force
    )

    if ($Force.IsPresent -and -not $Confirm)
    {
        $ConfirmPreference = 'None'
    }

    # If neither Remote nor Local is specified, assume Local
    $removeFromLocal = $Local.IsPresent -or (-not $PSBoundParameters.ContainsKey('Remote'))
    $removeFromRemote = $PSBoundParameters.ContainsKey('Remote')

    foreach ($tagName in $Tag)
    {
        # Remove from local repository
        if ($removeFromLocal)
        {
            $descriptionMessage = $script:localizedData.Remove_GitTag_Local_ShouldProcessVerboseDescription -f $tagName
            $confirmationMessage = $script:localizedData.Remove_GitTag_Local_ShouldProcessVerboseWarning -f $tagName
            $captionMessage = $script:localizedData.Remove_GitTag_Local_ShouldProcessCaption

            if ($PSCmdlet.ShouldProcess($descriptionMessage, $confirmationMessage, $captionMessage))
            {
                git tag -d $tagName

                if ($LASTEXITCODE -ne 0) # cSpell: ignore LASTEXITCODE
                {
                    $PSCmdlet.ThrowTerminatingError(
                        [System.Management.Automation.ErrorRecord]::new(
                            ($script:localizedData.Remove_GitTag_FailedToRemoveLocalTag -f $tagName),
                            'RGT0001', # cspell: disable-line
                            [System.Management.Automation.ErrorCategory]::InvalidOperation,
                            $tagName
                        )
                    )
                }
            }
        }

        # Remove from remote repositories
        if ($removeFromRemote)
        {
            foreach ($remoteName in $Remote)
            {
                $descriptionMessage = $script:localizedData.Remove_GitTag_Remote_ShouldProcessVerboseDescription -f $tagName, $remoteName
                $confirmationMessage = $script:localizedData.Remove_GitTag_Remote_ShouldProcessVerboseWarning -f $tagName, $remoteName
                $captionMessage = $script:localizedData.Remove_GitTag_Remote_ShouldProcessCaption

                if ($PSCmdlet.ShouldProcess($descriptionMessage, $confirmationMessage, $captionMessage))
                {
                    git push $remoteName ":refs/tags/$tagName"

                    if ($LASTEXITCODE -ne 0) # cSpell: ignore LASTEXITCODE
                    {
                        $PSCmdlet.ThrowTerminatingError(
                            [System.Management.Automation.ErrorRecord]::new(
                                ($script:localizedData.Remove_GitTag_FailedToRemoveRemoteTag -f $tagName, $remoteName),
                                'RGT0002', # cspell: disable-line
                                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                                $tagName
                            )
                        )
                    }
                }
            }
        }
    }
}
