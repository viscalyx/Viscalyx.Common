<#
    .SYNOPSIS
        Retrieves numerical sequences from a given set of numbers.

    .DESCRIPTION
        The Get-NumericalSequence command retrieves numerical sequences from a given
        set of numbers. It identifies consecutive numbers and groups them into ranges.

    .PARAMETER Number
        Specifies the number to be processed. This parameter is mandatory and can be
        provided via the pipeline.

    .INPUTS
        System.Int32

        Accepts integers from the pipeline for processing.

    .OUTPUTS
        System.Object[]

        An array of PSCustomObject objects representing the numerical sequences.
        Each object contains the Start and End properties, indicating the start
        and end numbers of a sequence.

    .EXAMPLE
        Get-NumericalSequence -Number 1, 2, 3, 5, 6, 7, 10

        Returns:
        Start End
        ----- ---
        1     3
        5     7
        10
#>
function Get-NumericalSequence
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [System.Int32]
        $Number
    )

    begin
    {
        $ranges = @()
        $start = $null
        $end = $null
    }

    process
    {
        if ($null -eq $start)
        {
            $start = $Number
            $end = $Number
        }
        elseif ($Number -eq $end + 1)
        {
            $end = $Number
        }
        else
        {
            if ($start -eq $end)
            {
                $end = $null
            }

            $ranges += [PSCustomObject] @{
                Start = $start
                End   = $end
            }

            $start = $Number
            $end = $Number
        }
    }

    end
    {
        if ($null -ne $start)
        {
            if ($start -eq $end)
            {
                $end = $null
            }

            $ranges += [PSCustomObject] @{
                Start = $start
                End   = $end
            }
        }

        $ranges
    }
}
