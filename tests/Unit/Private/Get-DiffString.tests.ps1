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
                & "$PSScriptRoot/../../../build.ps1" -Tasks 'noop' 2>&1 4>&1 5>&1 6>&1 > $null
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
    $script:dscModuleName = 'Viscalyx.Common'

    Import-Module -Name $script:dscModuleName

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:dscModuleName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:dscModuleName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:dscModuleName
}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    # Unload the module being tested so that it doesn't impact any other tests.
    Get-Module -Name $script:dscModuleName -All | Remove-Module -Force
}

Describe 'Get-DiffString' {
    It 'Should return a formatted string for different byte collections' {
        InModuleScope -ScriptBlock {
            $reference = [Microsoft.PowerShell.Commands.ByteCollection]::new([byte[]](0x61, 0x61, 0x61))
            $difference = [Microsoft.PowerShell.Commands.ByteCollection]::new([byte[]](0x61, 0x62, 0x61))

            $result = Get-DiffString -Reference $reference -Difference $difference

            $result | Should-BeString "61 `e[30;31m61`e[0m 61  a`e[30;31ma`e[0ma"
        }
    }

    It 'Should handle null value for difference' {
        InModuleScope -ScriptBlock {
            $reference = [Microsoft.PowerShell.Commands.ByteCollection]::new([byte[]](0x61, 0x61, 0x61))
            $difference = $null

            $result = Get-DiffString -Reference $reference -Difference $difference

            $result | Should-BeString "`e[30;31m61`e[0m `e[30;31m61`e[0m `e[30;31m61`e[0m  `e[30;31maaa`e[0m"
        }
    }

    It 'Should apply ANSI color codes if provided' {
        InModuleScope -ScriptBlock {
            $reference = [Microsoft.PowerShell.Commands.ByteCollection]::new([byte[]](0x61, 0x61, 0x61))
            $difference = [Microsoft.PowerShell.Commands.ByteCollection]::new([byte[]](0x61, 0x62, 0x61))

            $ansi = "`e[32m"  # Green color
            $ansiReset = "`e[4m"  # Reset color

            $result = Get-DiffString -Reference $reference -Difference $difference -Ansi $ansi -AnsiReset $ansiReset

            $result | Should -Match '\e\[32m'
            $result | Should -Match '\e\[4m'
        }
    }

    It 'Should respect column width parameters' {
        InModuleScope -ScriptBlock {
            $reference = [Microsoft.PowerShell.Commands.ByteCollection]::new([byte[]](0x61, 0x61, 0x61))
            $difference = [Microsoft.PowerShell.Commands.ByteCollection]::new([byte[]](0x61, 0x62, 0x61))

            $column1Width = 40
            $columnSeparatorWidth = 5

            $result = Get-DiffString -Reference $reference -Difference $difference -Column1Width $column1Width -ColumnSeparatorWidth $columnSeparatorWidth

            $result.Length | Should-BeGreaterThanOrEqual ($column1Width + $columnSeparatorWidth)
        }
    }
}
