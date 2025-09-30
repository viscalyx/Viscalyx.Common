[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification = 'Suppressing this rule because Script Analyzer does not understand Pester syntax.')]
param ()

BeforeDiscovery {
    try
    {
        if (-not (Get-Module -Name 'DscResource.Test'))
        {
            # Assumes dependencies have been resolved, so if this module is not available, run 'noop' task.
            if (-not (Get-Module -Name 'DscResource.Test' -ListAvailable))
            {
                # Redirect all streams to $null, except the error stream (stream 2)
                & "$PSScriptRoot/../../../build.ps1" -Tasks 'noop' 3>&1 4>&1 5>&1 6>&1 > $null
            }

            # If the dependencies have not been resolved, this will throw an error.
            Import-Module -Name 'DscResource.Test' -Force -ErrorAction 'Stop'
        }
    }
    catch [System.IO.FileNotFoundException]
    {
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -ResolveDependency -Tasks noop" first.'
    }
}

BeforeAll {
    $script:moduleName = 'Viscalyx.Common'

    Import-Module -Name $script:moduleName -Force -ErrorAction 'Stop'
    Import-Module -Name 'ModuleBuilder'

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:moduleName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:moduleName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:moduleName
}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    # Unload the module being tested so that it doesn't impact any other tests.
    Get-Module -Name $script:moduleName -All | Remove-Module -Force
}

Describe 'Invoke-PesterJob' {
    Context 'When checking command structure' {
        It 'Should have the correct parameters in parameter set <ExpectedParameterSetName>' -ForEach @(
            @{
                ExpectedParameterSetName = '__AllParameterSets'
                ExpectedParameters       = '[[-Path] <string[]>] [[-CodeCoveragePath] <string[]>] [-RootPath <string>] [-Tag <string[]>] [-TestNameFilter <string[]>] [-ModuleName <string>] [-Output <string>] [-SkipCodeCoverage] [-PassThru] [-EnableSourceLineMapping] [-FilterCodeCoverageResult <string[]>] [-ShowError] [-SkipRun] [-BuildScriptPath <string>] [-BuildScriptParameter <hashtable>] [<CommonParameters>]'
            }
        ) {
            $result = (Get-Command -Name 'Invoke-PesterJob').ParameterSets |
                Where-Object -FilterScript { $_.Name -eq $ExpectedParameterSetName } |
                Select-Object -Property @(
                    @{ Name = 'ParameterSetName'; Expression = { $_.Name } },
                    @{ Name = 'ParameterListAsString'; Expression = { $_.ToString() } }
                )
            $result.ParameterSetName | Should -Be $ExpectedParameterSetName
            $result.ParameterListAsString | Should -Be $ExpectedParameters
        }

        It 'Should have no mandatory parameters' {
            $mandatoryParams = (Get-Command -Name 'Invoke-PesterJob').Parameters.Values | Where-Object { $_.Attributes.Mandatory -eq $true }
            $mandatoryParams | Should -BeNullOrEmpty
        }
    }

    # Mock external dependencies
    BeforeAll {
        New-Item -Path $TestDrive -ItemType Directory -Name 'MockPath' | Out-Null

        $mockJob = Start-Job -Name 'Test_MockJob_InvokePesterJob' -ScriptBlock {
            Start-Sleep -Seconds 300
        }

        Mock -CommandName Write-Information
        Mock -CommandName Start-Job -MockWith { return $mockJob }
        Mock -CommandName Receive-Job
        Mock -CommandName Get-Location -MockWith { return @{ Path = Join-Path -Path $TestDrive -ChildPath 'MockPath' } }
        Mock -CommandName Test-Path -MockWith { return $true }
        Mock -CommandName Join-Path -MockWith { param ($Path, $ChildPath) return "$Path\$ChildPath" }
        Mock -CommandName Get-ChildItem -MockWith { return @() }
    }

    AfterAll {
        if ($mockJob)
        {
            $mockJob | Stop-Job
            $mockJob | Remove-Job
        }
    }

    Context 'When passing invalid parameter values' {
        BeforeAll {
            Mock -CommandName Get-Module
        }

        It 'Should throw error if BuildScriptPath does not exist' {
            Mock -CommandName Test-Path -MockWith { return $false }

            $params = @{
                BuildScriptPath = Join-Path -Path $TestDrive -ChildPath 'InvalidPath/build.ps1'
            }

            { Invoke-PesterJob @params } | Should -Throw -ErrorId 'ParameterArgumentValidationError,Invoke-PesterJob'
        }

        It 'Should handle empty Path parameter gracefully' {
            $params = @{
                Path = ''
            }

            { Invoke-PesterJob @params } | Should -Throw -ErrorId 'ParameterArgumentValidationError,Invoke-PesterJob'
        }

        It 'Should handle null Path parameter gracefully' {
            $params = @{
                Path = $null
            }

            { Invoke-PesterJob @params } | Should -Throw -ErrorId 'ParameterArgumentValidationError,Invoke-PesterJob'
        }

        It 'Should handle invalid Output verbosity value' {
            $params = @{
                Path   = Join-Path -Path $TestDrive -ChildPath 'MockPath/tests'
                Output = 'InvalidVerbosity'
            }

            { Invoke-PesterJob @params } | Should -Throw -ErrorId 'ParameterArgumentValidationError,Invoke-PesterJob'
        }

        It 'Should handle invalid combination of parameters' {
            $params = @{
                Path             = Join-Path -Path $TestDrive -ChildPath 'MockPath/tests'
                SkipCodeCoverage = $true
                Output           = 'InvalidVerbosity'
            }

            { Invoke-PesterJob @params } | Should -Throw -ErrorId 'ParameterArgumentValidationError,Invoke-PesterJob'
        }

        It 'Should throw localized error when Pester import fails and build script not found' {
            # Create a valid build script file first to pass parameter validation
            $buildScriptPath = Join-Path -Path $TestDrive -ChildPath 'build.ps1'
            $null = New-Item -Path $buildScriptPath -ItemType File -Force

            # Mock Import-Module to always throw an error
            Mock -CommandName Import-Module -ParameterFilter { $Name -eq 'Pester' } -MockWith {
                throw 'Mocked Pester import failure'
            }

            # Mock Test-Path with dual semantics: returns true for parameter validation (Leaf check)
            # but false for internal build script existence check (default Test-Path behavior)
            Mock -CommandName Test-Path -MockWith {
                param($Path, $PathType)
                if ($PathType -eq 'Leaf')
                {
                    return $true  # For parameter validation
                }
                else
                {
                    return $false  # For internal check (Test-Path -Path $BuildScriptPath)
                }
            }

            $params = @{
                Path            = Join-Path -Path $TestDrive -ChildPath 'MockPath/tests'
                BuildScriptPath = $buildScriptPath
            }

            { Invoke-PesterJob @params } | Should -Throw -ErrorId 'IPJ0005,Invoke-PesterJob'
        }
    }

    Context 'When using Pester v4' {
        BeforeAll {
            Mock -CommandName Get-Module # Mocked with nothing, to mimic not finding Sampler module
            Mock -CommandName Get-ModuleVersion -MockWith { return '4.10.1' }
            Mock -CommandName Import-Module -MockWith { return @{ Version = [version]'4.10.1' } }
        }

        Context 'When using default parameter values' {
            It 'Should use current location for Path and RootPath' {
                $null = Invoke-PesterJob

                Should -Invoke -CommandName Get-Location -Times 2
            }
        }

        Context 'When passing RootPath parameter' {
            It 'Should use passed RootPath' {
                $params = @{
                    Path     = Join-Path -Path $TestDrive -ChildPath 'MockPath/tests'
                    RootPath = $TestDrive
                }

                $null = Invoke-PesterJob @params
            }
        }

        Context 'When passing Tag parameter' {
            It 'Should use passed RootPath' {
                $params = @{
                    Path = Join-Path -Path $TestDrive -ChildPath 'MockPath/tests'
                    Tag  = 'Unit'
                }

                $null = Invoke-PesterJob @params
            }
        }
        Context 'When passing TestNameFilter parameter' {
            It 'Should accept TestNameFilter parameter without error' {
                $params = @{
                    Path           = Join-Path -Path $TestDrive -ChildPath 'MockPath/tests'
                    TestNameFilter = 'Should do something*'
                }

                $null = Invoke-PesterJob @params
            }

            It 'Should accept multiple test name patterns' {
                $params = @{
                    Path           = Join-Path -Path $TestDrive -ChildPath 'MockPath/tests'
                    TestNameFilter = @('Should validate*', 'Should handle*')
                }

                $null = Invoke-PesterJob @params
            }

            It 'Should work with TestName alias' {
                $params = @{
                    Path     = Join-Path -Path $TestDrive -ChildPath 'MockPath/tests'
                    TestName = 'Should work*'
                }

                $null = Invoke-PesterJob @params
            }

            It 'Should work with Test alias' {
                $params = @{
                    Path = Join-Path -Path $TestDrive -ChildPath 'MockPath/tests'
                    Test = 'Should pass*'
                }

                $null = Invoke-PesterJob @params
            }
        }


        Context 'When changing output verbosity levels' {
            It 'Should set Output verbosity to Detailed by default' {
                $params = @{
                    Path = Join-Path -Path $TestDrive -ChildPath 'MockPath/tests'
                }

                $null = Invoke-PesterJob @params

                Should -Invoke -CommandName Start-Job -ParameterFilter {
                    $ArgumentList[0].Show -eq 'All'
                }
            }

            It 'Should set Output verbosity to specified value' {
                $params = @{
                    Path   = Join-Path -Path $TestDrive -ChildPath 'MockPath/tests'
                    Output = 'Minimal'
                }

                $null = Invoke-PesterJob @params

                Should -Invoke -CommandName Start-Job -ParameterFilter {
                    $ArgumentList[0].Show -eq 'Minimal'
                }
            }
        }

        Context 'When using switch parameters' {
            It 'Should disable code coverage if SkipCodeCoverage is present' {
                $params = @{
                    Path             = Join-Path -Path $TestDrive -ChildPath 'MockPath/tests'
                    SkipCodeCoverage = $true
                }

                $null = Invoke-PesterJob @params

                Should -Invoke -CommandName Start-Job -ParameterFilter {
                    $ArgumentList[0].Keys -notcontains 'CodeCoverage'
                }
            }

            It 'Should pass Pester result object if PassThru is present' {
                $params = @{
                    Path     = Join-Path -Path $TestDrive -ChildPath 'MockPath/tests'
                    PassThru = $true
                }

                $null = Invoke-PesterJob @params

                Should -Invoke -CommandName Start-Job -ParameterFilter {
                    $ArgumentList[0].Keys -contains 'PassThru'
                }
            }

            It 'Should not show detailed error information as the default' {
                $params = @{
                    Path = Join-Path -Path $TestDrive -ChildPath 'MockPath/tests'
                }

                $null = Invoke-PesterJob @params

                Should -Invoke -CommandName Start-Job -ParameterFilter {
                    $ArgumentList[1] -eq $false
                }
            }

            It 'Should show detailed error information if ShowError is present' {
                $params = @{
                    Path      = Join-Path -Path $TestDrive -ChildPath 'MockPath/tests'
                    ShowError = $true
                }

                $null = Invoke-PesterJob @params

                Should -Invoke -CommandName Start-Job -ParameterFilter {
                    $ArgumentList[1] -eq $true
                }
            }
        }

        Context 'Job Execution' {
            It 'Should start a job and receive the result' {
                $params = @{
                    Path = Join-Path -Path $TestDrive -ChildPath 'MockPath/tests'
                }

                $null = Invoke-PesterJob @params

                Should -Invoke -CommandName Start-Job
                Should -Invoke -CommandName Receive-Job
            }
        }
    }

    Context 'When testing parameter sets' {
        BeforeAll {
            Mock -CommandName Get-Module # Mocked with nothing, to mimic not finding Sampler module
            Mock -CommandName Get-ModuleVersion -MockWith { return '5.4.0' }
            Mock -CommandName Import-Module -MockWith { return @{ Version = [version] '5.4.0' } }
        }

        It 'Should have EnableSourceLineMapping as a non-mandatory parameter' {
            $parameterInfo = (Get-Command -Name 'Invoke-PesterJob').Parameters['EnableSourceLineMapping']
            $parameterInfo.Attributes.Mandatory | Should -BeFalse
            $parameterInfo.ParameterType.FullName | Should -Be 'System.Management.Automation.SwitchParameter'
        }

        It 'Should have TestNameFilter as a non-mandatory parameter' {
            $parameterInfo = (Get-Command -Name 'Invoke-PesterJob').Parameters['TestNameFilter']
            $parameterInfo.Attributes.Mandatory | Should -BeFalse
            $parameterInfo.ParameterType.FullName | Should -Be 'System.String[]'
            $parameterInfo.Aliases | Should -Contain 'TestName'
            $parameterInfo.Aliases | Should -Contain 'Test'
        }
    }

    Context 'When using Pester v5' {
        BeforeAll {
            Mock -CommandName Get-Module -MockWith { return @{ Version = [version] '5.4.0' } }
            Mock -CommandName Get-SamplerProjectName -MockWith { return 'MockModuleName' }
            Mock -CommandName Get-ModuleVersion -MockWith { return '5.4.0' }
            Mock -CommandName Import-Module -MockWith { return @{ Version = [version] '5.4.0' } }
        }

        Context 'When using default parameter values' {
            It 'Should use current location for Path and RootPath' {
                $null = Invoke-PesterJob

                Should -Invoke -CommandName Get-Location -Times 2
            }
        }

        Context 'When passing RootPath parameter' {
            It 'Should use passed RootPath' {
                $params = @{
                    Path     = Join-Path -Path $TestDrive -ChildPath 'MockPath/tests'
                    RootPath = $TestDrive
                }

                $null = Invoke-PesterJob @params
            }
        }

        Context 'When passing Tag parameter' {
            It 'Should use passed RootPath' {
                $params = @{
                    Path = Join-Path -Path $TestDrive -ChildPath 'MockPath/tests'
                    Tag  = 'Unit'
                }

                $null = Invoke-PesterJob @params
            }
        }
        Context 'When passing TestNameFilter parameter' {
            It 'Should use passed TestNameFilter' {
                $params = @{
                    Path           = Join-Path -Path $TestDrive -ChildPath 'MockPath/tests'
                    TestNameFilter = 'Should do something*'
                }

                $null = Invoke-PesterJob @params
            }

            It 'Should accept multiple test name patterns' {
                $params = @{
                    Path           = Join-Path -Path $TestDrive -ChildPath 'MockPath/tests'
                    TestNameFilter = @('Should validate*', 'Should handle*')
                }

                $null = Invoke-PesterJob @params
            }

            It 'Should work with TestName alias' {
                $params = @{
                    Path     = Join-Path -Path $TestDrive -ChildPath 'MockPath/tests'
                    TestName = 'Should work*'
                }

                $null = Invoke-PesterJob @params
            }

            It 'Should work with Test alias' {
                $params = @{
                    Path = Join-Path -Path $TestDrive -ChildPath 'MockPath/tests'
                    Test = 'Should pass*'
                }

                $null = Invoke-PesterJob @params
            }
        }

        Context 'When changing output verbosity levels' {
            It 'Should set Output verbosity to Detailed by default' {
                $params = @{
                    Path = Join-Path -Path $TestDrive -ChildPath 'MockPath/tests'
                }

                $null = Invoke-PesterJob @params

                Should -Invoke -CommandName Start-Job -ParameterFilter {
                    $ArgumentList[0].Output.Verbosity.Value -eq 'Detailed'
                }
            }

            It 'Should set output verbosity Minimal to specified value' {
                $params = @{
                    Path   = Join-Path -Path $TestDrive -ChildPath 'MockPath/tests'
                    Output = 'Minimal'
                }

                $null = Invoke-PesterJob @params

                # Minimal verbosity is not supported in Pester v5, it set to Normal if used.
                Should -Invoke -CommandName Start-Job -ParameterFilter {
                    $ArgumentList[0].Output.Verbosity.Value -eq 'Normal'
                }
            }

            It 'Should set output verbosity None to specified value' {
                $params = @{
                    Path   = Join-Path -Path $TestDrive -ChildPath 'MockPath/tests'
                    Output = 'None'
                }

                $null = Invoke-PesterJob @params

                # None verbosity is supported in Pester v5.
                Should -Invoke -CommandName Start-Job -ParameterFilter {
                    $ArgumentList[0].Output.Verbosity.Value -eq 'None'
                }
            }
        }

        Context 'When using switch parameters' {
            It 'Should disable code coverage if SkipCodeCoverage is present' {
                $params = @{
                    Path             = Join-Path -Path $TestDrive -ChildPath 'MockPath/tests'
                    SkipCodeCoverage = $true
                }

                $null = Invoke-PesterJob @params

                Should -Invoke -CommandName Start-Job -ParameterFilter {
                    $ArgumentList[0].CodeCoverage.Enabled.Value -eq $false
                }
            }

            It 'Should pass Pester result object if PassThru is present' {
                $params = @{
                    Path     = Join-Path -Path $TestDrive -ChildPath 'MockPath/tests'
                    PassThru = $true
                }

                $null = Invoke-PesterJob @params

                Should -Invoke -CommandName Start-Job -ParameterFilter {
                    $ArgumentList[0].Run.PassThru.Value -eq $true
                }
            }

            It 'Should not show detailed error information as the default' {
                $params = @{
                    Path = Join-Path -Path $TestDrive -ChildPath 'MockPath/tests'
                }

                $null = Invoke-PesterJob @params

                Should -Invoke -CommandName Start-Job -ParameterFilter {
                    $ArgumentList[1] -eq $false
                }
            }

            It 'Should show detailed error information if ShowError is present' {
                $params = @{
                    Path      = Join-Path -Path $TestDrive -ChildPath 'MockPath/tests'
                    ShowError = $true
                }

                $null = Invoke-PesterJob @params

                Should -Invoke -CommandName Start-Job -ParameterFilter {
                    $ArgumentList[1] -eq $true
                }
            }

            It 'Should skip running tests if SkipRun is present' {
                $params = @{
                    Path    = Join-Path -Path $TestDrive -ChildPath 'MockPath/tests'
                    SkipRun = $true
                }
                $null = Invoke-PesterJob @params

                Should -Invoke -CommandName Start-Job -ParameterFilter {
                    $ArgumentList[0].Run.SkipRun.Value -eq $true
                }
            }
        }

        Context 'Job Execution' {
            It 'Should start a job and receive the result' {
                $params = @{
                    Path = Join-Path -Path $TestDrive -ChildPath 'MockPath/tests'
                }

                $null = Invoke-PesterJob @params

                Should -Invoke -CommandName Start-Job
                Should -Invoke -CommandName Receive-Job
            }
        }

        Context 'When using EnableSourceLineMapping parameter' {
            Context 'When in a Sampler project' {
                BeforeAll {
                    # Mock Get-Module to return Sampler module to simulate Sampler project
                    Mock -CommandName Get-Module -MockWith {
                        param($Name)
                        if ($Name -eq 'Sampler')
                        {
                            return @{ Name = 'Sampler'; Version = [version] '0.118.3' }
                        }
                        elseif ($Name -eq 'Pester')
                        {
                            return @{ Version = [version] '5.4.0' }
                        }
                        return $null
                    }
                }

                It 'Should auto-enable PassThru when EnableSourceLineMapping is used' {
                    $params = @{
                        Path                    = Join-Path -Path $TestDrive -ChildPath 'MockPath/tests'
                        EnableSourceLineMapping = $true
                    }

                    Invoke-PesterJob @params

                    Should -Invoke -CommandName Start-Job -ParameterFilter {
                        $ArgumentList[0].Run.PassThru.Value -eq $true
                    }
                }

                It 'Should not require ModuleBuilder check in Sampler project' {
                    $params = @{
                        Path                    = Join-Path -Path $TestDrive -ChildPath 'MockPath/tests'
                        EnableSourceLineMapping = $true
                    }

                    $null = Invoke-PesterJob @params
                }
            }

            Context 'When not in a Sampler project' {
                BeforeAll {
                    # Mock Get-Module to return no Sampler module but with ModuleBuilder available
                    Mock -CommandName Get-Module -MockWith {
                        param($Name, $ListAvailable)
                        if ($Name -eq 'Sampler')
                        {
                            return $null
                        }
                        elseif ($Name -eq 'Pester')
                        {
                            return @{ Version = [version] '5.4.0' }
                        }
                        elseif ($Name -eq 'ModuleBuilder' -and $ListAvailable)
                        {
                            return @{ Name = 'ModuleBuilder'; Version = [version] '3.0.0' }
                        }
                        return $null
                    }
                }

                It 'Should not throw when ModuleBuilder is available' {
                    $params = @{
                        Path                    = Join-Path -Path $TestDrive -ChildPath 'MockPath/tests'
                        EnableSourceLineMapping = $true
                    }

                    $null = Invoke-PesterJob @params
                }
            }

            Context 'When not in a Sampler project and ModuleBuilder is not available' {
                BeforeAll {
                    # Mock Get-Module to return no Sampler module and no ModuleBuilder
                    Mock -CommandName Get-Module -MockWith {
                        param($Name, $ListAvailable)
                        if ($Name -eq 'Sampler')
                        {
                            return $null
                        }
                        elseif ($Name -eq 'Pester')
                        {
                            return @{ Version = [version] '5.4.0' }
                        }
                        elseif ($Name -eq 'ModuleBuilder')
                        {
                            return $null
                        }
                        return $null
                    }
                }

                It 'Should throw error when ModuleBuilder is not available' {
                    $params = @{
                        Path                    = Join-Path -Path $TestDrive -ChildPath 'MockPath/tests'
                        EnableSourceLineMapping = $true
                    }

                    { Invoke-PesterJob @params } | Should -Throw -ErrorId 'ModuleBuilderNotFound,Invoke-PesterJob'
                }
            }
        }

        Context 'When using FilterCodeCoverageResult parameter' {
            It 'Should have FilterCodeCoverageResult as a non-mandatory parameter' {
                $parameterInfo = (Get-Command -Name 'Invoke-PesterJob').Parameters['FilterCodeCoverageResult']

                $parameterInfo.Attributes.Mandatory | Should -BeFalse
                $parameterInfo.ParameterType | Should -Be ([System.String[]])
            }

            It 'Should accept array of string values for FilterCodeCoverageResult' {
                $filterArray = @('Get-*', 'Set-*', 'Test-*')

                # This should not throw an error when validating parameter type
                $params = @{
                    FilterCodeCoverageResult = $filterArray
                    Path                     = '.'
                    SkipRun                  = $true
                    SkipCodeCoverage         = $true
                }

                # We're not actually running this, just validating parameter binding
                $command = Get-Command -Name 'Invoke-PesterJob'
                $null = $command.ResolveParameter('FilterCodeCoverageResult').ParameterType
            }
        }

        Context 'When processing source line mapping with FilterCodeCoverageResult' {
            BeforeAll {
                # Mock Get-Module to return Sampler module to simulate Sampler project
                Mock -CommandName Get-Module -MockWith {
                    param($Name)
                    if ($Name -eq 'Sampler')
                    {
                        return @{ Name = 'Sampler'; Version = [version] '0.118.3' }
                    }
                    elseif ($Name -eq 'Pester')
                    {
                        return @{ Version = [version] '5.4.0' }
                    }
                    return $null
                }

                # Create mock commands missed data in the proper Pester format
                # These should match the structure that Pester's CodeCoverage.CommandsMissed provides
                $script:mockCommandsMissed = @(
                    [PSCustomObject]@{
                        File        = Join-Path -Path $TestDrive -ChildPath 'output/builtModule/TestModule/1.0.0/TestModule.psm1'
                        Line        = 10
                        StartLine   = 10
                        EndLine     = 10
                        StartColumn = 1
                        EndColumn   = 50
                        Class       = ''
                        Function    = 'Get-Something'
                        Command     = 'Write-Verbose'
                        HitCount    = 0
                    },
                    [PSCustomObject]@{
                        File        = Join-Path -Path $TestDrive -ChildPath 'output/builtModule/TestModule/1.0.0/TestModule.psm1'
                        Line        = 15
                        StartLine   = 15
                        EndLine     = 15
                        StartColumn = 1
                        EndColumn   = 50
                        Class       = 'TestClass'
                        Function    = ''
                        Command     = 'Write-Debug'
                        HitCount    = 0
                    },
                    [PSCustomObject]@{
                        File        = Join-Path -Path $TestDrive -ChildPath 'output/builtModule/TestModule/1.0.0/TestModule.psm1'
                        Line        = 20
                        StartLine   = 20
                        EndLine     = 20
                        StartColumn = 1
                        EndColumn   = 50
                        Class       = ''
                        Function    = 'Set-Configuration'
                        Command     = '$variable = $value'
                        HitCount    = 0
                    },
                    [PSCustomObject]@{
                        File        = Join-Path -Path $TestDrive -ChildPath 'output/builtModule/TestModule/1.0.0/TestModule.psm1'
                        Line        = 25
                        StartLine   = 25
                        EndLine     = 25
                        StartColumn = 1
                        EndColumn   = 50
                        Class       = ''
                        Function    = 'Test-HashFunction'
                        Command     = 'Get-FileHash'
                        HitCount    = 0
                    }
                )

                # Create the necessary built module file for Convert-LineNumber to process
                $mockBuiltModuleDir = Join-Path -Path $TestDrive -ChildPath 'output/builtModule/TestModule/1.0.0'
                $null = New-Item -Path $mockBuiltModuleDir -ItemType Directory -Force
                $mockBuiltModuleFile = Join-Path -Path $mockBuiltModuleDir -ChildPath 'TestModule.psm1'
                Set-Content -Path $mockBuiltModuleFile -Value @'
function Get-Something {
    Write-Verbose "Getting something"
}

class TestClass {
    [void] DoSomething() {
        Write-Debug "Debug message"
    }
}

function Set-Configuration {
    $variable = $value
}

function Test-HashFunction {
    Get-FileHash -Path $file
}
'@

                # Create source directory structure for Convert-LineNumber to map to
                $mockSourceDir = Join-Path -Path $TestDrive -ChildPath 'source'
                $null = New-Item -Path "$mockSourceDir/Public" -ItemType Directory -Force
                $null = New-Item -Path "$mockSourceDir/Classes" -ItemType Directory -Force

                # Create source files
                Set-Content -Path "$mockSourceDir/Public/Get-Something.ps1" -Value 'function Get-Something { Write-Verbose "Getting something" }'
                Set-Content -Path "$mockSourceDir/Classes/TestClass.ps1" -Value 'class TestClass { [void] DoSomething() { Write-Debug "Debug message" } }'
                Set-Content -Path "$mockSourceDir/Public/Set-Configuration.ps1" -Value 'function Set-Configuration { $variable = $value }'
                Set-Content -Path "$mockSourceDir/Public/Test-HashFunction.ps1" -Value 'function Test-HashFunction { Get-FileHash -Path $file }'

                # Mock ConvertTo-SourceLineNumber to add SourceLineNumber and SourceFile properties
                Mock -CommandName ConvertTo-SourceLineNumber -MockWith {
                    param($InputObject, $PassThru)

                    if ($PassThru)
                    {
                        # Add SourceLineNumber and SourceFile properties to each input object
                        foreach ($item in $InputObject)
                        {
                            # Create a copy of the original object with additional properties
                            $enhancedItem = $item.PSObject.Copy()

                            # Map to appropriate source file based on function or class name
                            $sourceFile = if ($item.Function -eq 'Get-Something')
                            {
                                Join-Path -Path $TestDrive -ChildPath 'source/Public/Get-Something.ps1'
                            }
                            elseif ($item.Function -eq 'Set-Configuration')
                            {
                                Join-Path -Path $TestDrive -ChildPath 'source/Public/Set-Configuration.ps1'
                            }
                            elseif ($item.Function -eq 'Test-HashFunction')
                            {
                                Join-Path -Path $TestDrive -ChildPath 'source/Public/Test-HashFunction.ps1'
                            }
                            elseif ($item.Class -eq 'TestClass')
                            {
                                Join-Path -Path $TestDrive -ChildPath 'source/Classes/TestClass.ps1'
                            }
                            else
                            {
                                Join-Path -Path $TestDrive -ChildPath 'source/Unknown.ps1'
                            }

                            # Add the source mapping properties
                            $enhancedItem | Add-Member -NotePropertyName 'SourceLineNumber' -NotePropertyValue $item.Line
                            $enhancedItem | Add-Member -NotePropertyName 'SourceFile' -NotePropertyValue $sourceFile

                            Write-Output $enhancedItem
                        }
                    }
                    else
                    {
                        # If not PassThru, return objects with only SourceLineNumber and SourceFile
                        foreach ($item in $InputObject)
                        {
                            [PSCustomObject]@{
                                SourceLineNumber = $item.Line
                                SourceFile       = if ($item.Function -eq 'Get-Something')
                                {
                                    Join-Path -Path $TestDrive -ChildPath 'source/Public/Get-Something.ps1'
                                }
                                elseif ($item.Function -eq 'Set-Configuration')
                                {
                                    Join-Path -Path $TestDrive -ChildPath 'source/Public/Set-Configuration.ps1'
                                }
                                elseif ($item.Function -eq 'Test-HashFunction')
                                {
                                    Join-Path -Path $TestDrive -ChildPath 'source/Public/Test-HashFunction.ps1'
                                }
                                elseif ($item.Class -eq 'TestClass')
                                {
                                    Join-Path -Path $TestDrive -ChildPath 'source/Classes/TestClass.ps1'
                                }
                                else
                                {
                                    Join-Path -Path $TestDrive -ChildPath 'source/Unknown.ps1'
                                }
                            }
                        }
                    }
                }

                # Mock Receive-Job to return the commands missed data
                Mock -CommandName Receive-Job -MockWith {
                    return $script:mockCommandsMissed
                }
            }

            It 'Should filter commands by function name pattern when FilterCodeCoverageResult is specified' {
                $params = @{
                    Path                     = Join-Path -Path $TestDrive -ChildPath 'MockPath/tests'
                    EnableSourceLineMapping  = $true
                    FilterCodeCoverageResult = @('Get-*')
                }

                $result = Invoke-PesterJob @params

                # Should return commands from classes matching 'Test*' and functions matching 'Test*'
                $result | Should -HaveCount 1
                $result | Where-Object { $_.Function -eq 'Get-Something' } | Should -HaveCount 1
            }

            It 'Should filter commands by class name pattern when FilterCodeCoverageResult is specified' {
                $params = @{
                    Path                     = Join-Path -Path $TestDrive -ChildPath 'MockPath/tests'
                    EnableSourceLineMapping  = $true
                    FilterCodeCoverageResult = @('Test*')
                }

                $result = Invoke-PesterJob @params

                # Should return commands from classes matching 'Test*' and functions matching 'Test*'
                $result | Should -HaveCount 2
                $result | Where-Object { $_.Class -eq 'TestClass' } | Should -HaveCount 1
                $result | Where-Object { $_.Function -eq 'Test-HashFunction' } | Should -HaveCount 1
            }

            It 'Should filter commands by multiple patterns when FilterCodeCoverageResult contains multiple values' {
                $params = @{
                    Path                     = Join-Path -Path $TestDrive -ChildPath 'MockPath/tests'
                    EnableSourceLineMapping  = $true
                    FilterCodeCoverageResult = @('Get-*', 'Set-*')
                }

                $result = Invoke-PesterJob @params

                # Should return commands from functions matching either 'Get-*' or 'Set-*'
                $result | Should -HaveCount 2
                $result | Where-Object { $_.Function -eq 'Get-Something' } | Should -HaveCount 1
                $result | Where-Object { $_.Function -eq 'Set-Configuration' } | Should -HaveCount 1
            }

            It 'Should filter commands by specific hash-related pattern' {
                $params = @{
                    Path                     = Join-Path -Path $TestDrive -ChildPath 'MockPath/tests'
                    EnableSourceLineMapping  = $true
                    FilterCodeCoverageResult = @('*hash*')
                }

                $result = Invoke-PesterJob @params

                # Should return only commands from functions containing 'hash'
                $result | Should -HaveCount 1
                $result[0].Function | Should -Be 'Test-HashFunction'
            }

            It 'Should return all commands when FilterCodeCoverageResult is not specified' {
                $params = @{
                    Path                    = Join-Path -Path $TestDrive -ChildPath 'MockPath/tests'
                    EnableSourceLineMapping = $true
                }

                $result = Invoke-PesterJob @params

                # Should return all commands since no filter is applied
                $result | Should -HaveCount 4
            }

            It 'Should return empty result when FilterCodeCoverageResult pattern matches no commands' {
                $params = @{
                    Path                     = Join-Path -Path $TestDrive -ChildPath 'MockPath/tests'
                    EnableSourceLineMapping  = $true
                    FilterCodeCoverageResult = @('NonExistent-*')
                }

                $result = Invoke-PesterJob @params

                # Should return no commands since pattern matches nothing
                $result | Should -BeNullOrEmpty
            }

            It 'Should select only specific properties in the final output' {
                $params = @{
                    Path                     = Join-Path -Path $TestDrive -ChildPath 'MockPath/tests'
                    EnableSourceLineMapping  = $true
                    FilterCodeCoverageResult = @('Get-*')
                }

                $result = Invoke-PesterJob @params

                # Verify that only the expected properties are present (based on Select-Object in the actual code)
                $result | Should -HaveCount 1
                $result[0].PSObject.Properties.Name | Should -Contain 'Class'
                $result[0].PSObject.Properties.Name | Should -Contain 'Function'
                $result[0].PSObject.Properties.Name | Should -Contain 'Command'
                $result[0].PSObject.Properties.Name | Should -Contain 'SourceLineNumber'
                $result[0].PSObject.Properties.Name | Should -Contain 'SourceFile'

                # Verify it doesn't contain other properties from the original object
                $result[0].PSObject.Properties.Name | Should -Not -Contain 'Line'
                $result[0].PSObject.Properties.Name | Should -Not -Contain 'File'
            }
        }

        Context 'When EnableSourceLineMapping is used without code coverage' {
            BeforeAll {
                # Mock Get-Module to return Sampler module
                Mock -CommandName Get-Module -MockWith {
                    param($Name)
                    if ($Name -eq 'Sampler')
                    {
                        return @{ Name = 'Sampler'; Version = [version] '0.118.3' }
                    }
                    elseif ($Name -eq 'Pester')
                    {
                        return @{ Version = [version] '5.4.0' }
                    }
                    return $null
                }

                # Mock Receive-Job to return the Pester result object instead of commands missed
                Mock -CommandName Receive-Job -MockWith {
                    return [PSCustomObject]@{
                        Result      = 'Passed'
                        TotalCount  = 5
                        PassedCount = 5
                        FailedCount = 0
                    }
                }
            }

            It 'Should return original Pester result when SkipCodeCoverage is used with EnableSourceLineMapping' {
                $params = @{
                    Path                    = Join-Path -Path $TestDrive -ChildPath 'MockPath/tests'
                    EnableSourceLineMapping = $true
                    SkipCodeCoverage        = $true
                    PassThru                = $true
                }

                $result = Invoke-PesterJob @params

                # Should return the original Pester result, not processed commands
                $result.Result | Should -Be 'Passed'
                $result.TotalCount | Should -Be 5
            }
        }
    }
}
