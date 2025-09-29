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

    # Set up escape character for ANSI sequences
    $script:esc = [System.Char] 0x1b
}

Describe 'Clear-AnsiSequence' {
    Context 'When clearing basic escaped ANSI sequences' {
        It 'Should remove simple color sequences' {
            $inputString = "$($script:esc)[32mGreen text$($script:esc)[0m"
            $expected = 'Green text'

            $result = Clear-AnsiSequence -InputString $inputString -ErrorAction Stop

            $result | Should -BeExactly $expected
        }

        It 'Should remove complex formatting sequences' {
            $inputString = "$($script:esc)[1;37;44mBold white on blue$($script:esc)[0m"
            $expected = 'Bold white on blue'

            $result = Clear-AnsiSequence -InputString $inputString -ErrorAction Stop

            $result | Should -BeExactly $expected
        }

        It 'Should remove multiple color sequences' {
            $inputString = "$($script:esc)[32mGreen$($script:esc)[0m and $($script:esc)[31mRed$($script:esc)[0m text"
            $expected = 'Green and Red text'

            $result = Clear-AnsiSequence -InputString $inputString -ErrorAction Stop

            $result | Should -BeExactly $expected
        }
    }

    Context 'When clearing unescaped ANSI sequences' {
        It 'Should remove unescaped color sequences' {
            $inputString = '[32mGreen text[0m'
            $expected = 'Green text'

            $result = Clear-AnsiSequence -InputString $inputString -ErrorAction Stop

            $result | Should -BeExactly $expected
        }

        It 'Should remove unescaped complex sequences' {
            $inputString = '[1;37;44mBold white on blue[0m'
            $expected = 'Bold white on blue'

            $result = Clear-AnsiSequence -InputString $inputString -ErrorAction Stop

            $result | Should -BeExactly $expected
        }

        It 'Should remove multiple unescaped sequences' {
            $inputString = '[32mGreen[0m and [31mRed[0m text'
            $expected = 'Green and Red text'

            $result = Clear-AnsiSequence -InputString $inputString -ErrorAction Stop

            $result | Should -BeExactly $expected
        }
    }

    Context 'When using pipeline input' {
        It 'Should process single pipeline input' {
            $inputString = '[32mPiped input[0m'
            $expected = 'Piped input'

            $result = $inputString | Clear-AnsiSequence -ErrorAction Stop

            $result | Should -BeExactly $expected
        }

        It 'Should process multiple pipeline inputs' {
            $inputStrings = @('[32mFirst[0m', '[33mSecond[0m', '[31mThird[0m')
            $expected = @('First', 'Second', 'Third')

            $result = $inputStrings | Clear-AnsiSequence -ErrorAction Stop

            $result | Should -BeExactly $expected
        }

        It 'Should handle mixed pipeline content' {
            $inputStrings = @(
                "$($script:esc)[32mEscaped green$($script:esc)[0m",
                '[31mUnescaped red[0m',
                'Plain text'
            )
            $expected = @('Escaped green', 'Unescaped red', 'Plain text')

            $result = $inputStrings | Clear-AnsiSequence -ErrorAction Stop

            $result | Should -BeExactly $expected
        }
    }

    Context 'When handling RemovePartial behavior' {
        It 'Should preserve unterminated sequences by default' {
            $inputString = '[32mGreen text[0'
            $expected = 'Green text[0'

            $result = Clear-AnsiSequence -InputString $inputString -ErrorAction Stop

            $result | Should -BeExactly $expected
        }

        It 'Should remove unterminated sequences with -RemovePartial' {
            $inputString = '[32mGreen text[0'
            $expected = 'Green text'

            $result = Clear-AnsiSequence -InputString $inputString -RemovePartial -ErrorAction Stop

            $result | Should -BeExactly $expected
        }

        It 'Should handle mixed terminated and unterminated sequences with -RemovePartial' {
            $inputString = '[32mCompleted[0m and [31incomplete text'
            $expected = 'Completed and incomplete text'

            $result = Clear-AnsiSequence -InputString $inputString -RemovePartial -ErrorAction Stop

            $result | Should -BeExactly $expected
        }

        It 'Should preserve plain bracketed numbers even with -RemovePartial' {
            $inputString = '[32mColored[0m text and [42] value'
            $expected = 'Colored text and [42] value'

            $result = Clear-AnsiSequence -InputString $inputString -RemovePartial -ErrorAction Stop

            $result | Should -BeExactly $expected
        }
    }

    Context 'When handling mixed and unterminated sequences' {
        It 'Should handle mix of escaped and unescaped sequences' {
            $inputString = "$($script:esc)[32mEscaped[0mUnescaped"
            $expected = 'EscapedUnescaped'

            $result = Clear-AnsiSequence -InputString $inputString -ErrorAction Stop

            $result | Should -BeExactly $expected
        }

        It 'Should handle unterminated sequences missing m terminator' {
            $inputString = '[32mGreen text[31Red text[0m'
            $expected = 'Green text[31Red text'

            $result = Clear-AnsiSequence -InputString $inputString -ErrorAction Stop

            $result | Should -BeExactly $expected
        }

        It 'Should remove unterminated sequences missing m terminator with -RemovePartial' {
            $inputString = '[32mGreen text[31Red text[0m'
            $expected = 'Green textRed text'

            $result = Clear-AnsiSequence -InputString $inputString -RemovePartial -ErrorAction Stop

            $result | Should -BeExactly $expected
        }

        It 'Should handle multiple unterminated sequences' {
            $inputString = '[32mText[1;33More text[0'
            $expected = 'Text[1;33More text[0'

            $result = Clear-AnsiSequence -InputString $inputString -ErrorAction Stop

            $result | Should -BeExactly $expected
        }

        It 'Should remove multiple unterminated sequences with -RemovePartial' {
            $inputString = '[32mText[1;33More text[0'
            $expected = 'TextMore text'

            $result = Clear-AnsiSequence -InputString $inputString -RemovePartial -ErrorAction Stop

            $result | Should -BeExactly $expected
        }
    }

    Context 'When processing real-world examples' {
        It 'Should clean formatted log output' {
            $inputString = "$($script:esc)[32mINFO$($script:esc)[0m: Operation completed successfully"
            $expected = 'INFO: Operation completed successfully'

            $result = Clear-AnsiSequence -InputString $inputString -ErrorAction Stop

            $result | Should -BeExactly $expected
        }

        It 'Should clean complex formatted string templates' {
            $inputString = "[32mTag [1;37;44m{0}[0m[32m was created and pushed to upstream '{1}'[0m"
            $expected = "Tag {0} was created and pushed to upstream '{1}'"

            $result = Clear-AnsiSequence -InputString $inputString -ErrorAction Stop

            $result | Should -BeExactly $expected
        }

        It 'Should clean PowerShell prompt-like formatting' {
            $inputString = "$($script:esc)[32mPS$($script:esc)[0m $($script:esc)[33mC:\Users$($script:esc)[0m> "
            $expected = 'PS C:\Users> '

            $result = Clear-AnsiSequence -InputString $inputString -ErrorAction Stop

            $result | Should -BeExactly $expected
        }

        It 'Should handle Git output with color formatting' {
            $inputString = "$($script:esc)[32m+[0m Added line of code"
            $expected = '+ Added line of code'

            $result = Clear-AnsiSequence -InputString $inputString -ErrorAction Stop

            $result | Should -BeExactly $expected
        }

        It 'Should clean multi-line formatted output via pipeline' {
            $logLines = @(
                "$($script:esc)[31mERROR$($script:esc)[0m: Failed to connect",
                "$($script:esc)[33mWARN$($script:esc)[0m: Retrying connection",
                "$($script:esc)[32mINFO$($script:esc)[0m: Connection established"
            )
            $expected = @(
                'ERROR: Failed to connect',
                'WARN: Retrying connection',
                'INFO: Connection established'
            )

            $result = $logLines | Clear-AnsiSequence -ErrorAction Stop

            $result | Should -BeExactly $expected
        }

        It 'Should enable accurate visible length calculation' {
            $formattedString = "[32mHello[0m [31mWorld[0m"

            $result = Clear-AnsiSequence -InputString $formattedString -ErrorAction Stop
            $visibleLength = $result.Length

            $visibleLength | Should -BeExactly 11  # "Hello World"
            $result | Should -BeExactly "Hello World"
        }

        It 'Should handle progress bar-like sequences' {
            $inputString = "$($script:esc)[2K$($script:esc)[32m████████████$($script:esc)[0m 100%"
            $expected = '████████████ 100%'

            $result = Clear-AnsiSequence -InputString $inputString -ErrorAction Stop

            $result | Should -BeExactly $expected
        }

        It 'Should process terminal control sequences with cursor movement' {
            $inputString = "$($script:esc)[2J$($script:esc)[1;1HScreen cleared$($script:esc)[32mGreen text$($script:esc)[0m"
            $expected = 'Screen clearedGreen text'

            $result = Clear-AnsiSequence -InputString $inputString -ErrorAction Stop

            $result | Should -BeExactly $expected
        }
    }

    Context 'When handling edge cases and special scenarios' {
        It 'Should handle null input' {
            $result = Clear-AnsiSequence -InputString $null -ErrorAction Stop

            $result | Should -BeNullOrEmpty
        }

        It 'Should handle empty string input' {
            $result = Clear-AnsiSequence -InputString '' -ErrorAction Stop

            $result | Should -BeExactly ''
        }

        It 'Should preserve strings without ANSI sequences' {
            $inputString = 'Plain text without any formatting'
            $expected = 'Plain text without any formatting'

            $result = Clear-AnsiSequence -InputString $inputString -ErrorAction Stop

            $result | Should -BeExactly $expected
        }

        It 'Should preserve plain bracketed numbers and text' {
            $inputString = 'Array[5] and Object[10] with [IMPORTANT] note'
            $expected = 'Array[5] and Object[10] with [IMPORTANT] note'

            $result = Clear-AnsiSequence -InputString $inputString -ErrorAction Stop

            $result | Should -BeExactly $expected
        }

        It 'Should distinguish between ANSI sequences and plain brackets' {
            $inputString = '[32mColored[0m text and [32] value and [LABEL] text'
            $expected = 'Colored text and [32] value and [LABEL] text'

            $result = Clear-AnsiSequence -InputString $inputString -ErrorAction Stop

            $result | Should -BeExactly $expected
        }

        It 'Should handle backtick escaped sequences via pipeline' {
            $inputString = '`e[32mGreen text`e[0m'
            $expected = 'Green text'

            $result = $inputString | Clear-AnsiSequence -ErrorAction Stop

            $result | Should -BeExactly $expected
        }
    }
}
