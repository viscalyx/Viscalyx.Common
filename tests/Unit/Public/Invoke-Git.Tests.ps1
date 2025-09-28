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
            New-Object -TypeName 'Object' | `
                Add-Member -MemberType ScriptMethod -Name 'ReadToEnd' -Value { 'Standard Output Message' } -PassThru -Force
        } -Force

        $mockProcess | Add-Member -MemberType ScriptProperty -Name 'StandardError' -Value {
            New-Object -TypeName 'Object' | `
                Add-Member -MemberType ScriptMethod -Name 'ReadToEnd' -Value { 'Standard Error Message' } -PassThru -Force
        } -Force

        # Need to add StartInfo property and its nested properties
        $mockStartInfo = New-Object -TypeName 'Object'
        $mockStartInfo | Add-Member -MemberType NoteProperty -Name 'Arguments' -Value '' -Force
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
            { Viscalyx.Common\Invoke-Git -WorkingDirectory $TestDrive -Arguments @( 'status', '--verbose' ) } | Should -Not -Throw
        }

        It 'Should not throw without -PassThru, with -Verbose' {
            { Viscalyx.Common\Invoke-Git -WorkingDirectory $TestDrive -Arguments @( 'status', '--verbose' ) -Verbose } | Should -Not -Throw
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
            $newToken = (1..$newTokenLength | %{ ('abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890').ToCharArray() | Get-Random }) -join ''
        }

        $testCases = @(
            @{
                'Command'      = @('status','--verbose');
                'ErrorMessage' = 'status --verbose';
            },
            @{
                'Command'      = @( 'remote','add','origin',"https://gh$($tokenPrefix)_$($newToken)@github.com/owner/repo.git" );
                'ErrorMessage' = 'remote add origin https://**REDACTED-TOKEN**@github.com/owner/repo.git';
            }
        )

        It "Should throw exact with '<ErrorMessage>'" -TestCases $testCases {
            param( $Command, $ErrorMessage )

            $throwMessage = "$($script:localizedData.Invoke_Git_CommandDebug -f ('git {0}' -f $ErrorMessage))`n" +`
                            "$($script:localizedData.Invoke_Git_ExitCodeMessage -f 128)`n" +`
                            "$($script:localizedData.Invoke_Git_StandardOutputMessage -f 'Standard Output Message')`n" +`
                            "$($script:localizedData.Invoke_Git_StandardErrorMessage -f 'Standard Error Message')`n" +`
                            "$($script:localizedData.Invoke_Git_WorkingDirectoryDebug -f $TestDrive)`n"

            { Viscalyx.Common\Invoke-Git -WorkingDirectory $TestDrive -Arguments $Command } | Should -Throw $throwMessage
        }
    }
}
