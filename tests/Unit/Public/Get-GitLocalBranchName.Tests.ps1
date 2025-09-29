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

    # Test data for parameter set validation
    $script:parameterSetTestCases = @(
        @{
            ExpectedParameterSetName = '__AllParameterSets'
            ExpectedParameters = '[[-Name] <string>] [-Current] [<CommonParameters>]'
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

Describe 'Get-GitLocalBranchName' {
    Context 'When command has correct parameter sets' {
        It 'Should have the correct parameters in parameter set <ExpectedParameterSetName>' -ForEach $script:parameterSetTestCases {
            $result = (Get-Command -Name 'Get-GitLocalBranchName').ParameterSets |
                Where-Object -FilterScript { $_.Name -eq $ExpectedParameterSetName } |
                Select-Object -Property @(
                    @{ Name = 'ParameterSetName'; Expression = { $_.Name } },
                    @{ Name = 'ParameterListAsString'; Expression = { $_.ToString() } }
                )

            $result.ParameterSetName | Should -Be $ExpectedParameterSetName
            $result.ParameterListAsString | Should -Be $ExpectedParameters
        }

        It 'Should have __AllParameterSets as the default parameter set' {
            $defaultParameterSet = (Get-Command -Name 'Get-GitLocalBranchName').DefaultParameterSet
            $defaultParameterSet | Should -BeNullOrEmpty
        }
    }

    Context 'When command has correct parameter properties' {
        It 'Should have Name as a non-mandatory parameter' {
            $parameterInfo = (Get-Command -Name 'Get-GitLocalBranchName').Parameters['Name']
            $parameterInfo.Attributes.Mandatory | Should -BeFalse
        }

        It 'Should have Current as a non-mandatory parameter' {
            $parameterInfo = (Get-Command -Name 'Get-GitLocalBranchName').Parameters['Current']
            $parameterInfo.Attributes.Mandatory | Should -BeFalse
        }

        It 'Should have correct parameter types' {
            $command = Get-Command -Name 'Get-GitLocalBranchName'
            
            $command.Parameters['Name'].ParameterType | Should -Be ([System.String])
            $command.Parameters['Current'].ParameterType | Should -Be ([System.Management.Automation.SwitchParameter])
        }
    }

    Context 'When testing localized strings' {
        It 'Should have proper localized error messages' {
            InModuleScope -ScriptBlock {
                $script:localizedData.Get_GitLocalBranchName_Failed | Should -Match 'Failed to get the name of the local branch.*Make sure git repository is accessible'
            }
        }
    }

    Context 'When getting current branch' {
        It 'Should call git rev-parse --abbrev-ref HEAD when Current parameter is used' {
            Mock -CommandName 'git' -MockWith {
                return 'main'
            }
            
            $global:LASTEXITCODE = 0
            
            $result = Get-GitLocalBranchName -Current

            Should -Invoke -CommandName 'git' -ParameterFilter { 
                $args -contains 'rev-parse' -and $args -contains '--abbrev-ref' -and $args -contains 'HEAD'
            } -Times 1 -Exactly
            
            $result | Should -Be 'main'
        }

        It 'Should return the current branch name successfully' {
            Mock -CommandName 'git' -MockWith {
                return 'feature/new-feature'
            }
            
            $global:LASTEXITCODE = 0
            
            $result = Get-GitLocalBranchName -Current

            $result | Should -Be 'feature/new-feature'
        }
    }

    Context 'When getting branch by name' {
        It 'Should call git branch --format with specific name when Name parameter is provided' {
            InModuleScope -ScriptBlock {
                Mock -CommandName 'git' -MockWith {
                    return 'main'
                }
                
                $global:LASTEXITCODE = 0
                
                $result = Get-GitLocalBranchName -Name 'main'

                Should -Invoke -CommandName 'git' -ParameterFilter { 
                    $args -contains 'branch' -and $args -contains '--format=%(refname:short)' -and $args -contains '--list' -and $args -contains 'main'
                } -Times 1 -Exactly
                
                $result | Should -Be 'main'
            }
        }

        It 'Should support wildcard patterns in Name parameter' {
            InModuleScope -ScriptBlock {
                Mock -CommandName 'git' -MockWith {
                    return @('feature/branch1', 'feature/branch2')
                }
                
                $global:LASTEXITCODE = 0
                
                $result = Get-GitLocalBranchName -Name 'feature/*'

                Should -Invoke -CommandName 'git' -ParameterFilter { 
                    $args -contains 'branch' -and $args -contains '--format=%(refname:short)' -and $args -contains '--list' -and $args -contains 'feature/*'
                } -Times 1 -Exactly
                
                $result | Should -Be @('feature/branch1', 'feature/branch2')
            }
        }
    }

    Context 'When getting all branches' {
        It 'Should call git branch --format --list without name when no parameters are provided' {
            InModuleScope -ScriptBlock {
                Mock -CommandName 'git' -MockWith {
                    return @('main', 'develop', 'feature/test')
                }
                
                $global:LASTEXITCODE = 0
                
                $result = Get-GitLocalBranchName

                Should -Invoke -CommandName 'git' -ParameterFilter { 
                    $args -contains 'branch' -and $args -contains '--format=%(refname:short)' -and $args -contains '--list' -and $args.Count -eq 3
                } -Times 1 -Exactly
                
                $result | Should -Be @('main', 'develop', 'feature/test')
            }
        }
    }

    Context 'When git command fails' {
        It 'Should handle git command errors gracefully when getting current branch' {
            InModuleScope -ScriptBlock {
                Mock -CommandName 'git' -MockWith {
                    return $null
                }
                
                Mock -CommandName 'Write-Error' -MockWith { 
                    Write-Output "Mocked error"
                }
                
                # Simulate LASTEXITCODE failure
                $global:LASTEXITCODE = 128
                
                $result = Get-GitLocalBranchName -Current -WarningAction SilentlyContinue -ErrorAction SilentlyContinue

                Should -Invoke -CommandName 'Write-Error' -Times 1 -Exactly
            }
        }

        It 'Should handle git command errors gracefully when getting branch by name' {
            InModuleScope -ScriptBlock {
                Mock -CommandName 'git' -MockWith {
                    return $null
                }
                
                Mock -CommandName 'Write-Error' -MockWith { 
                    Write-Output "Mocked error"
                }
                
                # Simulate LASTEXITCODE failure
                $global:LASTEXITCODE = 128
                
                $result = Get-GitLocalBranchName -Name 'nonexistent' -WarningAction SilentlyContinue -ErrorAction SilentlyContinue

                Should -Invoke -CommandName 'Write-Error' -Times 1 -Exactly
            }
        }

        It 'Should write correct error message when git fails' {
            InModuleScope -ScriptBlock {
                Mock -CommandName 'git' -MockWith {
                    return $null
                }
                
                Mock -CommandName 'Write-Error' -MockWith { 
                    param($Message, $Category, $ErrorId, $TargetObject)
                    
                    $Message | Should -Be $script:localizedData.Get_GitLocalBranchName_Failed
                    $Category | Should -Be 'ObjectNotFound'
                    $ErrorId | Should -Be 'GGLBN0001'
                    $TargetObject | Should -Be $null
                }
                
                # Simulate LASTEXITCODE failure
                $global:LASTEXITCODE = 128
                
                Get-GitLocalBranchName -Current -WarningAction SilentlyContinue -ErrorAction SilentlyContinue

                Should -Invoke -CommandName 'Write-Error' -Times 1 -Exactly
            }
        }
    }

    Context 'When testing output type' {
        It 'Should have correct output type attribute' {
            $command = Get-Command -Name 'Get-GitLocalBranchName'
            $outputType = $command.OutputType
            
            $outputType.Type | Should -Contain ([System.String])
        }
    }
}