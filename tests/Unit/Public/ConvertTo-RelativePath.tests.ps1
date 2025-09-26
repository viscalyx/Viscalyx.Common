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

    Context 'When checking command structure' {
        It 'Should have the correct parameters in parameter set <ExpectedParameterSetName>' -ForEach @(
            @{
                ExpectedParameterSetName = '__AllParameterSets'
                ExpectedParameters       = '[-AbsolutePath] <string> [[-CurrentLocation] <string>] [-DirectorySeparator <char>] [<CommonParameters>]'
            }
        ) {
            $result = (Get-Command -Name 'ConvertTo-RelativePath').ParameterSets |
                Where-Object -FilterScript { $_.Name -eq $ExpectedParameterSetName } |
                Select-Object -Property @(
                    @{ Name = 'ParameterSetName'; Expression = { $_.Name } },
                    @{ Name = 'ParameterListAsString'; Expression = { $_.ToString() } }
                )
            $result.ParameterSetName | Should -Be $ExpectedParameterSetName
            $result.ParameterListAsString | Should -Be $ExpectedParameters
        }

        It 'Should have AbsolutePath as a mandatory parameter' {
            $parameterInfo = (Get-Command -Name 'ConvertTo-RelativePath').Parameters['AbsolutePath']
            $parameterInfo.Attributes.Mandatory | Should -BeTrue
        }
    }

    It 'Should convert absolute path to relative path when CurrentLocation is provided' {
        $result = ConvertTo-RelativePath -AbsolutePath '/source/Viscalyx.Common/source/Public/ConvertTo-RelativePath.ps1' -CurrentLocation '/source/Viscalyx.Common'
        $result | Should -Be ('.{0}source{0}Public{0}ConvertTo-RelativePath.ps1' -f [System.IO.Path]::DirectorySeparatorChar)
    }

    It 'Should convert absolute path to relative path using Get-Location when CurrentLocation is not provided' {
        $result = ConvertTo-RelativePath -AbsolutePath '/source/Viscalyx.Common/source/Public/ConvertTo-RelativePath.ps1'
        $result | Should -Be ('.{0}source{0}Public{0}ConvertTo-RelativePath.ps1' -f [System.IO.Path]::DirectorySeparatorChar)
    }

    It 'Should return normalized absolute path when it does not start with CurrentLocation' {
        $result = ConvertTo-RelativePath -AbsolutePath '/other/path/ConvertTo-RelativePath.ps1' -CurrentLocation '/source/Viscalyx.Common'
        $result | Should -Be ('{0}other{0}path{0}ConvertTo-RelativePath.ps1' -f [System.IO.Path]::DirectorySeparatorChar)
    }

    It 'Should work with pipeline input' {
        $result = '/source/Viscalyx.Common/source/Public/ConvertTo-RelativePath.ps1' | ConvertTo-RelativePath -CurrentLocation '/source/Viscalyx.Common'
        $result | Should -Be ('.{0}source{0}Public{0}ConvertTo-RelativePath.ps1' -f [System.IO.Path]::DirectorySeparatorChar)
    }

    It 'Should handle mixed directory separators correctly' {
        $mixedPath = '/source\Viscalyx.Common/source/Public\ConvertTo-RelativePath.ps1'
        $result = ConvertTo-RelativePath -AbsolutePath $mixedPath -CurrentLocation '/source/Viscalyx.Common'
        $result | Should -Be ('.{0}source{0}Public{0}ConvertTo-RelativePath.ps1' -f [System.IO.Path]::DirectorySeparatorChar)
    }

    It 'Should handle mixed separators in CurrentLocation' {
        $result = ConvertTo-RelativePath -AbsolutePath '/source/Viscalyx.Common/source/Public/ConvertTo-RelativePath.ps1' -CurrentLocation '/source\Viscalyx.Common'
        $result | Should -Be ('.{0}source{0}Public{0}ConvertTo-RelativePath.ps1' -f [System.IO.Path]::DirectorySeparatorChar)
    }

    It 'Should handle mixed separators in both paths' {
        $mixedAbsolute = '/source\Viscalyx.Common\source/Public/ConvertTo-RelativePath.ps1'
        $mixedCurrent = '\source/Viscalyx.Common'
        $result = ConvertTo-RelativePath -AbsolutePath $mixedAbsolute -CurrentLocation $mixedCurrent
        $result | Should -Be ('.{0}source{0}Public{0}ConvertTo-RelativePath.ps1' -f [System.IO.Path]::DirectorySeparatorChar)
    }

    It 'Should handle empty CurrentLocation parameter correctly' {
        Mock -CommandName Get-Location -MockWith { @{ Path = '/source/Viscalyx.Common' } }
        $result = ConvertTo-RelativePath -AbsolutePath '/source/Viscalyx.Common/source/Public/ConvertTo-RelativePath.ps1' -CurrentLocation ''
        $result | Should -Be ('.{0}source{0}Public{0}ConvertTo-RelativePath.ps1' -f [System.IO.Path]::DirectorySeparatorChar)
    }

    Context 'When testing cross-platform path handling' {
        It 'Should normalize Windows-style paths' {
            $windowsPath = 'C:\source\Viscalyx.Common\source\Public\ConvertTo-RelativePath.ps1'
            $currentLocation = 'C:\source\Viscalyx.Common'
            $result = ConvertTo-RelativePath -AbsolutePath $windowsPath -CurrentLocation $currentLocation
            $result | Should -Be ('.{0}source{0}Public{0}ConvertTo-RelativePath.ps1' -f [System.IO.Path]::DirectorySeparatorChar)
        }

        It 'Should normalize Unix-style paths' {
            $unixPath = '/home/user/projects/source/Public/ConvertTo-RelativePath.ps1'
            $currentLocation = '/home/user/projects'
            $result = ConvertTo-RelativePath -AbsolutePath $unixPath -CurrentLocation $currentLocation
            $result | Should -Be ('.{0}source{0}Public{0}ConvertTo-RelativePath.ps1' -f [System.IO.Path]::DirectorySeparatorChar)
        }

        It 'Should normalize mixed separators and handle literal backslashes in path names' {
            # Test with mixed separators where backslashes might be part of filename/folder names
            $mixedPath = '/home/user/some\folder/with\backslashes/file.txt'
            $currentLocation = '/home/user'
            $result = ConvertTo-RelativePath -AbsolutePath $mixedPath -CurrentLocation $currentLocation
            # All separators get normalized, including those that might be literal backslashes
            $result | Should -Be ('.{0}some{0}folder{0}with{0}backslashes{0}file.txt' -f [System.IO.Path]::DirectorySeparatorChar)
        }

        It 'Should return normalized path when paths do not share common root' {
            $absolutePath = '/usr/local/bin/someapp'
            $currentLocation = '/home/user/projects'
            $result = ConvertTo-RelativePath -AbsolutePath $absolutePath -CurrentLocation $currentLocation
            $result | Should -Be ('{0}usr{0}local{0}bin{0}someapp' -f [System.IO.Path]::DirectorySeparatorChar)
        }
    }

    Context 'When testing path normalization edge cases' {
        It 'Should normalize UNC paths' -Skip:(-not $IsWindows) {
            $uncPath = '\\server\share\folder\file.txt'
            $currentLocation = '\\server\share'
            $result = ConvertTo-RelativePath -AbsolutePath $uncPath -CurrentLocation $currentLocation
            $result | Should -Be ('.{0}folder{0}file.txt' -f [System.IO.Path]::DirectorySeparatorChar)
        }

        It 'Should handle UNC paths that do not match current location' -Skip:(-not $IsWindows) {
            $uncPath = '\\server1\share1\folder\file.txt'
            $currentLocation = '\\server2\share2'
            $result = ConvertTo-RelativePath -AbsolutePath $uncPath -CurrentLocation $currentLocation
            $result | Should -Be ('{0}{0}server1{0}share1{0}folder{0}file.txt' -f [System.IO.Path]::DirectorySeparatorChar)
        }

        It 'Should normalize paths with multiple consecutive separators' {
            $pathWithDoubleSeparators = '/home//user///projects//file.txt'
            $currentLocation = '/home/user'
            $result = ConvertTo-RelativePath -AbsolutePath $pathWithDoubleSeparators -CurrentLocation $currentLocation
            # Paths don't match after normalization so returns original absolute path
            $result | Should -Be '/home//user///projects//file.txt'
        }

        It 'Should handle empty string inputs gracefully' {
            # Empty string should be handled by parameter validation
            { ConvertTo-RelativePath -AbsolutePath '' -CurrentLocation '/home/user' } | Should -Throw
        }

        It 'Should handle paths with only separators' {
            $result = ConvertTo-RelativePath -AbsolutePath '///' -CurrentLocation '/'
            $result | Should -Be ('.{0}' -f [System.IO.Path]::DirectorySeparatorChar)
        }
    }
}
