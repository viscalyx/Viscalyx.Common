<#
    .SYNOPSIS
        Removes content from the PSReadLine history that matches a specified pattern.

    .DESCRIPTION
        The Remove-PSReadLineHistory function removes content from the PSReadLine
        history that matches a specified pattern.

    .PARAMETER Pattern
        Specifies the pattern to match against the command history entries. Only
        the entries that match the pattern will be removed.

    .PARAMETER EscapeRegularExpression
        Indicates that the pattern should be treated as a literal string. If this
        switch parameter is specified, the pattern will not be treated as a regular
        expression.

    .NOTES
        - This command requires the PSReadLine module to be installed.
        - The PSReadLine history is stored in a file specified by the HistorySavePath
          property of the PSReadLineOption object.

    .EXAMPLE
        Remove-PSReadLineHistory -Pattern ".*\.txt"

        This example removes all command history entries that end with the ".txt"
        extension, using a regular expression pattern.

    .EXAMPLE
        Remove-PSReadLineHistory -Pattern './build.ps1' -EscapeRegularExpression

        This example removes all command history entries that contain the string
        "./build.ps1".

    .INPUTS
        None. You cannot pipe input to this function.

    .OUTPUTS
        None. The function does not generate any output.
#>

function Remove-PSReadLineHistory
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

    $historyPath = (Get-PSReadLineOption).HistorySavePath

    $historyContent = Get-Content -Path $historyPath

    # Do not match the last line as it is the line that called the function.
    $matchingContent = $historyContent |
        Select-Object -SkipLast 1 |
        Select-String -Pattern $Pattern

    if ($matchingContent)
    {
        $matchingContent | Write-Verbose -Verbose

        $shouldProcessVerboseDescription = 'Removing content matching the pattern ''{0}''.' -f $Pattern
        $shouldProcessVerboseWarning = 'Are you sure you want to remove the content matching the pattern ''{0}'' from PSReadLine history?' -f $Pattern
        # This string shall not end with full stop (.) since it is used as a title of ShouldProcess messages.
        $shouldProcessCaption = 'Remove content matching the pattern from PSReadLine history'

        if ($PSCmdlet.ShouldProcess($shouldProcessVerboseDescription, $shouldProcessVerboseWarning, $shouldProcessCaption))
        {
            Set-Content -Path $historyPath -Value (
                $historyContent |
                    Select-String -NotMatch $Pattern
            ).Line

            Write-Information -MessageData 'Removed PSReadLine history content matching the pattern.' -InformationAction Continue
        }
    }
    else
    {
        Write-Information -MessageData 'No PSReadLine history content matching the pattern.' -InformationAction Continue
    }
}
