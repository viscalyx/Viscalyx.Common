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

Describe 'Out-Diff' {
    Context 'When output is made as verbose message' {
        BeforeAll {
            Mock -CommandName Write-Verbose
        }

        It 'Should output differences between two different strings' {
            $expected = 'This is a longer text string that was expected to be shown'
            $actual = 'This is the actual text string'

            $result = Out-Diff -Reference $expected -Difference $actual -AsVerbose

            $result | Should-BeNull
            Should -Invoke -CommandName Write-Verbose -Exactly -Times 5 -Scope It
        }

        It 'Should handle string array' {
            $expected = @(
                'Line 1'
                'Line 2'
                'Line 3'
            )
            $actual = @(
                'Line 1'
                'Line 2'
            )

            $result = Out-Diff -Reference $expected -Difference $actual -AsVerbose

            $result | Should-BeNull
            Should -Invoke -CommandName Write-Verbose -Exactly -Times 4 -Scope It
        }
    }

    Context 'When output is made as informational message' {
        BeforeAll {
            Mock -CommandName Write-Information
        }

        It 'Should output to console' {
            $expected = @(
                'My String very long string that is longer than actual'
                'Line 2'
                'Line 3'
            )
            $actual = @(
                'My string that is shorter'
                'Line 2'
                'Line 3 is longer than expected'
                'Line 4'
            )

            $result = Out-Diff -Reference $expected -Difference $actual

            $result | Should-BeNull
            Should -Invoke -CommandName Write-Information -Exactly -Times 7 -Scope It
        }

        Context 'When actual value is an empty value' {
            It 'Should output to console' {
                $expected = @(
                    'My String very long string that is longer than actual'
                    'Line 2'
                    'Line 3'
                )
                $actual = ''

                $result = Out-Diff -Reference $expected -Difference $actual

                $result | Should-BeNull
                Should -Invoke -CommandName Write-Information -Exactly -Times 7 -Scope It
            }
        }

        Context 'When actual value is null' {
            It 'Should output to console' {
                $expected = @(
                    'My String very long string that is longer than actual'
                    'Line 2'
                    'Line 3'
                )
                $actual = $null

                $result = Out-Diff -Reference $expected -Difference $actual

                $result | Should-BeNull
                Should -Invoke -CommandName Write-Information -Exactly -Times 7 -Scope It
            }
        }

        Context 'When expected value is an empty value' {
            It 'Should output to console' {
                $expected = ''
                $actual = @(
                    'My String very long string that is longer than actual'
                    'Line 2'
                    'Line 3'
                )

                $result = Out-Diff -Reference $expected -Difference $actual

                $result | Should-BeNull
                Should -Invoke -CommandName Write-Information -Exactly -Times 7 -Scope It
            }
        }

        Context 'When expected value is null' {
            It 'Should output to console' {
                $expected = $null
                $actual = @(
                    'My String very long string that is longer than actual'
                    'Line 2'
                    'Line 3'
                )

                $result = Out-Diff -Reference $expected -Difference $actual

                $result | Should-BeNull
                Should -Invoke -CommandName Write-Information -Exactly -Times 7 -Scope It
            }
        }

        Context 'When expected and actual value is null' {
            It 'Should output to console' {
                $expected = $null
                $actual = $null

                $result = Out-Diff -Reference $expected -Difference $actual

                $result | Should-BeNull
                Should -Invoke -CommandName Write-Information -Exactly -Times 3 -Scope It
            }
        }

        Context 'When expected and actual value is both an empty string' {
            It 'Should output to console' {
                $expected = ''
                $actual = ''

                $result = Out-Diff -Reference $expected -Difference $actual

                $result | Should-BeNull
                Should -Invoke -CommandName Write-Information -Exactly -Times 3 -Scope It
            }
        }

        Context 'When expected and actual value is a single string' {
            Context 'When expected and actual value is the same' {
                It 'Should output to console' {
                    $expected = 'This is a test'
                    $actual = 'This is a test'

                    $result = Out-Diff -Reference $expected -Difference $actual

                    $result | Should-BeNull
                    Should -Invoke -CommandName Write-Information -Exactly -Times 2 -Scope It
                }
            }

            Context 'When expected and actual value is different' {
                It 'Should output to console' {
                    $expected = 'This is a test'
                    $actual = 'This is another test'

                    $result = Out-Diff -Reference $expected -Difference $actual

                    $result | Should-BeNull
                    Should -Invoke -CommandName Write-Information -Exactly -Times 3 -Scope It
                }
            }

            Context 'When expected and actual value contain line breaks and new line' {
                It 'Should output to console' {
                    $expected = "This is`r`na test"
                    $actual = "This Is`r`nAnother`r`nTest"

                    $result = Out-Diff -Reference $expected -Difference $actual

                    $result | Should-BeNull
                    Should -Invoke -CommandName Write-Information -Exactly -Times 3 -Scope It
                }
            }

            Context 'When expected and actual value just different in case sensitivity' {
                It 'Should output to console' {
                    $expected = @('Test','a','b')
                    $actual = @('rest','a','b')

                    $result = Out-Diff -Reference $expected -Difference $actual

                    $result | Should-BeNull
                    Should -Invoke -CommandName Write-Information -Exactly -Times 4 -Scope It
                }
            }
        }

        Context 'When expected and actual value have different lengths but similar content' {
            It 'Should output to console' {
                $expected = 'This is a test string that is quite long'
                $actual = 'This is a test string'

                $result = Out-Diff -Reference $expected -Difference $actual

                $result | Should-BeNull
                Should -Invoke -CommandName Write-Information -Exactly -Times 4 -Scope It
            }
        }

        Context 'When expected and actual value contain special characters' {
            It 'Should output to console' {
                $expected = 'This is a test string with special characters: !@#$%^&*()'
                $actual = 'This is a test string with special characters: !@#$%^&*()'

                $result = Out-Diff -Reference $expected -Difference $actual

                $result | Should-BeNull
                Should -Invoke -CommandName Write-Information -Exactly -Times 5 -Scope It
            }
        }

        Context 'When expected and actual value are empty arrays' {
            It 'Should output to console' {
                $expected = @()
                $actual = @()

                $result = Out-Diff -Reference $expected -Difference $actual

                $result | Should-BeNull
                Should -Invoke -CommandName Write-Information -Exactly -Times 3 -Scope It
            }
        }

        Context 'When expected and actual value contain mixed content' {
            It 'Should output to console' {
                $expected = @('String', 123, 'Another String')
                $actual = @('String', 456, 'Another String')

                $result = Out-Diff -Reference $expected -Difference $actual

                $result | Should-BeNull
                Should -Invoke -CommandName Write-Information -Exactly -Times 4 -Scope It
            }
        }

        Context 'When expected and actual value contain Unicode characters' {
            It 'Should output to console' {
                $expected = 'This is a test string with Unicode: 你好, мир, hello'
                $actual = 'This is a test string with Unicode: 你好, мир, hello'

                $result = Out-Diff -Reference $expected -Difference $actual

                $result | Should-BeNull
                Should -Invoke -CommandName Write-Information -Exactly -Times 5 -Scope It
            }
        }
    }

    Context 'When returning output' {
        It 'Should output to console' {
            $expected = @(
                'My String very long string that is longer than actual'
                'Line 2'
                'Line 3'
            )
            $actual = @(
                'My string that is shorter'
                'Line 2'
                'Line 3 is longer than expected'
                'Line 4'
            )

            $result = Out-Diff -Reference $expected -Difference $actual -PassThru

            $result | Should-BeEquivalent @(
                "`e[4mExpected:`e[0m                                                              `e[4mBut was:`e[0m"
                "4D 79 20 `e[30;31m53`e[0m 74 72 69 6E 67 20 `e[30;31m76`e[0m `e[30;31m65`e[0m `e[30;31m72`e[0m `e[30;31m79`e[0m 20 `e[30;31m6C`e[0m  My `e[30;31mS`e[0mtring `e[30;31mvery`e[0m `e[30;31ml`e[0m  !=  4D 79 20 `e[30;31m73`e[0m 74 72 69 6E 67 20 `e[30;31m74`e[0m `e[30;31m68`e[0m `e[30;31m61`e[0m `e[30;31m74`e[0m 20 `e[30;31m69`e[0m  My `e[30;31ms`e[0mtring `e[30;31mthat`e[0m `e[30;31mi`e[0m"
                "`e[30;31m6F`e[0m `e[30;31m6E`e[0m `e[30;31m67`e[0m `e[30;31m20`e[0m `e[30;31m73`e[0m `e[30;31m74`e[0m `e[30;31m72`e[0m `e[30;31m69`e[0m `e[30;31m6E`e[0m `e[30;31m67`e[0m `e[30;31m20`e[0m `e[30;31m74`e[0m `e[30;31m68`e[0m `e[30;31m61`e[0m `e[30;31m74`e[0m `e[30;31m20`e[0m  `e[30;31mong string that `e[0m  !=  `e[30;31m73`e[0m `e[30;31m20`e[0m `e[30;31m73`e[0m `e[30;31m68`e[0m `e[30;31m6F`e[0m `e[30;31m72`e[0m `e[30;31m74`e[0m `e[30;31m65`e[0m `e[30;31m72`e[0m                       `e[30;31ms shorter`e[0m"
                "`e[30;31m69`e[0m `e[30;31m73`e[0m `e[30;31m20`e[0m `e[30;31m6C`e[0m `e[30;31m6F`e[0m `e[30;31m6E`e[0m `e[30;31m67`e[0m `e[30;31m65`e[0m `e[30;31m72`e[0m `e[30;31m20`e[0m `e[30;31m74`e[0m `e[30;31m68`e[0m `e[30;31m61`e[0m `e[30;31m6E`e[0m `e[30;31m20`e[0m `e[30;31m61`e[0m  `e[30;31mis longer than a`e[0m  !=  `e[30;31m4C`e[0m `e[30;31m69`e[0m `e[30;31m6E`e[0m `e[30;31m65`e[0m `e[30;31m20`e[0m `e[30;31m32`e[0m                                `e[30;31mLine 2`e[0m"
                "`e[30;31m63`e[0m `e[30;31m74`e[0m `e[30;31m75`e[0m `e[30;31m61`e[0m `e[30;31m6C`e[0m                                   `e[30;31mctual`e[0m             !=  `e[30;31m4C`e[0m `e[30;31m69`e[0m `e[30;31m6E`e[0m `e[30;31m65`e[0m `e[30;31m20`e[0m `e[30;31m33`e[0m `e[30;31m20`e[0m `e[30;31m69`e[0m `e[30;31m73`e[0m `e[30;31m20`e[0m `e[30;31m6C`e[0m `e[30;31m6F`e[0m `e[30;31m6E`e[0m `e[30;31m67`e[0m `e[30;31m65`e[0m `e[30;31m72`e[0m  `e[30;31mLine 3 is longer`e[0m"
                "`e[30;31m4C`e[0m `e[30;31m69`e[0m `e[30;31m6E`e[0m `e[30;31m65`e[0m `e[30;31m20`e[0m `e[30;31m32`e[0m                                `e[30;31mLine 2`e[0m            !=  `e[30;31m20`e[0m `e[30;31m74`e[0m `e[30;31m68`e[0m `e[30;31m61`e[0m `e[30;31m6E`e[0m `e[30;31m20`e[0m `e[30;31m65`e[0m `e[30;31m78`e[0m `e[30;31m70`e[0m `e[30;31m65`e[0m `e[30;31m63`e[0m `e[30;31m74`e[0m `e[30;31m65`e[0m `e[30;31m64`e[0m        `e[30;31m than expected`e[0m"
                "4C 69 6E 65 20 `e[30;31m33`e[0m                                Line `e[30;31m3`e[0m            !=  4C 69 6E 65 20 `e[30;31m34`e[0m                                Line `e[30;31m4`e[0m"
            )
        }

        It 'Should output to console, but without header' {
            $expected = @(
                'My String very long string that is longer than actual'
                'Line 2'
                'Line 3'
            )
            $actual = @(
                'My string that is shorter'
                'Line 2'
                'Line 3 is longer than expected'
                'Line 4'
            )

            $result = Out-Diff -Reference $expected -Difference $actual -PassThru -NoHeader

            $result | Should-BeEquivalent @(
                "4D 79 20 `e[30;31m53`e[0m 74 72 69 6E 67 20 `e[30;31m76`e[0m `e[30;31m65`e[0m `e[30;31m72`e[0m `e[30;31m79`e[0m 20 `e[30;31m6C`e[0m  My `e[30;31mS`e[0mtring `e[30;31mvery`e[0m `e[30;31ml`e[0m  !=  4D 79 20 `e[30;31m73`e[0m 74 72 69 6E 67 20 `e[30;31m74`e[0m `e[30;31m68`e[0m `e[30;31m61`e[0m `e[30;31m74`e[0m 20 `e[30;31m69`e[0m  My `e[30;31ms`e[0mtring `e[30;31mthat`e[0m `e[30;31mi`e[0m"
                "`e[30;31m6F`e[0m `e[30;31m6E`e[0m `e[30;31m67`e[0m `e[30;31m20`e[0m `e[30;31m73`e[0m `e[30;31m74`e[0m `e[30;31m72`e[0m `e[30;31m69`e[0m `e[30;31m6E`e[0m `e[30;31m67`e[0m `e[30;31m20`e[0m `e[30;31m74`e[0m `e[30;31m68`e[0m `e[30;31m61`e[0m `e[30;31m74`e[0m `e[30;31m20`e[0m  `e[30;31mong string that `e[0m  !=  `e[30;31m73`e[0m `e[30;31m20`e[0m `e[30;31m73`e[0m `e[30;31m68`e[0m `e[30;31m6F`e[0m `e[30;31m72`e[0m `e[30;31m74`e[0m `e[30;31m65`e[0m `e[30;31m72`e[0m                       `e[30;31ms shorter`e[0m"
                "`e[30;31m69`e[0m `e[30;31m73`e[0m `e[30;31m20`e[0m `e[30;31m6C`e[0m `e[30;31m6F`e[0m `e[30;31m6E`e[0m `e[30;31m67`e[0m `e[30;31m65`e[0m `e[30;31m72`e[0m `e[30;31m20`e[0m `e[30;31m74`e[0m `e[30;31m68`e[0m `e[30;31m61`e[0m `e[30;31m6E`e[0m `e[30;31m20`e[0m `e[30;31m61`e[0m  `e[30;31mis longer than a`e[0m  !=  `e[30;31m4C`e[0m `e[30;31m69`e[0m `e[30;31m6E`e[0m `e[30;31m65`e[0m `e[30;31m20`e[0m `e[30;31m32`e[0m                                `e[30;31mLine 2`e[0m"
                "`e[30;31m63`e[0m `e[30;31m74`e[0m `e[30;31m75`e[0m `e[30;31m61`e[0m `e[30;31m6C`e[0m                                   `e[30;31mctual`e[0m             !=  `e[30;31m4C`e[0m `e[30;31m69`e[0m `e[30;31m6E`e[0m `e[30;31m65`e[0m `e[30;31m20`e[0m `e[30;31m33`e[0m `e[30;31m20`e[0m `e[30;31m69`e[0m `e[30;31m73`e[0m `e[30;31m20`e[0m `e[30;31m6C`e[0m `e[30;31m6F`e[0m `e[30;31m6E`e[0m `e[30;31m67`e[0m `e[30;31m65`e[0m `e[30;31m72`e[0m  `e[30;31mLine 3 is longer`e[0m"
                "`e[30;31m4C`e[0m `e[30;31m69`e[0m `e[30;31m6E`e[0m `e[30;31m65`e[0m `e[30;31m20`e[0m `e[30;31m32`e[0m                                `e[30;31mLine 2`e[0m            !=  `e[30;31m20`e[0m `e[30;31m74`e[0m `e[30;31m68`e[0m `e[30;31m61`e[0m `e[30;31m6E`e[0m `e[30;31m20`e[0m `e[30;31m65`e[0m `e[30;31m78`e[0m `e[30;31m70`e[0m `e[30;31m65`e[0m `e[30;31m63`e[0m `e[30;31m74`e[0m `e[30;31m65`e[0m `e[30;31m64`e[0m        `e[30;31m than expected`e[0m"
                "4C 69 6E 65 20 `e[30;31m33`e[0m                                Line `e[30;31m3`e[0m            !=  4C 69 6E 65 20 `e[30;31m34`e[0m                                Line `e[30;31m4`e[0m"
            )
        }
    }
}
