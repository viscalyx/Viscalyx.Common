<#
    .SYNOPSIS
        Compares two sets of strings and highlights the differences in hexadecimal
        output.

    .DESCRIPTION
        The Out-Diff command compares two sets of strings, $Difference and $Reference.
        Outputs the result using hexadecimal output and highlights the differences
        between the two sets of strings in a side-by-side format, making it easier
        to spot discrepancies at a byte level.

        Its main intended use is in unit tests when comparing large text masses that
        can have small, normally invisible differences, such as an extra or missing
        line feed or new line character.

        The command supports ANSI escape sequences for coloring the differences
        between the actual and expected strings. The default color for differences
        is red. The command defaults to outputting the result as informational
        messages, but it also supports displaying the differences using the
        Write-Verbose cmdlet or returning the result as output.

    .PARAMETER Difference
        Specifies the set of strings to compare against the reference strings.
        This parameter is mandatory.

    .PARAMETER Reference
        Specifies the set of reference strings to compare against the difference
        strings. This parameter is mandatory.

    .PARAMETER DifferenceAnsi
        Specifies the ANSI escape sequence for controlling how the difference is
        highlighted. The default value is '30;31m' (red).

    .PARAMETER AnsiReset
        Specifies the ANSI escape sequence to reset the formatting. The
        default value is '0m'.

    .PARAMETER DiffIndicator
        Specifies the indicator to display for differences between the difference
        and reference strings. The default value is '!='.

    .PARAMETER AsVerbose
        Switch parameter. If specified, the differences are displayed using the
        Write-Verbose cmdlet.

    .PARAMETER NoHeader
        Switch parameter. If specified, the header message is not displayed.

    .PARAMETER ReferenceLabel
        Specifies the label for the reference strings. The default value is
        'Expected:'. The label should be no longer than 65 characters.

    .PARAMETER DifferenceLabel
        Specifies the label for the difference strings. The default value is
        'But was:'. The label should be no longer than 65 characters.

    .PARAMETER ReferenceLabelAnsi
        Specifies the ANSI escape sequence for controlling the look of the reference
        label. The default value is '4m' (underline).

    .PARAMETER DifferenceLabelAnsi
        Specifies the ANSI escape sequence for controlling the look of the difference
        label. The default value is '4m' (underline).

    .PARAMETER PassThru
        Switch parameter. If specified, the output is returned as an array of strings.

    .OUTPUTS
        If the PassThru parameter is specified, the function returns an array of
        strings representing the differences between the actual and expected strings.

    .EXAMPLE
        $actual = "Hello", "World"
        $expected = "Hello", "Universe"
        Out-Diff -Difference $actual -Reference $expected

        This example compares the actual strings "Hello" and "World" with the expected
        strings "Hello" and "Universe". The function displays the differences between
        the two sets of strings.
#>
function Out-Diff
{
    # cSpell: ignore isnot
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [AllowEmptyString()]
        [AllowNull()]
        [System.String[]]
        $Difference,

        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [AllowEmptyString()]
        [AllowNull()]
        [System.String[]]
        $Reference,

        [Parameter()]
        [System.String]
        $DifferenceAnsi = '30;31m', # '30;43m' or '38;5;(255);48;5;(124)m'

        [Parameter()]
        [System.String]
        $AnsiReset = '0m',

        [Parameter()]
        [System.String]
        $DiffIndicator = '!=',

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $AsVerbose,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $NoHeader,

        [Parameter()]
        [ValidateScript({ $_.Length -le 65 })]
        [System.String]
        $ReferenceLabel = 'Expected:',

        [Parameter()]
        [ValidateScript({ $_.Length -le 65 })]
        [System.String]
        $DifferenceLabel = 'But was:',

        [Parameter()]
        [System.String]
        $ReferenceLabelAnsi = '4m',

        [Parameter()]
        [System.String]
        $DifferenceLabelAnsi = '4m',

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $PassThru
    )

    if ($PassThru.IsPresent)
    {
        $outDiffResult = @()
    }
    else
    {
        $outDiffResult = $null
    }

    if (-not $Difference)
    {
        $Difference = @()
    }

    if (-not $Reference)
    {
        $Reference = @()
    }

    # Using ForEach-Object to convert numerical values to string.
    $expectedHex = $Reference | ForEach-Object -Process { $_.ToString() } | Format-Hex
    $actualHex = $Difference | ForEach-Object -Process { $_.ToString() } | Format-Hex

    $maxLength = @($expectedHex.Length, $actualHex.Length) |
        Measure-Object -Maximum |
        Select-Object -ExpandProperty 'Maximum'

    $columnSeparatorWidth = 2

    if ($expectedHex)
    {
        $expectedColumn1Width = (
            $expectedHex.HexBytes |
                ForEach-Object -Process {
                    $_.Length
                } |
                Measure-Object -Maximum
        ).Maximum

        $expectedColumn2Width = (
            $expectedHex.Ascii |
                ForEach-Object -Process {
                    $_.Length
                } |
                Measure-Object -Maximum
        ).Maximum
    }
    else
    {
        $expectedColumn1Width = 47
        $expectedColumn2Width = 16
    }

    if (@($actualHex)[0])
    {
        $actualColumn1Width = (
            $actualHex.HexBytes |
                ForEach-Object -Process {
                    $_.Length
                } |
                Measure-Object -Maximum
        ).Maximum
    }
    else
    {
        $actualColumn1Width = 47
    }

    if (-not $NoHeader.IsPresent)
    {
        $headerMessage = @(
            (ConvertTo-DiffString -InputString $ReferenceLabel -Ansi $ReferenceLabelAnsi -AnsiReset $AnsiReset)
            ''.PadRight((($expectedColumn1Width + $expectedColumn2Width - $ReferenceLabel.Length) + ($columnSeparatorWidth * 3) + $DiffIndicator.Length))
            (ConvertTo-DiffString -InputString $DifferenceLabel -Ansi $DifferenceLabelAnsi -AnsiReset $AnsiReset)
        ) -join ''

        if ($PassThru.IsPresent)
        {
            $outDiffResult += $headerMessage
        }
        elseif ($AsVerbose.IsPresent)
        {
            Write-Verbose -Message $headerMessage -Verbose
        }
        else
        {
            Write-Information -MessageData $headerMessage -InformationAction 'Continue'
        }
    }

    # Remove one since we start at 0.
    $maxLength -= 1

    foreach ($index in 0..$maxLength)
    {
        $expectedRowAscii = ''
        $actualRowAscii = ''

        if (@($expectedHex)[$index])
        {
            $expectedRowAscii = $expectedHex[$index].Ascii
        }

        if (@($actualHex)[$index])
        {
            $actualRowAscii = $actualHex[$index].Ascii
        }

        ##
        # Color mark the diff in the actual row.
        ##

        if ($actualRowAscii)
        {
            $getDiffStringParameters = @{
                Reference            = @($actualHex)[$index]
                Difference           = @($expectedHex)[$index]
                Column1Width         = $actualColumn1Width
                ColumnSeparatorWidth = $columnSeparatorWidth
                Ansi                 = $DifferenceAnsi
                AnsiReset            = $AnsiReset
            }

            $actualRow = Get-DiffString @getDiffStringParameters
        }
        else
        {
            $actualRow = ''
        }

        ##
        # Color mark the diff in the expected row.
        ##

        if ($expectedRowAscii)
        {
            $getDiffStringParameters = @{
                Reference            = @($expectedHex)[$index]
                Difference           = @($actualHex)[$index]
                Column1Width         = $expectedColumn1Width
                ColumnSeparatorWidth = $columnSeparatorWidth
                Ansi                 = $DifferenceAnsi
                AnsiReset            = $AnsiReset
            }

            $expectedRow = Get-DiffString @getDiffStringParameters
        }
        else
        {
            $expectedRow = ''
        }

        <#
            Calculate the difference in length between the expected row and calculated
            column width by removing all the ANSI escape sequences and subtracting the
            length from the column widths.
        #>
        $expectedRowLengthDiff = ($expectedColumn1Width + $expectedColumn2Width) - ($expectedRow -replace "`e\[[0-9;]*[a-zA-Z]").Length

        $expectedRow = $expectedRow.PadRight($expectedRow.Length + $expectedRowLengthDiff + $columnSeparatorWidth)

        if ($expectedRowAscii -cne $actualRowAscii)
        {
            $outputDiffIndicator = $DiffIndicator
        }
        else
        {
            $outputDiffIndicator = ' ' * $DiffIndicator.Length
        }

        $diffRowMessage = @(
            $expectedRow
            (' ' * $columnSeparatorWidth)
            $outputDiffIndicator
            (' ' * $columnSeparatorWidth)
            $actualRow
        ) -join ''

        if ($PassThru.IsPresent)
        {
            $outDiffResult += $diffRowMessage
        }
        elseif ($AsVerbose.IsPresent)
        {
            Write-Verbose -Message $diffRowMessage -Verbose
        }
        else
        {
            Write-Information -MessageData $diffRowMessage -InformationAction 'Continue'
        }
    }

    return $outDiffResult
}
