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

            Context 'Parameter Set Validation' {
                It 'Should have the correct parameters in parameter set <ExpectedParameterSetName>' -ForEach @(
                    @{
                        ExpectedParameterSetName = '__AllParameterSets'
                        ExpectedParameters       = '[-WorkingDirectory] <string> [[-Timeout] <int>] [[-Arguments] <string[]>] [-PassThru] [<CommonParameters>]'
                    }
                ) {
                    $result = (Get-Command -Name 'Invoke-Git').ParameterSets |
                        Where-Object -FilterScript { $_.Name -eq $ExpectedParameterSetName } |
                        Select-Object -Property @(
                            @{ Name = 'ParameterSetName'; Expression = { $_.Name } },
                            @{ Name = 'ParameterListAsString'; Expression = { $_.ToString() } }
                        )

                    $result.ParameterSetName | Should -Be $ExpectedParameterSetName

                    if ($PSVersionTable.PSEdition -eq 'Desktop')
                    {
                        # Windows PowerShell shows <int> instead of <int32> for System.Int32 type
                        $ExpectedParameters = $ExpectedParameters -replace '<int32>', '<int>'
                    }

                    $result.ParameterListAsString | Should -Be $ExpectedParameters
                }
            }

            Context 'Parameter Properties' {
                It 'Should have WorkingDirectory as a mandatory parameter' {
                    $parameterInfo = (Get-Command -Name 'Invoke-Git').Parameters['WorkingDirectory']
                    $parameterInfo.Attributes.Mandatory | Should -Contain $true
                }

                It 'Should have Timeout as a non-mandatory parameter' {
                    $parameterInfo = (Get-Command -Name 'Invoke-Git').Parameters['Timeout']
                    $parameterInfo.Attributes.Mandatory | Should -BeFalse
                }

                It 'Should have PassThru as a non-mandatory parameter' {
                    $parameterInfo = (Get-Command -Name 'Invoke-Git').Parameters['PassThru']
                    $parameterInfo.Attributes.Mandatory | Should -BeFalse
                }

                It 'Should have Arguments as a non-mandatory parameter' {
                    $parameterInfo = (Get-Command -Name 'Invoke-Git').Parameters['Arguments']
                    $parameterInfo.Attributes.Mandatory | Should -BeFalse
                }

                It 'Should have Arguments parameter with ValueFromRemainingArguments' {
                    $parameterInfo = (Get-Command -Name 'Invoke-Git').Parameters['Arguments']
                    $parameterInfo.Attributes.ValueFromRemainingArguments | Should -BeTrue
                }

                It 'Should have correct parameter types' {
                    $command = Get-Command -Name 'Invoke-Git'

                    $command.Parameters['WorkingDirectory'].ParameterType | Should -Be ([System.String])
                    $command.Parameters['Timeout'].ParameterType | Should -Be ([System.Int32])
                    $command.Parameters['PassThru'].ParameterType | Should -Be ([System.Management.Automation.SwitchParameter])
                    $command.Parameters['Arguments'].ParameterType | Should -Be ([System.String[]])
                }

                It 'Should have correct output type' {
                    $outputType = (Get-Command -Name 'Invoke-Git').OutputType
                    $outputType.Type | Should -Be ([System.Collections.Hashtable])
                }
            }

            Context 'When git ExitCode -eq 0' {
                BeforeAll {
                    $mockProcess | Add-Member -MemberType ScriptProperty -Name 'ExitCode' -Value { 0 } -Force
                }

                It 'Should not throw, return result with -PassThru' {
                    $result = Viscalyx.Common\Invoke-Git -WorkingDirectory $TestDrive -Arguments @( 'status', '--verbose' ) -PassThru

                    $result.ExitCode | Should -BeExactly 0

                    $result.StandardOutput | Should -BeExactly 'Standard Output Message'

                    $result.StandardError | Should -BeExactly 'Standard Error Message'
                }

                It 'Should not throw, return result with -PassThru, with -Verbose' {
                    $result = Viscalyx.Common\Invoke-Git -WorkingDirectory $TestDrive -Arguments @( 'status', '--verbose' ) -PassThru -Verbose

                    $result.ExitCode | Should -BeExactly 0

                    $result.StandardOutput | Should -BeExactly 'Standard Output Message'

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

                    $result.StandardOutput | Should -BeExactly 'Standard Output Message'

                    $result.StandardError | Should -BeExactly 'Standard Error Message'
                }

                It 'Should not throw, return result with -PassThru, with -Verbose' {
                    $result = Viscalyx.Common\Invoke-Git -WorkingDirectory $TestDrive -Arguments @( 'status', '--verbose' ) -PassThru -Verbose

                    $result.ExitCode | Should -BeExactly 128

                    $result.StandardOutput | Should -BeExactly 'Standard Output Message'

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

            $result.StandardOutput | Should -HaveCount 3
            $result.StandardOutput[0] | Should -BeExactly 'line1'
            $result.StandardOutput[1] | Should -BeExactly 'line2'
            $result.StandardOutput[2] | Should -BeExactly 'line3'
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

            $result.StandardOutput | Should -HaveCount 3
            $result.StandardOutput[0] | Should -BeExactly 'line1'
            $result.StandardOutput[1] | Should -BeExactly 'line2'
            $result.StandardOutput[2] | Should -BeExactly 'line3'
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

            $result.StandardOutput | Should -HaveCount 3
            $result.StandardOutput[0] | Should -BeExactly 'line1'
            $result.StandardOutput[1] | Should -BeExactly 'line2'
            $result.StandardOutput[2] | Should -BeExactly 'line3'
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

            $result.StandardOutput | Should -BeNullOrEmpty
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

            $result.StandardOutput | Should -BeOfType [System.String]
            $result.StandardOutput | Should -BeExactly 'single line'
        }
    }
}
