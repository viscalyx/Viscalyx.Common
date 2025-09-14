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

    $script:outOfRangeAddresses = @(
        '256.168.1.1',        # First octet too high (passes regex, fails range)
        '192.256.1.1',        # Second octet too high
        '192.168.256.1',      # Third octet too high
        '192.168.1.256'       # Fourth octet too high
    )

    # Specific test cases for 256 in each octet position
    $script:octet256TestCases = @(
        @{ IPAddress = '256.168.1.1'; Position = 'first'; ExpectedError = 'AIV0004' }
        @{ IPAddress = '192.256.1.1'; Position = 'second'; ExpectedError = 'AIV0004' }
        @{ IPAddress = '192.168.256.1'; Position = 'third'; ExpectedError = 'AIV0004' }
        @{ IPAddress = '192.168.1.256'; Position = 'fourth'; ExpectedError = 'AIV0004' }
    )

    $script:leadingZeroAddresses = @(
        '192.168.01.1',       # Leading zero in third octet
        '192.168.1.01',       # Leading zero in fourth octet
        '01.168.1.1',         # Leading zero in first octet
        '192.01.1.1',         # Leading zero in second octet
        '01.01.01.01',        # Leading zeros in all octets
        '192.168.001.1',      # Multiple leading zeros
        '192.168.010.1'       # Leading zero with non-zero digit
    )

    $script:conversionFailureAddresses = @(
        '192.168.1.1e10',     # Scientific notation
        '192.168.1.0x10',     # Hexadecimal
        '192.168.1.+1',       # Plus sign
        '192.168.1.1.0'       # Decimal point in octet
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
            {
                Assert-IPv4Address -IPAddress '192.168.1.1'
            } | Should -Not -Throw
        }
    }

    Context 'When validating edge case valid IPv4 addresses' {
        It 'Should not throw an exception for IPv4 address <_>' -ForEach $script:validEdgeCaseAddresses {
            {
                Assert-IPv4Address -IPAddress $_
            } | Should -Not -Throw
        }
    }

    Context 'When validating an IPv4 address with invalid format' {
        It 'Should throw InvalidResult exception for invalid format <_>' -ForEach $script:invalidFormatAddresses {
            {
                Assert-IPv4Address -IPAddress $_
            } | Should -Throw -ErrorId 'AIV0003,Assert-IPv4Address'
        }
    }

    Context 'When validating an IPv4 address with octets out of range' {
        It 'Should throw exception for out of range octet in <_>' -ForEach $script:outOfRangeAddresses {
            {
                Assert-IPv4Address -IPAddress $_
            } | Should -Throw
        }
    }

    Context 'When validating IPv4 addresses with 256 in specific octet positions' {
        It 'Should throw AIV0004 exception when <Position> octet is 256 in <IPAddress>' -ForEach $script:octet256TestCases {
            {
                Assert-IPv4Address -IPAddress $_.IPAddress
            } | Should -Throw -ErrorId "$($_.ExpectedError),Assert-IPv4Address"
        }
    }

    Context 'When validating an IPv4 address with invalid leading zeros' {
        It 'Should throw exception for leading zero in <_>' -ForEach $script:leadingZeroAddresses {
            {
                Assert-IPv4Address -IPAddress $_
            } | Should -Throw
        }
    }

    Context 'When validating an IPv4 address with octet conversion failure' {
        It 'Should throw exception for conversion failure in <_>' -ForEach $script:conversionFailureAddresses {
            {
                Assert-IPv4Address -IPAddress $_
            } | Should -Throw
        }
    }

    Context 'When validating boundary values' {
        It 'Should not throw an exception for boundary value <_>' -ForEach $script:boundaryAddresses {
            {
                Assert-IPv4Address -IPAddress $_
            } | Should -Not -Throw
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
