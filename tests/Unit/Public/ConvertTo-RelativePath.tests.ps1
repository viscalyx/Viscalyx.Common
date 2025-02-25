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

Describe 'ConvertTo-RelativePath' {
    BeforeAll {
        # Mock Get-Location to return a specific path
        Mock -CommandName Get-Location -MockWith { @{ Path = '/source/Viscalyx.Common' } }
    }

    It 'Should convert absolute path to relative path when CurrentLocation is provided' {
        $result = ConvertTo-RelativePath -AbsolutePath '/source/Viscalyx.Common/source/Public/ConvertTo-RelativePath.ps1' -CurrentLocation '/source/Viscalyx.Common'
        $result | Should -Be ('.{0}source{0}Public{0}ConvertTo-RelativePath.ps1' -f [System.IO.Path]::DirectorySeparatorChar)
    }

    It 'Should convert absolute path to relative path using Get-Location when CurrentLocation is not provided' {
        $result = ConvertTo-RelativePath -AbsolutePath '/source/Viscalyx.Common/source/Public/ConvertTo-RelativePath.ps1'
        $result | Should -Be ('.{0}source{0}Public{0}ConvertTo-RelativePath.ps1' -f [System.IO.Path]::DirectorySeparatorChar)
    }

    Context 'When passing a path on Linux or MacOS that does not start with CurrentLocation' -Skip:($PSEdition -eq 'Desktop' -or $IsWindows) {
        It 'Should return the absolute path as it was passed' {
            $result = ConvertTo-RelativePath -AbsolutePath '/other/path/ConvertTo-RelativePath.ps1' -CurrentLocation '/source/Viscalyx.Common'
            $result | Should -Be ('{0}other{0}path{0}ConvertTo-RelativePath.ps1' -f [System.IO.Path]::DirectorySeparatorChar)
        }
    }

    Context 'When passing a path on Windows that does not start with CurrentLocation' -Skip:($IsLinux -or $IsMacOS) {
        It 'Should return the absolute path as it was passed' {
            $result = ConvertTo-RelativePath -AbsolutePath '/other/path/ConvertTo-RelativePath.ps1' -CurrentLocation '/source/Viscalyx.Common'
            $result | Should -Be '/other/path/ConvertTo-RelativePath.ps1'
        }
    }
}
