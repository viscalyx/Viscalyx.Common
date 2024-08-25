<#
    .SYNOPSIS
        Retrieves the PSReadLine history content.

    .DESCRIPTION
        The Get-PSReadLineHistory function retrieves the content of the PSReadLine
        history file. By default, it returns the entire history content, but you
        can specify a pattern to filter the results.

    .PARAMETER Pattern
        Specifies a pattern to filter the history content. Only lines matching the
        pattern will be returned.

    .EXAMPLE
        Get-PSReadLineHistory

        Returns the entire content of the PSReadLine history file.

    .EXAMPLE
        Get-PSReadLineHistory -Pattern "git"

        Returns only the lines from the PSReadLine history file that contain the word "git".

    .INPUTS
        None

    .OUTPUTS
        System.String

    .NOTES
        This function requires the PSReadLine module to be installed.

    .LINK
        https://docs.microsoft.com/en-us/powershell/module/psreadline/
#>
function Get-PSReadLineHistory
{
    [CmdletBinding()]
    param
    (
        [Parameter(Position = 0)]
        [System.String]
        $Pattern
    )

    $historyPath = (Get-PSReadLineOption).HistorySavePath

    $historyContent = Get-Content -Path $historyPath

    if ($Pattern)
    {
        $historyContent = $historyContent |
            Select-Object -SkipLast 1 |
            Select-String -Pattern $Pattern -Raw
    }

    $historyContent
}
