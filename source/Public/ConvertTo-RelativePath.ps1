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
        ConvertTo-RelativePath -AbsolutePath '/source/Viscalyx.Common/source/Public/ConvertTo-RelativePath.ps1' -CurrentLocation "/source/Viscalyx.Common"

        Returns "./source/Public/ConvertTo-RelativePath.ps1", which is the
        relative path of the given absolute path based on the current location.

    .INPUTS
        System.String

        Absolute path to convert to a relative path.

    .OUTPUTS
        System.String

        The relative path based on the current location.

    .NOTES
        This function uses .NET Path methods for cross-platform compatibility.
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
        if (-not $PSBoundParameters.ContainsKey('CurrentLocation') -or [System.String]::IsNullOrWhiteSpace($CurrentLocation))
        {
            $CurrentLocation = (Get-Location).Path
        }
    }

    process
    {
        $relativePath = $AbsolutePath

        if ($relativePath.StartsWith($CurrentLocation))
        {
            # Convert the directory separator characters to the current system's directory separator character.
            $normalizedAbsolutePath = [System.IO.Path]::GetFullPath($AbsolutePath)
            $normalizedCurrentLocation = [System.IO.Path]::GetFullPath($CurrentLocation)

            $relativePath = [System.IO.Path]::GetRelativePath($normalizedCurrentLocation, $normalizedAbsolutePath).Insert(0, '.{0}' -f [System.IO.Path]::DirectorySeparatorChar)
        }

        return $relativePath
    }
}
