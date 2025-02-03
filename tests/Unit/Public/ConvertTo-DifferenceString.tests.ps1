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

Describe '-join (ConvertTo-DifferenceString' {
    It 'Should use custom labels' {
        $result = -join (ConvertTo-DifferenceString -ReferenceString 'Hello' -DifferenceString 'Hallo' -ReferenceLabel 'Ref:' -DifferenceLabel 'Diff:')
        $result | Should -Match 'Ref:'
        $result | Should -Match 'Diff:'
    }

    It 'Should handle different encoding types' {
        $result = -join (ConvertTo-DifferenceString -ReferenceString 'Hello' -DifferenceString 'Hallo' -EncodingType 'ASCII')
        $result | Should -Match '31m65'
        $result | Should -Match '31m61'
        $result | Should -Match '31me'
        $result | Should -Match '31ma'
    }

    It 'Should exclude column header when NoColumnHeader is specified' {
        $result = -join (ConvertTo-DifferenceString -ReferenceString 'Hello' -DifferenceString 'Hallo' -NoColumnHeader)
        $result | Should -Not -Match 'Bytes'
        $result | Should -Not -Match 'Ascii'
    }

    It 'Should exclude labels when NoLabels is specified' {
        $result = -join (ConvertTo-DifferenceString -ReferenceString 'Hello' -DifferenceString 'Hallo' -NoLabels)
        $result | Should -Not -Match 'Expected:'
        $result | Should -Not -Match 'But was:'
    }

    It 'Should return equal indicators for identical strings' {
        $result = -join (ConvertTo-DifferenceString -ReferenceString 'Hello' -DifferenceString 'Hello')
        $result | Should -Not -Match '!='
    }

    It 'Should highlight differences for different strings' {
        $result = -join (ConvertTo-DifferenceString -ReferenceString 'Hello' -DifferenceString 'Hallo')
        $result | Should -Match '31m65'
        $result | Should -Match '31m61'
        $result | Should -Match '31me'
        $result | Should -Match '31ma'
    }

    It 'Should use custom indicators' {
        $result = -join (ConvertTo-DifferenceString -ReferenceString 'Hello' -DifferenceString 'Hallo' -EqualIndicator 'EQ' -NotEqualIndicator 'NE')
        $result | Should -Match 'NE'
        $result | Should -Not -Match '=='
        $result | Should -Not -Match '!='
    }

    It 'Should handle empty strings' {
        $result = -join (ConvertTo-DifferenceString -ReferenceString '' -DifferenceString '')
        $result | Should -Not -Match '!='
    }

    It 'Should handle different length strings' {
        $result = -join (ConvertTo-DifferenceString -ReferenceString 'Hello' -DifferenceString 'HelloWorld')
        $result | Should -Match '31mW'
        $result | Should -Match '31mo'
        $result | Should -Match '31mr'
        $result | Should -Match '31ml'
        $result | Should -Match '31md'
    }

    It 'Should handle CR and LF special characters' {
        $result = -join (ConvertTo-DifferenceString -ReferenceString "Hello`n" -DifferenceString "Hello`r")
        $result | Should -Match '31m0A'
        $result | Should -Match '31m0D'
    }

    It 'Should handle DEL special characters' {
        $result = -join (ConvertTo-DifferenceString -ReferenceString ('Hello' + [char] 127) -DifferenceString ('Hello' + [char] 127))
        $result | Should -Match ([System.Char] 0x2421)
    }

    It 'Should use custom highlighting' {
        $result = -join (ConvertTo-DifferenceString -ReferenceString 'Hello' -DifferenceString 'Hallo' -HighlightStart "`e[32m" -HighlightEnd "`e[0m")
        $result | Should -Match '32m65'
        $result | Should -Match '32m61'
    }

    It 'Should exclude labels and column header' {
        $result = -join (ConvertTo-DifferenceString -ReferenceString 'Hello' -DifferenceString 'Hallo' -NoLabels -NoColumnHeader)
        $result | Should -Not -Match 'Expected:'
        $result | Should -Not -Match 'But was:'
        $result | Should -Not -Match 'Bytes'
        $result | Should -Not -Match 'Ascii'
    }

    It 'Should handle different encodings' {
        $result = -join (ConvertTo-DifferenceString -ReferenceString 'Hello' -DifferenceString 'Hallo' -EncodingType 'ASCII')
        $result | Should -Match '31m65'
        $result | Should -Match '31m61'
    }

    It 'Should handle null reference string' {
        $result = -join (ConvertTo-DifferenceString -ReferenceString $null -DifferenceString 'Hallo')
        $result | Should -Match '31m48'
    }

    It 'Should handle null difference string' {
        $result = -join (ConvertTo-DifferenceString -ReferenceString 'Hello' -DifferenceString $null)
        $result | Should -Match '31m48'
    }

    It 'Should handle escaped characters' {
        $result = -join (ConvertTo-DifferenceString -ReferenceString "Hello`tWorld" -DifferenceString "Hello`nWorld")
        $result | Should -Match '31m09'  # Tab character
        $result | Should -Match '31m0A'  # Newline character
    }

    It 'Should handle multiple escaped characters' {
        $result = -join (ConvertTo-DifferenceString -ReferenceString "Hello`r`nWorld" -DifferenceString "Hello`n`rWorld")
        $result | Should -Match "`e\[31m0D`e\[0m `e\[31m0A`e\[0m"  # Carriage return + Newline
        $result | Should -Match "`e\[31m0A`e\[0m `e\[31m0D`e\[0m"  # Newline + Carriage return
    }

    It 'Should process large strings efficiently' {
        $largeString1 = 'a' * 10000
        $largeString2 = 'a' * 9999 + 'b'

        Measure-Command { ConvertTo-DifferenceString -ReferenceString $largeString1 -DifferenceString $largeString2 } | Should-BeFasterThan '1.5s' -Because 'Large strings should be processed efficiently, and should not take more than 1.5 seconds.'
    }
}
