function Split-StringAtIndex
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [PSCustomObject]
        $IndexObject,

        [Parameter(Mandatory = $true)]
        [string]
        $InputString
    )

    begin
    {
        $result = @()
        $previousIndex = 0
    }

    process
    {
        $start = $IndexObject.Start
        $end = $IndexObject.End

        if ($null -eq $end)
        {
            $end = $start
        }

        if ($start -gt $previousIndex)
        {
            $result += $InputString.Substring($previousIndex, $start - $previousIndex)
        }

        $result += ($InputString.Substring($start, $end - $start + 1) + '(!)')
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
