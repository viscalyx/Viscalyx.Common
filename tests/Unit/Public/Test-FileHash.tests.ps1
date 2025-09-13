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

Describe 'Test-FileHash' {
    BeforeAll {
        # Create a temporary file for testing
        $mockTestFile = Join-Path -Path $TestDrive -ChildPath 'TestFile.txt'

        Set-Content -Path $mockTestFile -Value 'Test content'
        $mockHash = Get-FileHash -Path $mockTestFile -Algorithm 'SHA256' | Select-Object -ExpandProperty 'Hash'
    }

    Context 'When the file exists and the hash matches' {
        It 'Should return $true' {
            $result = Test-FileHash -Path $mockTestFile -Algorithm 'SHA256' -ExpectedHash $mockHash

            $result | Should -BeTrue
        }
    }

    Context 'When the file exists and the hash does not match' {
        It 'Should return $false' {
            $result = Test-FileHash -Path $mockTestFile -Algorithm 'SHA256' -ExpectedHash 'incorrect hash'
            $result | Should -BeFalse
        }
    }
}
