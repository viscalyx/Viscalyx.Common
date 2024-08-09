function ConvertTo-DiffString
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [PSCustomObject]
        $IndexObject,

        [Parameter(Mandatory = $true)]
        [System.String]
        $InputString,

        [Parameter()]
        [System.String]
        $DiffAnsiColor = '30;43m',

        [Parameter()]
        [System.String]
        $DiffAnsiColorReset = '0m'
    )

    begin
    {
        $result = @()
        $previousIndex = 0

        $ansiSequence = "`e[$DiffAnsiColor"
        $resetSequence = "`e[$DiffAnsiColorReset"
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
