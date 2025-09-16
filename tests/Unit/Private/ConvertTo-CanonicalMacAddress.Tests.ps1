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
                & "$PSScriptRoot/../../../../build.ps1" -Tasks 'noop' 3>&1 4>&1 5>&1 6>&1 > $null
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

Describe 'ConvertTo-CanonicalMacAddress' {
    Context 'When normalizing MAC addresses' {
        It 'Should normalize lowercase single-digit octets to uppercase two-digit format' {
            InModuleScope -ScriptBlock {
                $result = ConvertTo-CanonicalMacAddress -MacAddress '0a:0b:0c:0d:0e:0f'
                $result | Should -Be '0A:0B:0C:0D:0E:0F'
            }
        }

        It 'Should normalize mixed case and mixed single/double-digit octets' {
            InModuleScope -ScriptBlock {
                $result = ConvertTo-CanonicalMacAddress -MacAddress '1a:0B:c2:0D:e3:0F'
                $result | Should -Be '1A:0B:C2:0D:E3:0F'
            }
        }

        It 'Should handle already properly formatted MAC addresses' {
            InModuleScope -ScriptBlock {
                $result = ConvertTo-CanonicalMacAddress -MacAddress '00:11:22:33:44:55'
                $result | Should -Be '00:11:22:33:44:55'
            }
        }

        It 'Should normalize hyphen-separated MAC addresses' {
            InModuleScope -ScriptBlock {
                $result = ConvertTo-CanonicalMacAddress -MacAddress '00-11-22-33-44-55'
                $result | Should -Be '00:11:22:33:44:55'
            }
        }

        It 'Should normalize compact MAC addresses without separators' {
            InModuleScope -ScriptBlock {
                $result = ConvertTo-CanonicalMacAddress -MacAddress '001122334455'
                $result | Should -Be '00:11:22:33:44:55'
            }
        }

        It 'Should normalize MAC addresses with spaces' {
            InModuleScope -ScriptBlock {
                $result = ConvertTo-CanonicalMacAddress -MacAddress '00 11 22 33 44 55'
                $result | Should -Be '00:11:22:33:44:55'
            }
        }

        It 'Should handle MAC addresses with mixed separators' {
            InModuleScope -ScriptBlock {
                $result = ConvertTo-CanonicalMacAddress -MacAddress '00:11-22 33.44_55'
                $result | Should -Be '00:11:22:33:44:55'
            }
        }

        It 'Should convert lowercase to uppercase' {
            InModuleScope -ScriptBlock {
                $result = ConvertTo-CanonicalMacAddress -MacAddress 'aa:bb:cc:dd:ee:ff'
                $result | Should -Be 'AA:BB:CC:DD:EE:FF'
            }
        }
    }

    Context 'When handling invalid MAC addresses' {
        It 'Should return original value for MAC address with too few characters' {
            InModuleScope -ScriptBlock {
                $result = ConvertTo-CanonicalMacAddress -MacAddress '00:11:22:33:44'
                $result | Should -Be '00:11:22:33:44'
            }
        }

        It 'Should return original value for MAC address with too many characters' {
            InModuleScope -ScriptBlock {
                $result = ConvertTo-CanonicalMacAddress -MacAddress '00:11:22:33:44:55:66'
                $result | Should -Be '00:11:22:33:44:55:66'
            }
        }

        It 'Should return original value for MAC address with invalid hexadecimal characters' {
            InModuleScope -ScriptBlock {
                $result = ConvertTo-CanonicalMacAddress -MacAddress '00:11:22:33:44:GG'
                $result | Should -Be '00:11:22:33:44:GG'
            }
        }

        It 'Should return original value for empty string' {
            InModuleScope -ScriptBlock {
                $result = ConvertTo-CanonicalMacAddress -MacAddress ''
                $result | Should -Be ''
            }
        }

        It 'Should return original value for non-MAC string' {
            InModuleScope -ScriptBlock {
                $result = ConvertTo-CanonicalMacAddress -MacAddress 'not-a-mac-address'
                $result | Should -Be 'not-a-mac-address'
            }
        }

        It 'Should return original value for single-digit octets without padding' {
            InModuleScope -ScriptBlock {
                $result = ConvertTo-CanonicalMacAddress -MacAddress 'a:b:c:d:e:f'
                $result | Should -Be 'a:b:c:d:e:f'
            }
        }
    }
}
