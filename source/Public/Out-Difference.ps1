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
        [System.String]
        $EqualIndicator,

        [Parameter()]
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
