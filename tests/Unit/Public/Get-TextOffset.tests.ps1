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

Describe 'Get-TextOffset' {
    BeforeEach {
        $testFilePath = Join-Path -Path $TestDrive -ChildPath 'TestFile.txt'

        # Create a test file with some content
        @'
This is a test file.
It contains some text.
The text includes multiple lines.
'@ | Out-File -FilePath $testFilePath -Encoding UTF8
    }

    AfterEach {
        # Remove the test file
        Remove-Item -Path $testFilePath -Force
    }

    Context 'When the text is found in the file' {
        It 'Should return the correct start and end offsets' {
            $textToFind = 'test file'
            $result = Get-TextOffset -FilePath $testFilePath -TextToFind $textToFind

            $result.ScriptFile | Should -Be $testFilePath
            $result.StartOffset | Should -Be 10
            $result.EndOffset | Should -Be 19
        }
    }

    Context 'When the text is not found in the file' {
        BeforeAll {
            Mock -CommandName Write-Warning
        }

        It 'Should return $null and write a warning' {
            $textToFind = 'NonExistentText'
            $result = Get-TextOffset -FilePath $testFilePath -TextToFind $textToFind

            $result | Should -BeNullOrEmpty

            Should -Invoke -CommandName Write-Warning -Exactly 1 -Scope It
        }
    }

    Context 'When the file does not exist' {
        It 'Should throw an exception' {
            $filePath = 'NonExistentFile.txt'
            $textToFind = 'SomeText'

            { Get-TextOffset -FilePath $filePath -TextToFind $textToFind } | Should -Throw
        }
    }

    Context 'When the text contains carriage returns and newlines' {
        It 'Should normalize line endings and find the text' {
            $textToFind = "It contains some text.`r`n"
            $result = Get-TextOffset -FilePath $testFilePath -TextToFind $textToFind
            $result.StartOffset | Should -Be 21
            $result.EndOffset | Should -Be 44
        }
    }
}
