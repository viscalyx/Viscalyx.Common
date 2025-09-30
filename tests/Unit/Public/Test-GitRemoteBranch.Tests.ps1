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

    # Set the parameter set test cases at discovery time
    $script:parameterSetTestCases = @(
        @{
            ExpectedParameterSetName = 'Default'
            ExpectedParameters       = '[[-RemoteName] <string>] [<CommonParameters>]'
        },
        @{
            ExpectedParameterSetName = 'Name'
            ExpectedParameters       = '[-RemoteName] <string> [[-Name] <string>] [<CommonParameters>]'
        }
    )
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

Describe 'Test-GitRemoteBranch' {
    Context 'When checking parameter sets' {
        It 'Should have the correct parameters in parameter set <ExpectedParameterSetName>' -ForEach $script:parameterSetTestCases {
            $result = (Get-Command -Name 'Test-GitRemoteBranch').ParameterSets |
                Where-Object -FilterScript { $_.Name -eq $ExpectedParameterSetName } |
                Select-Object -Property @(
                    @{ Name = 'ParameterSetName'; Expression = { $_.Name } },
                    @{ Name = 'ParameterListAsString'; Expression = { $_.ToString() } }
                )

            $result.ParameterSetName | Should -Be $ExpectedParameterSetName
            $result.ParameterListAsString | Should -Be $ExpectedParameters
        }

        It 'Should have Default as the default parameter set' {
            $defaultParameterSet = (Get-Command -Name 'Test-GitRemoteBranch').DefaultParameterSet
            $defaultParameterSet | Should -Be 'Default'
        }
    }

    Context 'When checking parameter properties' {
        It 'Should have RemoteName as a non-mandatory parameter in Default parameter set' {
            $parameterInfo = (Get-Command -Name 'Test-GitRemoteBranch').Parameters['RemoteName']
            $defaultParameterSet = $parameterInfo.ParameterSets['Default']
            $defaultParameterSet.IsMandatory | Should -BeFalse
        }

        It 'Should have RemoteName as a mandatory parameter in Name parameter set' {
            $parameterInfo = (Get-Command -Name 'Test-GitRemoteBranch').Parameters['RemoteName']
            $nameParameterSet = $parameterInfo.ParameterSets['Name']
            $nameParameterSet.IsMandatory | Should -BeTrue
        }

        It 'Should have Name as a non-mandatory parameter in Name parameter set' {
            $parameterInfo = (Get-Command -Name 'Test-GitRemoteBranch').Parameters['Name']
            $nameParameterSet = $parameterInfo.ParameterSets['Name']
            $nameParameterSet.IsMandatory | Should -BeFalse
        }

        It 'Should have correct parameter types' {
            $command = Get-Command -Name 'Test-GitRemoteBranch'

            $command.Parameters['RemoteName'].ParameterType | Should -Be ([System.String])
            $command.Parameters['Name'].ParameterType | Should -Be ([System.String])
        }

        It 'Should have correct output type' {
            $outputType = (Get-Command -Name 'Test-GitRemoteBranch').OutputType
            $outputType.Type | Should -Be ([System.Boolean])
        }
    }

    Context 'When testing basic functionality without specific remote' {
        It 'Should return true when Get-GitRemoteBranch returns branches' {
            Mock -CommandName 'Get-GitRemoteBranch' -MockWith {
                return @('refs/heads/main', 'refs/heads/develop')
            }

            $result = Test-GitRemoteBranch
            $result | Should -BeTrue
            Should -Invoke -CommandName 'Get-GitRemoteBranch' -Times 1 -Exactly -ParameterFilter {
                $RemoveRefsHeads -eq $true
            }
        }

        It 'Should return false when Get-GitRemoteBranch returns no branches' {
            Mock -CommandName 'Get-GitRemoteBranch' -MockWith {
                return @()
            }

            $result = Test-GitRemoteBranch
            $result | Should -BeFalse
            Should -Invoke -CommandName 'Get-GitRemoteBranch' -Times 1 -Exactly
        }

        It 'Should return false when Get-GitRemoteBranch returns null' {
            Mock -CommandName 'Get-GitRemoteBranch' -MockWith {
                return $null
            }

            $result = Test-GitRemoteBranch
            $result | Should -BeFalse
            Should -Invoke -CommandName 'Get-GitRemoteBranch' -Times 1 -Exactly
        }
    }

    Context 'When testing with specific remote name' {
        It 'Should pass RemoteName parameter to Get-GitRemoteBranch and return true when branch exists' {
            Mock -CommandName 'Get-GitRemoteBranch' -MockWith {
                return 'refs/heads/main'
            }

            $result = Test-GitRemoteBranch -RemoteName 'origin'
            $result | Should -BeTrue
            Should -Invoke -CommandName 'Get-GitRemoteBranch' -Times 1 -Exactly -ParameterFilter {
                $RemoteName -eq 'origin' -and $RemoveRefsHeads -eq $true
            }
        }

        It 'Should return false when no branches found for specific remote' {
            Mock -CommandName 'Get-GitRemoteBranch' -MockWith {
                return $null
            }

            $result = Test-GitRemoteBranch -RemoteName 'upstream'
            $result | Should -BeFalse
            Should -Invoke -CommandName 'Get-GitRemoteBranch' -Times 1 -Exactly -ParameterFilter {
                $RemoteName -eq 'upstream' -and $RemoveRefsHeads -eq $true
            }
        }
    }

    Context 'When testing with specific remote name and branch name' {
        It 'Should pass both RemoteName and Name parameters to Get-GitRemoteBranch and return true when branch exists' {
            Mock -CommandName 'Get-GitRemoteBranch' -MockWith {
                return 'refs/heads/feature/test'
            }

            $result = Test-GitRemoteBranch -RemoteName 'origin' -Name 'feature/test'
            $result | Should -BeTrue
            Should -Invoke -CommandName 'Get-GitRemoteBranch' -Times 1 -Exactly -ParameterFilter {
                $RemoteName -eq 'origin' -and $Name -eq 'feature/test' -and $RemoveRefsHeads -eq $true
            }
        }

        It 'Should return false when specific branch does not exist' {
            Mock -CommandName 'Get-GitRemoteBranch' -MockWith {
                return $null
            }

            $result = Test-GitRemoteBranch -RemoteName 'origin' -Name 'nonexistent-branch'
            $result | Should -BeFalse
            Should -Invoke -CommandName 'Get-GitRemoteBranch' -Times 1 -Exactly -ParameterFilter {
                $RemoteName -eq 'origin' -and $Name -eq 'nonexistent-branch' -and $RemoveRefsHeads -eq $true
            }
        }

        It 'Should return true when Get-GitRemoteBranch returns multiple branches' {
            Mock -CommandName 'Get-GitRemoteBranch' -MockWith {
                return @('refs/heads/feature/test1', 'refs/heads/feature/test2')
            }

            $result = Test-GitRemoteBranch -RemoteName 'origin' -Name 'feature/*'
            $result | Should -BeTrue
            Should -Invoke -CommandName 'Get-GitRemoteBranch' -Times 1 -Exactly -ParameterFilter {
                $RemoteName -eq 'origin' -and $Name -eq 'feature/*' -and $RemoveRefsHeads -eq $true
            }
        }
    }

    Context 'When testing edge cases' {
        It 'Should handle empty string from Get-GitRemoteBranch as false' {
            Mock -CommandName 'Get-GitRemoteBranch' -MockWith {
                return ''
            }

            $result = Test-GitRemoteBranch -RemoteName 'origin'
            $result | Should -BeFalse
        }

        It 'Should handle single space from Get-GitRemoteBranch as true' {
            Mock -CommandName 'Get-GitRemoteBranch' -MockWith {
                return ' '
            }

            $result = Test-GitRemoteBranch -RemoteName 'origin'
            $result | Should -BeTrue
        }

        It 'Should handle array with empty string as false' {
            Mock -CommandName 'Get-GitRemoteBranch' -MockWith {
                return @('')
            }

            $result = Test-GitRemoteBranch -RemoteName 'origin'
            $result | Should -BeFalse
        }

        It 'Should handle array with null values as false' {
            Mock -CommandName 'Get-GitRemoteBranch' -MockWith {
                return @($null)
            }

            $result = Test-GitRemoteBranch -RemoteName 'origin'
            $result | Should -BeFalse
        }
    }

    Context 'When testing parameter validation' {
        It 'Should accept valid RemoteName values' {
            Mock -CommandName 'Get-GitRemoteBranch' -MockWith { return 'refs/heads/main' }

            $null = Test-GitRemoteBranch -RemoteName 'origin'
            $null = Test-GitRemoteBranch -RemoteName 'upstream'
            $null = Test-GitRemoteBranch -RemoteName 'remote-with-dashes'
        }

        It 'Should accept valid Name values' {
            Mock -CommandName 'Get-GitRemoteBranch' -MockWith { return 'refs/heads/main' }

            $null = Test-GitRemoteBranch -RemoteName 'origin' -Name 'main'
            $null = Test-GitRemoteBranch -RemoteName 'origin' -Name 'feature/test'
            $null = Test-GitRemoteBranch -RemoteName 'origin' -Name 'feature/*'
        }

        It 'Should not accept null or empty RemoteName when Name is specified' {
            { Test-GitRemoteBranch -RemoteName '' -Name 'main' } | Should -Throw
            { Test-GitRemoteBranch -RemoteName $null -Name 'main' } | Should -Throw
        }

        It 'Should not accept null or empty Name when specified' {
            { Test-GitRemoteBranch -RemoteName 'origin' -Name '' } | Should -Throw
            { Test-GitRemoteBranch -RemoteName 'origin' -Name $null } | Should -Throw
        }
    }
}
