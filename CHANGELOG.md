# Changelog for Viscalyx.Common

The format is based on and uses the types of changes according to [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- `Get-ClassAst` that parses PowerShell script files and extracts class
  definitions using Abstract Syntax Tree (AST) parsing. Can return all classes
  in a file or filter for a specific class by name.
- `ConvertTo-AnsiString` that converts strings containing ANSI
  sequences to properly escaped and terminated ANSI sequences. It adds the
  necessary escape character and ensures all sequences end with 'm'. Handles
  both escaped and unescaped sequences, as well as sequences that may be
  missing the 'm' terminator.
- `Assert-IPv4Address` that validates if a string is a valid IPv4 address,
  including format checking and value range validation (0-255 for each octet).
  Also validates that octets do not have leading zeros.

### Fixed

- `Out-Difference` now correctly aligns labels with column structure when using custom labels ([issue #7](https://github.com/viscalyx/Viscalyx.Common/issues/7))
- `Test-IPv4Address` that tests if a string is a valid IPv4 address and returns
  a boolean result. Performs the same validation as `Assert-IPv4Address` but
  returns `$true` for valid addresses and `$false` for invalid ones instead
  of throwing exceptions. Now supports pipeline input for processing multiple
  IP addresses.

### Changed

- `New-SamplerGitHubReleaseTag` - The git push operation is now properly wrapped
  in a ShouldProcess check, allowing WhatIf to report what would be pushed
  without actually executing the push command.
- `Get-LinkLayerAddress` (alias `Get-MacAddress`) that retrieves the MAC
  address for an IP address on the local subnet/VLAN. Works cross-platform
  across Windows, Linux, and macOS.
- `Resolve-DnsName` that resolves a DNS host name to a single IPv4 address
  using the cross-platform .NET System.Net.Dns class, providing compatibility
  when the built-in Resolve-DnsName cmdlet is not available.
- `Send-WakeOnLan` (alias `Send-WOL`) that sends a Wake-on-LAN magic packet
  to wake up a remote computer. Supports various MAC address formats and
  custom broadcast addresses and ports.
- Aligned ShouldProcess localized string key naming with DSC community convention
  by renaming `*_ShouldProcessVerboseDescription` and `*_ShouldProcessVerboseWarning`
  keys to `*_ShouldProcessDescription` and `*_ShouldProcessConfirmation` respectively.
  This affects string keys in `New-SamplerGitHubReleaseTag`, `Install-ModulePatch`,
  and `Send-WakeOnLan` commands.
- `Remove-PSHistory` and `Remove-PSReadLineHistory` now use localized strings
  instead of hardcoded strings for ShouldProcess prompts and status messages.
- Added proper string IDs to all localized strings following the pattern
  `(XXXNNNNN)` where XXX is a 3-4 letter abbreviation and NNNNN is a 4-digit
  number. This provides consistent identification and tracking of all
  localized messages across the module.

## [0.5.0] - 2025-09-14

### Added

- `Invoke-PesterJob`
  - Added new switch parameter `EnableSourceLineMapping` to map code coverage
    lines from built module files back to their corresponding source files
    using ModuleBuilder's Convert-LineNumber command. When enabled, this
    parameter automatically enables PassThru and requires ModuleBuilder
    module unless running in a Sampler project environment.
  - Added new parameter `FilterCodeCoverageResult` to filter code coverage results
    by function or class name when using EnableSourceLineMapping. Supports
    wildcard patterns and accepts arrays of filter patterns for flexible
    filtering of missed coverage lines.

### Fixed

- Improved handling escape character in tests.
- Fix build configuration due to changes in DscResource.DocGenerator.
- Fix error stream redirection in all test files to preserve error stream
  visibility ([issue #32](https://github.com/viscalyx/Viscalyx.Common/issues/32)).
- Fixed stream redirection in integration tests.
- Improved test code quality and accuracy.

### Changed

- Editor: Update VS Code settings to set default terminal
  profiles and enable Copilot instruction files.
- Tooling: Add task arguments and improve `test` and `build`
  task configuration for reproducible runs.
- Bump actions/checkout from 4 to 5
- Bump actions/stale from 9 to 10

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
  - `Pop-VMLatestSnapshot`
  - `Remove-History`
  - `Remove-PSHistory`
  - `Remove-PSReadLineHistory`
  - `Split-StringAtIndices`
