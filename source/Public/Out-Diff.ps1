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
        $AsVerbose,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $NoHeader,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $PassThru
    )

    $outDiffResult = $null

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

    $columnSeparatorWidth = 2

    if (@($expectedHex)[0])
    {
        $expectedColumn1Width = $expectedHex[0].HexBytes.Length
        $expectedColumn2Width = $expectedHex[0].Ascii.Length
    }
    else
    {
        $expectedColumn1Width = 47
        $expectedColumn2Width = 16
    }

    if (@($actualHex)[0])
    {
        $actualColumn1Width = $actualHex[0].HexBytes.Length
        #$actualColumn2Width = $actualHex[0].Ascii.Length
    }
    else
    {
        $actualColumn1Width = 47
        #$actualColumn2Width = 16
    }

    if (-not $NoHeader)
    {
        # TODO: The labels should be able to be specified, and have the option to choose the coloring.
        $headerMessage = @(
            (
                ConvertTo-DiffString -InputString 'Expected:' -IndexObject @{
                    Start = 0
                    End   = 8
                } -DiffAnsiColor '4m' -DiffAnsiColorReset $DiffAnsiColorReset
            )
            ''.PadRight(($expectedColumn1Width + $expectedColumn2Width) - 1)
            (
                ConvertTo-DiffString -InputString 'But was:' -IndexObject @{
                    Start = 0
                    End   = 6
                } -DiffAnsiColor '4m' -DiffAnsiColorReset $DiffAnsiColorReset
            )
        ) -join ''
    }

    if ($AsVerbose.IsPresent)
    {
        Write-Verbose -Message $headerMessage -Verbose
    }
    else
    {
        Write-Information -MessageData $headerMessage -InformationAction 'Continue'
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
                Reference = @($actualHex)[$index]
                Difference = @($expectedHex)[$index]
                Column1Width = $actualColumn1Width
                ColumnSeparatorWidth = $columnSeparatorWidth
                DiffAnsiColor      = $DiffAnsiColor
                DiffAnsiColorReset = $DiffAnsiColorReset
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
                Reference = @($expectedHex)[$index]
                Difference = @($actualHex)[$index]
                Column1Width = $expectedColumn1Width
                ColumnSeparatorWidth = $columnSeparatorWidth
                DiffAnsiColor      = $DiffAnsiColor
                DiffAnsiColorReset = $DiffAnsiColorReset
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

        if ($AsVerbose.IsPresent)
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
