function Out-DiffString
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [AllowEmptyString()]
        [AllowNull()]
        [AllowEmptyCollection()]
        [System.String[]]$ReferenceString,

        [Parameter(Mandatory=$true)]
        [AllowEmptyString()]
        [AllowNull()]
        [AllowEmptyCollection()]
        [System.String[]]$DifferenceString,

        [Parameter()]
        [System.String]$EqualIndicator = '==',

        [Parameter()]
        [System.String]$NotEqualIndicator = '!=',

        [Parameter()]
        [System.String]$HighlightStart = "`e[31m",  # Default to red color

        [Parameter()]
        [System.String]$HighlightEnd = "`e[0m",     # Default to reset color

        [Parameter()]
        [System.String]$ReferenceLabel = 'Expected:',

        [Parameter()]
        [System.String]$DifferenceLabel = 'But was:',

        [Parameter()]
        [System.Management.Automation.SwitchParameter]$NoHeader,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]$NoLabels,

        [Parameter()]
        [System.String]$ReferenceLabelAnsi = '',

        [Parameter()]
        [System.String]$DifferenceLabelAnsi = '',

        [Parameter()]
        [System.String]$HeaderAnsi = '',

        [Parameter()]
        [System.String]$HeaderResetAnsi = '',

        [Parameter()]
        [System.Management.Automation.SwitchParameter]$ConcatenateArray,

        [Parameter()]
        [System.String]$ConcatenateChar = [System.Environment]::NewLine
    )

    function ConvertTo-DiffString {
        param (
            [System.String]$refString,
            [System.String]$diffString
        )
        # Convert the strings to byte arrays using UTF-8 encoding
        $referenceBytes = [System.Text.Encoding]::UTF8.GetBytes($refString)
        $differenceBytes = [System.Text.Encoding]::UTF8.GetBytes($diffString)

        # Determine the maximum length of the two byte arrays
        $maxLength = [Math]::Max($referenceBytes.Length, $differenceBytes.Length)

        # Initialize arrays to hold hex values and characters
        $refHexArray = @()
        $refCharArray = @()
        $diffHexArray = @()
        $diffCharArray = @()

        # Output the labels if NoLabels is not specified
        if (-not $NoLabels) {
            "$($ReferenceLabelAnsi)$($ReferenceLabel)$($HighlightEnd)                                                               $($DifferenceLabelAnsi)$($DifferenceLabel)$($HighlightEnd)"
            ('-' * 64) + (' ' * 8) + ('-' * 64) # Output a line of dashes under the labels
        }

        # Output the column header once with dashes underline if NoHeader is not specified
        if (-not $NoHeader) {
            "$($HeaderAnsi) Bytes                                           Ascii                   Bytes                                           Ascii $($HeaderResetAnsi)"
            "$($HeaderAnsi) -----                                           -----                   -----                                           ----- $($HeaderResetAnsi)"
        }

        # Loop through each byte in the arrays up to the maximum length
        for ($i = 0; $i -lt $maxLength; $i++) {
            # Get the byte and character for the reference string
            if ($i -lt $referenceBytes.Length) {
                $refByte = $referenceBytes[$i]
                $refHex = '{0:X2}' -f $refByte
                $refChar = [char]$refByte
            } else {
                $refHex = '  '
                $refChar = ' '
            }

            # Get the byte and character for the difference string
            if ($i -lt $differenceBytes.Length) {
                $diffByte = $differenceBytes[$i]
                $diffHex = '{0:X2}' -f $diffByte
                $diffChar = [char]$diffByte
            } else {
                $diffHex = '  '
                $diffChar = ' '
            }

            # Highlight differences
            if ($refHex -ne $diffHex) {
                $refHex = "$($HighlightStart)$refHex$($HighlightEnd)"
                $refChar = "$($HighlightStart)$refChar$($HighlightEnd)"
                $diffHex = "$($HighlightStart)$diffHex$($HighlightEnd)"
                $diffChar = "$($HighlightStart)$diffChar$($HighlightEnd)"
            }

            # Escape $HighlightStart and $HighlightEnd for regex matching
            $escapedHighlightStart = [regex]::Escape($HighlightStart)
            $escapedHighlightEnd = [regex]::Escape($HighlightEnd)

            # Replace control characters with their Unicode representations in the output
            $refChar = $refChar -replace "`0", '␀' -replace "`a", '␇' -replace "`b", '␈' -replace "`t", '␉' -replace "`f", '␌' -replace "`r", '␍' -replace "`n", '␊' -replace "(?!$($escapedHighlightStart))(?!$($escapedHighlightEnd))`e", '␛'
            $diffChar = $diffChar -replace "`0", '␀' -replace "`a", '␇' -replace "`b", '␈' -replace "`t", '␉' -replace "`f", '␌' -replace "`r", '␍' -replace "`n", '␊' -replace "(?!$($escapedHighlightStart))(?!$($escapedHighlightEnd))`e", '␛'

            # Add to arrays
            $refHexArray += $refHex
            $refCharArray += $refChar
            $diffHexArray += $diffHex
            $diffCharArray += $diffChar

            # Output the results in groups of 16
            if (($i + 1) % 16 -eq 0 -or $i -eq $maxLength - 1) {
                # Pad arrays to ensure they have 16 elements
                while ($refHexArray.Count -lt 16) { $refHexArray += '  ' }
                while ($refCharArray.Count -lt 16) { $refCharArray += ' ' }
                while ($diffHexArray.Count -lt 16) { $diffHexArray += '  ' }
                while ($diffCharArray.Count -lt 16) { $diffCharArray += ' ' }

                $refHexLine = ($refHexArray -join ' ')
                $refCharLine = ($refCharArray -join '')
                $diffHexLine = ($diffHexArray -join ' ')
                $diffCharLine = ($diffCharArray -join '')

                # Determine if the line was highlighted
                $indicator = if ($refHexLine -match $escapedHighlightStart -or $diffHexLine -match $escapedHighlightStart) { $NotEqualIndicator } else { $EqualIndicator }

                # Output the results in the specified format
                '{0} {1}   {2}   {3} {4}' -f $refHexLine, $refCharLine, $indicator, $diffHexLine, $diffCharLine

                # Clear arrays for the next group of 16
                $refHexArray = @()
                $refCharArray = @()
                $diffHexArray = @()
                $diffCharArray = @()
            }
        }
    }

    if ($ConcatenateArray) {
        # Handle null values by converting them to empty strings
        if ($null -eq $ReferenceString) {
            $ReferenceString = ''
        } else {
            $ReferenceString = $ReferenceString -join $ConcatenateChar
        }

        if ($null -eq $DifferenceString) {
            $DifferenceString = ''
        } else {
            $DifferenceString = $DifferenceString -join $ConcatenateChar
        }

        ConvertTo-DiffString -refString $ReferenceString -diffString $DifferenceString
    } else {
        for ($i = 0; $i -lt [Math]::Max($ReferenceString.Length, $DifferenceString.Length); $i++) {
            $refString = if ($i -lt $ReferenceString.Length) { $ReferenceString[$i] } else { '' }
            $diffString = if ($i -lt $DifferenceString.Length) { $DifferenceString[$i] } else { '' }
            ConvertTo-DiffString -refString $refString -diffString $diffString
        }
    }
}
