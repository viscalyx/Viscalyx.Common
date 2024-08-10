function Get-DiffString
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [AllowNull()]
        [Microsoft.PowerShell.Commands.ByteCollection]
        $Reference,

        [Parameter(Mandatory = $true)]
        [AllowNull()]
        [Microsoft.PowerShell.Commands.ByteCollection]
        $Difference,

        [Parameter()]
        [System.String]
        $DiffAnsiColor,

        [Parameter()]
        [System.String]
        $DiffAnsiColorReset,

        [Parameter()]
        [System.Int32]
        $Column1Width,

        [Parameter()]
        [System.Int32]
        $ColumnSeparatorWidth
    )

    $convertToDiffStringDefaultParameters = @{
        DiffAnsiColor = $DiffAnsiColor
        DiffAnsiColorReset = $DiffAnsiColorReset
    }

    $diffIndex = 0..($Reference.Bytes.Length - 1) |
        Where-Object -FilterScript {
            $Reference.Bytes[$_] -ne @($Difference.Bytes)[$_]
        }

    $rowHexArray = -split $Reference.HexBytes

    $diffIndex |
        ForEach-Object -Process {
            $hexValue = $rowHexArray[$_]

            # TODO: Should not need to pass IndexObject here when entire string should be converted.
            $rowHexArray[$_] = ConvertTo-DiffString -InputString $hexValue -IndexObject @{
                Start = 0
                End   = $hexValue.Length - 1
            } @convertToDiffStringDefaultParameters
        }

        $byteCollectionString = ($rowHexArray -join ' ') + (' ' * ($Column1Width - $Reference.HexBytes.Length))

    $byteCollectionString += ' ' * $ColumnSeparatorWidth

    $byteCollectionString += $diffIndex |
        Get-NumericalSequence |
        ConvertTo-DiffString -InputString $Reference.Ascii @convertToDiffStringDefaultParameters

    return $byteCollectionString
}
