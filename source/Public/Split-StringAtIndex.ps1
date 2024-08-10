<#
    .SYNOPSIS
        Splits a string at a specified index or range of indices.

    .DESCRIPTION
        The Split-StringAtIndex function splits a given string at a specified index
        or range of indices. It can be used to extract substrings from a larger
        string based on the provided indices.

    .PARAMETER IndexObject
        Specifies the index object to split the string. This parameter is used
        when providing input via the pipeline.

    .PARAMETER InputString
        Specifies the input string to be split.

    .PARAMETER StartIndex
        Specifies the starting index of the substring to be extracted. The value
        must be less than the length of the input string.

    .PARAMETER EndIndex
        Specifies the ending index of the substring to be extracted. The value
        must be less than the length of the input string.

    .EXAMPLE
        PS> Split-StringAtIndex -InputString "Hello, World!" -StartIndex 0 -EndIndex 4

        This example splits the input string "Hello, World!" at the index specified
        by StartIndex and then at the index specified by EndIndex and returns the
        resulting array of substrings.

    .EXAMPLE
        PS> @(@{Start = 0; End = 2}, @{Start = 7; End = 11 }) | Split-StringAtIndex -InputString "Hello, world!"

        This example splits the input string "Hello, World!" at the indices provided
        by the pipeline. It will split the string at each StartIndex and EndIndex
        and returns the resulting array of substrings.

    .EXAMPLE
        PS> @(0, 1, 2, 7, 8, 9, 10, 11) | Get-NumericalSequence | Split-StringAtIndex -InputString "Hello, world!"

        This example splits the input string "Hello, World!" at the indices provided
        by the pipeline. It will split the string at each StartIndex and EndIndex
        and returns the resulting array of substrings.

    .OUTPUTS
        System.String[]

        An array of substrings extracted from the input string.

    .NOTES
        The Split-StringAtIndex function is designed to split strings based on indices
        and can be used in various scenarios where string manipulation is required.
        To get the indices the function Get-NumericalSequence can be used.
#>
function Split-StringAtIndex
{
    [CmdletBinding()]
    param
    (
        [Parameter(ParameterSetName = 'PipelineInput', Mandatory = $true, ValueFromPipeline = $true)]
        [PSCustomObject]
        $IndexObject,

        [Parameter(ParameterSetName = 'StartEndInput', Mandatory = $true)]
        [Parameter(ParameterSetName = 'PipelineInput', Mandatory = $true)]
        [System.String]
        $InputString,

        [Parameter(ParameterSetName = 'StartEndInput', Mandatory = $true)]
        [ValidateScript({ $_ -lt $InputString.Length })]
        [System.UInt32]
        $StartIndex,

        [Parameter(ParameterSetName = 'StartEndInput', Mandatory = $true)]
        [ValidateScript({ $_ -lt $InputString.Length })]
        [System.UInt32]
        $EndIndex
    )

    begin
    {
        $result = @()
        $previousIndex = 0
    }

    process
    {
        switch ($PSCmdlet.ParameterSetName)
        {
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

        $result += $InputString.Substring($start, $end - $start + 1)

        $previousIndex = $end + 1
    }

    end
    {
        if ($previousIndex -lt $InputString.Length)
        {
            $result += $InputString.Substring($previousIndex)
        }

        $result
    }
}
