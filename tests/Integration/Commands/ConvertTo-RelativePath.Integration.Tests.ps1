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
}

Describe 'ConvertTo-RelativePath' -Tag 'Integration' {
    Context 'When converting paths in real filesystem' {
        It 'Should convert absolute path to relative path when the path exists under current location' {
            $currentDir = Get-Location
            $testPath = Join-Path -Path $currentDir.Path -ChildPath 'source'

            $result = ConvertTo-RelativePath -AbsolutePath $testPath -CurrentLocation $currentDir.Path -ErrorAction 'Stop'

            $expected = '.{0}source' -f [System.IO.Path]::DirectorySeparatorChar
            $result | Should -Be $expected
        }

        It 'Should return original path when absolute path does not start with current location' {
            $currentDir = Get-Location
            $testPath = if ($IsWindows -or $PSVersionTable.PSEdition -eq 'Desktop')
            {
                'C:\NonExistent\Path'
            }
            else
            {
                '/nonexistent/path'
            }

            $result = ConvertTo-RelativePath -AbsolutePath $testPath -CurrentLocation $currentDir.Path -ErrorAction 'Stop'

            $result | Should -Be $testPath
        }

        It 'Should work with pipeline input' {
            $currentDir = Get-Location
            $testPath = Join-Path -Path $currentDir.Path -ChildPath 'tests'

            $result = $testPath | ConvertTo-RelativePath -CurrentLocation $currentDir.Path -ErrorAction 'Stop'

            $expected = '.{0}tests' -f [System.IO.Path]::DirectorySeparatorChar
            $result | Should -Be $expected
        }

        It 'Should use Get-Location when CurrentLocation is not specified' {
            $testPath = Join-Path -Path (Get-Location).Path -ChildPath 'source'

            $result = ConvertTo-RelativePath -AbsolutePath $testPath -ErrorAction 'Stop'

            $expected = '.{0}source' -f [System.IO.Path]::DirectorySeparatorChar
            $result | Should -Be $expected
        }

        It 'Should handle mixed directory separators correctly' {
            $currentDir = Get-Location
            $mixedPath = $currentDir.Path + '/source\Public'

            $result = ConvertTo-RelativePath -AbsolutePath $mixedPath -CurrentLocation $currentDir.Path -ErrorAction 'Stop'

            $expected = '.{0}source{0}Public' -f [System.IO.Path]::DirectorySeparatorChar
            $result | Should -Be $expected
        }

        It 'Should handle deeply nested paths correctly' {
            $currentDir = Get-Location
            $deepPath = Join-Path -Path $currentDir.Path -ChildPath 'source' |
                Join-Path -ChildPath 'Public' |
                Join-Path -ChildPath 'ConvertTo-RelativePath.ps1'

            $result = ConvertTo-RelativePath -AbsolutePath $deepPath -CurrentLocation $currentDir.Path -ErrorAction 'Stop'

            $expected = '.{0}source{0}Public{0}ConvertTo-RelativePath.ps1' -f [System.IO.Path]::DirectorySeparatorChar
            $result | Should -Be $expected
        }
    }
}
