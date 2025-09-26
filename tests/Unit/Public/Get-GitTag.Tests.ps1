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
Describe 'Get-GitTag' {
    Context 'Parameter Set Validation' {
        It 'Should have the correct parameters in parameter set <ExpectedParameterSetName>' -ForEach @(
            @{
                ExpectedParameterSetName = 'First'
                ExpectedParameters = '[[-Name] <string>] [-First <uint>] [-AsVersions] [-Descending] [<CommonParameters>]'
            }
            @{
                ExpectedParameterSetName = 'Latest'
                ExpectedParameters = '[-Latest] [<CommonParameters>]'
            }
        ) {
            $result = (Get-Command -Name 'Get-GitTag').ParameterSets |
                Where-Object -FilterScript { $_.Name -eq $ExpectedParameterSetName } |
                Select-Object -Property @(
                    @{ Name = 'ParameterSetName'; Expression = { $_.Name } },
                    @{ Name = 'ParameterListAsString'; Expression = { $_.ToString() } }
                )
            $result.ParameterSetName | Should -Be $ExpectedParameterSetName

            if ($PSVersionTable.PSVersion.Major -eq 5) {
                # Windows PowerShell 5.1 shows <uint32> for System.UInt32 type
                $ExpectedParameters = $ExpectedParameters -replace '<uint>', '<uint32>'
            }

            $result.ParameterListAsString | Should -Be $ExpectedParameters
        }
    }

    Context 'Parameter Properties' {
        It 'Should have Name as a non-mandatory parameter' {
            $parameterInfo = (Get-Command -Name 'Get-GitTag').Parameters['Name']
            $parameterInfo.Attributes.Mandatory | Should -BeFalse
        }

        It 'Should have Latest as a non-mandatory parameter' {
            $parameterInfo = (Get-Command -Name 'Get-GitTag').Parameters['Latest']
            $parameterInfo.Attributes.Mandatory | Should -BeFalse
        }

        It 'Should have First as a non-mandatory parameter' {
            $parameterInfo = (Get-Command -Name 'Get-GitTag').Parameters['First']
            $parameterInfo.Attributes.Mandatory | Should -BeFalse
        }

        It 'Should have AsVersions as a non-mandatory parameter' {
            $parameterInfo = (Get-Command -Name 'Get-GitTag').Parameters['AsVersions']
            $parameterInfo.Attributes.Mandatory | Should -BeFalse
        }

        It 'Should have Descending as a non-mandatory parameter' {
            $parameterInfo = (Get-Command -Name 'Get-GitTag').Parameters['Descending']
            $parameterInfo.Attributes.Mandatory | Should -BeFalse
        }
    }

    Context 'When retrieving tags with First parameter set' {
        BeforeAll {
            Mock -CommandName git -MockWith {
                if ($args[0] -eq 'tag' -and $args[1] -eq '--list' -and $args[2] -like '--sort=*')
                {
                    $global:LASTEXITCODE = 0
                    return @('v1.0.0', 'v1.1.0', 'v2.0.0', 'v2.1.0')
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

        It 'Should return all tags when no specific parameters are provided' {
            $result = Get-GitTag

            $result | Should -HaveCount 4
            $result | Should -Contain 'v1.0.0'
            $result | Should -Contain 'v1.1.0'
            $result | Should -Contain 'v2.0.0'
            $result | Should -Contain 'v2.1.0'

            Should -Invoke -CommandName git -ParameterFilter {
                $args[0] -eq 'tag' -and $args[1] -eq '--list' -and $args[2] -eq '--sort=refname'
            }
        }

        It 'Should return tags with version sorting when AsVersions is specified' {
            $result = Get-GitTag -AsVersions

            $result | Should -HaveCount 4

            Should -Invoke -CommandName git -ParameterFilter {
                $args[0] -eq 'tag' -and $args[1] -eq '--list' -and $args[2] -eq '--sort=v:refname'
            }
        }

        It 'Should return tags in descending order when Descending is specified' {
            $result = Get-GitTag -Descending

            $result | Should -HaveCount 4

            Should -Invoke -CommandName git -ParameterFilter {
                $args[0] -eq 'tag' -and $args[1] -eq '--list' -and $args[2] -eq '--sort=-refname'
            }
        }

        It 'Should return tags with version sorting in descending order when both AsVersions and Descending are specified' {
            $result = Get-GitTag -AsVersions -Descending

            $result | Should -HaveCount 4

            Should -Invoke -CommandName git -ParameterFilter {
                $args[0] -eq 'tag' -and $args[1] -eq '--list' -and $args[2] -eq '--sort=-v:refname'
            }
        }

        It 'Should return specific number of tags when First is specified' {
            $result = Get-GitTag -First 2

            $result | Should -HaveCount 2

            Should -Invoke -CommandName git -ParameterFilter {
                $args[0] -eq 'tag' -and $args[1] -eq '--list' -and $args[2] -eq '--sort=refname'
            }
        }

        It 'Should return filtered tags when Name pattern is specified' {
            Mock -CommandName git -MockWith {
                if ($args[0] -eq 'tag' -and $args[1] -eq '--list' -and $args[2] -like '--sort=*' -and $args[3] -eq 'v1*')
                {
                    $global:LASTEXITCODE = 0
                    return @('v1.0.0', 'v1.1.0')
                }
                else
                {
                    throw "Mock git unexpected args: $($args -join ' ')"
                }
            }

            $result = Get-GitTag -Name 'v1*'

            $result | Should -HaveCount 2
            $result | Should -Contain 'v1.0.0'
            $result | Should -Contain 'v1.1.0'

            Should -Invoke -CommandName git -ParameterFilter {
                $args[0] -eq 'tag' -and $args[1] -eq '--list' -and $args[2] -eq '--sort=refname' -and $args[3] -eq 'v1*'
            }
        }
    }

    Context 'When retrieving tags with Latest parameter set' {
        BeforeAll {
            Mock -CommandName git -MockWith {
                if ($args[0] -eq 'tag' -and $args[1] -eq '--list')
                {
                    $global:LASTEXITCODE = 0
                    return @('v2.1.0', 'v2.0.0', 'v1.1.0', 'v1.0.0')
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

        It 'Should return the latest tag when Latest is specified' {
            $result = Get-GitTag -Latest

            $result | Should -Be 'v2.1.0'
            $result | Should -HaveCount 1

            Should -Invoke -CommandName git -ParameterFilter {
                $args[0] -eq 'tag' -and $args[1] -eq '--list' -and $args[2] -eq '--sort=-v:refname'
            }
        }
    }

    Context 'When the operation fails' {
        BeforeAll {
            Mock -CommandName git -MockWith {
                if ($args[0] -eq 'tag')
                {
                    $global:LASTEXITCODE = 1
                    return @() # Return empty array instead of null
                }
                else
                {
                    throw "Mock git unexpected args: $($args -join ' ')"
                }
            }

            $mockErrorMessage = InModuleScope -ScriptBlock {
                $script:localizedData.Get_GitTag_FailedToGetTag
            }

            $mockErrorMessage = $mockErrorMessage -f 'v1.0.0'
        }

        AfterEach {
            $global:LASTEXITCODE = 0
        }

        It 'Should have a localized error message' {
            $mockErrorMessage | Should-BeTruthy -Because 'The error message should have been localized, and shall not be empty'
        }

        It 'Should handle non-terminating error correctly when retrieving specific tag' {
            Mock -CommandName Write-Error

            $result = Get-GitTag -Name 'v1.0.0'

            $result | Should -BeNullOrEmpty

            Should -Invoke -CommandName Write-Error -ParameterFilter {
                $Message -eq $mockErrorMessage
            }
        }

        It 'Should handle terminating error correctly when retrieving specific tag' {
            {
                Get-GitTag -Name 'v1.0.0' -ErrorAction 'Stop'
            } | Should -Throw -ExpectedMessage $mockErrorMessage
        }

        It 'Should handle non-terminating error correctly when retrieving all tags' {
            Mock -CommandName Write-Error

            $mockErrorMessageForAll = InModuleScope -ScriptBlock {
                $script:localizedData.Get_GitTag_FailedToGetTag
            }
            $mockErrorMessageForAll = $mockErrorMessageForAll -f ''

            $result = Get-GitTag

            $result | Should -BeNullOrEmpty

            Should -Invoke -CommandName Write-Error -ParameterFilter {
                $Message -eq $mockErrorMessageForAll
            }
        }
    }
}
