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

Describe "Assert-ScriptFileValidity" {
    It "Should validate module version and existence" {
        Mock -CommandName Test-Path -MockWith {
            return $true
        }

        Mock -CommandName Test-FileHash -MockWith {
            return $true
        }

        $null = InModuleScope -ScriptBlock {
            Assert-ScriptFileValidity -FilePath 'TestScript.ps1' -Hash '1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef' -ErrorAction 'Stop'
        }
    }

    It "Should validate module version and existence" {
        Mock -CommandName Test-Path -MockWith {
            return $true
        }

        Mock -CommandName Test-FileHash -MockWith {
            return $false
        }

        InModuleScope -ScriptBlock {
            $expectedMessage = $script:localizedData.Assert_ScriptFileValidity_HashValidationFailed -f 'TestScript.ps1', '1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef'

            { Assert-ScriptFileValidity -FilePath 'TestScript.ps1' -Hash '1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef' -ErrorAction 'Stop' } |
                Should -Throw -ExpectedMessage $expectedMessage
        }
    }

    It "Should validate module version and existence" {
        Mock -CommandName Test-Path -MockWith {
            return $false
        }

        InModuleScope -ScriptBlock {
            $expectedMessage = $script:localizedData.Assert_ScriptFileValidity_ScriptFileNotFound -f 'TestScript.ps1'

            { Assert-ScriptFileValidity -FilePath 'TestScript.ps1' -Hash '1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef' -ErrorAction 'Stop' } |
                Should -Throw -ExpectedMessage $expectedMessage
        }
    }
}
