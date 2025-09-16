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

Describe 'ConvertTo-DifferenceString' {
    Context 'When checking command structure' {
        It 'Should have the correct parameters in parameter set <ExpectedParameterSetName>' -ForEach @(
            @{
                ExpectedParameterSetName = '__AllParameterSets'
                ExpectedParameters = '[-ReferenceString] <string> [-DifferenceString] <string> [[-EqualIndicator] <string>] [[-NotEqualIndicator] <string>] [[-HighlightStart] <string>] [[-HighlightEnd] <string>] [[-ReferenceLabel] <string>] [[-DifferenceLabel] <string>] [[-ReferenceLabelAnsi] <string>] [[-DifferenceLabelAnsi] <string>] [[-ColumnHeaderAnsi] <string>] [[-ColumnHeaderResetAnsi] <string>] [[-EncodingType] <string>] [-NoColumnHeader] [-NoLabels] [-NoHexOutput] [<CommonParameters>]'
            }
        ) {
            $result = (Get-Command -Name 'ConvertTo-DifferenceString').ParameterSets |
                Where-Object -FilterScript { $_.Name -eq $ExpectedParameterSetName } |
                Select-Object -Property @(
                    @{ Name = 'ParameterSetName'; Expression = { $_.Name } },
                    @{ Name = 'ParameterListAsString'; Expression = { $_.ToString() } }
                )
            $result.ParameterSetName | Should -Be $ExpectedParameterSetName
            $result.ParameterListAsString | Should -Be $ExpectedParameters
        }

        It 'Should have ReferenceString as a mandatory parameter' {
            $parameterInfo = (Get-Command -Name 'ConvertTo-DifferenceString').Parameters['ReferenceString']
            $parameterInfo.Attributes.Mandatory | Should -BeTrue
        }

        It 'Should have DifferenceString as a mandatory parameter' {
            $parameterInfo = (Get-Command -Name 'ConvertTo-DifferenceString').Parameters['DifferenceString']
            $parameterInfo.Attributes.Mandatory | Should -BeTrue
        }
    }

    BeforeAll {
        $esc = [System.Char] 0x1b
    }

    It 'Should use custom labels' {
        $result = -join (ConvertTo-DifferenceString -ReferenceString 'Hello' -DifferenceString 'Hallo' -ReferenceLabel 'Ref:' -DifferenceLabel 'Diff:')
        $result | Should -Match 'Ref:'
        $result | Should -Match 'Diff:'
    }

    It 'Should align labels correctly with different label lengths' {
        # Test with very short labels
        $shortResult = ConvertTo-DifferenceString -ReferenceString 'Test' -DifferenceString 'Test' -ReferenceLabel 'A' -DifferenceLabel 'B'
        $shortLabelLine = $shortResult[0]
        
        # Test with default labels
        $defaultResult = ConvertTo-DifferenceString -ReferenceString 'Test' -DifferenceString 'Test'
        $defaultLabelLine = $defaultResult[0]
        
        # Test with long labels
        $longResult = ConvertTo-DifferenceString -ReferenceString 'Test' -DifferenceString 'Test' -ReferenceLabel 'VeryLongLabel:' -DifferenceLabel 'AlsoVeryLongLabel:'
        $longLabelLine = $longResult[0]
        
        # Check that all second labels start at the same relative position (after accounting for label length differences)
        $shortBIndex = $shortLabelLine.IndexOf('B')
        $defaultButWasIndex = $defaultLabelLine.IndexOf('But was:')
        $longAlsoIndex = $longLabelLine.IndexOf('AlsoVeryLongLabel:')
        
        # All should align to position 72 (64 + 8 for left column + spacing)
        # Note: Due to ANSI escape codes, the actual position may be slightly different, but they should be consistent
        $shortBIndex | Should -Be $defaultButWasIndex
        $shortBIndex | Should -Be $longAlsoIndex
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

    It 'Should handle special characters' {
        $result = -join (ConvertTo-DifferenceString -ReferenceString "Hello`n" -DifferenceString "Hello`r")
        $result | Should -Match '31m0A'
        $result | Should -Match '31m0D'
    }

    It 'Should use custom highlighting' {
        $result = -join (ConvertTo-DifferenceString -ReferenceString 'Hello' -DifferenceString 'Hallo' -HighlightStart "$($esc)[32m" -HighlightEnd "$($esc)[0m")
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
        $result | Should -Match "$($esc)\[31m0D$($esc)\[0m $($esc)\[31m0A$($esc)\[0m"  # Carriage return + Newline
        $result | Should -Match "$($esc)\[31m0A$($esc)\[0m $($esc)\[31m0D$($esc)\[0m"  # Newline + Carriage return
    }

    It 'Should handle longer strings' {
         $result = ConvertTo-DifferenceString -ReferenceString 'This is a string' -DifferenceString 'This is a string that is longer'
         $result | Should-BeBlockString -Expected @(
            "Expected:[0m                                                               But was:[0m"
            "----------------------------------------------------------------        ----------------------------------------------------------------"
            "Bytes                                           Ascii                   Bytes                                           Ascii"
            "-----                                           -----                   -----                                           -----"
            "54 68 69 73 20 69 73 20 61 20 73 74 72 69 6E 67 This is a string   ==   54 68 69 73 20 69 73 20 61 20 73 74 72 69 6E 67 This is a string"
            "[31m  [0m [31m  [0m [31m  [0m [31m  [0m [31m  [0m [31m  [0m [31m  [0m [31m  [0m [31m  [0m [31m  [0m [31m  [0m [31m  [0m [31m  [0m [31m  [0m [31m  [0m    [31m [0m[31m [0m[31m [0m[31m [0m[31m [0m[31m [0m[31m [0m[31m [0m[31m [0m[31m [0m[31m [0m[31m [0m[31m [0m[31m [0m[31m [0m    !=   [31m20[0m [31m74[0m [31m68[0m [31m61[0m [31m74[0m [31m20[0m [31m69[0m [31m73[0m [31m20[0m [31m6C[0m [31m6F[0m [31m6E[0m [31m67[0m [31m65[0m [31m72[0m    [31m [0m[31mt[0m[31mh[0m[31ma[0m[31mt[0m[31m [0m[31mi[0m[31ms[0m[31m [0m[31ml[0m[31mo[0m[31mn[0m[31mg[0m[31me[0m[31mr[0m "
         )
    }
}
