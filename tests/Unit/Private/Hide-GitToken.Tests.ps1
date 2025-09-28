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

Describe 'Hide-GitToken' {
    BeforeAll {
        $returnedValue = 'remote add origin https://**REDACTED-TOKEN**@github.com/owner/repo.git'
    }

    Context 'When command contains a legacy GitHub token' {
        BeforeAll {
            $legacyToken = (1..40 | %{ ('abcdef1234567890').ToCharArray() | Get-Random }) -join ''
        }

        It "Should redact: $legacyToken" {
            InModuleScope -ScriptBlock {
                $result = Hide-GitToken -InputString @( 'remote', 'add', 'origin', "https://$($legacyToken)@github.com/owner/repo.git" )

                $result -eq $returnedValue | Should -BeTrue
            } -Parameters @{
                legacyToken = $legacyToken
                returnedValue = $returnedValue
            }
        }
    }

    Context 'When command contains a GitHub 5 character token' {
        $newToken = (1..1 | %{ ('abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890').ToCharArray() | Get-Random }) -join ''
        $testTokens = @(
            @{ 'Token' = "ghp_$newToken" },
            @{ 'Token' = "gho_$newToken" },
            @{ 'Token' = "ghu_$newToken" },
            @{ 'Token' = "ghs_$newToken" },
            @{ 'Token' = "ghr_$newToken" }
        )

        It "Should redact: '<Token>'" -TestCases $testTokens {
            param( $Token )

            InModuleScope -ScriptBlock {
                $result = Hide-GitToken -InputString @( 'remote', 'add', 'origin', "https://$($Token)@github.com/owner/repo.git" )

                $result -eq $returnedValue | Should -BeTrue
            } -Parameters @{
                Token = $Token
                returnedValue = $returnedValue
            }
        }
    }

    Context 'When command contains a GitHub 40 character token' {
        $newToken = (1..36 | %{ ('abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890').ToCharArray() | Get-Random }) -join ''
        $testTokens = @(
            @{ 'Token' = "ghp_$newToken" },
            @{ 'Token' = "gho_$newToken" },
            @{ 'Token' = "ghu_$newToken" },
            @{ 'Token' = "ghs_$newToken" },
            @{ 'Token' = "ghr_$newToken" }
        )

        It "Should redact: '<Token>'" -TestCases $testTokens {
            param( $Token )

            InModuleScope -ScriptBlock {
                $result = Hide-GitToken -InputString @( 'remote', 'add', 'origin', "https://$($Token)@github.com/owner/repo.git" )

                $result -eq $returnedValue | Should -BeTrue
            } -Parameters @{
                Token = $Token
                returnedValue = $returnedValue
            }
        }
    }

    Context 'When command contains a GitHub 100 character token' {
        $newToken = (1..96 | %{ ('abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890').ToCharArray() | Get-Random }) -join ''
        $testTokens = @(
            @{ 'Token' = "ghp_$newToken" },
            @{ 'Token' = "gho_$newToken" },
            @{ 'Token' = "ghu_$newToken" },
            @{ 'Token' = "ghs_$newToken" },
            @{ 'Token' = "ghr_$newToken" }
        )

        It "Should redact: '<Token>'" -TestCases $testTokens {
            param( $Token )

            InModuleScope -ScriptBlock {
                $result = Hide-GitToken -InputString @( 'remote', 'add', 'origin', "https://$($Token)@github.com/owner/repo.git" )

                $result -eq $returnedValue | Should -BeTrue
            } -Parameters @{
                Token = $Token
                returnedValue = $returnedValue
            }
        }
    }

    Context 'When command contains a GitHub 200 character token' {
        $newToken = (1..196 | %{ ('abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890').ToCharArray() | Get-Random }) -join ''
        $testTokens = @(
            @{ 'Token' = "ghp_$newToken" },
            @{ 'Token' = "gho_$newToken" },
            @{ 'Token' = "ghu_$newToken" },
            @{ 'Token' = "ghs_$newToken" },
            @{ 'Token' = "ghr_$newToken" }
        )

        It "Should redact: '<Token>'" -TestCases $testTokens {
            param( $Token )

            InModuleScope -ScriptBlock {
                $result = Hide-GitToken -InputString @( 'remote', 'add', 'origin', "https://$($Token)@github.com/owner/repo.git" )

                $result -eq $returnedValue | Should -BeTrue
            } -Parameters @{
                Token = $Token
                returnedValue = $returnedValue
            }
        }
    }

    Context 'When command contains a GitHub 255 character token' {
        $newToken = (1..251 | %{ ('abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890').ToCharArray() | Get-Random }) -join ''
        $testTokens = @(
            @{ 'Token' = "ghp_$newToken" },
            @{ 'Token' = "gho_$newToken" },
            @{ 'Token' = "ghu_$newToken" },
            @{ 'Token' = "ghs_$newToken" },
            @{ 'Token' = "ghr_$newToken" }
        )

        It "Should redact: '<Token>'" -TestCases $testTokens {
            param( $Token )

            InModuleScope -ScriptBlock {
                $result = Hide-GitToken -InputString @( 'remote', 'add', 'origin', "https://$($Token)@github.com/owner/repo.git" )

                $result -eq $returnedValue | Should -BeTrue
            } -Parameters @{
                Token = $Token
                returnedValue = $returnedValue
            }
        }
    }
}
