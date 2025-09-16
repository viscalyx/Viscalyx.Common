<#
    .SYNOPSIS
        Clears ANSI escape sequences from a string.

    .DESCRIPTION
        The Clear-AnsiSequence command clears all ANSI escape sequences from a string,
        returning only the visible text content. This is useful for calculating the actual
        visible length of strings that contain ANSI formatting codes, or for extracting
        plain text from formatted console output.

    .PARAMETER InputString
        The string from which ANSI escape sequences should be cleared.
        The string can contain any combination of ANSI escape sequences with or without
        proper escape characters.

    .INPUTS
        System.String

    .OUTPUTS
        System.String

    .EXAMPLE
        Clear-AnsiSequence -InputString "`e[32mGreen text`e[0m"

        This example clears ANSI escape sequences from a string with properly escaped sequences,
        returning "Green text".

    .EXAMPLE
        Clear-AnsiSequence -InputString "[31mRed text[0m"

        This example clears ANSI escape sequences from a string with unescaped sequences,
        returning "Red text".

    .EXAMPLE
        Clear-AnsiSequence -InputString "`e[1;37;44mBold white on blue`e[0m and plain text"

        This example clears complex ANSI escape sequences, returning "Bold white on blue and plain text".

    .EXAMPLE
        $visibleLength = (Clear-AnsiSequence -InputString $formattedString).Length

        This example shows how to get the visible length of a string that contains ANSI sequences.

    .NOTES
        This function handles various ANSI escape sequence formats including:
        - Properly escaped sequences: `e[32m or [char]0x1b[32m
        - Unescaped sequences: [32m
        - Sequences with or without proper termination
        - Complex sequences with multiple codes: [1;37;44m
#>
function Clear-AnsiSequence
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [AllowEmptyString()]
        [AllowNull()]
        [System.String]
        $InputString
    )

    begin
    {
        Write-Debug -Message ($script:localizedData.Clear_AnsiSequence_ProcessingBegin)
    }

    process
    {
        if ([System.String]::IsNullOrEmpty($InputString))
        {
            Write-Debug -Message ($script:localizedData.Clear_AnsiSequence_EmptyInput)
            return $InputString
        }

        Write-Debug -Message ($script:localizedData.Clear_AnsiSequence_ProcessingString -f $InputString.Length)

        <#
            Pattern to match ANSI sequences:
            - Optional escape character (either `e or the actual escape char)
            - Opening bracket [
            - ANSI codes (numbers and semicolons)
            - Optional closing 'm' (some sequences might not be properly terminated)
        #>
        $ansiPattern = '(?:`e|\x1b)?\[([0-9;]+)m?'

        # Clear all ANSI escape sequences from the input string
        $result = [System.Text.RegularExpressions.Regex]::Replace($InputString, $ansiPattern, '')

        return $result
    }

    end
    {
        Write-Debug -Message ($script:localizedData.Clear_AnsiSequence_ProcessingComplete)
    }
}
