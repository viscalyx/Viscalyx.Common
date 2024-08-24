function ConvertTo-AnsiSequence
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true, Position = 0)]
        [AllowEmptyString()]
        [AllowNull()]
        [System.String]
        $Value
    )

    if ($Value)
    {
        if ($Value -match "^(?:`e)?\[?([0-9;]+)m?$")
        {
            $Value = "`e[" + $Matches[1] + 'm'
        }
    }

    return $Value
}
