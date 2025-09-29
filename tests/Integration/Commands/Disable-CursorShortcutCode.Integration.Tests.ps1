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
                & "$PSScriptRoot/../../../build.ps1" -Tasks 'noop' 3>&1 4>&1 5>&1 6>&1 > $null
            }

            # If the dependencies has not been resolved, this will throw an error.
            Import-Module -Name 'DscResource.Test' -Force -ErrorAction 'Stop'
        }
    }
    catch [System.IO.FileNotFoundException]
    {
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -ResolveDependency -Tasks noop" first.'
    }
}

BeforeAll {
    $script:dscModuleName = 'Viscalyx.Common'

    Import-Module -Name $script:dscModuleName -Force -ErrorAction Stop

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

Describe 'Disable-CursorShortcutCode' {
    BeforeAll {
        Mock -CommandName Move-Item

        if ($env:Path -notmatch 'Cursor')
        {
            $script:mockPreviousEnvironmentVariablePath = $env:Path
            $env:Path = $env:Path + ('{0}C:\Program Files\Cursor' -f [System.IO.Path]::PathSeparator)
        }
    }

    AfterAll {
        if ($script:mockPreviousEnvironmentVariablePath)
        {
            $env:Path = $script:mockPreviousEnvironmentVariablePath
        }
    }

    It 'Should disable Cursor shortcuts when Cursor path is found and files exist' {
        Mock -CommandName Test-Path -MockWith {
            return $true
        }

        Viscalyx.Common\Disable-CursorShortcutCode -Confirm:$false

        Should -Invoke -CommandName Move-Item -Exactly -Times 2 -Scope It
    }

    It 'Should not disable Cursor shortcuts when Cursor path is not found' {
        Mock -CommandName Test-Path -MockWith {
            return $false
        }

        Viscalyx.Common\Disable-CursorShortcutCode -Confirm:$false
        Should -Invoke -CommandName Move-Item -Times 0 -Scope It
    }

    It 'Should handle cases where code.cmd does not exist' {
        Mock -CommandName Test-Path -MockWith {
            return $false
        } -ParameterFilter {
            $Path -match 'code\.cmd$'
        }

        Viscalyx.Common\Disable-CursorShortcutCode -Confirm:$false

        Should -Invoke -CommandName Move-Item -Times 0 -Scope It
    }

    It 'Should handle cases where code.cmd or code file does not exist' {
        Mock -CommandName Test-Path -MockWith {
            return $false
        } -ParameterFilter {
            $Path -match 'code$'
        }

        Viscalyx.Common\Disable-CursorShortcutCode -Confirm:$false

        Should -Invoke -CommandName Move-Item -Times 0 -Scope It
    }

    It 'Should not perform operations when using WhatIf' {
        Mock -CommandName Test-Path -MockWith {
            return $true
        }

        Viscalyx.Common\Disable-CursorShortcutCode -WhatIf

        Should -Invoke -CommandName Move-Item -Times 0 -Scope It
    }

    It 'Should perform operations without confirmation when using Force' {
        Mock -CommandName Test-Path -MockWith {
            return $true
        }

        Viscalyx.Common\Disable-CursorShortcutCode -Force

        Should -Invoke -CommandName Move-Item -Exactly -Times 2 -Scope It
    }
}
