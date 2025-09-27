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

    It 'Should handle left labels longer than the right-column start' {
        $veryLongLeft = ('L' * 100)

        # Capture warnings
        $warnings = @()
        $result = ConvertTo-DifferenceString -ReferenceString 'X' -DifferenceString 'X' -ReferenceLabel $veryLongLeft -DifferenceLabel 'R' -WarningVariable warnings

        $firstLine = $result[0]

        # Should contain the truncated label (64 characters)
        $expectedTruncatedLabel = 'L' * 64
        $firstLine | Should -Match $expectedTruncatedLabel
        $firstLine | Should -Match 'R'  # right label should still appear

        # Should emit a warning about truncation
        $warnings | Should -HaveCount 1
        $warnings[0] | Should -Match "Reference label.*is longer than the maximum width of 64 characters and has been truncated"
    }

    It 'Should align right column precisely at column 72 when visible label length is exactly 72' {
        # Create a label that is exactly 72 characters visible (no ANSI sequences)
        $exactLabel = 'A' * 72
        $result = ConvertTo-DifferenceString -ReferenceString 'Test' -DifferenceString 'Test' -ReferenceLabel $exactLabel -DifferenceLabel 'Right'
        $firstLine = $result[0]

        # Strip ANSI sequences to get the actual visible content
        $visibleLine = $firstLine -replace '\x1b\[[0-9;]*m', ''

        # Find the position of 'Right' in the visible line
        $rightLabelIndex = $visibleLine.IndexOf('Right')

        # The right label should start exactly at position 72 (0-based indexing)
        $rightLabelIndex | Should -Be 72
    }

    It 'Should truncate reference label when longer than left column width' {
        # Create a label that is longer than the left column width (64 characters)
        $longLabel = 'A' * 80
        $result = ConvertTo-DifferenceString -ReferenceString 'Test' -DifferenceString 'Test' -ReferenceLabel $longLabel -DifferenceLabel 'Right' -WarningAction SilentlyContinue
        $firstLine = $result[0]

        # Strip ANSI sequences to get the actual visible content
        $visibleLine = $firstLine -replace '\x1b\[[0-9;]*m', ''

        # The reference label should be truncated to exactly 64 characters
        $truncatedLabel = $visibleLine.Substring(0, 64)
        $truncatedLabel | Should -Be ('A' * 64)

        # The right label should start exactly at position 72 (64 + 8 spacing)
        $rightLabelIndex = $visibleLine.IndexOf('Right')
        $rightLabelIndex | Should -Be 72
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

    # This could not be used in Azure DevOps pipeline due to irregular performance in build agents.
    # It 'Should process large strings efficiently' {
    #     $largeString1 = 'a' * 10000
    #     $largeString2 = 'a' * 9999 + 'b'

    #     # TODO: When Because works in Should-BeFasterThan, uncomment the part on the following line.
    #     Measure-Command { ConvertTo-DifferenceString -ReferenceString $largeString1 -DifferenceString $largeString2 } | Should-BeFasterThan '1.5s' #-Because 'Large strings should be processed efficiently, and should not take more than 1.5 seconds.'
    # }

    Context 'NoHexOutput functionality' {
        It 'Should output only ascii characters when NoHexOutput is specified' {
            $result = -join (ConvertTo-DifferenceString -ReferenceString 'Hello World' -DifferenceString 'Hello World' -NoHexOutput)
            # Ensure no hex values appear (e.g. two-digit hex groups).
            $result | Should -Not -Match '\b[0-9A-F]{2}\b'
            # Ensure that the ascii portion of the string is present.
            $result | Should -Match 'Hello World'
        }
        It 'Should use larger grouping (64 characters) when NoHexOutput is specified' {
            $longStr = 'A' * 70
            $result = -join (ConvertTo-DifferenceString -ReferenceString $longStr -DifferenceString $longStr -NoHexOutput)
            $result | Should -Match 'A{64}   ==   A{64}'
            ($result -split '\n').Count | Should -Be 1
        }
    }
}
