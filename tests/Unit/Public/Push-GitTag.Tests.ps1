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
    $script:dscModuleName = 'Viscalyx.Common'

    Import-Module -Name $script:dscModuleName -Force -ErrorAction Stop

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:dscModuleName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:dscModuleName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:dscModuleName
}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    # Unload the module being tested so that it doesn't impact any other tests.
    Get-Module -Name $script:dscModuleName -All | Remove-Module -Force
}

# cSpell: ignore LASTEXITCODE
Describe 'Push-GitTag' {
    Context 'When pushing a specific tag' {
        BeforeAll {
            Mock -CommandName git -MockWith {
                if ($args[0] -eq 'push')
                {
                    $global:LASTEXITCODE = 0
                }
                else
                {
                    throw "Mock git unexpected args: $($args -join ' ')"
                }
            }
        }

        AfterEach {
            $global:LASTEXITCODE = 0
        }

        It 'Should push the specified tag to the default remote' {
            $null = Push-GitTag -Name 'v1.0.0' -Force

            Should -Invoke -CommandName git -ParameterFilter {
                $args[0] -eq 'push' -and $args[1] -eq 'origin' -and $args[2] -eq 'refs/tags/v1.0.0'
            }
        }

        It 'Should push the specified tag to a custom remote' {
            $null = Push-GitTag -RemoteName 'upstream' -Name 'v1.0.0' -Force

            Should -Invoke -CommandName git -ParameterFilter {
                $args[0] -eq 'push' -and $args[1] -eq 'upstream' -and $args[2] -eq 'refs/tags/v1.0.0'
            }
        }

        Context 'When the operation fails' {
            BeforeAll {
                Mock -CommandName git -MockWith {
                    if ($args[0] -eq 'push')
                    {
                        $global:LASTEXITCODE = 1
                    }
                    else
                    {
                        throw "Mock git unexpected args: $($args -join ' ')"
                    }
                }

                $mockErrorMessage = InModuleScope -ScriptBlock {
                    $script:localizedData.Push_GitTag_FailedPushTag -f 'v1.0.0', 'origin'
                }
            }

            AfterEach {
                $global:LASTEXITCODE = 0
            }

            It 'Should have a localized error message for pushing specific tag' {
                $mockErrorMessage | Should-BeTruthy -Because 'The error message should have been localized, and shall not be empty'
            }

            It 'Should throw terminating error when git fails to push specific tag' {
                {
                    Push-GitTag -Name 'v1.0.0' -Force
                } | Should -Throw -ExpectedMessage $mockErrorMessage
            }

            It 'Should throw error with correct error code PGT0001' {
                try {
                    Push-GitTag -Name 'v1.0.0' -Force
                } catch {
                    $_.FullyQualifiedErrorId | Should -Be 'PGT0001,Push-GitTag'
                }
            }
        }
    }

    Context 'When pushing all tags' {
        BeforeAll {
            Mock -CommandName git -MockWith {
                if ($args[0] -eq 'push')
                {
                    $global:LASTEXITCODE = 0
                }
                elseif ($args[0] -eq 'tag')
                {
                    # Return some mock tags to simulate existing tags
                    $global:LASTEXITCODE = 0
                    return @('v1.0.0', 'v2.0.0')
                }
                else
                {
                    throw "Mock git unexpected args: $($args -join ' ')"
                }
            }
        }

        AfterEach {
            $global:LASTEXITCODE = 0
        }

        It 'Should push all tags to the default remote' {
            $null = Push-GitTag -Force

            Should -Invoke -CommandName git -ParameterFilter {
                $args[0] -eq 'push' -and $args[1] -eq 'origin' -and $args[2] -eq '--tags'
            }
        }

        It 'Should push all tags to a custom remote' {
            $null = Push-GitTag -RemoteName 'upstream' -Force

            Should -Invoke -CommandName git -ParameterFilter {
                $args[0] -eq 'push' -and $args[1] -eq 'upstream' -and $args[2] -eq '--tags'
            }
        }

        Context 'When the operation fails' {
            BeforeAll {
                Mock -CommandName git -MockWith {
                    if ($args[0] -eq 'push')
                    {
                        $global:LASTEXITCODE = 1
                    }
                    elseif ($args[0] -eq 'tag')
                    {
                        # Return some mock tags to simulate existing tags
                        $global:LASTEXITCODE = 0
                        return @('v1.0.0', 'v2.0.0')
                    }
                    else
                    {
                        throw "Mock git unexpected args: $($args -join ' ')"
                    }
                }

                $mockErrorMessage = InModuleScope -ScriptBlock {
                    $script:localizedData.Push_GitTag_FailedPushAllTags -f 'origin'
                }
            }

            AfterEach {
                $global:LASTEXITCODE = 0
            }

            It 'Should have a localized error message for pushing all tags' {
                $mockErrorMessage | Should-BeTruthy -Because 'The error message should have been localized, and shall not be empty'
            }

            It 'Should throw terminating error when git fails to push all tags' {
                {
                    Push-GitTag -Force
                } | Should -Throw -ExpectedMessage $mockErrorMessage
            }

            It 'Should throw error with correct error code PGT0001 when pushing all tags' {
                try {
                    Push-GitTag -Force
                } catch {
                    $_.FullyQualifiedErrorId | Should -Be 'PGT0001,Push-GitTag'
                }
            }
        }
    }

    Context 'When git tag command fails' {
        BeforeAll {
            Mock -CommandName git -MockWith {
                if ($args[0] -eq 'tag')
                {
                    # Simulate git tag command failure
                    $global:LASTEXITCODE = 128
                    return $null
                }
                elseif ($args[0] -eq 'push')
                {
                    $global:LASTEXITCODE = 0
                }
                else
                {
                    throw "Mock git unexpected args: $($args -join ' ')"
                }
            }

            $mockErrorMessage = InModuleScope -ScriptBlock {
                $script:localizedData.Push_GitTag_FailedListTags
            }
        }

        AfterEach {
            $global:LASTEXITCODE = 0
        }

        It 'Should have a localized error message for failed git tag command' {
            $mockErrorMessage | Should -Not -BeNullOrEmpty
            $mockErrorMessage | Should -BeLike '*Failed to list local tags*'
        }

        It 'Should throw terminating error when git tag fails' {
            { Push-GitTag -Force } | Should -Throw -ErrorId 'PGT0010,Push-GitTag'
        }

        It 'Should throw error with correct error code PGT0010' {
            try {
                Push-GitTag -Force
            } catch {
                $_.FullyQualifiedErrorId | Should -Be 'PGT0010,Push-GitTag'
            }
        }
    }

    Context 'When pushing all tags with no local tags (no-op)' {
        BeforeAll {
            Mock -CommandName git -MockWith {
                if ($args[0] -eq 'tag')
                {
                    # Return empty string to simulate no existing tags
                    $global:LASTEXITCODE = 0
                    return ''
                }
                elseif ($args[0] -eq 'push')
                {
                    # This should not be called, but if it is, we'll allow it for now
                    $global:LASTEXITCODE = 0
                }
                else
                {
                    throw "Mock git unexpected args: $($args -join ' ')"
                }
            }
        }

        AfterEach {
            $global:LASTEXITCODE = 0
        }

        It 'Should succeed without calling git push when no local tags exist' {
            $null = Push-GitTag -Force

            # Verify git tag was called to check for tags
            Should -Invoke -CommandName git -ParameterFilter {
                $args[0] -eq 'tag'
            } -Times 1

            # Verify git push was NOT called since no tags exist - if this fails, it means the logic needs adjustment
            Should -Invoke -CommandName git -ParameterFilter {
                $args[0] -eq 'push'
            } -Times 0 -Because "no git push should occur when no local tags exist"
        }
    }

    Context 'When ShouldProcess is used' {
        BeforeAll {
            Mock -CommandName git -MockWith {
                if ($args[0] -eq 'push')
                {
                    $global:LASTEXITCODE = 0
                }
                elseif ($args[0] -eq 'tag')
                {
                    # Return some mock tags for WhatIf testing
                    $global:LASTEXITCODE = 0
                    return @('v1.0.0')
                }
                else
                {
                    throw "Mock git unexpected args: $($args -join ' ')"
                }
            }
        }

        AfterEach {
            $global:LASTEXITCODE = 0
        }

        It 'Should not push tag when WhatIf is specified' {
            $null = Push-GitTag -Name 'v1.0.0' -WhatIf

            Should -Invoke -CommandName git -Times 0
        }

        It 'Should not push all tags when WhatIf is specified' {
            $null = Push-GitTag -WhatIf

            Should -Invoke -CommandName git -ParameterFilter { $args[0] -eq 'push' } -Times 0
            Should -Invoke -CommandName git -ParameterFilter { $args[0] -eq 'tag' } -Times 1
        }
    }

    Context 'When Force parameter is used' {
        BeforeAll {
            Mock -CommandName git -MockWith {
                if ($args[0] -eq 'push')
                {
                    $global:LASTEXITCODE = 0
                }
                elseif ($args[0] -eq 'tag')
                {
                    # Return some mock tags for Force testing
                    $global:LASTEXITCODE = 0
                    return @('v1.0.0')
                }
                else
                {
                    throw "Mock git unexpected args: $($args -join ' ')"
                }
            }
        }

        AfterEach {
            $global:LASTEXITCODE = 0
        }

        It 'Should bypass confirmation when Force is used with specific tag' {
            $null = Push-GitTag -Name 'v1.0.0' -Force

            Should -Invoke -CommandName git -ParameterFilter {
                $args[0] -eq 'push' -and $args[1] -eq 'origin' -and $args[2] -eq 'refs/tags/v1.0.0'
            }
        }

        It 'Should bypass confirmation when Force is used with all tags' {
            $null = Push-GitTag -Force

            Should -Invoke -CommandName git -ParameterFilter {
                $args[0] -eq 'push' -and $args[1] -eq 'origin' -and $args[2] -eq '--tags'
            }
        }
    }

    Context 'When parameter sets are validated' {
        It 'Should have the correct parameters in parameter set <ExpectedParameterSetName>' -ForEach @(
            @{
                ExpectedParameterSetName = 'AllTags'
                ExpectedParameters = '[[-RemoteName] <string>] [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]'
            }
            @{
                ExpectedParameterSetName = 'SingleTag'
                ExpectedParameters = '[[-RemoteName] <string>] [[-Name] <string>] [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]'
            }
        ) {
            $result = (Get-Command -Name 'Push-GitTag').ParameterSets |
                Where-Object -FilterScript { $_.Name -eq $ExpectedParameterSetName } |
                Select-Object -Property @(
                    @{ Name = 'ParameterSetName'; Expression = { $_.Name } },
                    @{ Name = 'ParameterListAsString'; Expression = { $_.ToString() } }
                )
            $result.ParameterSetName | Should -Be $ExpectedParameterSetName
            $result.ParameterListAsString | Should -Be $ExpectedParameters
        }

        It 'Should have AllTags as the default parameter set' {
            $command = Get-Command -Name 'Push-GitTag'
            $defaultParameterSet = $command.ParameterSets | Where-Object -FilterScript { $_.IsDefault }
            $defaultParameterSet.Name | Should -Be 'AllTags'
        }

        It 'Should have Name parameter only in SingleTag parameter set' {
            $command = Get-Command -Name 'Push-GitTag'
            $parameterSetsWithName = $command.ParameterSets | Where-Object -FilterScript {
                $_.Parameters.Name -contains 'Name'
            }
            $parameterSetsWithName.Count | Should -Be 1
            $parameterSetsWithName[0].Name | Should -Be 'SingleTag'
        }

        It 'Should have RemoteName parameter in both parameter sets' {
            $command = Get-Command -Name 'Push-GitTag'
            $parameterSetsWithRemoteName = $command.ParameterSets | Where-Object -FilterScript {
                $_.Parameters.Name -contains 'RemoteName'
            }
            $parameterSetsWithRemoteName.Count | Should -Be 2
            $parameterSetsWithRemoteName.Name | Should -Contain 'AllTags'
            $parameterSetsWithRemoteName.Name | Should -Contain 'SingleTag'
        }

        It 'Should have Force parameter in both parameter sets' {
            $command = Get-Command -Name 'Push-GitTag'
            $parameterSetsWithForce = $command.ParameterSets | Where-Object -FilterScript {
                $_.Parameters.Name -contains 'Force'
            }
            $parameterSetsWithForce.Count | Should -Be 2
            $parameterSetsWithForce.Name | Should -Contain 'AllTags'
            $parameterSetsWithForce.Name | Should -Contain 'SingleTag'
        }
    }

    Context 'When parameter properties are validated' {
        It 'Should have RemoteName as a non-mandatory parameter with correct attributes' {
            $parameterInfo = (Get-Command -Name 'Push-GitTag').Parameters['RemoteName']
            $parameterInfo.Attributes.Mandatory | Should -BeFalse
            $parameterInfo.ParameterType | Should -Be ([System.String])
            $parameterInfo.Attributes.Position | Should -Contain 0
        }

        It 'Should have Name as a non-mandatory parameter with correct attributes' {
            $parameterInfo = (Get-Command -Name 'Push-GitTag').Parameters['Name']
            $parameterInfo.Attributes.Mandatory | Should -BeFalse
            $parameterInfo.ParameterType | Should -Be ([System.String])
            $parameterInfo.Attributes.Position | Should -Contain 1
        }

        It 'Should have Force as a non-mandatory SwitchParameter' {
            $parameterInfo = (Get-Command -Name 'Push-GitTag').Parameters['Force']
            $parameterInfo.Attributes.Mandatory | Should -BeFalse
            $parameterInfo.ParameterType | Should -Be ([System.Management.Automation.SwitchParameter])
        }

        It 'Should have ValidateNotNullOrEmpty attribute on RemoteName parameter' {
            $parameterInfo = (Get-Command -Name 'Push-GitTag').Parameters['RemoteName']
            $validateAttributes = $parameterInfo.Attributes | Where-Object -FilterScript {
                $_ -is [System.Management.Automation.ValidateNotNullOrEmptyAttribute]
            }
            $validateAttributes | Should -Not -BeNullOrEmpty
        }

        It 'Should have ValidateNotNullOrEmpty attribute on Name parameter' {
            $parameterInfo = (Get-Command -Name 'Push-GitTag').Parameters['Name']
            $validateAttributes = $parameterInfo.Attributes | Where-Object -FilterScript {
                $_ -is [System.Management.Automation.ValidateNotNullOrEmptyAttribute]
            }
            $validateAttributes | Should -Not -BeNullOrEmpty
        }

        It 'Should support ShouldProcess' {
            $command = Get-Command -Name 'Push-GitTag'
            $command.Parameters.ContainsKey('WhatIf') | Should -BeTrue
            $command.Parameters.ContainsKey('Confirm') | Should -BeTrue
        }

        It 'Should have ConfirmImpact set to Medium' {
            $functionInfo = Get-Command -Name 'Push-GitTag'
            $cmdletBindingAttribute = $functionInfo.ScriptBlock.Attributes |
                Where-Object -FilterScript { $_ -is [System.Management.Automation.CmdletBindingAttribute] }
            $cmdletBindingAttribute.ConfirmImpact | Should -Be 'Medium'
        }
    }

    Context 'When parameter validation is tested' {
        BeforeAll {
            Mock -CommandName git -MockWith {
                if ($args[0] -eq 'push')
                {
                    $global:LASTEXITCODE = 0
                }
                elseif ($args[0] -eq 'tag')
                {
                    # Return some mock tags for testing
                    $global:LASTEXITCODE = 0
                    return @('v1.0.0')
                }
                else
                {
                    throw "Mock git unexpected args: $($args -join ' ')"
                }
            }
        }

        AfterEach {
            $global:LASTEXITCODE = 0
        }

        It 'Should accept valid RemoteName parameter' {
            $null = Push-GitTag -RemoteName 'upstream' -WhatIf
        }

        It 'Should accept valid Name parameter' {
            $null = Push-GitTag -Name 'v1.0.0' -WhatIf
        }

        It 'Should use origin as default RemoteName when not specified' {
            $null = Push-GitTag -Name 'v1.0.0' -Force

            Should -Invoke -CommandName git -ParameterFilter {
                $args[1] -eq 'origin'
            }
        }
    }
}
