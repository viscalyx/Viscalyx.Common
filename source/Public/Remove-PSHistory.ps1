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
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Because ShouldProcess is handled in the commands it calls')]
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

        $shouldProcessVerboseDescription = 'Removing content matching the pattern ''{0}''.' -f $Pattern
        $shouldProcessVerboseWarning = 'Are you sure you want to remove the content matching the pattern ''{0}'' from PowerShell history?' -f $Pattern
        # This string shall not end with full stop (.) since it is used as a title of ShouldProcess messages.
        $shouldProcessCaption = 'Remove content matching the pattern from PowerShell history'

        if ($PSCmdlet.ShouldProcess($shouldProcessVerboseDescription, $shouldProcessVerboseWarning, $shouldProcessCaption))
        {
            $matchingLines |
                ForEach-Object -Process {
                    Clear-History -Id $_.Id
                }

            Write-Information -MessageData 'Removed PowerShell history content matching the pattern.' -InformationAction Continue
        }
    }
    else
    {
        Write-Information -MessageData 'No PowerShell history content matching the pattern.' -InformationAction Continue
    }
}
