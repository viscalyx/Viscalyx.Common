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
                & "$PSScriptRoot/../../../build.ps1" -Tasks 'noop' 2>&1 4>&1 5>&1 6>&1 > $null
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
    $script:dscModuleName = 'Viscalyx.Common'

    Import-Module -Name $script:dscModuleName

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:dscModuleName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:dscModuleName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:dscModuleName
}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    # Unload the module being tested so that it doesn't impact any other tests.
    Get-Module -Name $script:dscModuleName -All | Remove-Module -Force
}

Describe "Assert-PatchValidity" {
    BeforeAll {
        # Mock Get-Module to return a module with the correct version
        Mock -CommandName Get-Module -MockWith{
            return @{
                ModuleBase = "$TestDrive/Modules/TestModule"
                Version = "1.0.0"
            }
        }

        # Mock Test-Path to return true for the script file existence check
        Mock -CommandName Test-Path -MockWith {
            return $true
        }

        # Mock Get-FileHash to return the expected hash
        Mock -CommandName Get-FileHash -MockWith {
            return @{
                Hash = "1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef"
            }
        }

        Mock -CommandName Get-ModuleVersion -MockWith {
            return '1.0.0'
        }
    }

    It "Should validate module version and existence" {
        InModuleScope Viscalyx.Common {
            $patchEntry = @{
                ModuleName = "TestModule"
                ModuleVersion = "1.0.0"
                ScriptFileName = "TestScript.ps1"
                OriginalHashSHA = "1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef"
            }

            Assert-PatchValidity -PatchEntry $patchEntry
        }
    }

    It "Should throw correct error for module version mismatch" {
        Mock -CommandName Get-Module -MockWith {
            return $null
        }

        Mock -CommandName Get-ModuleVersion -MockWith {
            return '1.0.0'
        }

        InModuleScope -ScriptBlock {
            $patchEntry = @{
                ModuleName = "TestModule"
                ModuleVersion = "1.0.0"
                ScriptFileName = "TestScript.ps1"
                OriginalHashSHA = "1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef"
            }

            { Assert-PatchValidity -PatchEntry $patchEntry -ErrorAction 'Stop' } |
                Should -Throw "Module not found: TestModule 1.0.0"
        }
    }

    It "Should throw correct error for script file not found" {
        Mock -CommandName Test-Path -MockWith {
            return $false
        }

        Mock -CommandName Get-ModuleVersion -MockWith {
            return '1.0.0'
        }

        InModuleScope -ScriptBlock {
            $patchEntry = @{
                ModuleName = "TestModule"
                ModuleVersion = "1.0.0"
                ScriptFileName = "TestScript.ps1"
                OriginalHashSHA = "1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef"
            }

            { Assert-PatchValidity -PatchEntry $patchEntry -ErrorAction 'Stop' } |
                Should -Throw ("Script file not found: $TestDrive{0}Modules{0}TestModule{0}TestScript.ps1" -f [System.IO.Path]::DirectorySeparatorChar)
        }
    }

    It "Should throw correct error for hash validation failure" {
        Mock -CommandName Get-FileHash -MockWith {
            return @{
                Hash = "abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890"
            }
        }

        Mock -CommandName Get-ModuleVersion -MockWith {
            return '1.0.0'
        }

        InModuleScope -ScriptBlock {
            $patchEntry = @{
                ModuleName = "TestModule"
                ModuleVersion = "1.0.0"
                ScriptFileName = "TestScript.ps1"
                OriginalHashSHA = "1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef"
            }

            { Assert-PatchValidity -PatchEntry $patchEntry -ErrorAction 'Stop' } |
                Should -Throw ("Hash validation failed for script file: $TestDrive{0}Modules{0}TestModule{0}TestScript.ps1. Expected: 1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef, Actual: abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890" -f [System.IO.Path]::DirectorySeparatorChar)
        }
    }

    It "Should throw correct error for module version mismatch" {
        Mock -CommandName Get-Module -MockWith {
            return @{
                ModuleBase = "$TestDrive/Modules/TestModule"
                Version = "2.0.0" # Different version
            }
        }

        Mock -CommandName Get-ModuleVersion -MockWith {
            return '2.0.0'
        }

        InModuleScope -ScriptBlock {
            $patchEntry = @{
                ModuleName = "TestModule"
                ModuleVersion = "1.0.0"
                ScriptFileName = "TestScript.ps1"
                OriginalHashSHA = "1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef"
            }

            { Assert-PatchValidity -PatchEntry $patchEntry -ErrorAction 'Stop' } |
                Should -Throw "Module version mismatch: TestModule 1.0.0"
        }
    }

    It "Should throw correct error for script file not found" {
        Mock -CommandName Get-Module -MockWith {
            return @{
                ModuleBase = "$TestDrive/Modules/TestModule"
                Version = "1.0.0"
            }
        }

        Mock -CommandName Test-Path -MockWith {
            return $false
        }

        Mock -CommandName Get-ModuleVersion -MockWith {
            return '1.0.0'
        }

        InModuleScope -ScriptBlock {
            $patchEntry = @{
                ModuleName = "TestModule"
                ModuleVersion = "1.0.0"
                ScriptFileName = "TestScript.ps1"
                OriginalHashSHA = "1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef"
            }

            { Assert-PatchValidity -PatchEntry $patchEntry -ErrorAction 'Stop' } |
                Should -Throw ("Script file not found: $TestDrive{0}Modules{0}TestModule{0}TestScript.ps1" -f [System.IO.Path]::DirectorySeparatorChar)
        }
    }

    It "Should throw correct error for hash validation failure" {
        Mock -CommandName Get-Module -MockWith {
            return @{
                ModuleBase = "$TestDrive/Modules/TestModule"
                Version = "1.0.0"
            }
        }

        Mock -CommandName Test-Path -MockWith {
            return $true
        }

        Mock -CommandName Get-FileHash -MockWith {
            return @{
                Hash = "abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890"
            }
        }

        Mock -CommandName Get-ModuleVersion -MockWith {
            return '1.0.0'
        }

        InModuleScope -ScriptBlock {
            $patchEntry = @{
                ModuleName = "TestModule"
                ModuleVersion = "1.0.0"
                ScriptFileName = "TestScript.ps1"
                OriginalHashSHA = "1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef"
            }

            { Assert-PatchValidity -PatchEntry $patchEntry -ErrorAction 'Stop' } |
                Should -Throw ("Hash validation failed for script file: $TestDrive{0}Modules{0}TestModule{0}TestScript.ps1. Expected: 1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef, Actual: abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890" -f [System.IO.Path]::DirectorySeparatorChar)
        }
    }
}
