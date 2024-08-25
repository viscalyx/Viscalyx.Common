<#
    .SYNOPSIS
        Compares two sets of strings and converts them into a difference string.

    .DESCRIPTION
        The Out-Difference function compares two sets of strings, Reference and
        Difference, and converts them into a difference string. It provides options
        to customize the indicators, labels, and formatting of the output.

    .PARAMETER Reference
        Specifies the reference set of strings to compare.

    .PARAMETER Difference
        Specifies the difference set of strings to compare.

    .PARAMETER EqualIndicator
        Specifies the indicator to use for equal strings.

    .PARAMETER NotEqualIndicator
        Specifies the indicator to use for unequal strings.

    .PARAMETER HighlightStart
        Specifies the starting indicator for highlighting differences.

    .PARAMETER HighlightEnd
        Specifies the ending indicator for highlighting differences.

    .PARAMETER ReferenceLabel
        Specifies the label for the reference set.

    .PARAMETER DifferenceLabel
        Specifies the label for the difference set.

    .PARAMETER NoColumnHeader
        Indicates whether to exclude the column header from the output.

    .PARAMETER NoLabels
        Indicates whether to exclude the labels from the output.

    .PARAMETER ReferenceLabelAnsi
        Specifies the ANSI escape sequence for the reference label.

    .PARAMETER DifferenceLabelAnsi
        Specifies the ANSI escape sequence for the difference label.

    .PARAMETER ColumnHeaderAnsi
        Specifies the ANSI escape sequence for the column header.

    .PARAMETER ColumnHeaderResetAnsi
        Specifies the ANSI escape sequence to reset the column header formatting.

    .PARAMETER EncodingType
        Specifies the encoding type to use for converting the strings to byte arrays.

    .PARAMETER ConcatenateArray
        Indicates whether to concatenate the arrays of strings into a single string.

    .PARAMETER ConcatenateChar
        Specifies the character used to concatenate the strings. Default is a new line character.

    .EXAMPLE
        $reference = "apple", "banana", "cherry"
        $difference = "apple", "orange", "cherry"
        Out-Difference -Reference $reference -Difference $difference -EqualIndicator '' -ReferenceLabel 'Reference:' -DifferenceLabel 'Difference:' -ConcatenateArray -ConcatenateChar ''

    .INPUTS
        None. You cannot pipe input to this function.

    .OUTPUTS
        System.String. The difference string representing the comparison between
        the reference and difference sets.

    .NOTES
        This command is using the default parameters values from the ConvertTo-DifferenceString
        command.
#>
function Out-Difference
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [AllowNull()]
        [AllowEmptyCollection()]
        [System.String[]]
        $Reference,

        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [AllowNull()]
        [AllowEmptyCollection()]
        [System.String[]]
        $Difference,

        [Parameter()]
        [ValidateLength(0, 2)]
        [System.String]
        $EqualIndicator,

        [Parameter()]
        [ValidateLength(0, 2)]
        [System.String]
        $NotEqualIndicator,

        [Parameter()]
        [System.String]
        $HighlightStart,

        [Parameter()]
        [System.String]
        $HighlightEnd,

        [Parameter()]
        [System.String]
        $ReferenceLabel,

        [Parameter()]
        [System.String]
        $DifferenceLabel,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $NoColumnHeader,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $NoLabels,

        [Parameter()]
        [System.String]
        $ReferenceLabelAnsi,

        [Parameter()]
        [System.String]
        $DifferenceLabelAnsi,

        [Parameter()]
        [System.String]
        $ColumnHeaderAnsi,

        [Parameter()]
        [System.String]
        $ColumnHeaderResetAnsi,

        [Parameter()]
        [ValidateSet('ASCII', 'BigEndianUnicode', 'Default', 'Unicode', 'UTF32', 'UTF7', 'UTF8')]
        [System.String]
        $EncodingType,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $ConcatenateArray,

        [Parameter()]
        [System.String]
        $ConcatenateChar = [System.Environment]::NewLine
    )

    if ($null -eq $ConcatenateChar)
    {
        $ConcatenateChar = ''
    }

    $behaviorParameters = @{} + $PSBoundParameters
    $behaviorParameters.Remove('Reference')
    $behaviorParameters.Remove('Difference')
    $behaviorParameters.Remove('ConcatenateArray')
    $behaviorParameters.Remove('ConcatenateChar')

    if ($ConcatenateArray.IsPresent)
    {
        # Handle null values by converting them to empty strings
        if ($null -eq $Reference)
        {
            $refString = ''
        }
        else
        {
            $refString = $Reference -join $ConcatenateChar
        }

        if ($null -eq $Difference)
        {
            $diffString = ''
        }
        else
        {
            $diffString = $Difference -join $ConcatenateChar
        }

        ConvertTo-DifferenceString -ReferenceString $refString -DifferenceString $diffString @behaviorParameters
    }
    else
    {
        for ($i = 0; $i -lt [Math]::Max($Reference.Length, $Difference.Length); $i++)
        {
            $refString = if ($i -lt $Reference.Length)
            {
                $Reference[$i]
            }
            else
            {
                ''
            }

            $diffString = if ($i -lt $Difference.Length)
            {
                $Difference[$i]
            }
            else
            {
                ''
            }

            ConvertTo-DifferenceString -ReferenceString $refString -DifferenceString $diffString @behaviorParameters
        }
    }
}
