<#
    .SYNOPSIS
        Converts an absolute path to a relative path.

    .DESCRIPTION
        The ConvertTo-RelativePath command takes an absolute path and converts it
        to a relative path based on the current location. If the absolute path
        starts with the current location, the function removes the current location
        from the beginning of the path and inserts a '.' to indicate the relative path.

    .PARAMETER AbsolutePath
        Specifies the absolute path that needs to be converted to a relative path.

    .PARAMETER CurrentLocation
        Specifies the current location used as a reference for converting the absolute
        path to a relative path. If not specified, the function uses the current
        location obtained from Get-Location.

    .EXAMPLE
        $convertToRelativePathParameters = @{
            AbsolutePath = '/source/Viscalyx.Common/source/Public/ConvertTo-RelativePath.ps1'
            CurrentLocation = "/source/Viscalyx.Common"
        }
        ConvertTo-RelativePath @convertToRelativePathParameters

        Returns "./source/Public/ConvertTo-RelativePath.ps1", which is the
        relative path of the given absolute path based on the current location.

    .INPUTS
        [System.String]

    .OUTPUTS
        [System.String]
#>
function ConvertTo-RelativePath
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
        [System.String]
        $AbsolutePath,

        [Parameter(Position = 1)]
        [System.String]
        $CurrentLocation
    )

    begin
    {
        if (-not $PSBoundParameters.ContainsKey('CurrentLocation'))
        {
            $CurrentLocation = (Get-Location).Path
        }
    }

    process
    {
        $relativePath = $AbsolutePath

        if ($relativePath.StartsWith($CurrentLocation))
        {
            $relativePath = $relativePath.Substring($CurrentLocation.Length).Insert(0, '.')
        }

        return $relativePath
    }
}
