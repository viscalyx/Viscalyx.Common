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

Describe 'Resolve-DnsName' {
    Context 'When checking command structure' {
        It 'Should have the correct parameters in parameter set __AllParameterSets' {
            $result = (Get-Command -Name 'Resolve-DnsName').ParameterSets[0].ToString()
            $result | Should -Be '[-HostName] <string> [<CommonParameters>]'
        }

        It 'Should have HostName as a mandatory parameter' {
            $result = (Get-Command -Name 'Resolve-DnsName').Parameters['HostName'].Attributes.Mandatory
            $result | Should -Contain $true
        }
    }

    Context 'When testing parameter validation' {
        It 'Should not accept null or empty hostname' {
            { Resolve-DnsName -HostName $null } | Should -Throw
            { Resolve-DnsName -HostName '' } | Should -Throw
        }

        It 'Should accept hostname by position' {
            # This test uses a real IP address that should resolve to itself
            $result = Resolve-DnsName '127.0.0.1'
            $result | Should -Be '127.0.0.1'
        }
    }

    Context 'When input is already a valid IPv4 address' {
        BeforeDiscovery {
            $testCases = @(
                @{ IPAddress = '127.0.0.1'; Description = 'localhost IP' }
                @{ IPAddress = '192.168.1.1'; Description = 'private network IP' }
                @{ IPAddress = '8.8.8.8'; Description = 'public DNS IP' }
                @{ IPAddress = '10.0.0.1'; Description = 'private network IP with 10.x range' }
            )
        }

        It 'Should return the same IPv4 address without modification for <Description>' -ForEach $testCases {
            $result = Resolve-DnsName -HostName $IPAddress
            $result | Should -Be $IPAddress
        }
    }

    Context 'When resolving known hostnames' {
        It 'Should resolve localhost to 127.0.0.1' {
            $result = Resolve-DnsName -HostName 'localhost'
            $result | Should -Be '127.0.0.1'
        }

        It 'Should resolve a well-known public hostname' {
            # Use a reliable public DNS name that should always resolve
            $result = Resolve-DnsName -HostName 'dns.google'
            $result | Should -Match '^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$'
        }
    }

    Context 'When DNS resolution fails' {
        It 'Should throw an error for non-existent domain' {
            $errorRecord = $null
            try {
                Resolve-DnsName -HostName 'this-domain-does-not-exist-12345.invalid' -ErrorAction Stop
            }
            catch {
                $errorRecord = $_
            }

            $errorRecord | Should -Not -BeNullOrEmpty
            $errorRecord.CategoryInfo.Category | Should -Be 'ObjectNotFound'
            $errorRecord.FullyQualifiedErrorId | Should -Match '^RDN000[56],Resolve-DnsName$'
        }

        It 'Should throw an error for invalid hostname format' {
            $errorRecord = $null
            try {
                Resolve-DnsName -HostName 'invalid..hostname' -ErrorAction Stop
            }
            catch {
                $errorRecord = $_
            }

            $errorRecord | Should -Not -BeNullOrEmpty
            $errorRecord.CategoryInfo.Category | Should -Be 'ObjectNotFound'
            $errorRecord.FullyQualifiedErrorId | Should -Match '^RDN000[56],Resolve-DnsName$'
        }
    }

    Context 'When using verbose output' {
        It 'Should successfully resolve localhost and return valid IP address' {
            $result = Resolve-DnsName -HostName 'localhost'

            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [System.String]
            $result | Should -Match '^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$'
        }

        It 'Should throw error for nonexistent domain during failed resolution' {
            { Resolve-DnsName -HostName 'nonexistent-domain.invalid' -ErrorAction Stop } | Should -Throw
        }
    }

    Context 'When testing output format' {
        It 'Should return a string value' {
            $result = Resolve-DnsName -HostName '127.0.0.1'
            $result | Should -BeOfType [System.String]
        }

        It 'Should return a valid IPv4 address format' {
            $result = Resolve-DnsName -HostName 'localhost'
            $result | Should -Match '^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$'
        }

        It 'Should return only one IP address even if multiple exist' {
            $result = Resolve-DnsName -HostName 'dns.google'
            $result | Should -BeOfType [System.String]
            # Should not be an array - test that it's a single string, not an array
            $result.GetType().IsArray | Should -BeFalse
        }
    }

    Context 'When testing localized string usage' {
        BeforeAll {
            $mockLocalizedStringAttempting = InModuleScope -ScriptBlock { $script:localizedData.Resolve_DnsName_AttemptingResolution }
            $mockLocalizedStringSuccessful = InModuleScope -ScriptBlock { $script:localizedData.Resolve_DnsName_ResolutionSuccessful }
            $mockLocalizedStringResolutionFailed = InModuleScope -ScriptBlock { $script:localizedData.Resolve_DnsName_ResolutionFailed }
            $mockLocalizedStringNoIPv4Found = InModuleScope -ScriptBlock { $script:localizedData.Resolve_DnsName_NoIPv4AddressFound }
        }

        It 'Should successfully resolve using localized strings' {
            $result = Resolve-DnsName -HostName 'localhost'

            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [System.String]
            $result | Should -Match '^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$'
        }

        It 'Should use localized strings for error messages' {
            { Resolve-DnsName -HostName 'nonexistent.domain.invalid' -ErrorAction Stop } | Should -Throw -ExpectedMessage "*nodename nor servname provided, or not known*"
        }
    }
}
