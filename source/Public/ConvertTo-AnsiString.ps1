<#
    .SYNOPSIS
        Converts a string containing ANSI sequences to properly escaped and terminated ANSI sequences.

    .DESCRIPTION
        The ConvertTo-AnsiString command takes a string that may contain
        ANSI escape sequences (with or without proper escape characters) and ensures
        that all ANSI sequences are properly escaped and terminated. It adds the
        necessary escape character ([char]0x1b) and ensures all sequences end with 'm'.

    .PARAMETER InputString
        The string containing ANSI sequences to be properly escaped and terminated.
        The string can contain ANSI sequences that may or may not already have escape
        characters, and may or may not be properly terminated.

    .INPUTS
        System.String

    .OUTPUTS
        System.String

    .EXAMPLE
        ConvertTo-AnsiString -InputString "[32mTag [1;37;44m{0}[0m[32m was created '{1}'[0m"

        This example converts ANSI sequences without escape characters to properly escaped sequences.

    .EXAMPLE
        ConvertTo-AnsiString -InputString "[32mTag [1;37;44m{0}[0m[32m was created '{1}'"

        This example ensures that unterminated ANSI sequences are properly terminated with a reset sequence.

    .EXAMPLE
        ConvertTo-AnsiString -InputString "`e[32mAlready escaped`e[0m"

        This example processes a string that already contains properly escaped ANSI sequences.

    .NOTES
        This function ensures that all ANSI escape sequences in the input string
        are properly formatted with the correct escape character and termination.
        It handles both escaped and unescaped sequences, as well as sequences that
        may be missing the 'm' terminator.
#>
function ConvertTo-AnsiString
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
        Write-Debug -Message ($script:localizedData.ConvertTo_AnsiString_ProcessingBegin)
    }

    process
    {
        if ([System.String]::IsNullOrEmpty($InputString))
        {
            Write-Debug -Message ($script:localizedData.ConvertTo_AnsiString_EmptyInput)
            return $InputString
        }

        Write-Verbose -Message ($script:localizedData.ConvertTo_AnsiString_ProcessingString -f $InputString.Length)

        # Define the escape character - use [char]0x1b for compatibility with Windows PowerShell
        $escapeChar = [System.Char] 0x1b

        <#
            Pattern to match ANSI sequences:
            - Optional escape character (either `e or the actual escape char)
            - Opening bracket [
            - ANSI codes (numbers and semicolons)
            - Optional closing 'm' (we'll ensure it's there)
        #>
        $ansiPattern = '(?:`e|\x1b)?\[([0-9;]+)m?'

        <#
            First, normalize all incomplete sequences by ensuring they end with 'm'.
            Note: We use Regex.Replace() with a callback instead of -replace because:
            - The -replace operator with regex patterns like '(?!m)' can match within
              complete sequences
            - We need conditional logic (only add 'm' if not already present) which
              requires a callback
            - This approach gives us precise control over each match individually
        #>
        $normalizedInput = [System.Text.RegularExpressions.Regex]::Replace(
            $InputString,
            $ansiPattern,
            {
                param($match)

                # If the match doesn't end with 'm', add it
                if (-not $match.Value.EndsWith('m'))
                {
                    return $match.Value + 'm'
                }
                else
                {
                    # Already complete, return as-is
                    return $match.Value
                }
            }
        )

        # Find all matches in the normalized input to determine active formatting state
        $regexMatches = [System.Text.RegularExpressions.Regex]::Matches($normalizedInput, $ansiPattern)

        # Track whether we have active formatting that needs reset
        $hasActiveFormatting = $false

        <#
            Process each match to determine if we end with active formatting
            Since all sequences are now complete, this logic is much simpler
        #>
        foreach ($match in $regexMatches)
        {
            $codes = $match.Groups[1].Value

            if ($codes -eq '0')
            {
                # Reset sequence - clears all formatting
                $hasActiveFormatting = $false
            }
            else
            {
                # Non-reset sequence - sets active formatting
                $hasActiveFormatting = $true
            }
        }

        # Replace all ANSI sequences with properly formatted ones using the normalized input
        $result = [System.Text.RegularExpressions.Regex]::Replace(
            $normalizedInput,
            $ansiPattern,
            {
                param($match)

                $codes = $match.Groups[1].Value

                Write-Debug -Message ($script:localizedData.ConvertTo_AnsiString_ProcessingSequence -f $codes)

                # Return properly formatted ANSI sequence
                return "$escapeChar[$codes" + 'm'
            }
        )

        # Add reset sequence if we have active formatting at the end
        if ($hasActiveFormatting)
        {
            $result += "$escapeChar[0m"
            Write-Debug -Message ($script:localizedData.ConvertTo_AnsiString_ProcessingSequence -f 'reset')
        }

        Write-Debug -Message ($script:localizedData.ConvertTo_AnsiString_ProcessingComplete)

        return $result
    }
}
