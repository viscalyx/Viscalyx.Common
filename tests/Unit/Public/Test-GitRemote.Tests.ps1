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

Describe 'Test-GitRemote' {
    Context 'When checking command structure' {
        It 'Should have correct command syntax' {
            $command = Get-Command -Name 'Test-GitRemote'
            $command.Parameters.Keys | Should -Contain 'Name'
            $command.OutputType[0].Type | Should -Be ([System.Boolean])
        }

        It 'Should have Name as a mandatory parameter' {
            $parameterInfo = (Get-Command -Name 'Test-GitRemote').Parameters['Name']
            $parameterInfo.Attributes | Where-Object { $_ -is [System.Management.Automation.ParameterAttribute] } |
                ForEach-Object { $_.Mandatory } | Should -Contain $true
        }

        It 'Should have Name parameter at position 0' {
            $parameterInfo = (Get-Command -Name 'Test-GitRemote').Parameters['Name']
            $parameterAttribute = $parameterInfo.Attributes | Where-Object { $_ -is [System.Management.Automation.ParameterAttribute] }
            $parameterAttribute.Position | Should -Be 0
        }

        It 'Should have correct parameter type for Name' {
            $command = Get-Command -Name 'Test-GitRemote'
            $command.Parameters['Name'].ParameterType | Should -Be ([System.String])
        }
    }

    Context 'When testing remote existence' {
        It 'Should return true when remote exists' {
            Mock -CommandName 'Get-GitRemote' -MockWith {
                return 'origin'
            }

            InModuleScope -ScriptBlock {
                $result = Test-GitRemote -Name 'origin'
                $result | Should -BeTrue
                $result | Should -BeOfType [System.Boolean]
                Should -Invoke -CommandName 'Get-GitRemote' -Times 1 -Exactly -ParameterFilter {
                    $Name -eq 'origin'
                }
            }
        }

        It 'Should return false when remote does not exist' {
            Mock -CommandName 'Get-GitRemote' -MockWith {
                return $null
            }

            InModuleScope -ScriptBlock {
                $result = Test-GitRemote -Name 'nonexistent'
                $result | Should -BeFalse
                $result | Should -BeOfType [System.Boolean]
                Should -Invoke -CommandName 'Get-GitRemote' -Times 1 -Exactly -ParameterFilter {
                    $Name -eq 'nonexistent'
                }
            }
        }

        It 'Should return false when Get-GitRemote returns empty string' {
            Mock -CommandName 'Get-GitRemote' -MockWith {
                return ''
            }

            InModuleScope -ScriptBlock {
                $result = Test-GitRemote -Name 'empty'
                $result | Should -BeFalse
                $result | Should -BeOfType [System.Boolean]
            }
        }

        It 'Should return false when Get-GitRemote returns empty array' {
            Mock -CommandName 'Get-GitRemote' -MockWith {
                return @()
            }

            InModuleScope -ScriptBlock {
                $result = Test-GitRemote -Name 'empty'
                $result | Should -BeFalse
                $result | Should -BeOfType [System.Boolean]
            }
        }

        It 'Should return true when Get-GitRemote returns the requested remote name' {
            Mock -CommandName 'Get-GitRemote' -MockWith {
                return 'upstream'
            }

            InModuleScope -ScriptBlock {
                $result = Test-GitRemote -Name 'upstream'
                $result | Should -BeTrue
                $result | Should -BeOfType [System.Boolean]
            }
        }
    }

    Context 'When validating parameter input' {
        It 'Should accept valid remote name strings' {
            Mock -CommandName 'Get-GitRemote' -MockWith { return 'validname' }

            InModuleScope -ScriptBlock {
                { Test-GitRemote -Name 'validname' } | Should -Not -Throw
                { Test-GitRemote -Name 'origin' } | Should -Not -Throw
                { Test-GitRemote -Name 'upstream' } | Should -Not -Throw
                { Test-GitRemote -Name 'my-remote' } | Should -Not -Throw
                { Test-GitRemote -Name 'remote_with_underscores' } | Should -Not -Throw
            }
        }

        It 'Should work with positional parameter' {
            Mock -CommandName 'Get-GitRemote' -MockWith { return 'origin' }

            InModuleScope -ScriptBlock {
                $result = Test-GitRemote 'origin'
                $result | Should -BeTrue
                Should -Invoke -CommandName 'Get-GitRemote' -Times 1 -Exactly -ParameterFilter {
                    $Name -eq 'origin'
                }
            }
        }
    }

    Context 'When handling different return types from Get-GitRemote' {
        It 'Should handle string return value correctly' {
            Mock -CommandName 'Get-GitRemote' -MockWith {
                return [string]'origin'
            }

            InModuleScope -ScriptBlock {
                $result = Test-GitRemote -Name 'origin'
                $result | Should -BeTrue
                $result | Should -BeOfType [System.Boolean]
            }
        }

        It 'Should handle array with single element correctly' {
            Mock -CommandName 'Get-GitRemote' -MockWith {
                return @('origin')
            }

            InModuleScope -ScriptBlock {
                $result = Test-GitRemote -Name 'origin'
                $result | Should -BeTrue
                $result | Should -BeOfType [System.Boolean]
            }
        }

        It 'Should handle null return value correctly' {
            Mock -CommandName 'Get-GitRemote' -MockWith {
                return $null
            }

            InModuleScope -ScriptBlock {
                $result = Test-GitRemote -Name 'nonexistent'
                $result | Should -BeFalse
                $result | Should -BeOfType [System.Boolean]
            }
        }
    }
}
