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
}

Describe 'Assert-IPv4Address' {
    Context 'When validating valid IPv4 addresses in real environment' {
        BeforeDiscovery {
            $validIPAddresses = @(
                '192.168.1.1',
                '10.0.0.1',
                '172.16.0.1',
                '127.0.0.1',
                '0.0.0.0',
                '255.255.255.255',
                '203.0.113.1',
                '198.51.100.1'
            )
        }

        It 'Should successfully validate IPv4 address <_>' -ForEach $validIPAddresses {
            $null = Assert-IPv4Address -IPAddress $_
        }
    }

    Context 'When validating invalid IPv4 addresses in real environment' {
        BeforeDiscovery {
            $invalidIPAddresses = @(
                @{
                    IPAddress = '256.168.1.1'
                    ExpectedErrorId = 'AIV0003,Assert-IPv4Address'
                    Description = 'octet out of range'
                },
                @{
                    IPAddress = '192.168.01.1'
                    ExpectedErrorId = 'AIV0003,Assert-IPv4Address'
                    Description = 'leading zero'
                },
                @{
                    IPAddress = '192.168.1'
                    ExpectedErrorId = 'AIV0003,Assert-IPv4Address'
                    Description = 'invalid format'
                },
                @{
                    IPAddress = '192.168.1.1.1'
                    ExpectedErrorId = 'AIV0003,Assert-IPv4Address'
                    Description = 'too many octets'
                },
                @{
                    IPAddress = '192.168.1.a'
                    ExpectedErrorId = 'AIV0003,Assert-IPv4Address'
                    Description = 'non-numeric octet'
                },
                @{
                    IPAddress = '999.999.999.999'
                    ExpectedErrorId = 'AIV0003,Assert-IPv4Address'
                    Description = 'all octets out of range'
                }
            )
        }

        It 'Should throw exception for invalid IPv4 address with <Description>: <IPAddress>' -ForEach $invalidIPAddresses {
            {
                Assert-IPv4Address -IPAddress $_.IPAddress
            } | Should -Throw -ErrorId "$($_.ExpectedErrorId)"
        }
    }

    Context 'When testing command availability and help' {
        It 'Should be available as a public command' {
            Get-Command -Name 'Assert-IPv4Address' -Module $script:moduleName | Should -Not -BeNullOrEmpty
        }

        It 'Should have proper command help' {
            $help = Get-Help -Name 'Assert-IPv4Address'
            $help.Synopsis | Should -Not -BeNullOrEmpty
            $help.Description | Should -Not -BeNullOrEmpty
            $help.Examples | Should -Not -BeNullOrEmpty
        }

        It 'Should have mandatory IPAddress parameter' {
            $command = Get-Command -Name 'Assert-IPv4Address'
            $ipAddressParam = $command.Parameters['IPAddress']
            $ipAddressParam | Should -Not -BeNullOrEmpty
            $ipAddressParam.Attributes.Mandatory | Should -Contain $true
        }
    }

    Context 'When testing edge cases in real environment' {
        BeforeDiscovery {
            $edgeCaseTests = @(
                @{
                    IPAddress = '0.0.0.1'
                    ShouldPass = $true
                    Description = 'minimum valid with last octet 1'
                },
                @{
                    IPAddress = '254.254.254.254'
                    ShouldPass = $true
                    Description = 'near maximum valid'
                },
                @{
                    IPAddress = '192.168.255.0'
                    ShouldPass = $true
                    Description = 'network address with high third octet'
                },
                @{
                    IPAddress = '10.255.255.255'
                    ShouldPass = $true
                    Description = 'broadcast address in private range'
                }
            )
        }

        It 'Should handle edge case <Description>: <IPAddress>' -ForEach $edgeCaseTests {
            if ($_.ShouldPass) {
                $null = Assert-IPv4Address -IPAddress $_.IPAddress
            } else {
                {
                    Assert-IPv4Address -IPAddress $_.IPAddress
                } | Should -Throw
            }
        }
    }

    Context 'When testing parameter validation in real environment' {
        It 'Should throw ParameterArgumentValidationError for null input' {
            {
                Assert-IPv4Address -IPAddress $null
            } | Should -Throw -ErrorId 'ParameterArgumentValidationError*'
        }

        It 'Should throw ParameterArgumentValidationError for empty string' {
            {
                Assert-IPv4Address -IPAddress ''
            } | Should -Throw -ErrorId 'ParameterArgumentValidationError*'
        }

        It 'Should throw InvalidFormat error for whitespace string' {
            {
                Assert-IPv4Address -IPAddress '   '
            } | Should -Throw -ErrorId 'AIV0003*'
        }
    }
}
