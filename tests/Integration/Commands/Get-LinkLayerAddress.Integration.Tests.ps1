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

Describe 'Get-LinkLayerAddress' {
    Context 'When querying a reachable IP address' {
        BeforeAll {
            # Use a common gateway IP that should be reachable in most environments
            # This will vary by environment, so we'll try multiple common gateway IPs
            $commonGatewayIPs = @('192.168.1.1', '192.168.0.1', '10.0.0.1', '172.16.0.1')
            $reachableIP = $null

            foreach ($ip in $commonGatewayIPs)
            {
                if (Test-Connection -ComputerName $ip -Count 1 -Quiet -ErrorAction SilentlyContinue)
                {
                    $reachableIP = $ip
                    break
                }
            }
        }

        Context 'When a reachable gateway is found' {
            It 'Should return a MAC address for the reachable gateway' -Skip:($null -eq $reachableIP) {
                $result = Get-LinkLayerAddress -IPAddress $reachableIP

                $result | Should -Not -BeNullOrEmpty
                # MAC address should be normalized to xx:xx:xx:xx:xx:xx (lower-case)
                $result | Should -Match '^([0-9a-f]{2}:){5}[0-9a-f]{2}$'
            }

            It 'Should work with pipeline input for the reachable gateway' -Skip:($null -eq $reachableIP) {
                $result = $reachableIP | Get-LinkLayerAddress

                $result | Should -Not -BeNullOrEmpty
                $result | Should -Match '^([0-9a-fA-F]{2}[:-]){5}[0-9a-fA-F]{2}$'
            }

            It 'Should work with Get-MacAddress alias for the reachable gateway' -Skip:($null -eq $reachableIP) {
                $result = Get-MacAddress -IPAddress $reachableIP

                $result | Should -Not -BeNullOrEmpty
                $result | Should -Match '^([0-9a-fA-F]{2}[:-]){5}[0-9a-fA-F]{2}$'
            }
        }

        Context 'When no reachable gateway is found' {
            It 'Should skip integration tests if no reachable gateway is available' -Skip:($null -ne $reachableIP) {
                # This test will only run if no reachable gateway was found
                Write-Warning 'No reachable gateway found. Integration tests for Get-LinkLayerAddress were skipped.'
                $true | Should -BeTrue  # Always pass this test
            }
        }
    }

    Context 'When querying an unreachable IP address' {
        It 'Should return a warning for an unreachable IP address' {
            # Use an IP that should not be reachable (reserved for documentation)
            $unreachableIP = '203.0.113.1'  # RFC 5737 - Reserved for documentation

            $warningOutput = $null
            $result = Get-LinkLayerAddress -IPAddress $unreachableIP -WarningVariable warningOutput

            $result | Should -BeNullOrEmpty
            $warningOutput | Should -Not -BeNullOrEmpty
        }
    }

    Context 'When using invalid IP address formats' {
        It 'Should throw an error for invalid IP address format' {
            { Get-LinkLayerAddress -IPAddress 'invalid.ip' } | Should -Throw
        }

        It 'Should throw an error for IP address with values over 255' {
            { Get-LinkLayerAddress -IPAddress '300.1.1.1' } | Should -Throw
        }

        It 'Should throw an error for incomplete IP address' {
            { Get-LinkLayerAddress -IPAddress '192.168.1' } | Should -Throw
        }
    }
}
