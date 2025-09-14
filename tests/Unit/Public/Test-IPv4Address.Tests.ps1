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

    # Test data arrays for ForEach tests
    $script:validIPv4Addresses = @(
        '0.0.0.0',
        '255.255.255.255',
        '127.0.0.1',
        '10.0.0.1',
        '172.16.0.1',
        '203.0.113.1',
        '192.168.1.1',
        '1.1.1.1',
        '8.8.8.8',
        '0.0.0.1',
        '1.0.0.0',
        '254.254.254.254',
        '255.0.0.0',
        '0.255.0.0',
        '0.0.255.0',
        '0.0.0.255'
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
        '192.168.1.1.0/24',   # CIDR notation
        '   ',                 # Whitespace only
        'abc.def.ghi.jkl'      # All letters
    )

    $script:outOfRangeAddresses = @(
        '256.168.1.1',        # First octet too high
        '192.256.1.1',        # Second octet too high
        '192.168.256.1',      # Third octet too high
        '192.168.1.256',      # Fourth octet too high
        '300.300.300.300',    # All octets too high
        '999.999.999.999'     # Way out of range
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

    # Test cases that should return true
    $script:validTestCases = @(
        @{ IPAddress = '192.168.1.1'; Description = 'standard private IP' }
        @{ IPAddress = '0.0.0.0'; Description = 'all zeros' }
        @{ IPAddress = '255.255.255.255'; Description = 'all max values' }
        @{ IPAddress = '127.0.0.1'; Description = 'localhost' }
        @{ IPAddress = '8.8.8.8'; Description = 'Google DNS' }
    )

    # Test cases that should return false
    $script:invalidTestCases = @(
        @{ IPAddress = '256.1.1.1'; Description = 'first octet over 255'; ExpectedReason = 'out of range' }
        @{ IPAddress = '1.256.1.1'; Description = 'second octet over 255'; ExpectedReason = 'out of range' }
        @{ IPAddress = '1.1.256.1'; Description = 'third octet over 255'; ExpectedReason = 'out of range' }
        @{ IPAddress = '1.1.1.256'; Description = 'fourth octet over 255'; ExpectedReason = 'out of range' }
        @{ IPAddress = '192.168.01.1'; Description = 'leading zero in third octet'; ExpectedReason = 'leading zero' }
        @{ IPAddress = '192.168.1'; Description = 'missing fourth octet'; ExpectedReason = 'invalid format' }
        @{ IPAddress = '192.168.1.1.1'; Description = 'too many octets'; ExpectedReason = 'invalid format' }
        @{ IPAddress = '192.168.1.a'; Description = 'letter in fourth octet'; ExpectedReason = 'invalid format' }
        @{ IPAddress = '192.168..1'; Description = 'empty third octet'; ExpectedReason = 'invalid format' }
        @{ IPAddress = '192.168.1.'; Description = 'trailing period'; ExpectedReason = 'invalid format' }
        @{ IPAddress = '.192.168.1.1'; Description = 'leading period'; ExpectedReason = 'invalid format' }
        @{ IPAddress = '192 168 1 1'; Description = 'spaces instead of periods'; ExpectedReason = 'invalid format' }
        @{ IPAddress = '192.168.1.1e10'; Description = 'scientific notation'; ExpectedReason = 'conversion failure' }
        @{ IPAddress = '192.168.1.0x10'; Description = 'hexadecimal format'; ExpectedReason = 'conversion failure' }
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

Describe 'Test-IPv4Address' {
    Context 'When checking command structure' {
        It 'Should have the correct parameters in parameter set <ExpectedParameterSetName>' -ForEach @(
            @{
                ExpectedParameterSetName = '__AllParameterSets'
                ExpectedParameters = '[-IPAddress] <String> [<CommonParameters>]'
            }
        ) {
            $result = (Get-Command -Name 'Test-IPv4Address').ParameterSets |
                Where-Object -FilterScript { $_.Name -eq $ExpectedParameterSetName } |
                Select-Object -Property @(
                    @{ Name = 'ParameterSetName'; Expression = { $_.Name } },
                    @{ Name = 'ParameterListAsString'; Expression = { $_.ToString() } }
                )
            $result.ParameterSetName | Should -Be $ExpectedParameterSetName
            $result.ParameterListAsString | Should -Be $ExpectedParameters
        }

        It 'Should have IPAddress as a mandatory parameter' {
            $parameterInfo = (Get-Command -Name 'Test-IPv4Address').Parameters['IPAddress']
            $parameterInfo.Attributes.Mandatory | Should -BeTrue
        }

        It 'Should have OutputType attribute set to Boolean' {
            $command = Get-Command -Name 'Test-IPv4Address'
            $outputType = $command.OutputType.Type
            $outputType.Name | Should -Contain 'Boolean'
        }
    }

    Context 'When testing valid IPv4 addresses' {
        It 'Should return True for valid IPv4 address <_>' -ForEach $script:validIPv4Addresses {
            Test-IPv4Address -IPAddress $_ | Should -BeTrue
        }

        It 'Should return True for valid IPv4 address: <Description>' -ForEach $script:validTestCases {
            Test-IPv4Address -IPAddress $_.IPAddress | Should -BeTrue
        }
    }

    Context 'When testing invalid IPv4 addresses' {
        It 'Should return False for invalid format <_>' -ForEach $script:invalidFormatAddresses {
            Test-IPv4Address -IPAddress $_ | Should -BeFalse
        }

        It 'Should return False for out of range octet <_>' -ForEach $script:outOfRangeAddresses {
            Test-IPv4Address -IPAddress $_ | Should -BeFalse
        }

        It 'Should return False for leading zero address <_>' -ForEach $script:leadingZeroAddresses {
            Test-IPv4Address -IPAddress $_ | Should -BeFalse
        }

        It 'Should return False for conversion failure address <_>' -ForEach $script:conversionFailureAddresses {
            Test-IPv4Address -IPAddress $_ | Should -BeFalse
        }

        It 'Should return False for <Description>: <IPAddress>' -ForEach $script:invalidTestCases {
            Test-IPv4Address -IPAddress $_.IPAddress | Should -BeFalse
        }
    }

    Context 'When parameter validation occurs' {
        It 'Should throw ParameterArgumentValidationError when IPAddress is null' {
            {
                Test-IPv4Address -IPAddress $null
            } | Should -Throw -ErrorId 'ParameterArgumentValidationError*'
        }

        It 'Should throw ParameterArgumentValidationError when IPAddress is empty string' {
            {
                Test-IPv4Address -IPAddress ''
            } | Should -Throw -ErrorId 'ParameterArgumentValidationError*'
        }

        It 'Should return False when IPAddress is whitespace only' {
            Test-IPv4Address -IPAddress '   ' | Should -BeFalse
        }
    }

    Context 'When testing edge cases' {
        It 'Should return True for minimum valid address 0.0.0.0' {
            Test-IPv4Address -IPAddress '0.0.0.0' | Should -BeTrue
        }

        It 'Should return True for maximum valid address 255.255.255.255' {
            Test-IPv4Address -IPAddress '255.255.255.255' | Should -BeTrue
        }

        It 'Should return False for address with octet 256' {
            Test-IPv4Address -IPAddress '256.0.0.0' | Should -BeFalse
        }

        It 'Should return False for negative octet values (conversion should fail)' {
            Test-IPv4Address -IPAddress '-1.0.0.0' | Should -BeFalse
        }

        It 'Should return True for single digit octets' {
            Test-IPv4Address -IPAddress '1.2.3.4' | Should -BeTrue
        }

        It 'Should return True for three digit octets at maximum' {
            Test-IPv4Address -IPAddress '100.200.255.254' | Should -BeTrue
        }
    }

    Context 'When testing verbose output' {
        It 'Should write verbose messages when -Verbose is used' {
            $verboseOutput = Test-IPv4Address -IPAddress '192.168.1.1' -Verbose 4>&1
            $verboseOutput | Should -Not -BeNullOrEmpty
        }

        It 'Should write verbose validation message for valid address' {
            $verboseOutput = Test-IPv4Address -IPAddress '192.168.1.1' -Verbose 4>&1
            $verboseOutput -join ' ' | Should -Match 'Testing IPv4 address format'
        }

        It 'Should write verbose validation message for invalid address' {
            $verboseOutput = Test-IPv4Address -IPAddress '256.168.1.1' -Verbose 4>&1
            $verboseOutput -join ' ' | Should -Match 'Testing IPv4 address format'
        }
    }

    Context 'When testing return values' {
        It 'Should return exactly $true for valid addresses' {
            $result = Test-IPv4Address -IPAddress '192.168.1.1'
            $result | Should -BeExactly $true
            $result.GetType().Name | Should -Be 'Boolean'
        }

        It 'Should return exactly $false for invalid addresses' {
            $result = Test-IPv4Address -IPAddress '256.168.1.1'
            $result | Should -BeExactly $false
            $result.GetType().Name | Should -Be 'Boolean'
        }
    }
}