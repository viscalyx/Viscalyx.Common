<#
    .SYNOPSIS
        This output two text blocks side-by-side in hex to easily
        compare the diff.

    .DESCRIPTION
        This output two text blocks side-by-side in hex to easily
        compare the diff. It is main intended use is as a helper for unit test
        when comparing large text mass which can have small normally invisible
        difference like an extra pch missing LF.

    .PARAMETER ActualString
        A text string that should be compared against the text string that is passed
        in parameter 'Expected'.

    .PARAMETER ExpectedString
        A text string that should be compared against the text string that is passed
        in parameter 'Actual'.

    .EXAMPLE
        Out-Diff `
            -ExpectedString 'This is a longer text string that was expected to be shown' `
            -ActualString 'This is the actual text string'

    .NOTES
        This outputs the lines in verbose statements because it is the easiest way
        to show output when running tests in Pester. The output is wide, 185 characters,
        to get the best side-by-side comparison.
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
        $ActualString,

        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [AllowEmptyString()]
        [AllowNull()]
        [System.String[]]
        $ExpectedString,

        [Parameter()]
        [System.String]
        $DiffAnsiColor = '30;31m', # '30;43m' or '38;5;(255);48;5;(124)m'

        [Parameter()]
        [System.String]
        $DiffAnsiColorReset = '0m',

        [Parameter()]
        [System.String]
        $DiffIndicator = '!=',

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $RemoveNewLine,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $PassThru
    )

    if (-not $ActualString)
    {
        $ActualString = @()
    }

    if (-not $ExpectedString)
    {
        $ExpectedString = @()
    }

    $expectedHex = $ExpectedString | Format-Hex
    $actualHex = $ActualString | Format-Hex

    $maxLength = @($expectedHex.Length, $actualHex.Length) |
        Measure-Object -Maximum |
        Select-Object -ExpandProperty 'Maximum'

    # TODO: Handle if RemoveNewLine is set
    #$column1Width = ($expectedHex[0] -replace '\r?\n').Length

    $columnSeparatorWidth = 2

    if (@($expectedHex)[0])
    {
        # Width is the length of HexBytes + Ascii + 2 for the space between the columns.
        $column1Width = $expectedHex[0].HexBytes.Length + $expectedHex[0].Ascii.Length + $columnSeparatorWidth
    }
    else
    {
        $column1Width = 64
    }

    #Write-Verbose -Message ("Expected:{0}But was:" -f ''.PadRight($column1Width - 1)) -Verbose
    Write-Information -MessageData ('Expected:{0}But was:' -f ''.PadRight($column1Width - 1)) -InformationAction 'Continue'

    # Remove one since we start at 0.
    $maxLength -= 1

    $null = 0..$maxLength | ForEach-Object -Process {
        $expectedRowHex = ''
        $expectedRowAscii = ''

        $actualRowHex = ''
        $actualRowAscii = ''

        if ($RemoveNewLine)
        {
            # TODO: this must remove the new line from the HexBytes, Bytes and Ascii
            # $expectedRow = $expectedHex[$_] -replace '\r?\n'
            # $actualRow = $actualHex[$_] -replace '\r?\n'
        }
        else
        {
            if (@($expectedHex)[$_])
            {
                $expectedRowHex = $expectedHex[$_].HexBytes
                $expectedRowAscii = $expectedHex[$_].Ascii
                $expectedBytes = $expectedHex[$_].Bytes
            }

            if (@($actualHex)[$_])
            {
                $actualRowHex = $actualHex[$_].HexBytes
                $actualRowAscii = $actualHex[$_].Ascii
                $actualBytes = $actualHex[$_].Bytes
            }
        }

        ##
        # Color mark the diff in the actual row.
        ##

        if ($actualRowAscii)
        {
            $actualDiffIndex = 0..($actualBytes.Length - 1) |
                Where-Object -FilterScript {
                    $actualBytes[$_] -ne @($expectedBytes)[$_]
                }

            $actualRowHexArray = -split $actualRowHex

            $actualDiffIndex |
                ForEach-Object -Process {
                    $hexValue = $actualRowHexArray[$_]

                    $actualRowHexArray[$_] = ConvertTo-DiffString -IndexObject @{Start = 0; End = $hexValue.Length - 1 } -InputString $hexValue -DiffAnsiColor $DiffAnsiColor -DiffAnsiColorReset $DiffAnsiColorReset
                }

            $actualRow = $actualRowHexArray -join ' '

            $actualRow += ' ' * $columnSeparatorWidth

            $actualRow += $actualDiffIndex |
                Get-NumericalSequence |
                ConvertTo-DiffString -InputString $actualRowAscii -DiffAnsiColor $DiffAnsiColor -DiffAnsiColorReset $DiffAnsiColorReset
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
            $expectedDiffIndex = 0..($expectedBytes.Length - 1) |
                Where-Object -FilterScript {
                    $expectedBytes[$_] -ne @($actualBytes)[$_]
                }

            $expectedRowHexArray = -split $expectedRowHex

            $expectedDiffIndex |
                ForEach-Object -Process {
                    $hexValue = $expectedRowHexArray[$_]

                    $expectedRowHexArray[$_] = ConvertTo-DiffString -IndexObject @{Start = 0; End = $hexValue.Length - 1 } -InputString $hexValue -DiffAnsiColor $DiffAnsiColor -DiffAnsiColorReset $DiffAnsiColorReset
                }

            $expectedRow = $expectedRowHexArray -join ' '

            $expectedRow += '  '

            $expectedRow += $expectedDiffIndex |
                Get-NumericalSequence |
                ConvertTo-DiffString -InputString $expectedRowAscii -DiffAnsiColor $DiffAnsiColor -DiffAnsiColorReset $DiffAnsiColorReset
        }
        else
        {
            $expectedRow = ''
        }

        <#
            Calculate the difference in length between the expected row and calculated
            column width by removing all the ANSI escape sequences and subtracting the
            length from the column width.
        #>
        $expectedRowLengthDiff = $column1Width - ($expectedRow -replace "`e\[[0-9;]*[a-zA-Z]").Length

        $expectedRow = $expectedRow.PadRight($expectedRow.Length + $expectedRowLengthDiff)

        $outputDiffIndicator = '  '

        if ($expectedRowAscii -cne $actualRowAscii)
        {
            $outputDiffIndicator = $DiffIndicator
        }

        #Write-Verbose -Message ("{0}   {1}   {2}" -f $expectedRow, $diffIndicator, $actualRow) -Verbose
        Write-Information -MessageData ('{0}   {1}   {2}' -f $expectedRow, $outputDiffIndicator, $actualRow) -InformationAction 'Continue'
    }
}
