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

    .PARAMETER RemovePartial
        When specified, also removes unterminated ANSI sequences that don't end with 'm'.
        By default, unterminated sequences like "[31" are preserved to avoid accidentally
        removing plain bracketed numbers.

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
        Clear-AnsiSequence -InputString "Value is [32] units"

        This example shows that plain bracketed numbers are preserved,
        returning "Value is [32] units".

    .EXAMPLE
        Clear-AnsiSequence -InputString "[31incomplete" -RemovePartial

        This example shows how the -RemovePartial switch removes unterminated sequences,
        returning "incomplete".

    .EXAMPLE
        Clear-AnsiSequence -InputString "`e[1;37;44mBold white on blue`e[0m and plain text"

        This example clears complex ANSI escape sequences, returning "Bold white on blue and plain text".

    .EXAMPLE
        $visibleLength = (Clear-AnsiSequence -InputString $formattedString).Length

        This example shows how to get the visible length of a string that contains ANSI sequences.

    .NOTES
        This function handles various ANSI escape sequence formats including:
        - Properly escaped sequences: `e[32m or [char]0x1b[32m
        - Unescaped SGR sequences: [32m (only when they end with 'm')
        - Non-SGR CSI sequences: ESC[2K, ESC[H (only when properly escaped)
        - Complex sequences with multiple codes: [1;37;44m

        The function uses a two-pass approach:
        1. Remove complete CSI sequences that start with an escape character
        2. Remove SGR-like patterns that aren't escaped but end with 'm'

        Plain bracketed numbers like "[32]" are preserved unless -RemovePartial is used.
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
        $InputString,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $RemovePartial
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
            Two-pass ANSI sequence removal approach:

            Pass 1: Remove complete CSI sequences that start with an escape character
            This handles all CSI sequences (SGR and non-SGR) that are properly escaped.
            Pattern matches: ESC[ followed by parameter bytes and final byte

            Pass 2: Remove SGR-like patterns that aren't escaped
            This only matches unescaped patterns that end with 'm' to avoid removing
            plain bracketed numbers like "[32]"

            With -RemovePartial: Also remove patterns that look like incomplete ANSI sequences
            but distinguish from plain bracketed numbers by requiring the pattern to be
            followed by text that suggests it was meant to be an ANSI sequence.
        #>

        # Pass 1: Remove properly escaped CSI sequences (both SGR and non-SGR)
        # ESC (0x1b or `e) followed by [ and CSI sequence pattern
        $escapedCsiPattern = '(?:`e|\x1b)\[[0-9;]*[A-Za-z]'
        $result = [System.Text.RegularExpressions.Regex]::Replace($InputString, $escapedCsiPattern, '')

        # Pass 2: Remove unescaped SGR sequences (must end with 'm' to be considered SGR)
        # By default, only remove complete SGR sequences ending with 'm'
        $unescapedSgrPattern = '\[([0-9;]+)m'
        $result = [System.Text.RegularExpressions.Regex]::Replace($result, $unescapedSgrPattern, '')

        # Pass 3: Optionally remove incomplete sequences that appear to be intended ANSI sequences
        if ($RemovePartial.IsPresent)
        {
            # Remove incomplete ANSI-like sequences: [digits/semicolons] but only if NOT closed with ]
            # Use word boundary or end of string to identify incomplete sequences
            $incompletePattern = '\[([0-9;]+)(?![0-9;\]])'
            $result = [System.Text.RegularExpressions.Regex]::Replace($result, $incompletePattern, '')
        }

        return $result
    }

    end
    {
        Write-Debug -Message ($script:localizedData.Clear_AnsiSequence_ProcessingComplete)
    }
}
