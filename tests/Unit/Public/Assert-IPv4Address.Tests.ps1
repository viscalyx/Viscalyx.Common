[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification = 'Pester scoping confuses analyzer.')]
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

    # Test data arrays for ForEach tests
    $script:validEdgeCaseAddresses = @(
        '0.0.0.0',
        '255.255.255.255',
        '127.0.0.1',
        '10.0.0.1',
        '172.16.0.1',
        '203.0.113.1'
    )

    $script:invalidFormatAddresses = @(
        '192.168.1',           # Missing octet
        '192.168.1.1.1',      # Too many octets
        '192.168.1.a',        # Letter in octet
        '192.168..1',          # Empty octet
        '192.168.1.',          # Trailing period
        '.192.168.1.1',       # Leading period
        '192 168 1 1',         # Spaces instead of periods
        '192-168-1-1',         # Dashes instead of periods
        'not.an.ip.address',   # Non-numeric octets
        '192.168.1.1.0/24'     # CIDR notation
    )

    # Specific test cases for invalid IPv4 addresses (all should throw AIV0003)
    $script:invalidIPAddressTestCases = @(
        @{ IPAddress = '256.168.1.1'; Description = 'first octet 256' }
        @{ IPAddress = '192.256.1.1'; Description = 'second octet 256' }
        @{ IPAddress = '192.168.256.1'; Description = 'third octet 256' }
        @{ IPAddress = '192.168.1.256'; Description = 'fourth octet 256' }
        @{ IPAddress = '192.168.01.1'; Description = 'leading zero in third octet' }
        @{ IPAddress = '192.168.1.01'; Description = 'leading zero in fourth octet' }
        @{ IPAddress = '01.168.1.1'; Description = 'leading zero in first octet' }
        @{ IPAddress = '192.01.1.1'; Description = 'leading zero in second octet' }
        @{ IPAddress = '01.01.01.01'; Description = 'leading zeros in all octets' }
        @{ IPAddress = '192.168.001.1'; Description = 'multiple leading zeros' }
        @{ IPAddress = '192.168.010.1'; Description = 'leading zero with non-zero digit' }
        @{ IPAddress = '192.168.1.1e10'; Description = 'scientific notation' }
        @{ IPAddress = '192.168.1.0x10'; Description = 'hexadecimal' }
        @{ IPAddress = '192.168.1.+1'; Description = 'plus sign' }
        @{ IPAddress = '192.168.1.1.0'; Description = 'decimal point in octet' }
        @{ IPAddress = '192.168.1'; Description = 'missing octet' }
        @{ IPAddress = '192.168.1.1.1'; Description = 'too many octets' }
        @{ IPAddress = '192.168.1.a'; Description = 'letter in octet' }
        @{ IPAddress = '192.168..1'; Description = 'empty octet' }
        @{ IPAddress = '192.168.1.'; Description = 'trailing period' }
        @{ IPAddress = '.192.168.1.1'; Description = 'leading period' }
        @{ IPAddress = '192 168 1 1'; Description = 'spaces instead of periods' }
        @{ IPAddress = '192-168-1-1'; Description = 'dashes instead of periods' }
        @{ IPAddress = 'not.an.ip.address'; Description = 'non-numeric octets' }
        @{ IPAddress = '192.168.1.1.0/24'; Description = 'CIDR notation' }
    )

    $script:boundaryAddresses = @(
        '0.0.0.1',            # Minimum with last octet 1
        '1.0.0.0',            # Minimum with first octet 1
        '254.254.254.254',    # Near maximum
        '255.0.0.0',          # Maximum first octet
        '0.255.0.0',          # Maximum second octet
        '0.0.255.0',          # Maximum third octet
        '0.0.0.255'           # Maximum fourth octet
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

Describe 'Assert-IPv4Address' {
    Context 'When checking command structure' {
        It 'Should have the correct parameters in parameter set <ExpectedParameterSetName>' -ForEach @(
            @{
                ExpectedParameterSetName = '__AllParameterSets'
                ExpectedParameters = '[-IPAddress] <String> [<CommonParameters>]'
            }
        ) {
            $result = (Get-Command -Name 'Assert-IPv4Address').ParameterSets |
                Where-Object -FilterScript { $_.Name -eq $ExpectedParameterSetName } |
                Select-Object -Property @(
                    @{ Name = 'ParameterSetName'; Expression = { $_.Name } },
                    @{ Name = 'ParameterListAsString'; Expression = { $_.ToString() } }
                )
            $result.ParameterSetName | Should -Be $ExpectedParameterSetName
            $result.ParameterListAsString | Should -Be $ExpectedParameters
        }

        It 'Should have IPAddress as a mandatory parameter' {
            $parameterInfo = (Get-Command -Name 'Assert-IPv4Address').Parameters['IPAddress']
            $parameterInfo.Attributes.Mandatory | Should -BeTrue
        }
    }

    Context 'When validating a valid IPv4 address' {
        It 'Should not throw an exception for a valid IPv4 address' {
            $null = Assert-IPv4Address -IPAddress '192.168.1.1'
        }
    }

    Context 'When validating edge case valid IPv4 addresses' {
        It 'Should not throw an exception for IPv4 address <_>' -ForEach $script:validEdgeCaseAddresses {
            $null = Assert-IPv4Address -IPAddress $_
        }
    }

    Context 'When validating an invalid IPv4 address' {
        It 'Should throw InvalidResult exception for <Description>: <IPAddress>' -ForEach $script:invalidIPAddressTestCases {
            {
                Assert-IPv4Address -IPAddress $_.IPAddress
            } | Should -Throw -ErrorId 'AIV0003,Assert-IPv4Address'
        }
    }

    Context 'When validating boundary values' {
        It 'Should not throw an exception for boundary value <_>' -ForEach $script:boundaryAddresses {
            $null = Assert-IPv4Address -IPAddress $_
        }
    }

    Context 'When parameter validation occurs' {
        It 'Should throw ParameterArgumentValidationError when IPAddress is null' {
            {
                Assert-IPv4Address -IPAddress $null
            } | Should -Throw -ErrorId 'ParameterArgumentValidationError*'
        }

        It 'Should throw ParameterArgumentValidationError when IPAddress is empty string' {
            {
                Assert-IPv4Address -IPAddress ''
            } | Should -Throw -ErrorId 'ParameterArgumentValidationError*'
        }

        It 'Should throw InvalidResult exception when IPAddress is whitespace only' {
            {
                Assert-IPv4Address -IPAddress '   '
            } | Should -Throw -ErrorId 'AIV0003,Assert-IPv4Address'
        }
    }
}
