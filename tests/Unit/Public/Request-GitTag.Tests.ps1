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

# cSpell: ignore LASTEXITCODE
Describe 'Request-GitTag' {
    Context 'Parameter Set Validation' {
        It 'Should have the correct parameters in parameter set __AllParameterSets' {
            $result = (Get-Command -Name 'Request-GitTag').ParameterSets |
                Where-Object -FilterScript { $_.Name -eq '__AllParameterSets' } |
                Select-Object -Property @(
                    @{ Name = 'ParameterSetName'; Expression = { $_.Name } },
                    @{ Name = 'ParameterListAsString'; Expression = { $_.ToString() } }
                )
            $result.ParameterSetName | Should -Be '__AllParameterSets'
            $result.ParameterListAsString | Should -Be '[-RemoteName] <string> [[-Name] <string>] [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]'
        }
    }

    Context 'Parameter Properties' {
        It 'Should have RemoteName as a mandatory parameter' {
            $parameterInfo = (Get-Command -Name 'Request-GitTag').Parameters['RemoteName']
            $parameterInfo.Attributes.Mandatory | Should -BeTrue
        }

        It 'Should have Name as a non-mandatory parameter' {
            $parameterInfo = (Get-Command -Name 'Request-GitTag').Parameters['Name']
            $parameterInfo.Attributes.Mandatory | Should -BeFalse
        }

        It 'Should have Force as a non-mandatory parameter' {
            $parameterInfo = (Get-Command -Name 'Request-GitTag').Parameters['Force']
            $parameterInfo.Attributes.Mandatory | Should -BeFalse
        }

        It 'Should have WhatIf parameter available' {
            $parameterInfo = (Get-Command -Name 'Request-GitTag').Parameters['WhatIf']
            $parameterInfo | Should -Not -BeNullOrEmpty
        }

        It 'Should have Confirm parameter available' {
            $parameterInfo = (Get-Command -Name 'Request-GitTag').Parameters['Confirm']
            $parameterInfo | Should -Not -BeNullOrEmpty
        }
    }

    Context 'When fetching a specific tag successfully' {
        BeforeAll {
            Mock -CommandName git -MockWith {
                if ($args[0] -eq 'fetch')
                {
                    $global:LASTEXITCODE = 0
                    return
                }
                else
                {
                    throw "Mock git unexpected args: $($args -join ' ')"
                }
            }
        }

        BeforeEach {
            $global:LASTEXITCODE = 0
        }

        AfterEach {
            $global:LASTEXITCODE = 0
        }

        It 'Should call git fetch with correct arguments for specific tag' {
            $null = Request-GitTag -RemoteName 'origin' -Name 'v1.0.0' -Force

            Should -Invoke -CommandName git -ModuleName $script:moduleName -Times 1
        }

        It 'Should not throw an error when git command succeeds' {
            { Request-GitTag -RemoteName 'origin' -Name 'v1.0.0' -Force } | Should -Not -Throw
        }
    }

    Context 'When fetching all tags successfully' {
        BeforeAll {
            Mock -CommandName git -MockWith {
                if ($args[0] -eq 'fetch')
                {
                    $global:LASTEXITCODE = 0
                    return
                }
                else
                {
                    throw "Mock git unexpected args: $($args -join ' ')"
                }
            }
        }

        BeforeEach {
            $global:LASTEXITCODE = 0
        }

        AfterEach {
            $global:LASTEXITCODE = 0
        }

        It 'Should call git fetch with correct arguments for all tags' {
            $null = Request-GitTag -RemoteName 'upstream' -Force

            Should -Invoke -CommandName git -ModuleName $script:moduleName -ParameterFilter {
                $args[0] -eq 'fetch' -and
                $args[1] -eq 'upstream' -and
                $args[2] -eq '--tags'
            }
        }

        It 'Should not throw an error when git command succeeds' {
            { Request-GitTag -RemoteName 'upstream' -Force } | Should -Not -Throw
        }
    }

    Context 'When git command fails for specific tag' {
        BeforeAll {
            Mock -CommandName git -MockWith {
                if ($args[0] -eq 'fetch')
                {
                    $global:LASTEXITCODE = 1
                    return
                }
                else
                {
                    throw "Mock git unexpected args: $($args -join ' ')"
                }
            }

            $mockErrorMessage = InModuleScope -ScriptBlock {
                $script:localizedData.Request_GitTag_FailedFetchTag -f 'v1.0.0', 'origin'
            }
        }

        BeforeEach {
            $global:LASTEXITCODE = 0
        }

        AfterEach {
            $global:LASTEXITCODE = 0
        }

        It 'Should throw terminating error with correct error record for specific tag' {
            $errorRecord = { Request-GitTag -RemoteName 'origin' -Name 'v1.0.0' -Force } |
                Should -Throw -PassThru

            $errorRecord.Exception.Message | Should -Be $mockErrorMessage
            $errorRecord.FullyQualifiedErrorId | Should -Be 'RGT0001,Request-GitTag'
            $errorRecord.CategoryInfo.Category | Should -Be 'InvalidOperation'
            $errorRecord.TargetObject | Should -Be 'v1.0.0'
        }
    }

    Context 'When git command fails for all tags' {
        BeforeAll {
            Mock -CommandName git -MockWith {
                if ($args[0] -eq 'fetch')
                {
                    $global:LASTEXITCODE = 1
                    return
                }
                else
                {
                    throw "Mock git unexpected args: $($args -join ' ')"
                }
            }

            $mockErrorMessage = InModuleScope -ScriptBlock {
                $script:localizedData.Request_GitTag_FailedFetchAllTags -f 'upstream'
            }
        }

        BeforeEach {
            $global:LASTEXITCODE = 0
        }

        AfterEach {
            $global:LASTEXITCODE = 0
        }

        It 'Should throw terminating error with correct error record for all tags' {
            $errorRecord = { Request-GitTag -RemoteName 'upstream' -Force } |
                Should -Throw -PassThru

            $errorRecord.Exception.Message | Should -Be $mockErrorMessage
            $errorRecord.FullyQualifiedErrorId | Should -Be 'RGT0001,Request-GitTag'
            $errorRecord.CategoryInfo.Category | Should -Be 'InvalidOperation'
            $errorRecord.TargetObject | Should -BeNullOrEmpty
        }
    }

    Context 'ShouldProcess functionality' {
        BeforeAll {
            Mock -CommandName git -MockWith {
                $global:LASTEXITCODE = 0
                return
            }
        }

        BeforeEach {
            $global:LASTEXITCODE = 0
        }

        AfterEach {
            $global:LASTEXITCODE = 0
        }

        It 'Should support WhatIf for specific tag' {
            $null = Request-GitTag -RemoteName 'origin' -Name 'v1.0.0' -WhatIf

            Should -Invoke -CommandName git -Times 0
        }

        It 'Should support WhatIf for all tags' {
            $null = Request-GitTag -RemoteName 'upstream' -WhatIf

            Should -Invoke -CommandName git -Times 0
        }

        It 'Should proceed when Force is specified with Confirm:$false' {
            $null = Request-GitTag -RemoteName 'origin' -Name 'v1.0.0' -Force -Confirm:$false

            Should -Invoke -CommandName git -Times 1
        }
    }

    Context 'When Name parameter contains ValidateNotNullOrEmpty violation' {
        It 'Should not allow empty string for Name parameter' {
            { Request-GitTag -RemoteName 'origin' -Name '' -Force } | Should -Throw
        }

        It 'Should not allow null for Name parameter' {
            { Request-GitTag -RemoteName 'origin' -Name $null -Force } | Should -Throw
        }
    }

    Context 'When RemoteName parameter is not provided' {
        It 'Should require RemoteName parameter when not provided' {
            # Use a script block to capture the parameter binding exception
            $scriptBlock = {
                # This should fail at parameter validation before the function executes
                $command = Get-Command Request-GitTag
                $command.Parameters['RemoteName'].Attributes.Mandatory | Should -BeTrue
            }
            
            $scriptBlock | Should -Not -Throw
        }
    }

    Context 'Localized strings validation' {
        BeforeAll {
            Mock -CommandName git -MockWith {
                $global:LASTEXITCODE = 0
            }

            # Mock the ShouldProcess method to capture the messages
            $script:shouldProcessMessages = @()
            
            Mock -CommandName 'Request-GitTag' -ModuleName $script:moduleName -MockWith {
                param($RemoteName, $Name, $Force)
                
                # Capture the localized strings that would be used
                if ($PSBoundParameters.ContainsKey('Name'))
                {
                    $script:shouldProcessMessages += @{
                        Description = $script:localizedData.Request_GitTag_FetchTag_ShouldProcessVerboseDescription -f $Name, $RemoteName
                        Warning = $script:localizedData.Request_GitTag_FetchTag_ShouldProcessVerboseWarning -f $Name, $RemoteName
                        Caption = $script:localizedData.Request_GitTag_FetchTag_ShouldProcessCaption
                    }
                }
                else
                {
                    $script:shouldProcessMessages += @{
                        Description = $script:localizedData.Request_GitTag_FetchAllTags_ShouldProcessVerboseDescription -f $RemoteName
                        Warning = $script:localizedData.Request_GitTag_FetchAllTags_ShouldProcessVerboseWarning -f $RemoteName
                        Caption = $script:localizedData.Request_GitTag_FetchAllTags_ShouldProcessCaption
                    }
                }
                
                return $true
            } -ParameterFilter { $WhatIf -eq $true }
        }

        It 'Should use correct localized strings for specific tag WhatIf' {
            InModuleScope -ScriptBlock {
                $script:shouldProcessMessages = @()
                
                # Test the actual localized strings exist and can be formatted
                $testName = 'v1.0.0'
                $testRemote = 'origin'
                
                $description = $script:localizedData.Request_GitTag_FetchTag_ShouldProcessVerboseDescription -f $testName, $testRemote
                $warning = $script:localizedData.Request_GitTag_FetchTag_ShouldProcessVerboseWarning -f $testName, $testRemote
                $caption = $script:localizedData.Request_GitTag_FetchTag_ShouldProcessCaption
                
                $description | Should -Be "Fetching tag 'v1.0.0' from remote 'origin'. (RQT0001)"
                $warning | Should -Be "Are you sure you want to fetch tag 'v1.0.0' from remote 'origin'? (RQT0002)"
                $caption | Should -Be "Fetch tag (RQT0003)"
            }
        }

        It 'Should use correct localized strings for all tags WhatIf' {
            InModuleScope -ScriptBlock {
                # Test the actual localized strings exist and can be formatted
                $testRemote = 'upstream'
                
                $description = $script:localizedData.Request_GitTag_FetchAllTags_ShouldProcessVerboseDescription -f $testRemote
                $warning = $script:localizedData.Request_GitTag_FetchAllTags_ShouldProcessVerboseWarning -f $testRemote
                $caption = $script:localizedData.Request_GitTag_FetchAllTags_ShouldProcessCaption
                
                $description | Should -Be "Fetching all tags from remote 'upstream'. (RQT0004)"
                $warning | Should -Be "Are you sure you want to fetch all tags from remote 'upstream'? (RQT0005)"
                $caption | Should -Be "Fetch all tags (RQT0006)"
            }
        }
    }
}