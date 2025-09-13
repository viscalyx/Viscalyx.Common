[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
param ()

BeforeDiscovery {
    try
    {
        if (-not (Get-Module -Name 'DscResource.Test'))
        {
            # Assumes dependencies has been resolved, so if this module is not available, run 'noop' task.
            if (-not (Get-Module -Name 'DscResource.Test' -ListAvailable))
            {
                # Redirect all streams to $null, except the error stream (stream 2)
                & "$PSScriptRoot/../../../build.ps1" -Tasks 'noop' 3>&1 4>&1 5>&1 6>&1 > $null
            }

            # If the dependencies has not been resolved, this will throw an error.
            Import-Module -Name 'DscResource.Test' -Force -ErrorAction 'Stop'
        }
    }
    catch [System.IO.FileNotFoundException]
    {
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -ResolveDependency -Tasks build" first.'
    }
}

BeforeAll {
    $script:moduleName = 'Viscalyx.Common'

    Import-Module -Name $script:moduleName -Force -ErrorAction 'Stop'

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
    It 'Should have the expected parameter set <Name>' -ForEach @(
        @{
            Name = '__AllParameterSets'
            ExpectedParameterSetString = '[[-Path] <string[]>] [[-CodeCoveragePath] <string[]>] [-RootPath <string>] [-Tag <string[]>] [-ModuleName <string>] [-Output <string>] [-SkipCodeCoverage] [-PassThru] [-ShowError] [-SkipRun] [-BuildScriptPath <string>] [-BuildScriptParameter <hashtable>] [<CommonParameters>]'
        }
    ) {
        $parameterSet = (Get-Command -Name 'Invoke-PesterJob').ParameterSets |
            Where-Object -FilterScript { $_.Name -eq $Name }

        $parameterSet | Should -Not -BeNullOrEmpty
        $parameterSet.Name | Should -Be $Name
        $parameterSet.ToString() | Should -Be $ExpectedParameterSetString
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
    }

    Context 'When using Pester v4' {
        BeforeAll {
            Mock -CommandName Get-Module # Mocked with nothing, to mimic not finding Sampler module
            Mock -CommandName Get-ModuleVersion -MockWith { return '4.10.1' }
            Mock -CommandName Import-Module -MockWith { return @{ Version = [version]'4.10.1' } }
        }

        Context 'When using default parameter values' {
            It 'Should use current location for Path and RootPath' {
                Invoke-PesterJob

                Should -Invoke -CommandName Get-Location -Times 2
            }
        }

        Context 'When passing RootPath parameter' {
            It 'Should use passed RootPath' {
                $params = @{
                    Path     = Join-Path -Path $TestDrive -ChildPath 'MockPath/tests'
                    RootPath = $TestDrive
                }

                Invoke-PesterJob @params
            }
        }

        Context 'When passing Tag parameter' {
            It 'Should use passed RootPath' {
                $params = @{
                    Path = Join-Path -Path $TestDrive -ChildPath 'MockPath/tests'
                    Tag  = 'Unit'
                }

                Invoke-PesterJob @params
            }
        }

        Context 'When changing output verbosity levels' {
            It 'Should set Output verbosity to Detailed by default' {
                $params = @{
                    Path = Join-Path -Path $TestDrive -ChildPath 'MockPath/tests'
                }

                Invoke-PesterJob @params

                Should -Invoke -CommandName Start-Job -ParameterFilter {
                    $ArgumentList[0].Show -eq 'All'
                }
            }

            It 'Should set Output verbosity to specified value' {
                $params = @{
                    Path   = Join-Path -Path $TestDrive -ChildPath 'MockPath/tests'
                    Output = 'Minimal'
                }

                Invoke-PesterJob @params

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

                Invoke-PesterJob @params

                Should -Invoke -CommandName Start-Job -ParameterFilter {
                    $ArgumentList[0].Keys -notcontains 'CodeCoverage'
                }
            }

            It 'Should pass Pester result object if PassThru is present' {
                $params = @{
                    Path     = Join-Path -Path $TestDrive -ChildPath 'MockPath\tests'
                    PassThru = $true
                }

                Invoke-PesterJob @params

                Should -Invoke -CommandName Start-Job -ParameterFilter {
                    $ArgumentList[0].Keys -contains 'PassThru'
                }
            }

            It 'Should not show detailed error information as the default' {
                $params = @{
                    Path = Join-Path -Path $TestDrive -ChildPath 'MockPath\tests'
                }

                Invoke-PesterJob @params

                Should -Invoke -CommandName Start-Job -ParameterFilter {
                    $ArgumentList[1] -eq $false
                }
            }

            It 'Should show detailed error information if ShowError is present' {
                $params = @{
                    Path      = Join-Path -Path $TestDrive -ChildPath 'MockPath\tests'
                    ShowError = $true
                }

                Invoke-PesterJob @params

                Should -Invoke -CommandName Start-Job -ParameterFilter {
                    $ArgumentList[1] -eq $true
                }
            }
        }

        Context 'Job Execution' {
            It 'Should start a job and receive the result' {
                $params = @{
                    Path = Join-Path -Path $TestDrive -ChildPath 'MockPath\tests'
                }

                Invoke-PesterJob @params

                Should -Invoke -CommandName Start-Job
                Should -Invoke -CommandName Receive-Job
            }
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
                Invoke-PesterJob

                Should -Invoke -CommandName Get-Location -Times 2
            }
        }

        Context 'When passing RootPath parameter' {
            It 'Should use passed RootPath' {
                $params = @{
                    Path     = Join-Path -Path $TestDrive -ChildPath 'MockPath/tests'
                    RootPath = $TestDrive
                }

                Invoke-PesterJob @params
            }
        }

        Context 'When passing Tag parameter' {
            It 'Should use passed RootPath' {
                $params = @{
                    Path = Join-Path -Path $TestDrive -ChildPath 'MockPath/tests'
                    Tag  = 'Unit'
                }

                Invoke-PesterJob @params
            }
        }

        Context 'When changing output verbosity levels' {
            It 'Should set Output verbosity to Detailed by default' {
                $params = @{
                    Path = Join-Path -Path $TestDrive -ChildPath 'MockPath/tests'
                }

                Invoke-PesterJob @params

                Should -Invoke -CommandName Start-Job -ParameterFilter {
                    $ArgumentList[0].Output.Verbosity.Value -eq 'Detailed'
                }
            }

            It 'Should set output verbosity Minimal to specified value' {
                $params = @{
                    Path   = Join-Path -Path $TestDrive -ChildPath 'MockPath/tests'
                    Output = 'Minimal'
                }

                Invoke-PesterJob @params

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

                Invoke-PesterJob @params

                # Minimal verbosity is not supported in Pester v5, it set to Normal if used.
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

                Invoke-PesterJob @params

                Should -Invoke -CommandName Start-Job -ParameterFilter {
                    $ArgumentList[0].CodeCoverage.Enabled.Value -eq $false
                }
            }

            It 'Should pass Pester result object if PassThru is present' {
                $params = @{
                    Path     = Join-Path -Path $TestDrive -ChildPath 'MockPath\tests'
                    PassThru = $true
                }

                Invoke-PesterJob @params

                Should -Invoke -CommandName Start-Job -ParameterFilter {
                    $ArgumentList[0].Run.PassThru.Value -eq $true
                }
            }

            It 'Should not show detailed error information as the default' {
                $params = @{
                    Path = Join-Path -Path $TestDrive -ChildPath 'MockPath\tests'
                }

                Invoke-PesterJob @params

                Should -Invoke -CommandName Start-Job -ParameterFilter {
                    $ArgumentList[1] -eq $false
                }
            }

            It 'Should show detailed error information if ShowError is present' {
                $params = @{
                    Path      = Join-Path -Path $TestDrive -ChildPath 'MockPath\tests'
                    ShowError = $true
                }

                Invoke-PesterJob @params

                Should -Invoke -CommandName Start-Job -ParameterFilter {
                    $ArgumentList[1] -eq $true
                }
            }

            It 'Should skip running tests if SkipRun is present' {
                $params = @{
                    Path    = Join-Path -Path $TestDrive -ChildPath 'MockPath\tests'
                    SkipRun = $true
                }
                Invoke-PesterJob @params

                Should -Invoke -CommandName Start-Job -ParameterFilter {
                    $ArgumentList[0].Run.SkipRun.Value -eq $true
                }
            }
        }

        Context 'Job Execution' {
            It 'Should start a job and receive the result' {
                $params = @{
                    Path = Join-Path -Path $TestDrive -ChildPath 'MockPath\tests'
                }

                Invoke-PesterJob @params

                Should -Invoke -CommandName Start-Job
                Should -Invoke -CommandName Receive-Job
            }
        }
    }
}
