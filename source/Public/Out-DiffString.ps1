function Out-DiffString
{
    param (
        [string]$referenceString,
        [string]$differenceString,
        [string]$equalIndicator = '==',
        [string]$notEqualIndicator = '!=',
        [string]$highlightAnsi = "`e[31m",  # Default to red color
        [string]$highlightEndAnsi = "`e[0m",     # Default to reset color
        [string]$ReferenceLabel = 'Expected:',
        [string]$DifferenceLabel = 'But was:',
        [switch]$NoHeader,
        [switch]$NoLabels,
        [string]$ReferenceLabelAnsi = '',
        [string]$DifferenceLabelAnsi = '',
        [string]$HeaderAnsi = ''
    )

    # Convert the strings to byte arrays using UTF-8 encoding
    $referenceBytes = [System.Text.Encoding]::UTF8.GetBytes($referenceString)
    $differenceBytes = [System.Text.Encoding]::UTF8.GetBytes($differenceString)

    # Determine the maximum length of the two byte arrays
    $maxLength = [Math]::Max($referenceBytes.Length, $differenceBytes.Length)

    # Initialize arrays to hold hex values and characters
    $refHexArray = @()
    $refCharArray = @()
    $diffHexArray = @()
    $diffCharArray = @()

    # Output the labels if NoLabels is not specified
    if (-not $NoLabels) {
        "$($ReferenceLabelAnsi)$($ReferenceLabel)$($highlightEndAnsi)                                                               $($DifferenceLabelAnsi)$($DifferenceLabel)$($highlightEndAnsi)"
        ("-" * 64) + (" " * 8) + ("-" * 64) # Output a line of dashes under the labels
    }

    # Output the column header once with dashes underline if NoHeader is not specified
    if (-not $NoHeader) {
        "$($HeaderAnsi)Bytes                                           Ascii                   Bytes                                           Ascii$($highlightEndAnsi)"
        "$($HeaderAnsi)-----                                           -----                   -----                                           -----$($highlightEndAnsi)"
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
            $refHex = "$highlightAnsi$refHex$highlightEndAnsi"
            $refChar = "$highlightAnsi$refChar$highlightEndAnsi"
            $diffHex = "$highlightAnsi$diffHex$highlightEndAnsi"
            $diffChar = "$highlightAnsi$diffChar$highlightEndAnsi"
        }

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

            # Escape $highlightAnsi for regex matching
            $escapedHighlightAnsi = [regex]::Escape($highlightAnsi)

            # Determine if the line was highlighted
            $indicator = if ($refHexLine -match $escapedHighlightAnsi -or $diffHexLine -match $escapedHighlightAnsi) { $notEqualIndicator } else { $equalIndicator }

            # Output the results in the specified format
            "{0} {1}   {2}   {3} {4}" -f $refHexLine, $refCharLine, $indicator, $diffHexLine, $diffCharLine

            # Clear arrays for the next group of 16
            $refHexArray = @()
            $refCharArray = @()
            $diffHexArray = @()
            $diffCharArray = @()
        }
    }
}
