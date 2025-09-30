---
Category: General
---

# Testing PowerShell Modules with Invoke-PesterJob: A Beginner's Guide

Testing is essential when developing PowerShell modules, especially those
containing DSC resources. However, running tests in your development session
can cause session pollution, where classes and assemblies remain loaded and
interfere with your workflow. The `Invoke-PesterJob` command solves this by
running Pester tests in an isolated PowerShell job.

## What is Invoke-PesterJob?

`Invoke-PesterJob` is a command that runs _Pester_ tests in a separate
PowerShell job, providing these key benefits:

1. **Session isolation** - Tests run separately, preventing class and assembly
   pollution in your main session
1. **Clean environment** - Each test run starts with a fresh PowerShell session
1. **Reliable results** - Eliminates conflicts from previously loaded modules
   or assemblies

## When to Use Invoke-PesterJob

Use `Invoke-PesterJob` when testing:

- PowerShell modules with classes
- DSC resources (both class-based and MOF-based)
- Code that loads assemblies
- Any project requiring test isolation

This is particularly beneficial when using projects based on _Sampler_-based
templates, for example the ones in _DSC Community_. The command recognizes a
_Sampler_ project (best effort) and automatically uses the defaults for your
project.

## Basic Usage

### Running all unit tests

```powershell
Invoke-PesterJob -Path './tests/Unit'
```

`Invoke-PesterJob` enables code coverage by default, providing immediate
visibility into test effectiveness and code quality metrics. This design
decision ensures that development teams maintain awareness of their testing
coverage without requiring explicit configuration, promoting a culture of
comprehensive testing. Default code coverage collection facilitates continuous
quality assessment and helps identify untested code paths that may represent
potential risk areas in production deployments.

### Running a Single Test File

```powershell
Invoke-PesterJob -Path './tests/Unit/Public/Get-Something.Tests.ps1'
```

> [!TIP]
> When testing individual files, you may see coverage results for code that
> isn't directly tested by that file. For cleaner output during focused
> testing, use **SkipCodeCoverage** or leverage **EnableSourceLineMapping**
> with **FilterCodeCoverageResult** (covered later) to target specific
> functions.

```powershell
# Skip code coverage for simpler output
Invoke-PesterJob -Path './tests/Unit/Public/Get-Something.Tests.ps1' -SkipCodeCoverage
```

### Running Tests with Tab Completion

<!-- markdownlint-disable MD033 -->
The **Path** parameter supports <kbd>tab</kbd> completion to help you find test files
quickly:
<!-- markdownlint-enable MD033 -->

```powershell
# Type partial name and press Tab
Invoke-PesterJob -Path ./tests/Unit/Public/Get-Som<TAB>
# Results in: Invoke-PesterJob -Path ./tests/Unit/Public/Get-Something.Tests.ps1
```

or

```powershell
# Type partial name and press Tab
Invoke-PesterJob -Path Some<TAB>
# Results in: Invoke-PesterJob -Path ./tests/Unit/Public/Get-Something.Tests.ps1
# (or cycles through multiple matches like ./tests/Unit/Privet/Assert-Something.Tests.ps1)
```

This tab completion works by searching for test files (*.Tests.ps1) that match
your partial input, making it much faster to locate and run specific tests
without typing the full path.

> [!NOTE]
> Tab completion only filters through unit tests in the `tests/Unit` folder.
> For tests in other folders like `tests/Integration` or `tests/QA`, you must
> specify the full path manually enough so PowerShell can uniquely identify
> it before using tab completion:
>
> ```powershell
> Invoke-PesterJob -Path ./tests/Integration/MyIntegration*<TAB>
> Invoke-PesterJob -Path ./tests/QA
> ```

### Running Multiple Test Files

You can use tab completion to build a command with multiple test files:

```powershell
# Type each file name with tab completion, separated by commas
Invoke-PesterJob -Path Some<TAB>, SomeOther<TAB>
# Results in two files being selected:
# ./tests/Unit/Public/Get-Something.Tests.ps1, ./tests/Unit/Private/Assert-SomeOther.Tests.ps1
```

Alternatively, use the hashtable approach for better readability:

```powershell
$testParams = @{
    Path = @(
        './tests/Unit/Public/Get-Something.Tests.ps1'
        './tests/Unit/Private/Assert-Something.Tests.ps1'
    )
}

Invoke-PesterJob @testParams
```

## Code Coverage

Code coverage shows which parts of your code are tested and which are not.

By default, `Invoke-PesterJob` automatically includes the module's root script
files for code coverage. The **CodeCoveragePath** parameter is used when you
need to point to specific `.psm1` or `.ps1` files that are not included by
default, such as when testing MOF-based DSC resources or specific module
components. When you specify **CodeCoveragePath**, it overrides the default
coverage files entirely.

### Basic Code Coverage

<!-- markdownlint-disable MD013 -->
```powershell
Invoke-PesterJob -Path './tests/Unit/Public/Get-Something.Tests.ps1' -CodeCoveragePath './source/Public/Get-Something.ps1'
```
<!-- markdownlint-enable MD013 -->

### Code Coverage with Tab Completion

The **CodeCoveragePath** parameter also supports tab completion for built
module files. It searches for `.ps1` and `.psm1` files in the
`./output/builtModule` directory:

<!-- markdownlint-disable MD013 -->
```powershell
# Tab completion for coverage files
Invoke-PesterJob -Path './tests/Unit' -CodeCoveragePath ./output/builtModule/<TAB>
# Results in available .ps1 and .psm1 files from the built module
```
<!-- markdownlint-enable MD013 -->

### Advanced Code Coverage with Source Line Mapping

The **EnableSourceLineMapping** parameter maps coverage results back to your
source files, making it easier to identify uncovered code:

<!-- markdownlint-disable MD013 -->
```powershell
$missedLines = Invoke-PesterJob -Path './tests/Unit' -EnableSourceLineMapping
$missedLines | Format-Table -Property SourceFile,SourceLineNumber,Command
```
<!-- markdownlint-enable MD013 -->

This automatically enables **PassThru** (overriding the default behavior) as
it's required to generate the source line mapping data. Note that _Pester_
will still output all missed commands during test execution, as there's no way
to selectively disable this output - you can suppress all output by using
`-Output 'None'` or use `-Output 'Minimal'` to suppress detailed coverage
output while still showing high-level test results.

### Filtering Coverage Results

Use **FilterCodeCoverageResult** with wildcard patterns to focus on specific
functions or classes:

```powershell
# Filter for specific function patterns
$testParams = @{
    Path = './tests/Unit'
    EnableSourceLineMapping = $true
    FilterCodeCoverageResult = @('Get-*', 'Set-*', 'Test-*')
}

Invoke-PesterJob @testParams
```

## Controlling Test Execution

### Test Discovery Without Execution

Use **SkipRun** to discover which tests would run without executing them:

```powershell
$testParams = @{
    Path = './tests/Unit'
    SkipRun = $true
    PassThru = $true
    SkipCodeCoverage = $true
}

$discovery = Invoke-PesterJob @testParams

# Show discovered test names
$discovery.Tests
$discovery.Tests.Count
```

### Running Tests by Tag

Filter tests using the **Tag** parameter:

<!-- markdownlint-disable MD013 -->
```powershell
# Run only unit tests
Invoke-PesterJob -Path './tests' -Tag 'Unit'
```
<!-- markdownlint-enable MD013 -->

### Output Verbosity Control

Control the amount of output using the **Output** parameter:

```powershell
# Detailed output for debugging
Invoke-PesterJob -Path './tests/Unit' -Output 'Detailed'

# Minimal output for CI/CD
Invoke-PesterJob -Path './tests/Unit' -Output 'Minimal'
```

Valid values are: `Normal`, `Detailed`, `None`, `Diagnostic`, and `Minimal`.

## Debugging and Troubleshooting

### Displaying Detailed Error Information

When tests fail, use **ShowError** to get detailed stack error information:

```powershell
$testParams = @{
    Path = './tests/Unit/Public/Get-Something.Tests.ps1'
    SkipCodeCoverage = $true
    ShowError = $true
}

Invoke-PesterJob @testParams
```

> **Note**: Run as few tests as possible when using **ShowError** to limit
> the amount of error output.

### Custom Build Scripts

For projects with custom build configurations, specify a different build
script:

```powershell
$testParams = @{
    Path = './tests/Unit'
    BuildScriptPath = './custom-build.ps1'
    BuildScriptParameter = @{
        Task = 'test-setup'
        Configuration = 'Debug'
    }
}

Invoke-PesterJob @testParams
```

The build script ensures the test environment is properly configured with
required modules and dependencies.

## Testing Different Resource Types

### MOF-Based DSC Resources

MOF-based DSC resources require explicit **CodeCoveragePath** specification
since their `.psm1` files are located in nested DSCResources folders:
<!-- markdownlint-disable MD013 -->
```powershell
$testParams = @{
    Path             = './tests/Unit/DSC_SqlProtocol.Tests.ps1'
    CodeCoveragePath = './output/builtModule/SqlServerDsc/**/DSCResources/DSC_SqlProtocol/DSC_SqlProtocol.psm1'
}

Invoke-PesterJob @testParams
```
<!-- markdownlint-enable MD013 -->

> [!WARNING]
> **EnableSourceLineMapping** is not supported for MOF-based DSC resources
> that weren't built using _ModuleBuilder_. If you include this parameter,
> you'll see a warning like:
>
> ```text
> WARNING: No SourceMap for C:\source\SqlServerDsc\output\builtModule\
> SqlServerDsc\17.2.0\DSCResources\DSC_SqlProtocol\DSC_SqlProtocol.psm1
> ```
>
> This is because in the above example the MOF-based resource don't contain
> the source mapping files that _ModuleBuilder_ creates.

### Class-Based DSC Resources

Class-based resources benefit especially from job isolation since PowerShell
classes cannot be unloaded:

<!-- markdownlint-disable MD013 -->
```powershell
$testParams = @{
    Path = './tests/Unit/Classes/SqlServerDscException.Tests.ps1'
    CodeCoveragePath = './output/builtModule/SqlServerDsc/Classes/001.SqlServerDscException.ps1'
    EnableSourceLineMapping = $true
}

Invoke-PesterJob @testParams
```
<!-- markdownlint-enable MD013 -->

### Public Functions

<!-- markdownlint-disable MD013 -->
```powershell
Invoke-PesterJob -Path './tests/Unit/Public' -CodeCoveragePath './source/Public' -Output 'Detailed'
```
<!-- markdownlint-enable MD013 -->

## Complete Examples

### Comprehensive Module Testing

```powershell
# Test entire module with coverage and source mapping
$testParams = @{
    Path = @(
        './tests/Unit/Public'
        './tests/Unit/Private'
        './tests/Unit/Classes'
    )
    EnableSourceLineMapping = $true
    Output = 'Detailed'
    Tag = 'Unit'
}

$result = Invoke-PesterJob @testParams

# Display coverage summary
Write-Host "Code Coverage: $($result.CodeCoverage.CoveragePercent)%"
```

### CI/CD Pipeline Testing

<!-- markdownlint-disable MD013 -->
```powershell
# Optimized for automated environments
$testParams = @{
    Path = './tests/Unit'
    Output = 'Normal'
    SkipCodeCoverage = $false
    PassThru = $true
}

$result = Invoke-PesterJob @testParams

if ($result.FailedCount -gt 0) {
    throw "Tests failed: $($result.FailedCount) failed out of $($result.TotalCount)"
}
```
<!-- markdownlint-enable MD013 -->

### Development Workflow

```powershell
# Quick test during development
$testParams = @{
    Path = './tests/Unit/Public/Get-Something.Tests.ps1'
    Output = 'Detailed'
    ShowError = $true
    SkipCodeCoverage = $true
}

Invoke-PesterJob @testParams
```

## Best Practices

1. **Use job isolation**: Always prefer `Invoke-PesterJob` over direct
   `Invoke-Pester` for module testing
1. **Enable source mapping**: Use **EnableSourceLineMapping** for better
   coverage reporting in development
1. **Filter coverage results**: Use **FilterCodeCoverageResult** to focus on
   specific functions during debugging
1. **Leverage tab completion**: Use tab completion for **Path** and
   **CodeCoveragePath** parameters
1. **Control output**: Use appropriate **Output** levels for different
   scenarios (development vs. CI/CD)
1. **Custom build scripts**: Specify **BuildScriptPath** and
   **BuildScriptParameter** for projects with custom setup requirements

### Test File Structure

>[!NOTE]
>This assumes your project is using _Sampler_-based templates and you are
>following its best practices for test file structure. If not, adapt as
>needed.

Every unit test file should start with this standard setup block:

<!-- markdownlint-disable MD013 -->
```powershell
BeforeDiscovery {
    try
    {
        <#
            Change to any unique module only used by the project, a module
            not likely to be installed by users on dev machines.
        #>
        if (-not (Get-Module -Name 'DscResource.Test'))
        {
            # Assumes dependencies have been resolved
            if (-not (Get-Module -Name 'DscResource.Test' -ListAvailable))
            {
                # Redirect all streams to $null, except the error stream
                & "$PSScriptRoot/../../../build.ps1" -Tasks 'noop' `
                    3>&1 4>&1 5>&1 6>&1 > $null
            }

            Import-Module -Name 'DscResource.Test' -Force -ErrorAction 'Stop'
        }
    }
    catch [System.IO.FileNotFoundException]
    {
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -ResolveDependency -Tasks noop" first.'
    }
}

BeforeAll {
    # Replace with your module name
    Import-Module -Name 'YourModuleName' -Force -ErrorAction 'Stop'
}
```
<!-- markdownlint-enable MD013 -->

This setup block serves as a self-contained environment initialization system
that automatically loads required project dependencies into the testing
session. By incorporating dependency resolution directly within the test file,
the testing environment becomes ready for execution without requiring manual
intervention or preliminary commands. This design pattern is particularly
beneficial for automated testing scenarios and AI agents, as it enables them
to execute `Invoke-PesterJob` commands directly without needing to understand
or execute project-specific setup procedures beforehand.

## Summary

`Invoke-PesterJob` is essential for reliable PowerShell module testing. It
provides session isolation, comprehensive code coverage with source mapping,
and flexible test execution options. By running tests in isolated jobs, you
avoid session pollution and ensure consistent, reliable test results.

For developers working with DSC resources, PowerShell classes, or any complex
modules, `Invoke-PesterJob` should be your primary testing tool. It integrates
seamlessly with _Sampler_-based projects and follows DSC community best
practices.
