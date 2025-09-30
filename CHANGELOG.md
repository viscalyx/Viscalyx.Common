# Changelog for Viscalyx.Common

The format is based on and uses the types of changes according to [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Viscalyx.Common
  - Added unit tests to run in Windows PowerShell.
- Public commands:
  - `Assert-GitLocalChange`
  - `Assert-GitRemote`
  - `Disable-CursorShortcutCode`
  - `Get-GitBranchCommit`
  - `Get-GitLocalBranchName`
  - `Get-GitRemote`
  - `Get-GitRemoteBranch`
  - `Get-GitTag`
  - `Invoke-Git`
  - `New-GitTag`
  - `Push-GitTag`
  - `Receive-GitBranch` ([#5](https://github.com/viscalyx/Viscalyx.Common/issues/5))
  - `Remove-GitTag` ([#16](https://github.com/viscalyx/Viscalyx.Common/issues/16))
  - `Rename-GitLocalBranch` ([#10](https://github.com/viscalyx/Viscalyx.Common/issues/10))
  - `Rename-GitRemote` ([#11](https://github.com/viscalyx/Viscalyx.Common/issues/11))
  - `Request-GitTag`
  - `Resume-GitRebase` ([#14](https://github.com/viscalyx/Viscalyx.Common/issues/14))
  - `Start-GitRebase` ([#13](https://github.com/viscalyx/Viscalyx.Common/issues/13))
  - `Stop-GitRebase` ([#15](https://github.com/viscalyx/Viscalyx.Common/issues/15))
  - `Switch-GitLocalBranch`
  - `Test-GitLocalChanges`
  - `Test-GitRemote`
  - `Test-GitRemoteBranch`
  - `Update-GitLocalBranch`
  - `Update-RemoteTrackingBranch`
- Documentation:
  - `Testing-PowerShell-Modules.md` - Comprehensive beginner's guide for
    testing PowerShell modules with `Invoke-PesterJob`, covering session
    isolation, code coverage, source line mapping, and best practices for
    different resource types including MOF-based and class-based DSC resources.

### Changed

- `Invoke-PesterJob` - Updated documentation example to use `-TestNameFilter`
  parameter instead of the `-TestName` alias and removed reference to alias
  usage for consistency and clarity.
- `New-SamplerGitHubReleaseTag` - Major architectural rewrite with the following
  key improvements:
  - Complete implementation refactor replacing ~200 lines of raw Git commands
    with dedicated PowerShell helper functions for improved reliability.
  - Enhanced error handling using proper try-catch blocks instead of manual
    `$LASTEXITCODE` checking, with automatic cleanup on failures.
  - Improved WhatIf support with intelligent handling that skips complex logic
    during WhatIf operations.
  - Renamed `SwitchBackToPreviousBranch` parameter to `ReturnToCurrentBranch`
    for better clarity.
  - Updated documentation sections.
- `ConvertTo-RelativePath` - Simplified function logic to consistently normalize
  directory separators using `[System.IO.Path]::DirectorySeparatorChar` and
  removed complex cross-platform path handling.
- `Receive-GitBranch` - Refactored to use multiple ShouldProcess blocks instead
  of a single combined block ([#50](https://github.com/viscalyx/Viscalyx.Common/issues/50)).
  - Each operation (checkout, fetch, rebase, pull) now has its own ShouldProcess
    block for better WhatIf support and granular confirmation prompts.
  - Removed Write-Verbose calls from inside ShouldProcess blocks to comply with
    coding guidelines.
  - Write-Verbose messages are now placed outside ShouldProcess blocks to provide
    detailed progress feedback during execution.
  - Added parameter sets to enforce that `BranchName` can only be specified when
    `-Checkout` is used, preventing invalid parameter combinations.

### Fixed

- `Push-GitTag` now properly handles the no-op case when trying to push all
  tags but no local tags exist, treating it as a successful operation instead
  of throwing an error.

## [0.6.0] - 2025-09-25

### Added

- `Assert-IPv4Address` that validates if a string is a valid IPv4 address,
  including format checking and value range validation (0-255 for each octet).
  Also validates that octets do not have leading zeros.
- `Clear-AnsiSequence` that clears all ANSI escape sequences from a string,
  returning only the visible text content. Useful for calculating the actual
  visible length of strings that contain ANSI formatting codes or extracting
  plain text from formatted console output.
- `ConvertTo-AnsiString` that converts strings containing ANSI
  sequences to properly escaped and terminated ANSI sequences. It adds the
  necessary escape character and ensures all sequences end with 'm'. Handles
  both escaped and unescaped sequences, as well as sequences that may be
  missing the 'm' terminator.
- `Get-ClassAst` that parses PowerShell script files and extracts class
  definitions using Abstract Syntax Tree (AST) parsing. Can return all classes
  in a file or filter for a specific class by name.
- `Get-ClassResourceAst` that parses PowerShell script files and extracts DSC
  class resource definitions using Abstract Syntax Tree (AST) parsing. Filters
  for classes that have the [DscResource()] attribute. Can return all DSC class
  resources in a file or filter for a specific class by name.
- `Invoke-PesterJob` now supports filtering tests by name using the new
  `TestNameFilter` parameter (with aliases `TestName` and `Test`). This feature
  enables AI agents and automation scenarios to focus on specific tests by
  providing test name patterns with wildcard support.

### Fixed

- `Out-Difference` now correctly aligns labels with column
  structure when using custom labels ([issue #7](https://github.com/viscalyx/Viscalyx.Common/issues/7))
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
  for all user-facing messages following DSC community guidelines.
- Removed unused localized strings for `Get-ClassResourceAst` command that were
  inherited from `Get-ClassAst` but not actually used in the implementation.
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
