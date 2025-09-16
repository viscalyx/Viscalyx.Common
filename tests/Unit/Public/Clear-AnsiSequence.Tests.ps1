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

Describe 'Clear-AnsiSequence' {
    BeforeAll {
        $esc = [System.Char] 0x1b
    }

    Context 'When checking command structure' {
        It 'Should be available as a command' {
            Get-Command -Name 'Clear-AnsiSequence' | Should -Not -BeNullOrEmpty
        }

        It 'Should have exactly one parameter set' {
            (Get-Command -Name 'Clear-AnsiSequence').ParameterSets | Should -HaveCount 1
        }

        It 'Should have CmdletBinding attribute' {
            $commandInfo = Get-Command -Name 'Clear-AnsiSequence'
            $commandInfo.CmdletBinding | Should -BeTrue
        }

        It 'Should have OutputType attribute' {
            $commandInfo = Get-Command -Name 'Clear-AnsiSequence'
            $commandInfo.OutputType.Name | Should -Contain 'System.String'
        }

        It 'Should have the correct parameter attributes for InputString' {
            $parameterInfo = (Get-Command -Name 'Clear-AnsiSequence').Parameters['InputString']
            $parameterInfo.Attributes.Mandatory | Should -Contain $true
            $parameterInfo.Attributes.Position | Should -Contain 0
        }

        It 'Should accept pipeline input for InputString parameter' {
            $parameterInfo = (Get-Command -Name 'Clear-AnsiSequence').Parameters['InputString']
            $parameterInfo.Attributes.ValueFromPipeline | Should -BeTrue
        }
    }

    Context 'When handling null or empty input' {
        It 'Should return null when input is null' {
            $result = Clear-AnsiSequence -InputString $null
            $result | Should -BeNullOrEmpty
        }

        It 'Should return empty string when input is empty' {
            $result = Clear-AnsiSequence -InputString ''
            $result | Should -BeExactly ''
        }
    }

    Context 'When handling strings without ANSI sequences' {
        It 'Should return the same string when no ANSI sequences are present' {
            $inputString = 'Hello World'
            $result = Clear-AnsiSequence -InputString $inputString
            $result | Should -BeExactly $inputString
        }

        It 'Should return the same string when input contains only text' {
            $inputString = 'This is a normal string with no formatting.'
            $result = Clear-AnsiSequence -InputString $inputString
            $result | Should -BeExactly $inputString
        }

        It 'Should handle strings with special characters but no ANSI sequences' {
            $inputString = 'String with symbols: !@#$%^&*()'
            $result = Clear-AnsiSequence -InputString $inputString
            $result | Should -BeExactly $inputString
        }
    }

    Context 'When handling properly escaped ANSI sequences' {
        It 'Should remove simple ANSI sequence' {
            $inputString = "$($esc)[32mGreen text$($esc)[0m"
            $expected = 'Green text'
            $result = Clear-AnsiSequence -InputString $inputString
            $result | Should -BeExactly $expected
        }

        It 'Should remove complex ANSI sequence' {
            $inputString = "$($esc)[1;37;44mBold white on blue$($esc)[0m"
            $expected = 'Bold white on blue'
            $result = Clear-AnsiSequence -InputString $inputString
            $result | Should -BeExactly $expected
        }

        It 'Should remove multiple ANSI sequences' {
            $inputString = "$($esc)[32mGreen$($esc)[0m and $($esc)[31mRed$($esc)[0m text"
            $expected = 'Green and Red text'
            $result = Clear-AnsiSequence -InputString $inputString
            $result | Should -BeExactly $expected
        }

        It 'Should handle sequences at beginning, middle, and end' {
            $inputString = "$($esc)[32mStart$($esc)[0m middle $($esc)[31mend$($esc)[0m"
            $expected = 'Start middle end'
            $result = Clear-AnsiSequence -InputString $inputString
            $result | Should -BeExactly $expected
        }
    }

    Context 'When handling unescaped ANSI sequences' {
        It 'Should remove unescaped simple ANSI sequence' {
            $inputString = '[32mGreen text[0m'
            $expected = 'Green text'
            $result = Clear-AnsiSequence -InputString $inputString
            $result | Should -BeExactly $expected
        }

        It 'Should remove unescaped complex ANSI sequence' {
            $inputString = '[1;37;44mBold white on blue[0m'
            $expected = 'Bold white on blue'
            $result = Clear-AnsiSequence -InputString $inputString
            $result | Should -BeExactly $expected
        }

        It 'Should remove multiple unescaped ANSI sequences' {
            $inputString = '[32mGreen[0m and [31mRed[0m text'
            $expected = 'Green and Red text'
            $result = Clear-AnsiSequence -InputString $inputString
            $result | Should -BeExactly $expected
        }
    }

    Context 'When handling sequences with backtick escape' {
        It 'Should remove backtick escaped sequences' {
            $inputString = '`e[32mGreen text`e[0m'
            $expected = 'Green text'
            $result = Clear-AnsiSequence -InputString $inputString
            $result | Should -BeExactly $expected
        }

        <#
            TODO: Remove Skip when bug in Windows PowerShell is fixed (leaves an extra 'e' at start and end of string).

            Bug:
            ##[error]     Expected strings to be the same, but they were different.
            ##[error]     Expected length: 30
            ##[error]     Actual length:   32
            ##[error]     Strings differ at index 0.
            ##[error]     Expected: 'Backtick escapedProper escaped'
            ##[error]     But was:  'eBacktick escapedProper escapede'
        #>
        It 'Should handle mix of backtick and proper escape characters' -Skip:($PSVersionTable.PSEdition -eq 'Desktop') {
            $inputString = "`e[32mBacktick escaped$($esc)[1mProper escaped`e[0m"
            $expected = 'Backtick escapedProper escaped'
            $result = Clear-AnsiSequence -InputString $inputString
            $result | Should -BeExactly $expected
        }
    }

    Context 'When handling unterminated ANSI sequences' {
        It 'Should remove unterminated ANSI sequence' {
            $inputString = '[32mGreen text[0'
            $expected = 'Green text'
            $result = Clear-AnsiSequence -InputString $inputString
            $result | Should -BeExactly $expected
        }

        It 'Should remove sequence missing m terminator' {
            $inputString = '[32mGreen text[31Red text[0m'
            $expected = 'Green textRed text'
            $result = Clear-AnsiSequence -InputString $inputString
            $result | Should -BeExactly $expected
        }

        It 'Should handle multiple unterminated sequences' {
            $inputString = '[32mText[1;33mMore text[0'
            $expected = 'TextMore text'
            $result = Clear-AnsiSequence -InputString $inputString
            $result | Should -BeExactly $expected
        }
    }

    Context 'When handling mixed sequence formats' {
        It 'Should handle mix of escaped and unescaped sequences' {
            $inputString = "$($esc)[32mEscaped[0mUnescaped"
            $expected = 'EscapedUnescaped'
            $result = Clear-AnsiSequence -InputString $inputString
            $result | Should -BeExactly $expected
        }

        It 'Should handle mix of terminated and unterminated sequences' {
            $inputString = '[32mTerminated[0m and [31unterminated'
            $expected = 'Terminated and unterminated'
            $result = Clear-AnsiSequence -InputString $inputString
            $result | Should -BeExactly $expected
        }
    }

    Context 'When handling real-world examples' {
        It 'Should remove sequences from formatted log output' {
            $inputString = "$($esc)[32mINFO$($esc)[0m: Operation completed successfully"
            $expected = 'INFO: Operation completed successfully'
            $result = Clear-AnsiSequence -InputString $inputString
            $result | Should -BeExactly $expected
        }

        It 'Should remove sequences from complex formatted string' {
            $inputString = "[32mTag [1;37;44m{0}[0m[32m was created and pushed to upstream '{1}'[0m"
            $expected = "Tag {0} was created and pushed to upstream '{1}'"
            $result = Clear-AnsiSequence -InputString $inputString
            $result | Should -BeExactly $expected
        }

        It 'Should handle PowerShell prompt-like formatting' {
            $inputString = "$($esc)[32mPS$($esc)[0m $($esc)[33mC:\Users$($esc)[0m> "
            $expected = 'PS C:\Users> '
            $result = Clear-AnsiSequence -InputString $inputString
            $result | Should -BeExactly $expected
        }
    }

    Context 'When using pipeline input' {
        It 'Should accept pipeline input' {
            $inputString = '[32mPiped input[0m'
            $expected = 'Piped input'
            $result = $inputString | Clear-AnsiSequence
            $result | Should -BeExactly $expected
        }

        It 'Should process multiple pipeline inputs' {
            $inputStrings = @('[32mFirst[0m', '[33mSecond[0m')
            $expected = @('First', 'Second')
            $result = $inputStrings | Clear-AnsiSequence
            $result | Should -BeExactly $expected
        }
    }

    Context 'When calculating visible length' {
        It 'Should enable accurate length calculation' {
            $formattedString = "[32mHello[0m [31mWorld[0m"
            $visibleLength = (Clear-AnsiSequence -InputString $formattedString).Length
            $visibleLength | Should -BeExactly 11  # "Hello World"
        }

        It 'Should handle long formatted strings' {
            $formattedString = "[1;32mThis is a very long string with multiple [31mformatted[32m sections and [0mreset[32m sequences[0m"
            $plainText = Clear-AnsiSequence -InputString $formattedString
            $plainText | Should -BeExactly "This is a very long string with multiple formatted sections and reset sequences"
            $plainText.Length | Should -BeExactly 79
        }
    }
}
