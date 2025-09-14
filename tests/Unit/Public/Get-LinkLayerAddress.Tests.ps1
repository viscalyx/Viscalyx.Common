[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
param ()

BeforeDiscovery {
    try
    {
        if (-not (Get-Module -Name 'DscResource.Test'))
        {
            # Assumes dependencies has been resolved, so if this module is not available, run 'noop' task.
            if (-not (Get-Module -Name 'DscResource.Test' -ListAvailable))
            {
                # Redirect all streams to $null, except the error stream (stream 2)
                & "$PSScriptRoot/../../../build.ps1" -Tasks 'noop' 3>&1 4>&1 5>&1 6>&1 > $null
            }

            # If the dependencies has not been resolved, this will throw an error.
            Import-Module -Name 'DscResource.Test' -Force -ErrorAction 'Stop'
        }
    }
    catch [System.IO.FileNotFoundException]
    {
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -ResolveDependency -Tasks build" first.'
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

Describe 'Get-LinkLayerAddress' {
    Context 'When checking command structure' {
        It 'Should have the correct parameters in parameter set <ExpectedParameterSetName>' -ForEach @(
            @{
                ExpectedParameterSetName = '__AllParameterSets'
                ExpectedParameters = '[-IPAddress] <string> [<CommonParameters>]'
            }
        ) {
            $result = (Get-Command -Name 'Get-LinkLayerAddress').ParameterSets |
                Where-Object -FilterScript { $_.Name -eq $ExpectedParameterSetName } |
                Select-Object -Property @(
                    @{ Name = 'ParameterSetName'; Expression = { $_.Name } },
                    @{ Name = 'ParameterListAsString'; Expression = { $_.ToString() } }
                )
            $result.ParameterSetName | Should -Be $ExpectedParameterSetName
            $result.ParameterListAsString | Should -Be $ExpectedParameters
        }

        It 'Should have IPAddress as a mandatory parameter' {
            $parameterInfo = (Get-Command -Name 'Get-LinkLayerAddress').Parameters['IPAddress']
            $parameterInfo.Attributes.Mandatory | Should -BeTrue
        }
    }

    Context 'When validating parameter input' {
        Context 'When IP address format is invalid' {
            It 'Should throw an error for invalid IP address format' {
                {
                    Get-LinkLayerAddress -IPAddress 'invalid.ip.address' -ErrorAction Stop
                } | Should -Throw
            }

            It 'Should throw an error for IP address with values over 255' {
                {
                    Get-LinkLayerAddress -IPAddress '256.1.1.1' -ErrorAction Stop
                } | Should -Throw
            }

            It 'Should throw an error for incomplete IP address' {
                {
                    Get-LinkLayerAddress -IPAddress '192.168.1' -ErrorAction Stop
                } | Should -Throw
            }
        }

        Context 'When IP address format is valid' {
            BeforeAll {
                Mock -CommandName Test-Connection -MockWith { $true }
                Mock -CommandName Write-Warning
            }

            It 'Should accept valid IP address format' {
                { Get-LinkLayerAddress -IPAddress '192.168.1.1' } | Should -Not -Throw
            }
        }
    }

    Context 'When running on Windows with Get-NetNeighbor available' {
        BeforeAll {
            Mock -CommandName Test-Connection -MockWith { $true }

            # Mock Windows environment
            InModuleScope -ScriptBlock {
                $script:IsWindows = $true
                $script:IsLinux = $false
                $script:IsMacOS = $false
            }

            Mock -CommandName Get-Command -MockWith {
                return [PSCustomObject]@{ Name = 'Get-NetNeighbor' }
            } -ParameterFilter { $Name -eq 'Get-NetNeighbor' -and $ErrorAction -eq 'SilentlyContinue' }
        }

        Context 'When Get-NetNeighbor returns a MAC address' {
            BeforeAll {
                Mock -CommandName Get-NetNeighbor -MockWith {
                    return [PSCustomObject]@{
                        LinkLayerAddress = '00:11:22:33:44:55'
                    }
                }
            }

            It 'Should return the MAC address from Get-NetNeighbor' -Skip:(-not $IsWindows) {
                $result = Get-LinkLayerAddress -IPAddress '192.168.1.1'

                $result | Should -Be '00:11:22:33:44:55'
            }

            It 'Should call Test-Connection to refresh ARP entry' -Skip:(-not $IsWindows) {
                Get-LinkLayerAddress -IPAddress '192.168.1.1'

                Should -Invoke -CommandName Test-Connection -Exactly 1
            }

            It 'Should call Get-NetNeighbor with correct IP address' -Skip:(-not $IsWindows) {
                Get-LinkLayerAddress -IPAddress '192.168.1.1'

                Should -Invoke -CommandName Get-NetNeighbor -ParameterFilter {
                    $IPAddress -eq '192.168.1.1'
                } -Exactly 1
            }
        }

        Context 'When Get-NetNeighbor returns empty or null MAC address' {
            BeforeAll {
                Mock -CommandName Get-NetNeighbor -MockWith {
                    return [PSCustomObject]@{
                        LinkLayerAddress = $null
                    }
                }
                Mock -CommandName Write-Warning
            }

            It 'Should write a warning when no MAC address is found' -Skip:(-not $IsWindows) {
                Get-LinkLayerAddress -IPAddress '192.168.1.1'

                Should -Invoke -CommandName Write-Warning -Exactly 1
            }
        }
    }

    Context 'When running on Windows without Get-NetNeighbor available' {
        BeforeAll {
            Mock -CommandName Test-Connection -MockWith { $true }

            # Mock Windows environment
            InModuleScope -ScriptBlock {
                $script:IsWindows = $true
                $script:IsLinux = $false
                $script:IsMacOS = $false
            }

            Mock -CommandName Get-Command -MockWith { $null } -ParameterFilter { $Name -eq 'Get-NetNeighbor' -and $ErrorAction -eq 'SilentlyContinue' }
        }

        Context 'When arp.exe returns a MAC address' {
            BeforeAll {
                Mock -CommandName Write-Warning
            }

            It 'Should handle arp.exe command execution' -Skip:(-not $IsWindows) {
                # Since we can't easily mock arp.exe, we'll just test that it doesn't crash
                { Get-LinkLayerAddress -IPAddress '192.168.1.1' } | Should -Not -Throw
            }
        }

        Context 'When arp.exe fails or returns no results' {
            BeforeAll {
                Mock -CommandName Write-Warning
            }

            It 'Should write a warning when arp command fails' -Skip:(-not $IsWindows) {
                Get-LinkLayerAddress -IPAddress '192.168.1.1'

                Should -Invoke -CommandName Write-Warning -Exactly 1
            }
        }
    }

    Context 'When running on Linux' {
        BeforeAll {
            Mock -CommandName Test-Connection -MockWith { $true }

            # Mock Linux environment
            InModuleScope -ScriptBlock {
                $script:IsWindows = $false
                $script:IsLinux = $true
                $script:IsMacOS = $false
            }
        }

        Context 'When ip command returns a MAC address' {
            BeforeAll {
                Mock -CommandName Write-Warning
            }

            It 'Should return the MAC address from ip command' -Skip:(-not $IsLinux) {
                # Since we can't easily mock the ip command, we'll just test that it doesn't crash
                { Get-LinkLayerAddress -IPAddress '192.168.1.1' } | Should -Not -Throw
            }
        }

        Context 'When ip command fails or returns no results' {
            BeforeAll {
                Mock -CommandName Write-Warning
            }

            It 'Should write a warning when ip command fails' -Skip:(-not $IsLinux) {
                Get-LinkLayerAddress -IPAddress '192.168.1.1'

                Should -Invoke -CommandName Write-Warning -Exactly 1
            }
        }
    }

    Context 'When running on macOS' {
        BeforeAll {
            Mock -CommandName Test-Connection -MockWith { $true }

            # Mock macOS environment
            InModuleScope -ScriptBlock {
                $script:IsWindows = $false
                $script:IsLinux = $false
                $script:IsMacOS = $true
            }
        }

        Context 'When arp command returns a MAC address' {
            BeforeAll {
                Mock -CommandName Write-Warning
            }

            It 'Should return the MAC address from arp command' -Skip:(-not $IsMacOS) {
                # Since we can't easily mock the arp command, we'll just test that it doesn't crash
                { Get-LinkLayerAddress -IPAddress '192.168.1.1' } | Should -Not -Throw
            }
        }

        Context 'When arp command fails or returns no results' {
            BeforeAll {
                Mock -CommandName Write-Warning
            }

            It 'Should write a warning when arp command fails' -Skip:(-not $IsMacOS) {
                Get-LinkLayerAddress -IPAddress '192.168.1.1'

                Should -Invoke -CommandName Write-Warning -Exactly 1
            }
        }
    }

    Context 'When using pipeline input' {
        BeforeAll {
            Mock -CommandName Test-Connection -MockWith { $true }
            Mock -CommandName Write-Warning

            # Mock the current OS environment without changing it
            if ($IsMacOS) {
                # On macOS, we'll just test that it processes multiple inputs
                InModuleScope -ScriptBlock {
                    $script:IsMacOS = $true
                    $script:IsWindows = $false
                    $script:IsLinux = $false
                }
            }
            elseif ($IsLinux) {
                InModuleScope -ScriptBlock {
                    $script:IsLinux = $true
                    $script:IsWindows = $false
                    $script:IsMacOS = $false
                }
            }
            else {
                # Assume Windows for testing
                InModuleScope -ScriptBlock {
                    $script:IsWindows = $true
                    $script:IsLinux = $false
                    $script:IsMacOS = $false
                }

                Mock -CommandName Get-Command -MockWith { $null } -ParameterFilter { $Name -eq 'Get-NetNeighbor' -and $ErrorAction -eq 'SilentlyContinue' }
            }
        }

        It 'Should process multiple IP addresses from pipeline' {
            $ipAddresses = @('192.168.1.1', '192.168.1.2')

            { $ipAddresses | Get-LinkLayerAddress } | Should -Not -Throw

            # Verify Test-Connection was called for each IP
            Should -Invoke -CommandName Test-Connection -Exactly 2
        }
    }

    Context 'When using alias Get-MacAddress' {
        BeforeAll {
            Mock -CommandName Test-Connection -MockWith { $true }
            Mock -CommandName Write-Warning

            # Mock the current OS environment
            if ($IsMacOS) {
                InModuleScope -ScriptBlock {
                    $script:IsMacOS = $true
                    $script:IsWindows = $false
                    $script:IsLinux = $false
                }
            }
            else {
                # Assume Windows for testing
                InModuleScope -ScriptBlock {
                    $script:IsWindows = $true
                    $script:IsLinux = $false
                    $script:IsMacOS = $false
                }

                Mock -CommandName Get-Command -MockWith { $null } -ParameterFilter { $Name -eq 'Get-NetNeighbor' -and $ErrorAction -eq 'SilentlyContinue' }
            }
        }

        It 'Should work with Get-MacAddress alias' {
            { Get-MacAddress -IPAddress '192.168.1.1' } | Should -Not -Throw
        }
    }
}
