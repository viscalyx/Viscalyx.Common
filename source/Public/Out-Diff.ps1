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
        $hexBytesWidth = $expectedHex[0].HexBytes.Length

        # Width is the length of HexBytes + Ascii + 2 for the space between the columns.
        $column1Width = $hexBytesWidth + $expectedHex[0].Ascii.Length
    }
    else
    {
        $column1Width = 64
    }

    $headerMessage = @(
        (
            ConvertTo-DiffString -InputString 'Expected:' -IndexObject @{
                Start = 0
                End = 8
            } -DiffAnsiColor '4m' -DiffAnsiColorReset $DiffAnsiColorReset
        )
        ''.PadRight($column1Width - 1)
        (
            ConvertTo-DiffString -InputString 'But was:' -IndexObject @{
                Start = 0
                End = 6
            } -DiffAnsiColor '4m' -DiffAnsiColorReset $DiffAnsiColorReset
        )
    ) -join ''

    if ($AsVerbose.IsPresent)
    {
        Write-Verbose -Message $headerMessage -Verbose
    }
    else
    {
        Write-Information -MessageData $headerMessage -InformationAction 'Continue'
    }

    $convertToDiffStringDefaultParameters = @{
        DiffAnsiColor = $DiffAnsiColor
        DiffAnsiColorReset = $DiffAnsiColorReset
    }

    # Remove one since we start at 0.
    $maxLength -= 1

    0..$maxLength | ForEach-Object -Process {
        $expectedRowHex = ''
        $expectedRowAscii = ''

        $actualRowHex = ''
        $actualRowAscii = ''

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

        ##
        # Color mark the diff in the actual row.
        ##

        if ($actualRowAscii)
        {
            $actualRow = ConvertFrom-ByteCollection -Reference @($actualHex)[$_] -Difference @($expectedHex)[$_] -Column1Width $column1Width -ColumnSeparatorWidth $columnSeparatorWidth @convertToDiffStringDefaultParameters
            # $actualDiffIndex = 0..($actualBytes.Length - 1) |
            #     Where-Object -FilterScript {
            #         $actualBytes[$_] -ne @($expectedBytes)[$_]
            #     }

            # $actualRowHexArray = -split $actualRowHex

            # $actualDiffIndex |
            #     ForEach-Object -Process {
            #         $hexValue = $actualRowHexArray[$_]

            #         # TODO: Should not need to pass IndexObject here when entire string should be converted.
            #         $actualRowHexArray[$_] = ConvertTo-DiffString -InputString $hexValue -IndexObject @{
            #             Start = 0
            #             End = $hexValue.Length - 1
            #         } @convertToDiffStringDefaultParameters
            #     }

            # $actualRow = ($actualRowHexArray -join ' ') + (' ' * ($hexBytesWidth - $actualRowHex.Length))

            # $actualRow += ' ' * $columnSeparatorWidth

            # $actualRow += $actualDiffIndex |
            #     Get-NumericalSequence |
            #     ConvertTo-DiffString -InputString $actualRowAscii @convertToDiffStringDefaultParameters
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
            $expectedRow = ConvertFrom-ByteCollection -Reference @($expectedHex)[$_] -Difference @($actualHex)[$_] -Column1Width $column1Width -ColumnSeparatorWidth $columnSeparatorWidth @convertToDiffStringDefaultParameters

            # $expectedDiffIndex = 0..($expectedBytes.Length - 1) |
            #     Where-Object -FilterScript {
            #         $expectedBytes[$_] -ne @($actualBytes)[$_]
            #     }

            # $expectedRowHexArray = -split $expectedRowHex

            # $expectedDiffIndex |
            #     ForEach-Object -Process {
            #         $hexValue = $expectedRowHexArray[$_]

            #         $expectedRowHexArray[$_] = ConvertTo-DiffString -InputString $hexValue -IndexObject @{
            #             Start = 0
            #             End = $hexValue.Length - 1
            #         } @convertToDiffStringDefaultParameters
            #     }

            # $expectedRow = ($expectedRowHexArray -join ' ') + (' ' * ($hexBytesWidth - $expectedRowHex.Length))

            # $expectedRow += ' ' * $columnSeparatorWidth

            # $expectedRow += $expectedDiffIndex |
            #     Get-NumericalSequence |
            #     ConvertTo-DiffString -InputString $expectedRowAscii @convertToDiffStringDefaultParameters
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

        $expectedRow = $expectedRow.PadRight($expectedRow.Length + $expectedRowLengthDiff + $columnSeparatorWidth)

        $outputDiffIndicator = ' ' * $columnSeparatorWidth

        if ($expectedRowAscii -cne $actualRowAscii)
        {
            $outputDiffIndicator = $DiffIndicator
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
