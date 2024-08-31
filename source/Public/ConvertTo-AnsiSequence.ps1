<#
    .SYNOPSIS
        Converts a string value to an ANSI escape sequence.

    .DESCRIPTION
        The ConvertTo-AnsiSequence command converts a string value to an ANSI escape
        sequence. It is used to format text with ANSI escape codes for color and
        formatting in console output.

    .PARAMETER Value
        The string value to be converted to an ANSI escape sequence.

    .INPUTS
        System.String

    .OUTPUTS
        System.String

    .EXAMPLE
        ConvertTo-AnsiSequence -Value "31"

        This example converts the string value "31" to its ANSI escape sequence.

    .NOTES
        This function supports ANSI escape codes for color and formatting. It checks
        if the input string matches the pattern of an ANSI escape sequence and
        converts it accordingly. If the input string does not match the pattern,
        it is returned as is.
#>
function ConvertTo-AnsiSequence
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true, Position = 0)]
        [AllowEmptyString()]
        [AllowNull()]
        [System.String]
        $Value
    )

    if ($Value)
    {
        if ($Value -match "^(?:`e)?\[?([0-9;]+)m?$")
        {
            # Cannot use `e in Windows PowerShell, so use [char]0x1b instead.
            $Value = "$([System.Char] 0x1b)[" + $Matches[1] + 'm'
        }
    }

    return $Value
}
