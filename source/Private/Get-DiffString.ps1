<#
    .SYNOPSIS
        Returns the difference between two byte collections as a formatted string.

    .DESCRIPTION
        The Get-DiffString function takes two byte collections, a reference byte
        collection and a difference byte collection, and returns the difference
        between them as a formatted string. The formatted string represents the
        differences between the two byte collections in a human-readable format.

    .PARAMETER Reference
        Specifies the reference byte collection. This parameter is mandatory.

    .PARAMETER Difference
        Specifies the difference byte collection. This parameter is mandatory.

    .PARAMETER Ansi
        Specifies the ANSI color code to apply to the differences in the formatted
        string.

    .PARAMETER AnsiReset
        Specifies the ANSI color code to reset the color in the formatted string.

    .PARAMETER Column1Width
        Specifies the width of the first column in the formatted string.

    .PARAMETER ColumnSeparatorWidth
        Specifies the width of the separator between the columns in the formatted
        string.

    .OUTPUTS
        System.String

        The formatted string representing the differences between the reference
        and difference byte collections.

    .EXAMPLE
        $reference = [Microsoft.PowerShell.Commands.ByteCollection]::new()
        $difference = [Microsoft.PowerShell.Commands.ByteCollection]::new()
        $diffString = Get-DiffString -Reference $reference -Difference $difference

        Returns a formatted string representing the differences between the reference
        and difference byte collections.
#>
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
        $Ansi,

        [Parameter()]
        [System.String]
        $AnsiReset,

        [Parameter()]
        [System.Int32]
        $Column1Width,

        [Parameter()]
        [System.Int32]
        $ColumnSeparatorWidth
    )

    $convertToDiffStringDefaultParameters = @{
        Ansi      = $Ansi
        AnsiReset = $AnsiReset
    }

    $diffIndex = 0..($Reference.Bytes.Length - 1) |
        Where-Object -FilterScript {
            $Reference.Bytes[$_] -ne @($Difference.Bytes)[$_]
        }

    $rowHexArray = -split $Reference.HexBytes

    $diffIndex |
        ForEach-Object -Process {
            $hexValue = $rowHexArray[$_]

            $rowHexArray[$_] = ConvertTo-DiffString -InputString $hexValue @convertToDiffStringDefaultParameters
        }

    $byteCollectionString = ($rowHexArray -join ' ') + (' ' * ($Column1Width - $Reference.HexBytes.Length))

    $byteCollectionString += ' ' * $ColumnSeparatorWidth

    $byteCollectionString += $diffIndex |
        Get-NumericalSequence |
        ConvertTo-DiffString -InputString $Reference.Ascii @convertToDiffStringDefaultParameters

    return $byteCollectionString
}
