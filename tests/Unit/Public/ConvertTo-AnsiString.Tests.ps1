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

Describe 'ConvertTo-AnsiString' {
    BeforeAll {
        $esc = [System.Char] 0x1b
    }

    Context 'When checking command structure' {
        It 'Should have the correct parameters in parameter set <ExpectedParameterSetName>' -ForEach @(
            @{
                ExpectedParameterSetName = '__AllParameterSets'
                ExpectedParameters = '[-InputString] <string> [<CommonParameters>]'
            }
        ) {
            $result = (Get-Command -Name 'ConvertTo-AnsiString').ParameterSets |
                Where-Object -FilterScript { $_.Name -eq $ExpectedParameterSetName } |
                Select-Object -Property @(
                    @{ Name = 'ParameterSetName'; Expression = { $_.Name } },
                    @{ Name = 'ParameterListAsString'; Expression = { $_.ToString() } }
                )
            $result.ParameterSetName | Should -Be $ExpectedParameterSetName
            $result.ParameterListAsString | Should -Be $ExpectedParameters
        }

        It 'Should have InputString as a mandatory parameter' {
            $parameterInfo = (Get-Command -Name 'ConvertTo-AnsiString').Parameters['InputString']
            $parameterInfo.Attributes.Mandatory | Should -BeTrue
        }

        It 'Should accept pipeline input for InputString parameter' {
            $parameterInfo = (Get-Command -Name 'ConvertTo-AnsiString').Parameters['InputString']
            $parameterInfo.Attributes.ValueFromPipeline | Should -BeTrue
        }
    }

    Context 'When handling null or empty input' {
        It 'Should return null when input is null' {
            $result = ConvertTo-AnsiString -InputString $null
            $result | Should -BeNullOrEmpty
        }

        It 'Should return empty string when input is empty' {
            $result = ConvertTo-AnsiString -InputString ''
            $result | Should -BeExactly ''
        }
    }

    Context 'When handling strings without ANSI sequences' {
        It 'Should return the same string when no ANSI sequences are present' {
            $inputString = 'Hello World'
            $result = ConvertTo-AnsiString -InputString $inputString
            $result | Should -BeExactly $inputString
        }

        It 'Should return the same string when input contains only text' {
            $inputString = 'This is a normal string with no formatting.'
            $result = ConvertTo-AnsiString -InputString $inputString
            $result | Should -BeExactly $inputString
        }
    }

    Context 'When handling unescaped ANSI sequences' {
        It 'Should add escape character to simple ANSI sequence' {
            $inputString = '[32mGreen text[0m'
            $expected = "$($esc)[32mGreen text$($esc)[0m"
            $result = ConvertTo-AnsiString -InputString $inputString
            $result | Should -BeExactly $expected
        }

        It 'Should add escape character to complex ANSI sequence' {
            $inputString = '[1;37;44mBold white on blue[0m'
            $expected = "$($esc)[1;37;44mBold white on blue$($esc)[0m"
            $result = ConvertTo-AnsiString -InputString $inputString
            $result | Should -BeExactly $expected
        }

        It 'Should handle multiple unescaped ANSI sequences' {
            $inputString = '[32mTag [1;37;44m{0}[0m[32m was created[0m'
            $expected = "$($esc)[32mTag $($esc)[1;37;44m{0}$($esc)[0m$($esc)[32m was created$($esc)[0m"
            $result = ConvertTo-AnsiString -InputString $inputString
            $result | Should -BeExactly $expected
        }
    }

    Context 'When handling unterminated ANSI sequences' {
        It 'Should add termination to unterminated ANSI sequence' {
            $inputString = '[32mGreen text[0'
            $expected = "$($esc)[32mGreen text$($esc)[0m"
            $result = ConvertTo-AnsiString -InputString $inputString
            $result | Should -BeExactly $expected
        }

        It 'Should add termination to unterminated sequence at end of string' {
            $inputString = "[32mTag [1;37;44m{0}[0m[32m was created and pushed to upstream '{1}'"
            $expected = "$($esc)[32mTag $($esc)[1;37;44m{0}$($esc)[0m$($esc)[32m was created and pushed to upstream '{1}'$($esc)[0m"
            $result = ConvertTo-AnsiString -InputString $inputString
            $result | Should -BeExactly $expected
        }

        It 'Should handle multiple unterminated sequences' {
            $inputString = '[32mText[1;33mMore text[0'
            $expected = "$($esc)[32mText$($esc)[1;33mMore text$($esc)[0m"
            $result = ConvertTo-AnsiString -InputString $inputString
            $result | Should -BeExactly $expected
        }
    }

    Context 'When handling already escaped ANSI sequences' {
        It 'Should preserve already escaped ANSI sequences' {
            $inputString = "$($esc)[32mGreen text$($esc)[0m"
            $expected = "$($esc)[32mGreen text$($esc)[0m"
            $result = ConvertTo-AnsiString -InputString $inputString
            $result | Should -BeExactly $expected
        }

        It 'Should handle mix of escaped and unescaped sequences' {
            $inputString = "$($esc)[32mEscaped[0mUnescaped"
            $expected = "$($esc)[32mEscaped$($esc)[0mUnescaped"
            $result = ConvertTo-AnsiString -InputString $inputString
            $result | Should -BeExactly $expected
        }
    }

    Context 'When handling sequences with backtick escape' {
        It 'Should convert backtick escaped sequences to proper escape character' {
            $inputString = '`e[32mGreen text`e[0m'
            $expected = "$($esc)[32mGreen text$($esc)[0m"
            $result = ConvertTo-AnsiString -InputString $inputString
            $result | Should -BeExactly $expected
        }

        <#
            TODO: Remove Skip when bug in Windows PowerShell is fixed (leaves an extra 'e' at start and end of string).

            Bug:
            ##[error]     Expected strings to be the same, but they were different.
            ##[error]     Expected length: 43
            ##[error]     Actual length:   45
            ##[error]     Strings differ at index 0.
            ##[error]     Expected: 'Backtick escapedProper escaped'
            ##[error]     But was:  'eBacktick escapedProper escapede'
        #>
        It 'Should handle mix of backtick and proper escape characters' -Skip:($PSVersionTable.PSEdition -eq 'Desktop') {
            $inputString = "`e[32mBacktick escaped$($esc)[1mProper escaped`e[0m"
            $expected = "$($esc)[32mBacktick escaped$($esc)[1mProper escaped$($esc)[0m"
            $result = ConvertTo-AnsiString -InputString $inputString
            $result | Should -BeExactly $expected
        }
    }

    Context 'When handling real-world examples' {
        It 'Should handle the first example from the user request' {
            $inputString = "[32mTag [1;37;44m{0}[0m[32m was created and pushed to upstream '{1}'[0m"
            $expected = "$($esc)[32mTag $($esc)[1;37;44m{0}$($esc)[0m$($esc)[32m was created and pushed to upstream '{1}'$($esc)[0m"
            $result = ConvertTo-AnsiString -InputString $inputString
            $result | Should -BeExactly $expected
        }

        It 'Should handle the second example from the user request' {
            $inputString = "[32mTag [1;37;44m{0}[0m[32m was created and pushed to upstream '{1}'"
            $expected = "$($esc)[32mTag $($esc)[1;37;44m{0}$($esc)[0m$($esc)[32m was created and pushed to upstream '{1}'$($esc)[0m"
            $result = ConvertTo-AnsiString -InputString $inputString
            $result | Should -BeExactly $expected
        }

        It 'Should handle consecutive ANSI sequences with incomplete reset at end' {
            # This test specifically covers the bug reported by the user
            $inputString = "[32mTag [1;37;44m{0}[0m[32m was [31mcreated and [31pushed to upstream '{1}'"
            $expected = "$($esc)[32mTag $($esc)[1;37;44m{0}$($esc)[0m$($esc)[32m was $($esc)[31mcreated and $($esc)[31mpushed to upstream '{1}'$($esc)[0m"
            $result = ConvertTo-AnsiString -InputString $inputString
            $result | Should -BeExactly $expected
        }
    }

    Context 'When using pipeline input' {
        It 'Should accept pipeline input' {
            $inputString = '[32mPiped input[0m'
            $expected = "$($esc)[32mPiped input$($esc)[0m"
            $result = $inputString | ConvertTo-AnsiString
            $result | Should -BeExactly $expected
        }

        It 'Should process multiple pipeline inputs' {
            $inputStrings = @('[32mFirst[0m', '[33mSecond[0m')
            $expected = @("$($esc)[32mFirst$($esc)[0m", "$($esc)[33mSecond$($esc)[0m")
            $result = $inputStrings | ConvertTo-AnsiString
            $result | Should -BeExactly $expected
        }
    }
}
