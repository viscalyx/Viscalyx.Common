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

    .EXAMPLE
        ConvertTo-RelativePath -AbsolutePath '/source/Viscalyx.Common/source/Public/ConvertTo-RelativePath.ps1' -CurrentLocation "/source/Viscalyx.Common"

        Returns "./source/Public/ConvertTo-RelativePath.ps1", which is the
        relative path of the given absolute path based on the current location.

    .EXAMPLE
        ConvertTo-RelativePath -AbsolutePath 'C:\Projects\MyApp\src\file.txt' -CurrentLocation 'C:\Projects\MyApp'

        On Windows, returns ".\src\file.txt". On non-Windows platforms, returns the
        original path unchanged since Windows-style paths are not valid absolute paths
        on those platforms.

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

        # Check if both paths are absolute and valid for the current platform
        $isAbsolutePathValid = [System.IO.Path]::IsPathRooted($AbsolutePath)
        $isCurrentLocationValid = [System.IO.Path]::IsPathRooted($CurrentLocation)

        # Additional checks for cross-platform scenarios
        $isWindowsStylePath = $AbsolutePath -match '^[A-Za-z]:\\' -or $AbsolutePath.StartsWith('\\')
        $isUncPath = $AbsolutePath.StartsWith('\\') -or $AbsolutePath.StartsWith('//')

        # On non-Windows platforms, don't process Windows-style paths or UNC paths with backslashes
        if (-not $IsWindows -and (($isWindowsStylePath -and -not $isUncPath) -or ($isUncPath -and $AbsolutePath.StartsWith('\\'))))
        {
            return $relativePath
        }

        # On Windows platforms, don't process Unix-style paths unless they have string matching
        # (this preserves the existing behavior where Unix-style paths can work on Windows if they match as strings)

        # Determine if we should attempt path processing based on platform validation or basic string matching
        $shouldProcessPaths = ($isAbsolutePathValid -and $isCurrentLocationValid) -or $relativePath.StartsWith($CurrentLocation)

        if ($shouldProcessPaths)
        {
            try
            {
                # For cross-platform compatibility, handle cases where paths use different separators
                # but are logically equivalent (e.g., Unix-style paths on Windows)
                if ($isAbsolutePathValid -and $isCurrentLocationValid)
                {
                    # Both paths are platform-valid, use standard normalization
                    $normalizedAbsolutePath = [System.IO.Path]::GetFullPath($AbsolutePath)
                    $normalizedCurrentLocation = [System.IO.Path]::GetFullPath($CurrentLocation)
                }
                elseif ($relativePath.StartsWith($CurrentLocation))
                {
                    # Handle mixed platform scenarios where paths match as strings but aren't platform-valid
                    # Only do this if the string-based comparison already shows they match
                    $normalizedAbsolutePath = $AbsolutePath.Replace('/', [System.IO.Path]::DirectorySeparatorChar).Replace('\', [System.IO.Path]::DirectorySeparatorChar)
                    $normalizedCurrentLocation = $CurrentLocation.Replace('/', [System.IO.Path]::DirectorySeparatorChar).Replace('\', [System.IO.Path]::DirectorySeparatorChar)
                }
                else
                {
                    # If we shouldn't process, skip to avoid unwanted conversions
                    return $relativePath
                }

                # Use normalized paths for comparison to handle mixed separators correctly
                if ($normalizedAbsolutePath.StartsWith($normalizedCurrentLocation, [System.StringComparison]::OrdinalIgnoreCase))
                {
                    $relativePath = [System.IO.Path]::GetRelativePath($normalizedCurrentLocation, $normalizedAbsolutePath).Insert(0, '.{0}' -f [System.IO.Path]::DirectorySeparatorChar)
                }
            }
            catch
            {
                # If path processing fails, return original path unchanged
                Write-Debug -Message "Path processing failed: $($_.Exception.Message)"
            }
        }

        return $relativePath
    }
}
