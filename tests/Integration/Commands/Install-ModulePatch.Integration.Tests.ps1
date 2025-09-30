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

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:moduleName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:moduleName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:moduleName

    # Save the original PSModulePath
    $script:originalPSModulePath = $env:PSModulePath

    # Add $TestDrive to the beginning of PSModulePath
    $env:PSModulePath = '{0}{1}{2}' -f $TestDrive, [System.IO.Path]::PathSeparator, $env:PSModulePath
}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    # Unload the module being tested so that it doesn't impact any other tests.
    Get-Module -Name $script:moduleName -All | Remove-Module -Force

    # Restore the original PSModulePath
    $env:PSModulePath = $script:originalPSModulePath
}

Describe 'Install-ModulePatch' {
    BeforeAll {
        # Save the original PSModulePath
        $script:originalPSModulePath = $env:PSModulePath

        # Add $TestDrive to the beginning of PSModulePath
        $env:PSModulePath = '{0}{1}{2}' -f $TestDrive, [System.IO.Path]::PathSeparator, $env:PSModulePath
    }

    AfterAll {
        # Restore the original PSModulePath
        $env:PSModulePath = $script:originalPSModulePath
    }

    It 'Should correctly patch ModuleBuilder v3.1.7' {
        $null = Save-Module -Name 'ModuleBuilder' -RequiredVersion 3.1.7 -Path $TestDrive -Force -ErrorAction 'Stop'

        $patchPath = Join-Path -Path $PSScriptRoot -ChildPath '../../../patches/ModuleBuilder_3.1.7_patch.json'

        # Run Install-ModulePatch
        $null = Install-ModulePatch -Path $patchPath -Force -ErrorAction 'Stop'
    }
}
