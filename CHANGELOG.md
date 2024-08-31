# Changelog for Viscalyx.Common

The format is based on and uses the types of changes according to [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Viscalyx.Common
  - Added unit tests to run in Windows PowerShell.
- Public commands:
  - `Update-GitBranch`

### Fixed

- `ConvertTo-DifferenceString`
  - Make it render ANSI sequences in Windows PowerShell
  - Optimize using List\<T\> instead of using `+=` for adding to arrays.

## [0.2.0] - 2024-08-25

### Added

- Public commands:
  - `ConvertTo-AnsiSequence`
  - `ConvertTo-DifferenceString`
  - `Get-GitTag`
  - `Get-NumericalSequence`
  - `Get-PSReadLineHistory`
  - `New-GitTag`
  - `New-SamplerGitHubReleaseTag`
  - `Out-Difference`
  - `Pop-VMLatestSnapShot`
  - `Push-GitTag`
  - `Remove-History`
  - `Remove-PSHistory`
  - `Remove-PSReadLineHistory`
  - `Request-GitTag`
  - `Split-StringAtIndices`
  - `Switch-GitLocalBranch`
  - `Test-GitLocalChanges`
  - `Test-GitRemote`
  - `Test-GitRemoteBranch`
  - `Update-GitLocalBranch`
  - `Update-RemoteTrackingBranch`
