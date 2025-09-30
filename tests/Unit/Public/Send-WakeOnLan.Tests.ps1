[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification = 'Pester scoping confuses analyzer.')]
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

Describe 'Send-WakeOnLan' {
    Context 'When checking command structure' {
        It 'Should have the correct parameters in parameter set __AllParameterSets' {
            $result = (Get-Command -Name 'Send-WakeOnLan').ParameterSets[0].ToString()

            if ($PSVersionTable.PSVersion.Major -eq 5)
            {
                # Windows PowerShell 5.1 shows <uint16> for System.UInt16 type
                $result | Should -Be '[-LinkLayerAddress] <string> [[-Broadcast] <string>] [[-Port] <uint16>] [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]'
            }
            else
            {
                # PowerShell Core/7+ shows <ushort> for System.UInt16 type
                $result | Should -Be '[-LinkLayerAddress] <string> [[-Broadcast] <string>] [[-Port] <ushort>] [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]'
            }
        }

        It 'Should have LinkLayerAddress as a mandatory parameter' {
            $result = (Get-Command -Name 'Send-WakeOnLan').Parameters['LinkLayerAddress'].Attributes.Mandatory
            $result | Should -Contain $true
        }
    }

    Context 'When sending Wake-on-LAN packet with valid parameters' {
        BeforeAll {
            Mock -CommandName Write-Verbose
            Mock -CommandName Write-Debug

            # Mock the UDP client to avoid actual network operations
            $mockUdpClient = [PSCustomObject] @{
                EnableBroadcast = $false
                ConnectCalled   = $false
                SendCalled      = $false
                CloseCalled     = $false
                DisposeCalled   = $false
                ConnectedHost   = $null
                ConnectedPort   = $null
                SentPacket      = $null
                SentLength      = $null
            }

            # Add methods to the mock object
            $mockUdpClient | Add-Member -MemberType ScriptMethod -Name 'Connect' -Value {
                param($hostAddress, $portNumber)
                $this.ConnectCalled = $true
                $this.ConnectedHost = $hostAddress
                $this.ConnectedPort = $portNumber
            }

            $mockUdpClient | Add-Member -MemberType ScriptMethod -Name 'Send' -Value {
                param($packet, $length)
                $this.SendCalled = $true
                $this.SentPacket = $packet
                $this.SentLength = $length
                return $length
            }

            $mockUdpClient | Add-Member -MemberType ScriptMethod -Name 'Close' -Value {
                $this.CloseCalled = $true
            }

            $mockUdpClient | Add-Member -MemberType ScriptMethod -Name 'Dispose' -Value {
                $this.DisposeCalled = $true
            }

            Mock -CommandName New-Object -ParameterFilter {
                $TypeName -eq 'System.Net.Sockets.UdpClient'
            } -MockWith {
                return $mockUdpClient
            }
        }

        It 'Should send packet with colon-separated MAC address' {
            $null = Send-WakeOnLan -LinkLayerAddress '00:11:22:33:44:55' -Force

            $mockUdpClient.ConnectCalled | Should -BeTrue
            $mockUdpClient.SendCalled | Should -BeTrue
            $mockUdpClient.CloseCalled | Should -BeTrue
            $mockUdpClient.DisposeCalled | Should -BeTrue
            $mockUdpClient.ConnectedHost | Should -Be '255.255.255.255'
            $mockUdpClient.ConnectedPort | Should -Be 9
            $mockUdpClient.SentLength | Should -Be 102
        }

        It 'Should send packet with hyphen-separated MAC address' {
            $null = Send-WakeOnLan -LinkLayerAddress '00-11-22-33-44-55' -Force

            $mockUdpClient.ConnectCalled | Should -BeTrue
            $mockUdpClient.SendCalled | Should -BeTrue
            $mockUdpClient.ConnectedHost | Should -Be '255.255.255.255'
            $mockUdpClient.ConnectedPort | Should -Be 9
        }

        It 'Should send packet with no-separator MAC address' {
            $null = Send-WakeOnLan -LinkLayerAddress '001122334455' -Force

            $mockUdpClient.ConnectCalled | Should -BeTrue
            $mockUdpClient.SendCalled | Should -BeTrue
            $mockUdpClient.ConnectedHost | Should -Be '255.255.255.255'
            $mockUdpClient.ConnectedPort | Should -Be 9
        }

        It 'Should send packet with custom broadcast address' {
            $null = Send-WakeOnLan -LinkLayerAddress '00:11:22:33:44:55' -Broadcast '192.168.1.255' -Force

            $mockUdpClient.ConnectedHost | Should -Be '192.168.1.255'
            $mockUdpClient.ConnectedPort | Should -Be 9
        }

        It 'Should send packet with custom port' {
            $null = Send-WakeOnLan -LinkLayerAddress '00:11:22:33:44:55' -Port 7 -Force

            $mockUdpClient.ConnectedHost | Should -Be '255.255.255.255'
            $mockUdpClient.ConnectedPort | Should -Be 7
        }

        It 'Should work with MacAddress alias' {
            $null = Send-WakeOnLan -MacAddress '00:11:22:33:44:55' -Force

            $mockUdpClient.ConnectCalled | Should -BeTrue
            $mockUdpClient.SendCalled | Should -BeTrue
        }

        It 'Should enable broadcast on UDP client' {
            $null = Send-WakeOnLan -LinkLayerAddress '00:11:22:33:44:55' -Force

            $mockUdpClient.EnableBroadcast | Should -BeTrue
        }

        It 'Should create correct magic packet structure' {
            $null = Send-WakeOnLan -LinkLayerAddress '00:11:22:33:44:55' -Force

            # Magic packet should be 102 bytes: 6 bytes of 0xFF + (6 bytes MAC * 16 repetitions)
            $mockUdpClient.SentLength | Should -Be 102

            # Check that packet starts with 6 bytes of 0xFF
            $packet = $mockUdpClient.SentPacket
            for ($i = 0; $i -lt 6; $i++)
            {
                $packet[$i] | Should -Be 255
            }

            # Check that the MAC address is repeated 16 times
            $expectedMacBytes = @(0x00, 0x11, 0x22, 0x33, 0x44, 0x55)
            for ($repetition = 0; $repetition -lt 16; $repetition++)
            {
                for ($byteIndex = 0; $byteIndex -lt 6; $byteIndex++)
                {
                    $packetIndex = 6 + ($repetition * 6) + $byteIndex
                    $packet[$packetIndex] | Should -Be $expectedMacBytes[$byteIndex]
                }
            }
        }
    }

    Context 'When pipeline input is provided' {
        BeforeAll {
            Mock -CommandName Write-Verbose
            Mock -CommandName Write-Debug

            Mock -CommandName New-Object -ParameterFilter {
                $TypeName -eq 'System.Net.Sockets.UdpClient'
            } -MockWith {
                $mockUdpClient = [PSCustomObject] @{
                    EnableBroadcast = $false
                    ConnectCalled   = $false
                    SendCalled      = $false
                    CloseCalled     = $false
                    DisposeCalled   = $false
                }

                $mockUdpClient | Add-Member -MemberType ScriptMethod -Name 'Connect' -Value {
                    $this.ConnectCalled = $true
                }

                $mockUdpClient | Add-Member -MemberType ScriptMethod -Name 'Send' -Value {
                    param($packet, $length)
                    $this.SendCalled = $true
                    return $length
                }

                $mockUdpClient | Add-Member -MemberType ScriptMethod -Name 'Close' -Value {
                    $this.CloseCalled = $true
                }

                $mockUdpClient | Add-Member -MemberType ScriptMethod -Name 'Dispose' -Value {
                    $this.DisposeCalled = $true
                }

                return $mockUdpClient
            }
        }

        It 'Should process multiple MAC addresses from pipeline' {
            $macAddresses = @('00:11:22:33:44:55', '00-AA-BB-CC-DD-EE', '001122334455')

            $macAddresses | Send-WakeOnLan -Force

            Should -Invoke -CommandName New-Object -ParameterFilter {
                $TypeName -eq 'System.Net.Sockets.UdpClient'
            } -Exactly 3 -Scope It
        }
    }

    Context 'When WhatIf is specified' {
        BeforeAll {
            Mock -CommandName Write-Verbose
            Mock -CommandName Write-Debug
            Mock -CommandName New-Object -ParameterFilter {
                $TypeName -eq 'System.Net.Sockets.UdpClient'
            }
        }

        It 'Should not create UDP client when using WhatIf' {
            $null = Send-WakeOnLan -LinkLayerAddress '00:11:22:33:44:55' -WhatIf

            Should -Invoke -CommandName New-Object -ParameterFilter {
                $TypeName -eq 'System.Net.Sockets.UdpClient'
            } -Exactly 0 -Scope It
        }
    }

    Context 'When Force parameter is used' {
        BeforeAll {
            Mock -CommandName Write-Verbose
            Mock -CommandName Write-Debug

            $mockUdpClient = [PSCustomObject] @{
                EnableBroadcast = $false
                ConnectCalled   = $false
                SendCalled      = $false
            }

            $mockUdpClient | Add-Member -MemberType ScriptMethod -Name 'Connect' -Value {
                $this.ConnectCalled = $true
            }

            $mockUdpClient | Add-Member -MemberType ScriptMethod -Name 'Send' -Value {
                param($packet, $length)
                $this.SendCalled = $true
                return $length
            }

            $mockUdpClient | Add-Member -MemberType ScriptMethod -Name 'Close' -Value { }
            $mockUdpClient | Add-Member -MemberType ScriptMethod -Name 'Dispose' -Value { }

            Mock -CommandName New-Object -ParameterFilter {
                $TypeName -eq 'System.Net.Sockets.UdpClient'
            } -MockWith {
                return $mockUdpClient
            }
        }

        It 'Should bypass confirmation when Force is specified' {
            $null = Send-WakeOnLan -LinkLayerAddress '00:11:22:33:44:55' -Force

            $mockUdpClient.ConnectCalled | Should -BeTrue
            $mockUdpClient.SendCalled | Should -BeTrue
        }
    }

    Context 'When invalid MAC address is provided' {
        It 'Should throw error for invalid MAC address format' {
            { Send-WakeOnLan -LinkLayerAddress 'invalid' -Force } |
                Should -Throw -ExpectedMessage '*does not match the*pattern*'
        }

        It 'Should throw error for MAC address with wrong length' {
            { Send-WakeOnLan -LinkLayerAddress '00:11:22:33:44' -Force } |
                Should -Throw -ExpectedMessage '*does not match the*pattern*'
        }

        It 'Should throw error for MAC address with invalid characters' {
            { Send-WakeOnLan -LinkLayerAddress 'GG:11:22:33:44:55' -Force } |
                Should -Throw -ExpectedMessage '*does not match the*pattern*'
        }
    }

    Context 'When invalid parameters are provided' {
        It 'Should validate broadcast IP address format' {
            { Send-WakeOnLan -LinkLayerAddress '00:11:22:33:44:55' -Broadcast 'invalid.ip' -Force } |
                Should -Throw
        }

        It 'Should validate port range' {
            { Send-WakeOnLan -LinkLayerAddress '00:11:22:33:44:55' -Port 70000 -Force } |
                Should -Throw
        }
    }

    Context 'When UDP client operations fail' {
        BeforeAll {
            Mock -CommandName Write-Verbose
            Mock -CommandName Write-Debug

            $mockUdpClient = [PSCustomObject] @{
                EnableBroadcast = $false
                DisposeCalled   = $false
                CloseCalled     = $false
            }

            $mockUdpClient | Add-Member -MemberType ScriptMethod -Name 'Connect' -Value {
                throw 'Network error'
            }

            $mockUdpClient | Add-Member -MemberType ScriptMethod -Name 'Send' -Value {
                throw 'Send error'
            }

            $mockUdpClient | Add-Member -MemberType ScriptMethod -Name 'Close' -Value {
                $this.CloseCalled = $true
            }

            $mockUdpClient | Add-Member -MemberType ScriptMethod -Name 'Dispose' -Value {
                $this.DisposeCalled = $true
            }

            Mock -CommandName New-Object -ParameterFilter {
                $TypeName -eq 'System.Net.Sockets.UdpClient'
            } -MockWith {
                return $mockUdpClient
            }
        }

        It 'Should properly dispose UDP client even when Connect fails' {
            { Send-WakeOnLan -LinkLayerAddress '00:11:22:33:44:55' -Force } | Should -Throw -ExpectedMessage '*Failed to send Wake-on-LAN packet*'

            $mockUdpClient.CloseCalled | Should -BeTrue
            $mockUdpClient.DisposeCalled | Should -BeTrue
        }
    }

    Context 'When using command aliases' {
        BeforeAll {
            Mock -CommandName Write-Verbose
            Mock -CommandName Write-Debug

            $mockUdpClient = [PSCustomObject] @{
                EnableBroadcast = $false
                ConnectCalled   = $false
                SendCalled      = $false
            }

            $mockUdpClient | Add-Member -MemberType ScriptMethod -Name 'Connect' -Value {
                $this.ConnectCalled = $true
            }

            $mockUdpClient | Add-Member -MemberType ScriptMethod -Name 'Send' -Value {
                param($packet, $length)
                $this.SendCalled = $true
                return $length
            }

            $mockUdpClient | Add-Member -MemberType ScriptMethod -Name 'Close' -Value { }
            $mockUdpClient | Add-Member -MemberType ScriptMethod -Name 'Dispose' -Value { }

            Mock -CommandName New-Object -ParameterFilter {
                $TypeName -eq 'System.Net.Sockets.UdpClient'
            } -MockWith {
                return $mockUdpClient
            }
        }

        It 'Should work with Send-WOL alias' {
            $null = Send-WOL -LinkLayerAddress '00:11:22:33:44:55' -Force

            $mockUdpClient.ConnectCalled | Should -BeTrue
            $mockUdpClient.SendCalled | Should -BeTrue
        }
    }
}
