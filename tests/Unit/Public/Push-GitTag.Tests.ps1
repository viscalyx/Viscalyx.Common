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

    Import-Module -Name $script:dscModuleName

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
            Push-GitTag -Name 'v1.0.0' -Force

            Should -Invoke -CommandName git -ParameterFilter {
                $args[0] -eq 'push' -and $args[1] -eq 'origin' -and $args[2] -eq 'refs/tags/v1.0.0'
            }
        }

        It 'Should push the specified tag to a custom remote' {
            Push-GitTag -RemoteName 'upstream' -Name 'v1.0.0' -Force

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
            Push-GitTag -Force

            Should -Invoke -CommandName git -ParameterFilter {
                $args[0] -eq 'push' -and $args[1] -eq 'origin' -and $args[2] -eq '--tags'
            }
        }

        It 'Should push all tags to a custom remote' {
            Push-GitTag -RemoteName 'upstream' -Force

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
            { Push-GitTag -Force } | Should -Not -Throw

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
            Push-GitTag -Name 'v1.0.0' -WhatIf

            Should -Invoke -CommandName git -Times 0
        }

        It 'Should not push all tags when WhatIf is specified' {
            Push-GitTag -WhatIf

            Should -Invoke -CommandName git -Times 0
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
            Push-GitTag -Name 'v1.0.0' -Force

            Should -Invoke -CommandName git -ParameterFilter {
                $args[0] -eq 'push' -and $args[1] -eq 'origin' -and $args[2] -eq 'refs/tags/v1.0.0'
            }
        }

        It 'Should bypass confirmation when Force is used with all tags' {
            Push-GitTag -Force

            Should -Invoke -CommandName git -ParameterFilter {
                $args[0] -eq 'push' -and $args[1] -eq 'origin' -and $args[2] -eq '--tags'
            }
        }
    }

    Context 'When parameter validation is tested' {
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

        It 'Should accept valid RemoteName parameter' {
            { Push-GitTag -RemoteName 'upstream' -WhatIf } | Should -Not -Throw
        }

        It 'Should accept valid Name parameter' {
            { Push-GitTag -Name 'v1.0.0' -WhatIf } | Should -Not -Throw
        }

        It 'Should use origin as default RemoteName when not specified' {
            Push-GitTag -Name 'v1.0.0' -Force

            Should -Invoke -CommandName git -ParameterFilter {
                $args[1] -eq 'origin'
            }
        }
    }
}