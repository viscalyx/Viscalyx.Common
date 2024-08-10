<#
    .SYNOPSIS
        Converts a specified portion of a string to a diff string with ANSI color
        codes.

    .DESCRIPTION
        The ConvertTo-DiffString function converts a specified portion of a string
        to a diff string with ANSI color codes. It can be used to highlight differences
        in text or display changes in a visually appealing way.

    .PARAMETER IndexObject
        Specifies the input object containing the start and end indices of the
        portion to convert. This parameter is mandatory when using pipeline input.

    .PARAMETER InputString
        Specifies the input string to convert. This parameter is mandatory when
        using start and end indices or when only the input string is provided.

    .PARAMETER StartIndex
        Specifies the start index of the portion to convert. This parameter is
        mandatory when using start and end indices.

    .PARAMETER EndIndex
        Specifies the end index of the portion to convert. This parameter is
        optional when using start and end indices. If not provided, only one
        character will be converted specified by the start index.

    .PARAMETER Ansi
        Specifies the ANSI color code to apply to the converted portion. The
        default value is '30;43m', which represents black text on a yellow
        background.

    .PARAMETER AnsiReset
        Specifies the ANSI color code to reset the color after the converted portion.
        The default value is '0m', which resets the color to the default.

    .EXAMPLE
        PS> ConvertTo-DiffString -InputString "Hello, world!" -StartIndex 7 -EndIndex 11

        Converts the portion of the input string from index 7 to index 11 to a diff
        string with the default ANSI color codes.

    .EXAMPLE
        PS> @{Start = 7; End = 11 }  | ConvertTo-DiffString -InputString "Hello, world!"

        Converts the portion of the input string from index 7 to index 11, provided
        through pipeline input, to a diff string with the default ANSI color codes.

    .NOTES
        This function uses ANSI escape sequences to apply color codes to the converted
        portion of the string. The resulting diff string can be displayed in a console
        or terminal that supports ANSI color codes.
#>
function ConvertTo-DiffString
{
    [CmdletBinding()]
    param
    (
        [Parameter(ParameterSetName = 'PipelineInput', Mandatory = $true, ValueFromPipeline = $true)]
        [PSCustomObject]
        $IndexObject,

        [Parameter(ParameterSetName = 'StartEndInput', Mandatory = $true)]
        [Parameter(ParameterSetName = 'PipelineInput', Mandatory = $true)]
        [Parameter(ParameterSetName = 'InputStringOnly', Mandatory = $true)]
        [System.String]
        $InputString,

        [Parameter(ParameterSetName = 'StartEndInput', Mandatory = $true)]
        [ValidateScript({ $_ -lt $InputString.Length })]
        [System.UInt32]
        $StartIndex,

        [Parameter(ParameterSetName = 'StartEndInput')]
        [ValidateScript({ $_ -lt $InputString.Length })]
        [Nullable[System.UInt32]]
        $EndIndex,

        [Parameter()]
        [System.String]
        $Ansi = '30;43m',

        [Parameter()]
        [System.String]
        $AnsiReset = '0m'
    )

    begin
    {
        $result = @()
        $previousIndex = 0

        $ansiSequence = "`e[$Ansi"
        $resetSequence = "`e[$AnsiReset"
    }

    process
    {
        switch ($PSCmdlet.ParameterSetName)
        {
            'InputStringOnly'
            {
                $start = 0
                $end = $InputString.Length - 1
            }

            'PipelineInput'
            {
                $start = $IndexObject.Start
                $end = $IndexObject.End
            }

            'StartEndInput'
            {
                $start = $StartIndex
                $end = $EndIndex
            }
        }

        if ($null -eq $end)
        {
            $end = $start
        }

        if ($start -gt $previousIndex)
        {
            $result += $InputString.Substring($previousIndex, $start - $previousIndex)
        }

        $result += ($ansiSequence + $InputString.Substring($start, $end - $start + 1) + $resetSequence)

        $previousIndex = $end + 1
    }

    end
    {
        if ($previousIndex -lt $InputString.Length)
        {
            $result += $InputString.Substring($previousIndex)
        }

        $result -join ''
    }
}
