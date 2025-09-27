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

Describe 'Test-GitLocalChanges' {
    Context 'When checking parameter sets' {
        It 'Should have the correct parameters in parameter set <ExpectedParameterSetName>' -ForEach @(
            @{
                ExpectedParameterSetName = '__AllParameterSets'
                ExpectedParameters = '[<CommonParameters>]'
            }
        ) {
            $result = (Get-Command -Name 'Test-GitLocalChanges').ParameterSets | Where-Object -FilterScript { $_.Name -eq $ExpectedParameterSetName }

            $result.ToString() | Should -Be $ExpectedParameters
        }
    }

    Context 'When there are no local changes' {
        BeforeAll {
            Mock -CommandName 'git' -MockWith {
                return $null
            }
        }

        It 'Should return false when git status returns empty' {
            $result = Test-GitLocalChanges

            $result | Should -Be $false
        }

        It 'Should call git status with correct parameters' {
            Test-GitLocalChanges

            Should -Invoke -CommandName 'git' -ParameterFilter {
                $args[0] -eq 'status' -and $args[1] -eq '--porcelain'
            } -Exactly -Times 1
        }
    }

    Context 'When there are local changes' {
        BeforeAll {
            Mock -CommandName 'git' -MockWith {
                return @('M  file1.txt', 'A  file2.txt')
            }
        }

        It 'Should return true when git status returns changes' {
            $result = Test-GitLocalChanges

            $result | Should -Be $true
        }

        It 'Should call git status with correct parameters' {
            Test-GitLocalChanges

            Should -Invoke -CommandName 'git' -ParameterFilter {
                $args[0] -eq 'status' -and $args[1] -eq '--porcelain'
            } -Exactly -Times 1
        }
    }

    Context 'When there are staged changes' {
        BeforeAll {
            Mock -CommandName 'git' -MockWith {
                return @('A  newfile.txt')
            }
        }

        It 'Should return true for staged changes' {
            $result = Test-GitLocalChanges

            $result | Should -Be $true
        }
    }

    Context 'When there are unstaged changes' {
        BeforeAll {
            Mock -CommandName 'git' -MockWith {
                return @(' M modifiedfile.txt')
            }
        }

        It 'Should return true for unstaged changes' {
            $result = Test-GitLocalChanges

            $result | Should -Be $true
        }
    }

    Context 'When testing return type' {
        BeforeAll {
            Mock -CommandName 'git' -MockWith {
                return $null
            }
        }

        It 'Should return a boolean value' {
            $result = Test-GitLocalChanges

            $result | Should -BeOfType [System.Boolean]
        }
    }
}
