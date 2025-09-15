<#
    .SYNOPSIS
        Removes PowerShell history content matching a specified pattern.

    .DESCRIPTION
        The Remove-PSHistory function removes PowerShell history content that matches
        a specified pattern.

    .PARAMETER Pattern
        Specifies the pattern to match against the command history entries. Only
        the entries that match the pattern will be removed.

    .PARAMETER EscapeRegularExpression
        Indicates that the pattern should be treated as a literal string. If this
        switch parameter is specified, the pattern will not be treated as a regular
        expression.

    .EXAMPLE
        Remove-PSHistory -Pattern ".*\.txt"

        This example removes all command history entries that end with the ".txt"
        extension, using a regular expression pattern.

    .EXAMPLE
        Remove-PSHistory -Pattern './build.ps1' -EscapeRegularExpression

        This example removes all command history entries that contain the string
        "./build.ps1".

    .INPUTS
        None. You cannot pipe input to this function.

    .OUTPUTS
        None. The function does not generate any output.
#>
function Remove-PSHistory
{
    [CmdletBinding(SupportsShouldProcess = $true , ConfirmImpact = 'High')]
    param
    (
        [Parameter(Mandatory = $true, Position = 0)]
        [System.String]
        $Pattern,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $EscapeRegularExpression
    )

    if ($EscapeRegularExpression.IsPresent)
    {
        $Pattern = [System.Text.RegularExpressions.Regex]::Escape($Pattern)
    }

    $historyContent = Get-History

    $matchingLines = $historyContent |
        Where-Object -FilterScript {
            $_.CommandLine -match $Pattern
        }

    if ($matchingLines)
    {
        $matchingLines | Write-Verbose -Verbose

        $shouldProcessDescription = $script:localizedData.Remove_PSHistory_ShouldProcessDescription -f $Pattern
        $shouldProcessConfirmation = $script:localizedData.Remove_PSHistory_ShouldProcessConfirmation -f $Pattern
        # This string shall not end with full stop (.) since it is used as a title of ShouldProcess messages.
        $shouldProcessCaption = $script:localizedData.Remove_PSHistory_ShouldProcessCaption

        if ($PSCmdlet.ShouldProcess($shouldProcessDescription, $shouldProcessConfirmation, $shouldProcessCaption))
        {
            $matchingLines |
                ForEach-Object -Process {
                    Clear-History -Id $_.Id
                }

            Write-Information -MessageData ($script:localizedData.Remove_PSHistory_Removed) -InformationAction Continue
        }
    }
    else
    {
        Write-Information -MessageData ($script:localizedData.Remove_PSHistory_NoMatches) -InformationAction Continue
    }
}
