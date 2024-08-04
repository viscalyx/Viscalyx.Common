<#
    .SYNOPSIS
        Removes command history entries that match a specified pattern.

    .DESCRIPTION
        The Remove-History function removes command history entries that match a
        specified pattern. It removes both the history entries stored by the
        PSReadLine module and the history entries stored by the PowerShell session.

    .PARAMETER Pattern
        Specifies the pattern to match against the command history entries. Only
        the entries that match the pattern will be removed.

    .PARAMETER EscapeRegularExpression
        Indicates that the pattern should be treated as a literal string. If this
        switch parameter is specified, the pattern will not be treated as a regular
        expression.

    .INPUTS
        None. You cannot pipe input to this function.

    .OUTPUTS
        None. The function does not generate any output.

    .EXAMPLE
        Remove-History -Pattern ".*\.txt"

        This example removes all command history entries that end with the ".txt"
        extension, using a regular expression pattern.

    .EXAMPLE
        Remove-History -Pattern './build.ps1' -EscapeRegularExpression

        This example removes all command history entries that contain the string
        "./build.ps1".
#>
function Remove-History
{
    param
    (
        [Parameter(Mandatory = $true, Position = 0)]
        [System.String]
        $Pattern,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $EscapeRegularExpression
    )

    Remove-PSReadLineHistory @PSBoundParameters
    Remove-PSHistory @PSBoundParameters
}
