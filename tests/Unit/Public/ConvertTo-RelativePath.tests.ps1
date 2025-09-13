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

    Import-Module -Name $script:moduleName

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

Describe 'ConvertTo-RelativePath' {
    BeforeAll {
        # Mock Get-Location to return a specific path
        Mock -CommandName Get-Location -MockWith { @{ Path = '/source/Viscalyx.Common' } }
    }

    It 'Should convert absolute path to relative path when CurrentLocation is provided' {
        $result = ConvertTo-RelativePath -AbsolutePath '/source/Viscalyx.Common/source/Public/ConvertTo-RelativePath.ps1' -CurrentLocation '/source/Viscalyx.Common'
        $result | Should -Be './source/Public/ConvertTo-RelativePath.ps1'
    }

    It 'Should convert absolute path to relative path using Get-Location when CurrentLocation is not provided' {
        $result = ConvertTo-RelativePath -AbsolutePath '/source/Viscalyx.Common/source/Public/ConvertTo-RelativePath.ps1'
        $result | Should -Be './source/Public/ConvertTo-RelativePath.ps1'
    }

    It 'Should return the absolute path if it does not start with CurrentLocation' {
        $result = ConvertTo-RelativePath -AbsolutePath '/other/path/ConvertTo-RelativePath.ps1' -CurrentLocation '/source/Viscalyx.Common'
        $result | Should -Be '/other/path/ConvertTo-RelativePath.ps1'
    }
}

