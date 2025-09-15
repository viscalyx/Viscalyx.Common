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

Describe 'Disable-CursorShortcutCode' {
    It 'Should have the correct parameters in parameter set <ExpectedParameterSetName>' -ForEach @(
        @{
            ExpectedParameterSetName = '__AllParameterSets'
            ExpectedParameters = '[<CommonParameters>]'
        }
    ) {
        $result = (Get-Command -Name 'Disable-CursorShortcutCode').ParameterSets |
            Where-Object -FilterScript { $_.Name -eq $ExpectedParameterSetName } |
            Select-Object -Property @(
                @{ Name = 'ParameterSetName'; Expression = { $_.Name } },
                @{ Name = 'ParameterListAsString'; Expression = { $_.ToString() } }
            )
        $result.ParameterSetName | Should -Be $ExpectedParameterSetName
        $result.ParameterListAsString | Should -Be $ExpectedParameters
    }

    BeforeEach {
        # Mock Write-Information to capture information messages
        Mock -CommandName Write-Information

        # Mock Test-Path and Rename-Item
        Mock -CommandName Test-Path
        Mock -CommandName Rename-Item
    }

    Context 'When Cursor path is found in PATH variable' {
        BeforeAll {
            # Set up environment variable with Cursor path
            $script:originalPath = $env:Path
            $env:Path = 'C:\Windows\System32;C:\Users\User\AppData\Local\Programs\Cursor\resources\app\bin;C:\Program Files\Git\cmd'
        }

        AfterAll {
            # Restore original PATH
            $env:Path = $script:originalPath
        }

        Context 'When both code files exist' {
            BeforeAll {
                Mock -CommandName Test-Path -MockWith { $true }
            }

            It 'Should rename both code.cmd and code files' {
                Disable-CursorShortcutCode

                Should -Invoke -CommandName Test-Path -Exactly -Times 2
                Should -Invoke -CommandName Rename-Item -Exactly -Times 2
                Should -Invoke -CommandName Rename-Item -ParameterFilter { $NewName -eq 'code.cmd.old' } -Exactly -Times 1
                Should -Invoke -CommandName Rename-Item -ParameterFilter { $NewName -eq 'code.old' } -Exactly -Times 1
                Should -Invoke -CommandName Write-Information -ParameterFilter { $MessageData -eq 'Renamed code.cmd to code.cmd.old' } -Exactly -Times 1
                Should -Invoke -CommandName Write-Information -ParameterFilter { $MessageData -eq 'Renamed code to code.old' } -Exactly -Times 1
            }
        }

        Context 'When only code.cmd file exists' {
            BeforeAll {
                Mock -CommandName Test-Path -MockWith {
                    param($Path)
                    return $Path -like '*code.cmd'
                }
            }

            It 'Should rename only code.cmd file' {
                Disable-CursorShortcutCode

                Should -Invoke -CommandName Test-Path -Exactly -Times 2
                Should -Invoke -CommandName Rename-Item -Exactly -Times 1
                Should -Invoke -CommandName Rename-Item -ParameterFilter { $NewName -eq 'code.cmd.old' } -Exactly -Times 1
                Should -Invoke -CommandName Write-Information -ParameterFilter { $MessageData -eq 'Renamed code.cmd to code.cmd.old' } -Exactly -Times 1
                Should -Invoke -CommandName Write-Information -ParameterFilter { $MessageData -eq "File 'code' not found in the Cursor path." } -Exactly -Times 1
            }
        }

        Context 'When no code files exist' {
            BeforeAll {
                Mock -CommandName Test-Path -MockWith { $false }
            }

            It 'Should not rename any files and display appropriate messages' {
                Disable-CursorShortcutCode

                Should -Invoke -CommandName Test-Path -Exactly -Times 2
                Should -Invoke -CommandName Rename-Item -Times 0
                Should -Invoke -CommandName Write-Information -ParameterFilter { $MessageData -eq "File 'code.cmd' not found in the Cursor path." } -Exactly -Times 1
                Should -Invoke -CommandName Write-Information -ParameterFilter { $MessageData -eq "File 'code' not found in the Cursor path." } -Exactly -Times 1
            }
        }
    }

    Context 'When Cursor path is not found in PATH variable' {
        BeforeAll {
            # Set up environment variable without Cursor path
            $script:originalPath = $env:Path
            $env:Path = 'C:\Windows\System32;C:\Program Files\Git\cmd'
        }

        AfterAll {
            # Restore original PATH
            $env:Path = $script:originalPath
        }

        It 'Should display message that Cursor path was not found' {
            Disable-CursorShortcutCode

            Should -Invoke -CommandName Test-Path -Times 0
            Should -Invoke -CommandName Rename-Item -Times 0
            Should -Invoke -CommandName Write-Information -ParameterFilter { $MessageData -eq 'Cursor path not found in the PATH variable.' } -Exactly -Times 1
        }
    }
}
