<#
    .SYNOPSIS
        Converts two strings into a difference string, highlighting the differences
        between them.

    .DESCRIPTION
        The ConvertTo-DifferenceString command takes two strings, a reference string
        and a difference string, and converts them into a difference string that
        highlights the differences between the two strings. The function compares
        the byte values of each character in the strings and outputs the differences
        in a formatted manner. It supports customizing the indicators, labels, colors,
        and encoding type.

    .PARAMETER ReferenceString
        Specifies the reference string to compare against.

    .PARAMETER DifferenceString
        Specifies the difference string to compare.

    .PARAMETER EqualIndicator
        Specifies the indicator to use for equal bytes. Default is '=='.

    .PARAMETER NotEqualIndicator
        Specifies the indicator to use for not equal bytes. Default is '!='.

    .PARAMETER HighlightStart
        Specifies the ANSI escape sequence to start highlighting. Default is
        "[31m" (red color).

    .PARAMETER HighlightEnd
        Specifies the ANSI escape sequence to end highlighting. Default is
        "[0m" (reset color).

    .PARAMETER ReferenceLabel
        Specifies the label for the reference string. Default is 'Expected:'.

    .PARAMETER DifferenceLabel
        Specifies the label for the difference string. Default is 'But was:'.

    .PARAMETER NoColumnHeader
        Specifies whether to exclude the column header from the output.

    .PARAMETER NoLabels
        Specifies whether to exclude the labels from the output.

    .PARAMETER ReferenceLabelAnsi
        Specifies the ANSI escape sequence to apply to the reference label.

    .PARAMETER DifferenceLabelAnsi
        Specifies the ANSI escape sequence to apply to the difference label.

    .PARAMETER ColumnHeaderAnsi
        Specifies the ANSI escape sequence to apply to the column header.

    .PARAMETER ColumnHeaderResetAnsi
        Specifies the ANSI escape sequence to reset the column header.

    .PARAMETER EncodingType
        Specifies the encoding type to use for converting the strings to byte arrays.
        Default is 'UTF8'.

    .EXAMPLE
        PS> ConvertTo-DifferenceString -ReferenceString 'Hello' -DifferenceString 'Hallo'

        Expected:                                                               But was:
        ----------------------------------------------------------------        --------------------------------------------------------
        Bytes                                           Ascii                   Bytes                                           Ascii
        -----                                           -----                   -----                                           -----
        48 65 6C 6C 6F                                  Hello              ==   48 61 6C 6C 6F                                  Hallo

        Converts the reference string 'Hello' and the difference string 'Hallo'
        into a difference string, highlighting the differences.

    .INPUTS
        None.

    .OUTPUTS
        System.String.
#>
function ConvertTo-DifferenceString
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [System.String]
        $ReferenceString,

        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [System.String]
        $DifferenceString,

        [Parameter()]
        [ValidateLength(0, 2)]
        [System.String]
        $EqualIndicator = '==',

        [Parameter()]
        [ValidateLength(0, 2)]
        [System.String]
        $NotEqualIndicator = '!=',

        [Parameter()]
        [System.String]
        $HighlightStart = '[31m', # Default to red color

        [Parameter()]
        [System.String]
        $HighlightEnd = '[0m', # Default to reset color

        [Parameter()]
        [System.String]
        $ReferenceLabel = 'Expected:',

        [Parameter()]
        [System.String]
        $DifferenceLabel = 'But was:',

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $NoColumnHeader,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $NoLabels,

        [Parameter()]
        [System.String]
        $ReferenceLabelAnsi = '',

        [Parameter()]
        [System.String]
        $DifferenceLabelAnsi = '',

        [Parameter()]
        [System.String]
        $ColumnHeaderAnsi = '',

        [Parameter()]
        [System.String]
        $ColumnHeaderResetAnsi = '',

        [Parameter()]
        [ValidateSet('ASCII', 'BigEndianUnicode', 'Default', 'Unicode', 'UTF32', 'UTF7', 'UTF8')]
        [System.String]
        $EncodingType = 'UTF8',

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $NoHexOutput
    )

    # Get actual ANSI escape sequences if they weren't.
    $HighlightStart = ConvertTo-AnsiSequence -Value $HighlightStart
    $HighlightEnd = ConvertTo-AnsiSequence -Value $HighlightEnd
    $ReferenceLabelAnsi = ConvertTo-AnsiSequence -Value $ReferenceLabelAnsi
    $DifferenceLabelAnsi = ConvertTo-AnsiSequence -Value $DifferenceLabelAnsi
    $ColumnHeaderAnsi = ConvertTo-AnsiSequence -Value $ColumnHeaderAnsi
    $ColumnHeaderResetAnsi = ConvertTo-AnsiSequence -Value $ColumnHeaderResetAnsi

    # Pre-pad indicators
    $NotEqualIndicator = $NotEqualIndicator.PadRight(2)
    $EqualIndicator = $EqualIndicator.PadRight(2)

    # Convert the strings to byte arrays using the specified encoding
    $encoding = [System.Text.Encoding]::$EncodingType
    $referenceBytes = $encoding.GetBytes($ReferenceString)
    $differenceBytes = $encoding.GetBytes($DifferenceString)

    # Precompute lengths to avoid repeated property lookups
    $refLength = $referenceBytes.Length
    $diffLength = $differenceBytes.Length
    $maxLength = [Math]::Max($refLength, $diffLength)

    # Use a larger group size when hex output is disabled
    $groupSize = if ($NoHexOutput)
    {
        64
    }
    else
    {
        16
    }

    # Output the labels if NoLabels is not specified
    if (-not $NoLabels)
    {
        "$($ReferenceLabelAnsi)$($ReferenceLabel)$($HighlightEnd)                                                               $($DifferenceLabelAnsi)$($DifferenceLabel)$($HighlightEnd)"
        ('-' * 64) + (' ' * 8) + ('-' * 64) # Output a line of dashes under the labels
    }

    # Output the column header once with dashes underline if NoColumnHeader is not specified
    if (-not $NoColumnHeader)
    {
        if ($NoHexOutput)
        {
            # New header when hex column is disabled
            "$($ColumnHeaderAnsi)Ascii$(' ' * 67)Ascii$($ColumnHeaderResetAnsi)"
            "$($ColumnHeaderAnsi)" + ('-' * 64) + (' ' * 8) + ('-' * 64) + "$($ColumnHeaderResetAnsi)"
        }
        else
        {
            "$($ColumnHeaderAnsi)Bytes                                           Ascii                   Bytes                                           Ascii$($ColumnHeaderResetAnsi)"
            "$($ColumnHeaderAnsi)-----                                           -----                   -----                                           -----$($ColumnHeaderResetAnsi)"
        }
    }

    if ($NoHexOutput)
    {
        # Initialize arrays for ascii only
        $refCharArray = @()
        $diffCharArray = @()
    }
    else
    {
        # Initialize arrays for hex and ascii
        $refHexArray = @()
        $refCharArray = @()
        $diffHexArray = @()
        $diffCharArray = @()
    }

    $currentGroupHighlighted = $false

    # Loop through each byte in the arrays up to the maximum length
    for ($i = 0; $i -lt $maxLength; $i++)
    {
        # At the beginning of a new group, reset the highlight flag
        if (($i % $groupSize) -eq 0)
        {
            $currentGroupHighlighted = $false

            if (-not $NoHexOutput)
            {
                $refHexArray = @()
                $refCharArray = @()
                $diffHexArray = @()
                $diffCharArray = @()
            }
            else
            {
                $refCharArray = @()
                $diffCharArray = @()
            }
        }

        # Get the byte and corresponding values for the reference string
        if ($i -lt $refLength)
        {
            $refByte = $referenceBytes[$i]
            $refHex = '{0:X2}' -f $refByte
            $refChar = if ($refByte -lt 32)
            {
                [System.Char] ($refByte + 0x2400)
            }
            elseif ($refByte -eq 127)
            {
                [System.Char] 0x2421
            }
            else
            {
                [System.Char] $refByte
            }
        }
        else
        {
            $refByte = -1
            $refHex = '  '
            $refChar = ' '
        }

        # Get the byte and corresponding values for the difference string
        if ($i -lt $diffLength)
        {
            $diffByte = $differenceBytes[$i]
            $diffHex = '{0:X2}' -f $diffByte
            $diffChar = if ($diffByte -lt 32)
            {
                [System.Char] ($diffByte + 0x2400)
            }
            elseif ($diffByte -eq 127)
            {
                [System.Char] 0x2421
            }
            else
            {
                [System.Char] $diffByte
            }
        }
        else
        {
            $diffByte = -1
            $diffHex = '  '
            $diffChar = ' '
        }

        # Highlight differences and set the group's flag if any difference is found
        if ($refByte -ne $diffByte)
        {
            $refHex = "$HighlightStart$refHex$HighlightEnd"
            $refChar = "$HighlightStart$refChar$HighlightEnd"
            $diffHex = "$HighlightStart$diffHex$HighlightEnd"
            $diffChar = "$HighlightStart$diffChar$HighlightEnd"

            $currentGroupHighlighted = $true
        }

        if (-not $NoHexOutput)
        {
            # Add to arrays
            $refHexArray += $refHex
            $refCharArray += $refChar
            $diffHexArray += $diffHex
            $diffCharArray += $diffChar
        }
        else
        {
            $refCharArray += $refChar
            $diffCharArray += $diffChar
        }

        # When a group is completed or at the end...
        if ((($i + 1) % $groupSize) -eq 0 -or $i -eq $maxLength - 1)
        {
            if (-not $NoHexOutput)
            {
                # Pad arrays to ensure they have the correct number of elements using for loops
                for ($j = $refHexArray.Count; $j -lt $groupSize; $j++)
                {
                    $refHexArray += '  '
                }

                for ($j = $refCharArray.Count; $j -lt $groupSize; $j++)
                {
                    $refCharArray += ' '
                }

                for ($j = $diffHexArray.Count; $j -lt $groupSize; $j++)
                {
                    $diffHexArray += '  '
                }

                for ($j = $diffCharArray.Count; $j -lt $groupSize; $j++)
                {
                    $diffCharArray += ' '
                }

                $refHexLine = $refHexArray -join ' '
                $refCharLine = $refCharArray -join ''
                $diffHexLine = $diffHexArray -join ' '
                $diffCharLine = $diffCharArray -join ''

                # Use the precomputed flag for this group
                $indicator = if ($currentGroupHighlighted)
                {
                    $NotEqualIndicator
                }
                else
                {
                    $EqualIndicator
                }

                # Output the results in the specified format
                '{0} {1}   {2}   {3} {4}' -f $refHexLine, $refCharLine, $indicator, $diffHexLine, $diffCharLine
            }
            else
            {
                for ($j = $refCharArray.Count; $j -lt $groupSize; $j++)
                {
                    $refCharArray += ' '
                }
                for ($j = $diffCharArray.Count; $j -lt $groupSize; $j++)
                {
                    $diffCharArray += ' '
                }
                $refChars = $refCharArray -join ''
                $diffChars = $diffCharArray -join ''
                $indicator = if ($currentGroupHighlighted)
                {
                    $NotEqualIndicator
                }
                else
                {
                    $EqualIndicator
                }
                '{0}   {1}   {2}' -f $refChars, $indicator, $diffChars
            }
        }
    }
}
