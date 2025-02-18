# Changelog for Viscalyx.Common

The format is based on and uses the types of changes according to [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- `Install-ModulePatch` that can be used to patch PowerShell modules prior
  to being released.

### Changed

- `ConvertTo-DifferenceString`
  - Improve how control characters (ASCII values 0-31 and 127) are converted
    to their corresponding Unicode representations in the Control Pictures
    block to output printable versions.
  - Optimize code and improve performance.
  - Added parameter `NoHexOutput`.
- `Out-Difference`
  - Added parameter `NoHexOutput`.

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
