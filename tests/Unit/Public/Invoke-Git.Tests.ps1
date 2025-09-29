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

Describe 'Viscalyx.Common\Invoke-Git' {
    BeforeAll {
        $mockProcess = New-MockObject -Type System.Diagnostics.Process
        $mockProcess | Add-Member -MemberType ScriptMethod -Name 'Start' -Value { return [bool]$true } -Force
        $mockProcess | Add-Member -MemberType ScriptMethod -Name 'WaitForExit' -Value { param($timeout) return [bool]$true } -Force
        $mockProcess | Add-Member -MemberType ScriptMethod -Name 'Dispose' -Value { } -Force
        $mockProcess | Add-Member -MemberType ScriptProperty -Name WorkingDirectory -Value { '' } -Force

        $mockProcess | Add-Member -MemberType ScriptProperty -Name 'StandardOutput' -Value {
            New-Object -TypeName 'Object' |
                    Add-Member -MemberType ScriptMethod -Name 'ReadToEnd' -Value { 'Standard Output Message' } -PassThru -Force
            } -Force

            $mockProcess | Add-Member -MemberType ScriptProperty -Name 'StandardError' -Value {
                New-Object -TypeName 'Object' |
                        Add-Member -MemberType ScriptMethod -Name 'ReadToEnd' -Value { 'Standard Error Message' } -PassThru -Force
                } -Force

                # Need to add StartInfo property and its nested properties
                $mockStartInfo = New-Object -TypeName 'Object'
                $mockStartInfo | Add-Member -MemberType NoteProperty -Name 'Arguments' -Value @() -Force
                $mockStartInfo | Add-Member -MemberType NoteProperty -Name 'CreateNoWindow' -Value $false -Force
                $mockStartInfo | Add-Member -MemberType NoteProperty -Name 'FileName' -Value '' -Force
                $mockStartInfo | Add-Member -MemberType NoteProperty -Name 'RedirectStandardOutput' -Value $false -Force
                $mockStartInfo | Add-Member -MemberType NoteProperty -Name 'RedirectStandardError' -Value $false -Force
                $mockStartInfo | Add-Member -MemberType NoteProperty -Name 'UseShellExecute' -Value $true -Force
                $mockStartInfo | Add-Member -MemberType NoteProperty -Name 'WindowStyle' -Value 'Normal' -Force
                $mockStartInfo | Add-Member -MemberType NoteProperty -Name 'WorkingDirectory' -Value '' -Force

                $mockProcess | Add-Member -MemberType NoteProperty -Name 'StartInfo' -Value $mockStartInfo -Force

                Mock -CommandName New-Object -MockWith { return $mockProcess } -ParameterFilter { $TypeName -eq 'System.Diagnostics.Process' }
            }

            Context 'When git ExitCode -eq 0' {
                BeforeAll {
                    $mockProcess | Add-Member -MemberType ScriptProperty -Name 'ExitCode' -Value { 0 } -Force
                }

                It 'Should not throw, return result with -PassThru' {
                    $result = Viscalyx.Common\Invoke-Git -WorkingDirectory $TestDrive -Arguments @( 'status', '--verbose' ) -PassThru

                    $result.ExitCode | Should -BeExactly 0

                    $result.Output | Should -BeExactly 'Standard Output Message'

                    $result.StandardError | Should -BeExactly 'Standard Error Message'
                }

                It 'Should not throw, return result with -PassThru, with -Verbose' {
                    $result = Viscalyx.Common\Invoke-Git -WorkingDirectory $TestDrive -Arguments @( 'status', '--verbose' ) -PassThru -Verbose

                    $result.ExitCode | Should -BeExactly 0

                    $result.Output | Should -BeExactly 'Standard Output Message'

                    $result.StandardError | Should -BeExactly 'Standard Error Message'
                }

                It 'Should not throw without -PassThru' {
                    $null = Viscalyx.Common\Invoke-Git -WorkingDirectory $TestDrive -Arguments @( 'status', '--verbose' )
                }

                It 'Should not throw without -PassThru, with -Verbose' {
                    $null = Viscalyx.Common\Invoke-Git -WorkingDirectory $TestDrive -Arguments @( 'status', '--verbose' ) -Verbose
                }
            }

            Context 'When git ExitCode -ne 0' {
                BeforeAll {
                    $mockProcess | Add-Member -MemberType ScriptProperty -Name 'ExitCode' -Value { 128 } -Force
                }

                It 'Should not throw, return result with -PassThru' {
                    $result = Viscalyx.Common\Invoke-Git -WorkingDirectory $TestDrive -Arguments @( 'status', '--verbose' ) -PassThru

                    $result.ExitCode | Should -BeExactly 128

                    $result.Output | Should -BeExactly 'Standard Output Message'

                    $result.StandardError | Should -BeExactly 'Standard Error Message'
                }

                It 'Should not throw, return result with -PassThru, with -Verbose' {
                    $result = Viscalyx.Common\Invoke-Git -WorkingDirectory $TestDrive -Arguments @( 'status', '--verbose' ) -PassThru -Verbose

                    $result.ExitCode | Should -BeExactly 128

                    $result.Output | Should -BeExactly 'Standard Output Message'

                    $result.StandardError | Should -BeExactly 'Standard Error Message'
                }

                It 'Should throw without -PassThru' {
                    { Viscalyx.Common\Invoke-Git -WorkingDirectory $TestDrive -Arguments @( 'status', '--verbose' ) } | Should -Throw
                }

                It 'Should throw without -PassThru, with -Verbose' {
                    { Viscalyx.Common\Invoke-Git -WorkingDirectory $TestDrive -Arguments @( 'status', '--verbose' ) -Verbose } | Should -Throw
                }
            }

            Context 'When throwing an error' {
                BeforeAll {
                    $mockProcess | Add-Member -MemberType ScriptProperty -Name 'ExitCode' -Value { 128 } -Force

                    $tokenPrefix = ('pousr').ToCharArray() | Get-Random
                    $newTokenLength = Get-Random -Minimum 1 -Maximum 251
                    $newToken = (1..$newTokenLength | ForEach-Object -Process { ('abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890').ToCharArray() | Get-Random }) -join ''
                }

                $testCases = @(
                    @{
                        'Command'      = @('status', '--verbose');
                        'ErrorMessage' = 'status --verbose';
                    },
                    @{
                        'Command'      = @( 'remote', 'add', 'origin', "https://gh$($tokenPrefix)_$($newToken)@github.com/owner/repo.git" );
                        'ErrorMessage' = 'remote add origin https://**REDACTED-TOKEN**@github.com/owner/repo.git';
                    }
                )

                It "Should throw exact with '<ErrorMessage>'" -TestCases $testCases {
                    param( $Command, $ErrorMessage )

                    $errorMessage = $script:localizedData.Invoke_Git_CommandFailed -f 128

                    $detailsMessage = (
                        "$($script:localizedData.Invoke_Git_CommandDebug -f ('git {0}' -f $ErrorMessage))`n" +
                        "$($script:localizedData.Invoke_Git_StandardOutputMessage -f 'Standard Output Message')`n" +
                        "$($script:localizedData.Invoke_Git_StandardErrorMessage -f 'Standard Error Message')`n" +
                        "$($script:localizedData.Invoke_Git_WorkingDirectoryDebug -f $TestDrive)"
                    )

                    $throwMessage = "$errorMessage`n$detailsMessage`n"

                    { Viscalyx.Common\Invoke-Git -WorkingDirectory $TestDrive -Arguments $Command } | Should -Throw $throwMessage
                }
            }

            Context 'When arguments contain spaces' {
                BeforeAll {
                    $mockProcess | Add-Member -MemberType ScriptProperty -Name 'ExitCode' -Value { 0 } -Force
                }

                It 'Should quote arguments containing spaces that are not already quoted' {
                    Viscalyx.Common\Invoke-Git -WorkingDirectory $TestDrive -Arguments @( 'config', 'user.name', 'John Doe' ) -PassThru

                    # Verify that the processed arguments array contains properly quoted arguments
                    $processedArgs = $mockProcess.StartInfo.Arguments
                    $processedArgs | Should -Contain 'config'
                    $processedArgs | Should -Contain 'user.name'
                    $processedArgs | Should -Contain '"John Doe"'
                    $processedArgs | Should -Not -Contain 'John Doe'
                }

                It 'Should not add quotes to arguments that are already quoted' {
                    Viscalyx.Common\Invoke-Git -WorkingDirectory $TestDrive -Arguments @( 'config', 'user.name', '"John Doe"' ) -PassThru

                    # Verify that already quoted arguments are not double-quoted
                    $processedArgs = $mockProcess.StartInfo.Arguments
                    $processedArgs | Should -Contain 'config'
                    $processedArgs | Should -Contain 'user.name'
                    $processedArgs | Should -Contain '"John Doe"'
                    $processedArgs | Should -Not -Contain '""John Doe""'
                }

                It 'Should not quote arguments without spaces' {
                    Viscalyx.Common\Invoke-Git -WorkingDirectory $TestDrive -Arguments @( 'config', 'user.name', 'JohnDoe' ) -PassThru

                    # Verify that arguments without spaces are not quoted
                    $processedArgs = $mockProcess.StartInfo.Arguments
                    $processedArgs | Should -Contain 'config'
                    $processedArgs | Should -Contain 'user.name'
                    $processedArgs | Should -Contain 'JohnDoe'
                    $processedArgs | Should -Not -Contain '"JohnDoe"'
                }

                It 'Should handle mixed arguments with and without spaces' {
                    Viscalyx.Common\Invoke-Git -WorkingDirectory $TestDrive -Arguments @( 'commit', '-m', 'Fix bug in module', '--author', 'John Doe <john@example.com>' ) -PassThru

                    # Verify mixed argument handling
                    $processedArgs = $mockProcess.StartInfo.Arguments
                    $processedArgs | Should -Contain 'commit'
                    $processedArgs | Should -Contain '-m'
                    $processedArgs | Should -Contain '"Fix bug in module"'
                    $processedArgs | Should -Contain '--author'
                    $processedArgs | Should -Contain '"John Doe <john@example.com>"'
                }

                It 'Should handle arguments with different types of whitespace' {
                    $messageWithWhitespace = "Fix`tbug`nwith`rwhitespace"
                    Viscalyx.Common\Invoke-Git -WorkingDirectory $TestDrive -Arguments @( 'commit', '-m', $messageWithWhitespace ) -PassThru

                    # Verify that tab, newline, and carriage return characters trigger quoting
                    $processedArgs = $mockProcess.StartInfo.Arguments
                    $processedArgs | Should -Contain 'commit'
                    $processedArgs | Should -Contain '-m'
                    $processedArgs | Should -Contain "`"$messageWithWhitespace`""
                }
            }

            Context 'When git output contains multiple lines with whitespace' {
                BeforeAll {
                    $mockProcess | Add-Member -MemberType ScriptProperty -Name 'ExitCode' -Value { 0 } -Force
                }

                It 'Should split CRLF lines and trim whitespace, filtering empty lines' {
                    Mock -CommandName New-Object -MockWith {
                        $testMockProcess = New-MockObject -Type System.Diagnostics.Process
                        $testMockProcess | Add-Member -MemberType ScriptMethod -Name 'Start' -Value { return [bool]$true } -Force
                        $testMockProcess | Add-Member -MemberType ScriptMethod -Name 'WaitForExit' -Value { param($timeout) return [bool]$true } -Force
                        $testMockProcess | Add-Member -MemberType ScriptMethod -Name 'Dispose' -Value { } -Force
                        $testMockProcess | Add-Member -MemberType ScriptProperty -Name 'ExitCode' -Value { 0 } -Force

                        # Mock StandardOutput to return multi-line string with CRLF, whitespace, and empty lines
                        $testMockProcess |
                            Add-Member -MemberType ScriptProperty -Name 'StandardOutput' -Value {
                                New-Object -TypeName 'Object' |
                                    Add-Member -MemberType ScriptMethod -Name 'ReadToEnd' -Value { "  line1  `r`n`r`n  line2  `r`n   `r`n  line3  `r`n" } -PassThru -Force
                                } -Force

                $testMockProcess |
                    Add-Member -MemberType ScriptProperty -Name 'StandardError' -Value {
                        New-Object -TypeName 'Object' |
                            Add-Member -MemberType ScriptMethod -Name 'ReadToEnd' -Value { '' } -PassThru -Force
                        } -Force

                # Need to add StartInfo property and its nested properties
                $testMockStartInfo = New-Object -TypeName 'Object'
                $testMockStartInfo | Add-Member -MemberType NoteProperty -Name 'Arguments' -Value @() -Force
                $testMockStartInfo | Add-Member -MemberType NoteProperty -Name 'CreateNoWindow' -Value $false -Force
                $testMockStartInfo | Add-Member -MemberType NoteProperty -Name 'FileName' -Value '' -Force
                $testMockStartInfo | Add-Member -MemberType NoteProperty -Name 'RedirectStandardOutput' -Value $false -Force
                $testMockStartInfo | Add-Member -MemberType NoteProperty -Name 'RedirectStandardError' -Value $false -Force
                $testMockStartInfo | Add-Member -MemberType NoteProperty -Name 'UseShellExecute' -Value $true -Force
                $testMockStartInfo | Add-Member -MemberType NoteProperty -Name 'WindowStyle' -Value 'Normal' -Force
                $testMockStartInfo | Add-Member -MemberType NoteProperty -Name 'WorkingDirectory' -Value '' -Force

                $testMockProcess | Add-Member -MemberType NoteProperty -Name 'StartInfo' -Value $testMockStartInfo -Force
                return $testMockProcess
            } -ParameterFilter { $TypeName -eq 'System.Diagnostics.Process' }

            $result = Viscalyx.Common\Invoke-Git -WorkingDirectory $TestDrive -Arguments @( 'status' ) -PassThru

            $result.Output | Should -HaveCount 3
            $result.Output[0] | Should -BeExactly 'line1'
            $result.Output[1] | Should -BeExactly 'line2'
            $result.Output[2] | Should -BeExactly 'line3'
        }

        It 'Should split LF lines and trim whitespace, filtering empty lines' {
            Mock -CommandName New-Object -MockWith {
                $testMockProcess = New-MockObject -Type System.Diagnostics.Process
                $testMockProcess | Add-Member -MemberType ScriptMethod -Name 'Start' -Value { return [bool]$true } -Force
                $testMockProcess | Add-Member -MemberType ScriptMethod -Name 'WaitForExit' -Value { param($timeout) return [bool]$true } -Force
                $testMockProcess | Add-Member -MemberType ScriptMethod -Name 'Dispose' -Value { } -Force
                $testMockProcess | Add-Member -MemberType ScriptProperty -Name 'ExitCode' -Value { 0 } -Force

                # Mock StandardOutput to return multi-line string with LF, whitespace, and empty lines
                $testMockProcess |
                    Add-Member -MemberType ScriptProperty -Name 'StandardOutput' -Value {
                        New-Object -TypeName 'Object' |
                                Add-Member -MemberType ScriptMethod -Name 'ReadToEnd' -Value { "  line1  `n`n  line2  `n   `n  line3  `n" } -PassThru -Force
                        } -Force

                $testMockProcess |
                    Add-Member -MemberType ScriptProperty -Name 'StandardError' -Value {
                        New-Object -TypeName 'Object' |
                                Add-Member -MemberType ScriptMethod -Name 'ReadToEnd' -Value { '' } -PassThru -Force
                        } -Force

                # Need to add StartInfo property and its nested properties
                $testMockStartInfo = New-Object -TypeName 'Object'
                $testMockStartInfo | Add-Member -MemberType NoteProperty -Name 'Arguments' -Value @() -Force
                $testMockStartInfo | Add-Member -MemberType NoteProperty -Name 'CreateNoWindow' -Value $false -Force
                $testMockStartInfo | Add-Member -MemberType NoteProperty -Name 'FileName' -Value '' -Force
                $testMockStartInfo | Add-Member -MemberType NoteProperty -Name 'RedirectStandardOutput' -Value $false -Force
                $testMockStartInfo | Add-Member -MemberType NoteProperty -Name 'RedirectStandardError' -Value $false -Force
                $testMockStartInfo | Add-Member -MemberType NoteProperty -Name 'UseShellExecute' -Value $true -Force
                $testMockStartInfo | Add-Member -MemberType NoteProperty -Name 'WindowStyle' -Value 'Normal' -Force
                $testMockStartInfo | Add-Member -MemberType NoteProperty -Name 'WorkingDirectory' -Value '' -Force

                $testMockProcess | Add-Member -MemberType NoteProperty -Name 'StartInfo' -Value $testMockStartInfo -Force
                return $testMockProcess
            } -ParameterFilter { $TypeName -eq 'System.Diagnostics.Process' }

            $result = Viscalyx.Common\Invoke-Git -WorkingDirectory $TestDrive -Arguments @( 'status' ) -PassThru

            $result.Output | Should -HaveCount 3
            $result.Output[0] | Should -BeExactly 'line1'
            $result.Output[1] | Should -BeExactly 'line2'
            $result.Output[2] | Should -BeExactly 'line3'
        }

        It 'Should handle mixed CRLF and LF line endings' {
            Mock -CommandName New-Object -MockWith {
                $testMockProcess = New-MockObject -Type System.Diagnostics.Process
                $testMockProcess | Add-Member -MemberType ScriptMethod -Name 'Start' -Value { return [bool]$true } -Force
                $testMockProcess | Add-Member -MemberType ScriptMethod -Name 'WaitForExit' -Value { param($timeout) return [bool]$true } -Force
                $testMockProcess | Add-Member -MemberType ScriptMethod -Name 'Dispose' -Value { } -Force
                $testMockProcess | Add-Member -MemberType ScriptProperty -Name 'ExitCode' -Value { 0 } -Force

                # Mock StandardOutput with mixed line endings
                $testMockProcess |
                    Add-Member -MemberType ScriptProperty -Name 'StandardOutput' -Value {
                        New-Object -TypeName 'Object' |
                                Add-Member -MemberType ScriptMethod -Name 'ReadToEnd' -Value { "line1`r`nline2`nline3`r`n" } -PassThru -Force
                        } -Force

                $testMockProcess |
                    Add-Member -MemberType ScriptProperty -Name 'StandardError' -Value {
                        New-Object -TypeName 'Object' |
                                Add-Member -MemberType ScriptMethod -Name 'ReadToEnd' -Value { '' } -PassThru -Force
                        } -Force

                # Need to add StartInfo property and its nested properties
                $testMockStartInfo = New-Object -TypeName 'Object'
                $testMockStartInfo | Add-Member -MemberType NoteProperty -Name 'Arguments' -Value @() -Force
                $testMockStartInfo | Add-Member -MemberType NoteProperty -Name 'CreateNoWindow' -Value $false -Force
                $testMockStartInfo | Add-Member -MemberType NoteProperty -Name 'FileName' -Value '' -Force
                $testMockStartInfo | Add-Member -MemberType NoteProperty -Name 'RedirectStandardOutput' -Value $false -Force
                $testMockStartInfo | Add-Member -MemberType NoteProperty -Name 'RedirectStandardError' -Value $false -Force
                $testMockStartInfo | Add-Member -MemberType NoteProperty -Name 'UseShellExecute' -Value $true -Force
                $testMockStartInfo | Add-Member -MemberType NoteProperty -Name 'WindowStyle' -Value 'Normal' -Force
                $testMockStartInfo | Add-Member -MemberType NoteProperty -Name 'WorkingDirectory' -Value '' -Force

                $testMockProcess | Add-Member -MemberType NoteProperty -Name 'StartInfo' -Value $testMockStartInfo -Force
                return $testMockProcess
            } -ParameterFilter { $TypeName -eq 'System.Diagnostics.Process' }

            $result = Viscalyx.Common\Invoke-Git -WorkingDirectory $TestDrive -Arguments @( 'status' ) -PassThru

            $result.Output | Should -HaveCount 3
            $result.Output[0] | Should -BeExactly 'line1'
            $result.Output[1] | Should -BeExactly 'line2'
            $result.Output[2] | Should -BeExactly 'line3'
        }

        It 'Should return $null when all lines are empty or whitespace' {
            Mock -CommandName New-Object -MockWith {
                $testMockProcess = New-MockObject -Type System.Diagnostics.Process
                $testMockProcess | Add-Member -MemberType ScriptMethod -Name 'Start' -Value { return [bool]$true } -Force
                $testMockProcess | Add-Member -MemberType ScriptMethod -Name 'WaitForExit' -Value { param($timeout) return [bool]$true } -Force
                $testMockProcess | Add-Member -MemberType ScriptMethod -Name 'Dispose' -Value { } -Force
                $testMockProcess | Add-Member -MemberType ScriptProperty -Name 'ExitCode' -Value { 0 } -Force

                # Mock StandardOutput with only empty lines and whitespace
                $testMockProcess |
                    Add-Member -MemberType ScriptProperty -Name 'StandardOutput' -Value {
                        New-Object -TypeName 'Object' |
                                Add-Member -MemberType ScriptMethod -Name 'ReadToEnd' -Value { "`r`n   `r`n`t`r`n  " } -PassThru -Force
                        } -Force

                $testMockProcess |
                    Add-Member -MemberType ScriptProperty -Name 'StandardError' -Value {
                        New-Object -TypeName 'Object' |
                                Add-Member -MemberType ScriptMethod -Name 'ReadToEnd' -Value { '' } -PassThru -Force
                        } -Force

                # Need to add StartInfo property and its nested properties
                $testMockStartInfo = New-Object -TypeName 'Object'
                $testMockStartInfo | Add-Member -MemberType NoteProperty -Name 'Arguments' -Value @() -Force
                $testMockStartInfo | Add-Member -MemberType NoteProperty -Name 'CreateNoWindow' -Value $false -Force
                $testMockStartInfo | Add-Member -MemberType NoteProperty -Name 'FileName' -Value '' -Force
                $testMockStartInfo | Add-Member -MemberType NoteProperty -Name 'RedirectStandardOutput' -Value $false -Force
                $testMockStartInfo | Add-Member -MemberType NoteProperty -Name 'RedirectStandardError' -Value $false -Force
                $testMockStartInfo | Add-Member -MemberType NoteProperty -Name 'UseShellExecute' -Value $true -Force
                $testMockStartInfo | Add-Member -MemberType NoteProperty -Name 'WindowStyle' -Value 'Normal' -Force
                $testMockStartInfo | Add-Member -MemberType NoteProperty -Name 'WorkingDirectory' -Value '' -Force

                $testMockProcess | Add-Member -MemberType NoteProperty -Name 'StartInfo' -Value $testMockStartInfo -Force
                return $testMockProcess
            } -ParameterFilter { $TypeName -eq 'System.Diagnostics.Process' }

            $result = Viscalyx.Common\Invoke-Git -WorkingDirectory $TestDrive -Arguments @( 'status' ) -PassThru

            $result.Output | Should -BeNullOrEmpty
        }

        It 'Should handle single line with whitespace (returns string for backward compatibility)' {
            Mock -CommandName New-Object -MockWith {
                $testMockProcess = New-MockObject -Type System.Diagnostics.Process
                $testMockProcess | Add-Member -MemberType ScriptMethod -Name 'Start' -Value { return [bool]$true } -Force
                $testMockProcess | Add-Member -MemberType ScriptMethod -Name 'WaitForExit' -Value { param($timeout) return [bool]$true } -Force
                $testMockProcess | Add-Member -MemberType ScriptMethod -Name 'Dispose' -Value { } -Force
                $testMockProcess | Add-Member -MemberType ScriptProperty -Name 'ExitCode' -Value { 0 } -Force

                # Mock StandardOutput with single line containing whitespace
                $testMockProcess |
                    Add-Member -MemberType ScriptProperty -Name 'StandardOutput' -Value {
                        New-Object -TypeName 'Object' |
                                Add-Member -MemberType ScriptMethod -Name 'ReadToEnd' -Value { '  single line  ' } -PassThru -Force
                        } -Force

                $testMockProcess |
                    Add-Member -MemberType ScriptProperty -Name 'StandardError' -Value {
                        New-Object -TypeName 'Object' |
                                Add-Member -MemberType ScriptMethod -Name 'ReadToEnd' -Value { '' } -PassThru -Force
                        } -Force

                # Need to add StartInfo property and its nested properties
                $testMockStartInfo = New-Object -TypeName 'Object'
                $testMockStartInfo | Add-Member -MemberType NoteProperty -Name 'Arguments' -Value @() -Force
                $testMockStartInfo | Add-Member -MemberType NoteProperty -Name 'CreateNoWindow' -Value $false -Force
                $testMockStartInfo | Add-Member -MemberType NoteProperty -Name 'FileName' -Value '' -Force
                $testMockStartInfo | Add-Member -MemberType NoteProperty -Name 'RedirectStandardOutput' -Value $false -Force
                $testMockStartInfo | Add-Member -MemberType NoteProperty -Name 'RedirectStandardError' -Value $false -Force
                $testMockStartInfo | Add-Member -MemberType NoteProperty -Name 'UseShellExecute' -Value $true -Force
                $testMockStartInfo | Add-Member -MemberType NoteProperty -Name 'WindowStyle' -Value 'Normal' -Force
                $testMockStartInfo | Add-Member -MemberType NoteProperty -Name 'WorkingDirectory' -Value '' -Force

                $testMockProcess | Add-Member -MemberType NoteProperty -Name 'StartInfo' -Value $testMockStartInfo -Force
                return $testMockProcess
            } -ParameterFilter { $TypeName -eq 'System.Diagnostics.Process' }

            $result = Viscalyx.Common\Invoke-Git -WorkingDirectory $TestDrive -Arguments @( 'status' ) -PassThru

            $result.Output | Should -BeOfType [System.String]
            $result.Output | Should -BeExactly 'single line'
        }
    }
}
