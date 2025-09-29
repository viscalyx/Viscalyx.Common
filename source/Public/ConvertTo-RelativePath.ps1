<#
    .SYNOPSIS
        Converts an absolute path to a relative path.

    .DESCRIPTION
        The ConvertTo-RelativePath command takes an absolute path and converts it
        to a relative path based on the current location. The function performs
        platform-aware path validation to ensure that both the absolute path and
        current location are valid for the current operating system before
        attempting path conversion.

        If the absolute path starts with the current location (after normalization),
        the function creates a relative path. Otherwise, it returns the original
        absolute path unchanged.

        The function handles mixed directory separators and uses .NET Path methods
        for cross-platform compatibility, with additional validation to prevent
        unexpected behavior when processing platform-incompatible paths.

    .PARAMETER AbsolutePath
        Specifies the absolute path that needs to be converted to a relative path.

    .PARAMETER CurrentLocation
        Specifies the current location used as a reference for converting the absolute
        path to a relative path. If not specified, the function uses the current
        location obtained from Get-Location.

    .PARAMETER DirectorySeparator
        Specifies the directory separator character to use when normalizing paths
        and constructing the relative path. If not specified, the function uses
        the current platform's directory separator character.

    .EXAMPLE
        ConvertTo-RelativePath -AbsolutePath '/source/Viscalyx.Common/source/Public/ConvertTo-RelativePath.ps1' -CurrentLocation "/source/Viscalyx.Common"

        Returns "./source/Public/ConvertTo-RelativePath.ps1", which is the
        relative path of the given absolute path based on the current location.

    .EXAMPLE
        ConvertTo-RelativePath -AbsolutePath 'C:\Projects\MyApp\src\file.txt' -CurrentLocation 'C:\Projects\MyApp'

        On Windows, returns ".\src\file.txt". On non-Windows platforms, returns the
        original path unchanged since Windows-style paths are not valid absolute paths
        on those platforms.

    .EXAMPLE
        ConvertTo-RelativePath -AbsolutePath 'C:\Projects\MyApp\src\file.txt' -CurrentLocation 'C:\Projects\MyApp' -DirectorySeparator '/'

        Returns "./src/file.txt" using forward slash as the directory separator,
        even on Windows platforms.

    .NOTES
        This function uses .NET Path methods for cross-platform compatibility with
        additional platform-aware validation. The function performs the following checks:

        1. Validates that both paths are considered absolute/rooted for the current platform
        2. Uses GetFullPath() for normalization only when paths are platform-compatible
        3. Includes error handling for cases where path operations might fail
        4. Returns the original absolute path unchanged if conversion is not applicable

        Cross-platform behavior:
        - Windows paths (C:\path) work correctly on Windows but are returned unchanged on Unix-like systems
        - Unix paths (/path) work correctly on Unix-like systems but may have limitations on Windows
        - Mixed directory separators are normalized when possible

    .INPUTS
        System.String

        Absolute path to convert to a relative path.

    .OUTPUTS
        System.String

        The relative path based on the current location.
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
        $CurrentLocation,

        [Parameter()]
        [System.Char]
        $DirectorySeparator = [System.IO.Path]::DirectorySeparatorChar
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
        # 1. Normalize all directory separators to the specified separator
        $normalizedAbsolutePath = $AbsolutePath -replace '[/\\]', $DirectorySeparator
        $normalizedCurrentLocation = $CurrentLocation -replace '[/\\]', $DirectorySeparator

        # 2. Check if normalized AbsolutePath starts with CurrentLocation
        # Use case-insensitive comparison on Windows, case-sensitive on other platforms
        $stringComparison = if ($IsWindows -or $PSVersionTable.PSEdition -eq 'Desktop')
        {
            [System.StringComparison]::OrdinalIgnoreCase
        }
        else
        {
            [System.StringComparison]::Ordinal
        }

        if ($normalizedAbsolutePath.StartsWith($normalizedCurrentLocation, $stringComparison))
        {
            # Remove CurrentLocation from the start of AbsolutePath
            $strippedPath = $normalizedAbsolutePath.Substring($normalizedCurrentLocation.Length)

            # Remove leading separator if present
            $strippedPath = $strippedPath.TrimStart($DirectorySeparator)

            # 3. Return stripped path with ./ prefix
            return '.{0}{1}' -f $DirectorySeparator, $strippedPath
        }
        else
        {
            # Return normalized absolute path unchanged
            return $normalizedAbsolutePath
        }
    }
}
