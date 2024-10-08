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

Describe 'Get-ModuleVersion' {
    Context 'When the module is passed as a string and exists' {
        BeforeAll {
            Mock -CommandName Get-Module -MockWith {
                if ($Name -eq 'ExistingModule')
                {
                    return [PSCustomObject] @{
                        Name        = 'ExistingModule'
                        Version     = [System.Version] '1.0.0'
                        PrivateData = [PSCustomObject] @{
                            PSData = [PSCustomObject] @{
                                Prerelease = 'preview0001'
                            }
                        }
                    }
                }
                else
                {
                    throw "Cannot find the module '$Name'."
                }
            }
        }

        It 'Should return the module version' {
            $result = Get-ModuleVersion -Module 'ExistingModule'
            $result | Should -Be '1.0.0-preview0001'
        }
    }

    Context 'When the module is passed as a string and does not exist' {
        It 'Should throw an error' {
            { Get-ModuleVersion -Module 'NonExistingModule' -ErrorAction 'Stop' } | Should -Throw -ExpectedMessage "Cannot find the module 'NonExistingModule'. Make sure it is loaded into the session."
        }
    }

    Context 'When the module is passed as a PSModuleInfo object' {
        It 'Should return the module version' {
            # Using a module that is guaranteed to exist.
            $moduleInfo = Get-Module -Name 'Microsoft.PowerShell.Utility' -ListAvailable

            $result = Get-ModuleVersion -Module $moduleInfo
            $result | Should -Be $moduleInfo.Version.ToString()
        }
    }

    Context 'When the module is passed as an invalid type' {
        It 'Should throw an error' {
            { Get-ModuleVersion -Module 123 -ErrorAction 'Stop' } | Should -Throw -ExpectedMessage "Invalid parameter type. The parameter 'Module' must be either a string or a PSModuleInfo object."
        }
    }
}
