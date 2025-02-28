# Changelog for Viscalyx.Common

The format is based on and uses the types of changes according to [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixed

- Improved handling escape character in tests.
- Fix build configuration due to changes in DscResource.DocGenerator.

## [0.4.1] - 2025-02-27

### Changed

- Run unit tests on Windows PowerShell.
- Run integration tests.
- `Install-ModulePatch`
  - Tested using integration test.

### Fixed

- Fix documentation naming in GitHub repository Wiki.
- `Install-ModulePatch`
  - Fix a private command that used command parameters that is not available
    in Windows PowerShell.
  - Fixed progress counter text.

## [0.4.0] - 2025-02-26

### Added

- `Install-ModulePatch` that can be used to patch PowerShell modules prior
  to being released.
- `Get-ModuleFileSha` that outputs the SHA256 for each PowerShell script
   file in a specific PowerShell module.
- `Get-TextOffset` that returns the start and end offset of the specified
  text from within the specified file.
- `Test-FileHash` that returns whether a file has the expected hash.
- `Get-ModuleByVersion` that returns an installed module with the specific
  version.

### Changed

- `ConvertTo-DifferenceString`
  - Improve how control characters (ASCII values 0-31 and 127) are converted
    to their corresponding Unicode representations in the Control Pictures
    block to output printable versions.
  - Optimize code and improve performance.
  - Added parameter `NoHexOutput`.
- `Out-Difference`
  - Added parameter `NoHexOutput`.

### Fixed

- `ConvertTo-DifferenceString`
  - Make it render ANSI sequences in Windows PowerShell
  - Optimize using List\<T\> instead of using `+=` for adding to arrays.

## [0.3.0] - 2024-09-02

### Added

- Public commands:
  - `Invoke-PesterJob`
  - `Get-ModuleVersion`
  - `ConvertTo-RelativePath`

## [0.2.0] - 2024-08-25

### Added

- Public commands:
  - `ConvertTo-AnsiSequence`
  - `ConvertTo-DifferenceString`
  - `Get-NumericalSequence`
  - `Get-PSReadLineHistory`
  - `Invoke-PesterJob`
  - `New-SamplerGitHubReleaseTag`
  - `Out-Difference`
  - `Pop-VMLatestSnapShot`
  - `Remove-History`
  - `Remove-PSHistory`
  - `Remove-PSReadLineHistory`
  - `Split-StringAtIndices`
