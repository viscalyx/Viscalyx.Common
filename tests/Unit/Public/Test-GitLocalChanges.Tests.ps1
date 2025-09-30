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
                ExpectedParameters       = '[<CommonParameters>]'
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

            $result | Should -BeFalse
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

            $result | Should -BeTrue
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

            $result | Should -BeTrue
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

            $result | Should -BeTrue
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

    Context 'When git command fails' {
        BeforeAll {
            Mock -CommandName 'git' -MockWith {
                if ($args[0] -eq 'status' -and $args[1] -eq '--porcelain')
                {
                    $global:LASTEXITCODE = 1
                    return $null
                }
                else
                {
                    throw "Mock git unexpected args: $($args -join ' ')"
                }
            }

            Mock -CommandName 'Write-Error'

            $mockErrorMessage = InModuleScope -ScriptBlock {
                $script:localizedData.Test_GitLocalChanges_GitFailed
            }
        }

        AfterEach {
            $global:LASTEXITCODE = 0
        }

        It 'Should have a localized error message' {
            $mockErrorMessage | Should -Not -BeNullOrEmpty -Because 'The error message should have been localized, and shall not be empty'
        }

        It 'Should return null when git status fails' {
            $result = Test-GitLocalChanges

            $result | Should -BeNullOrEmpty
        }

        It 'Should call Write-Error with localized message when git fails' {
            Test-GitLocalChanges

            Should -Invoke -CommandName 'Write-Error' -ParameterFilter {
                $Message -eq $mockErrorMessage -and
                $Category -eq 'InvalidOperation' -and
                $ErrorId -eq 'TGLC0001'
            } -Exactly -Times 1
        }

        It 'Should call git status with correct parameters even when it fails' {
            Test-GitLocalChanges

            Should -Invoke -CommandName 'git' -ParameterFilter {
                $args[0] -eq 'status' -and $args[1] -eq '--porcelain'
            } -Exactly -Times 1
        }
    }
}
