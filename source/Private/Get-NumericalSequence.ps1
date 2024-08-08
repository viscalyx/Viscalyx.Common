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

            $ranges += [PSCustomObject]@{ Start = $start; End = $end }

            $start = $Number
            $end = $Number
        }
    }

    end
    {
        if ($null -eq $start)
        {
            if ($start -eq $end)
            {
                $end = $null
            }

            $ranges += [PSCustomObject]@{ Start = $start; End = $end }
        }

        $ranges
    }
}
